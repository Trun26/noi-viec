package vn.mobi.ung_dung

import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.graphics.pdf.PdfDocument
import android.graphics.pdf.PdfRenderer
import android.os.ParcelFileDescriptor
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val cvExecutor = Executors.newSingleThreadExecutor()
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "vn.noiviec/cv").setMethodCallHandler { call, result ->
            if (call.method !in listOf("taoPdf", "xemTrang")) {
                result.notImplemented()
            } else {
                cvExecutor.execute {
                    try {
                        val value: Any = if (call.method == "taoPdf") {
                            val fields = call.argument<Map<String, String>>("duLieu") ?: error("Thiếu nội dung CV")
                            taoPdf(fields, call.argument<String>("mau") == "toiGian")
                        } else {
                            val bytes = call.argument<ByteArray>("pdf") ?: error("Thiếu PDF")
                            xemTrang(bytes, call.argument<Int>("trang") ?: 0)
                        }
                        runOnUiThread { result.success(value) }
                    } catch (e: Exception) {
                        runOnUiThread { result.error("CV_PDF", e.message ?: "Không tạo được CV", null) }
                    }
                }
            }
        }
    }
    override fun onDestroy() {
        cvExecutor.shutdown()
        super.onDestroy()
    }
    private fun taoPdf(fields: Map<String, String>, simple: Boolean): Map<String, Any> {
        require(fields.values.sumOf { it.length } <= 24000) { "Nội dung CV quá dài" }
        require(!fields["hoTen"].isNullOrBlank()) { "Nhập họ và tên" }
        val doc = PdfDocument()
        val accent = if (simple) Color.rgb(35, 48, 65) else Color.rgb(98, 80, 216)
        val paint = TextPaint(Paint.ANTI_ALIAS_FLAG)
        var page: PdfDocument.Page? = null
        var y = 0f
        var count = 0
        fun footer() {
            paint.textSize = 9f
            paint.color = Color.GRAY
            paint.typeface = Typeface.create("sans-serif", Typeface.NORMAL)
            page!!.canvas.drawText("${fields["hoTen"]}  •  ${count}", 48f, 813f, paint)
            doc.finishPage(page!!)
            page = null
        }
        fun newPage() {
            if (page != null) footer()
            count++
            require(count <= 12) { "CV vượt quá 12 trang. Hãy rút gọn nội dung." }
            page = doc.startPage(PdfDocument.PageInfo.Builder(595, 842, count).create())
            page!!.canvas.drawColor(Color.WHITE)
            val bar = Paint().apply { color = accent }
            page!!.canvas.drawRect(0f, 0f, 595f, if (simple) 5f else 12f, bar)
            y = 48f
        }
        fun text(value: String, size: Float, bold: Boolean, color: Int) {
            if (value.isBlank()) return
            paint.textSize = size
            paint.color = color
            paint.typeface = Typeface.create("sans-serif", if (bold) Typeface.BOLD else Typeface.NORMAL)
            val layout = StaticLayout.Builder.obtain(value, 0, value.length, paint, 499)
                .setAlignment(Layout.Alignment.ALIGN_NORMAL).setIncludePad(false).build()
            for (i in 0 until layout.lineCount) {
                val height = size * 1.55f
                if (y + height > 785f) {
                    newPage()
                    // Page footer changes the shared paint, so restore this paragraph's style.
                    paint.textSize = size
                    paint.color = color
                    paint.typeface = Typeface.create("sans-serif", if (bold) Typeface.BOLD else Typeface.NORMAL)
                }
                val line = value.substring(layout.getLineStart(i), layout.getLineEnd(i)).trimEnd('\n', '\r')
                page!!.canvas.drawText(line, 48f, y + size, paint)
                y += height
            }
        }
        try {
            newPage()
            text(fields["hoTen"].orEmpty(), 26f, true, accent)
            text(fields["viTriMongMuon"].orEmpty(), 14f, true, Color.DKGRAY)
            y += 10f
            for (key in listOf("email", "lienHe", "diaChi", "lienKet")) {
                text(fields[key].orEmpty(), 11f, false, Color.DKGRAY)
            }
            y += 12f
            for ((key, title) in linkedMapOf("gioiThieu" to "GIỚI THIỆU", "kinhNghiem" to "KINH NGHIỆM LÀM VIỆC", "hocVan" to "HỌC VẤN", "kyNang" to "KỸ NĂNG", "duAn" to "DỰ ÁN", "chungChi" to "CHỨNG CHỈ & THÀNH TÍCH")) {
                val value = fields[key].orEmpty().trim()
                if (value.isEmpty()) continue
                if (y + 65f > 785f) newPage()
                text(title, 12f, true, accent)
                y += 5f
                text(value, 11f, false, Color.rgb(50, 50, 60))
                y += 17f
            }
            footer()
            val output = ByteArrayOutputStream()
            doc.writeTo(output)
            return mapOf("pdf" to output.toByteArray(), "soTrang" to count)
        } finally {
            if (page != null) doc.finishPage(page!!)
            doc.close()
        }
    }
    private fun xemTrang(bytes: ByteArray, index: Int): ByteArray {
        require(bytes.size <= 10 * 1024 * 1024) { "PDF quá lớn" }
        val temp = File.createTempFile("cv-preview-", ".pdf", cacheDir)
        try {
            temp.writeBytes(bytes)
            ParcelFileDescriptor.open(temp, ParcelFileDescriptor.MODE_READ_ONLY).use { fd ->
                PdfRenderer(fd).use { renderer ->
                    require(index in 0 until renderer.pageCount) { "Trang không hợp lệ" }
                    renderer.openPage(index).use { p ->
                        val bitmap = Bitmap.createBitmap(900, (900f * p.height / p.width).toInt(), Bitmap.Config.ARGB_8888)
                        try {
                            bitmap.eraseColor(Color.WHITE)
                            p.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                            val out = ByteArrayOutputStream()
                            bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
                            return out.toByteArray()
                        } finally { bitmap.recycle() }
                    }
                }
            }
        } finally { temp.delete() }
    }
}
