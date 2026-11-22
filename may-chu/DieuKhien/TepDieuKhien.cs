using MayChu.DuLieu;
using MayChu.NghiepVu;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using static MayChu.NghiepVu.PhienLamViec;
namespace MayChu.DieuKhien;

[ApiController, Route("api/v1")]
public class TepDieuKhien(KhoDuLieu db, PhienLamViec phien, IWebHostEnvironment moiTruong) : ControllerBase
{
    [HttpPost("tep"), RequestSizeLimit(11 * 1024 * 1024)]
    public async Task<object> TaiLen(IFormFile tep, [FromForm] string loai)
    {
        var tk = await phien.Nguoi(Request);
        KiemTra(loai is "Anh" or "CV", "Loại tập tin không hợp lệ.");
        KiemTra(loai != "CV" || tk.Loai == "UngVien", "Chỉ ứng viên tải CV.", 403);
        KiemTra(loai != "Anh" || tk.VaiTro == "QuanTri", "Chỉ quản trị tải ảnh dịch vụ.", 403);
        KiemTra(tep.Length > 0 && tep.Length <= (loai == "CV" ? 10 : 5) * 1024 * 1024, "Tập tin vượt giới hạn hoặc trống (CV 10 MB, ảnh 5 MB).");
        await using var s = tep.OpenReadStream();
        var dau = new byte[12];
        var n = await s.ReadAsync(dau);
        string mime, duoi;
        if (loai == "CV")
        {
            KiemTra(n >= 5 && System.Text.Encoding.ASCII.GetString(dau, 0, 5) == "%PDF-" && Path.GetExtension(tep.FileName).Equals(".pdf", StringComparison.OrdinalIgnoreCase), "CV phải là tập tin PDF.");
            mime = "application/pdf";
            duoi = ".pdf";
        }
        else if (n >= 8 && dau.Take(8).SequenceEqual(new byte[] { 137, 80, 78, 71, 13, 10, 26, 10 }))
        {
            mime = "image/png";
            duoi = ".png";
        }
        else if (n >= 3 && dau[0] == 255 && dau[1] == 216 && dau[2] == 255)
        {
            mime = "image/jpeg";
            duoi = ".jpg";
        }
        else
            throw new LoiNghiepVu("Ảnh phải là PNG hoặc JPEG hợp lệ.");
        var thuMuc = Path.Combine(moiTruong.ContentRootPath, "kho-tep");
        Directory.CreateDirectory(thuMuc);
        var t = new Tep { ChuSoHuuId = tk.Id, Ten = Path.GetFileName(tep.FileName), Loai = loai, Mime = mime };
        t.DuongDan = Path.Combine(thuMuc, t.Id + duoi);
        try
        {
            await using (var ra = System.IO.File.Create(t.DuongDan))
            {
                await ra.WriteAsync(dau.AsMemory(0, n));
                await s.CopyToAsync(ra);
            }
            db.Add(t);
            await db.SaveChangesAsync();
        }
        catch { if (System.IO.File.Exists(t.DuongDan)) System.IO.File.Delete(t.DuongDan); throw; }
        return new
        {
            t.Id,
            t.Ten,
            t.Loai
        };
    }
    [HttpGet("tep")]
    public async Task<object> TepToi()
    {
        var tk = await phien.Nguoi(Request);
        return await db.Tep.Where(x => x.ChuSoHuuId == tk.Id && x.Loai == "CV").Select(x => new { x.Id, x.Ten, x.TaoLuc }).ToListAsync();
    }
    [HttpGet("tep/{id:guid}")]
    public async Task<IActionResult> Tai(Guid id)
    {
        var t = await db.Tep.FindAsync(id) ?? throw new LoiNghiepVu("Không tìm thấy tập tin.", 404);
        if (t.Loai != "Anh")
        {
            var tk = await phien.Nguoi(Request);
            var coQuyen = t.ChuSoHuuId == tk.Id || tk.VaiTro == "QuanTri" || tk.Loai == "NhaTuyenDung" && await db.HoSo.AnyAsync(h => h.CvId == id && db.Tin.Any(tin => tin.Id == h.TinId && tin.DoanhNghiepId == tk.DoanhNghiepId));
            KiemTra(coQuyen, "Bạn không có quyền xem CV.", 403);
        }
        KiemTra(System.IO.File.Exists(t.DuongDan), "Tập tin không còn trên máy chủ.", 404);
        Response.Headers.CacheControl = t.Loai == "CV" ? "no-store" : "public, max-age=300";
        return PhysicalFile(t.DuongDan, t.Mime, t.Ten);
    }
    [HttpDelete("tep/{id:guid}")]
    public async Task<object> Xoa(Guid id)
    {
        var tk = await phien.Nguoi(Request);
        var t = await db.Tep.SingleOrDefaultAsync(x => x.Id == id && x.ChuSoHuuId == tk.Id) ?? throw new LoiNghiepVu("Không tìm thấy tập tin.", 404);
        KiemTra(!await db.HoSo.AnyAsync(x => x.CvId == id) && !await db.GoiLuot.AnyAsync(x => x.AnhId == id) && !await db.DanhMuc.AnyAsync(x => x.AnhId == id), "Tập tin đang được tham chiếu, không thể xóa.", 409);
        db.Remove(t);
        await db.SaveChangesAsync();
        if (System.IO.File.Exists(t.DuongDan))
            System.IO.File.Delete(t.DuongDan);
        return new
        {
            thongBao = "Đã xóa tập tin."
        };
    }
    [HttpGet("thong-bao")]
    public async Task<object> ThongBao(int trang = 1)
    {
        var tk = await phien.Nguoi(Request);
        return await Trang(db.ThongBao.Where(x => x.TaiKhoanId == tk.Id).OrderByDescending(x => x.TaoLuc), trang, 20);
    }
    [HttpPut("thong-bao/{id:guid}/da-doc")]
    public async Task<object> Doc(Guid id)
    {
        var tk = await phien.Nguoi(Request);
        var tb = await db.ThongBao.SingleOrDefaultAsync(x => x.Id == id && x.TaiKhoanId == tk.Id) ?? throw new LoiNghiepVu("Không tìm thấy thông báo.", 404);
        tb.DaDoc = true;
        await db.SaveChangesAsync();
        return tb;
    }
    [HttpGet("thong-ke")]
    public async Task<object> ThongKe(DateTime? tuNgay, DateTime? denNgay)
    {
        var tk = await phien.Nguoi(Request);
        var hs = db.HoSo.Where(x => (tuNgay == null || x.TaoLuc >= tuNgay) && (denNgay == null || x.TaoLuc < denNgay));
        if (tk.VaiTro != "QuanTri")
            hs = hs.Where(x => tk.Loai == "UngVien" ? x.UngVienId == tk.Id : db.Tin.Any(t => t.Id == x.TinId && t.DoanhNghiepId == tk.DoanhNghiepId));
        var ketQua = await hs.GroupBy(x => x.TrangThai).Select(x => new { trangThai = x.Key, soLuong = x.Count() }).ToListAsync();
        if (tk.VaiTro == "QuanTri")
            return new
            {
                hoSo = ketQua,
                taiKhoan = await db.TaiKhoan.CountAsync(),
                doanhNghiep = await db.DoanhNghiep.CountAsync(),
                tin = await db.Tin.CountAsync(),
                doanhThu = await db.DonHang.Where(x => x.TrangThai == "DaThanhToan" && (tuNgay == null || x.XacNhanLuc >= tuNgay) && (denNgay == null || x.XacNhanLuc < denNgay)).SumAsync(x => (decimal?)x.TongTien) ?? 0
            };
        return new
        {
            hoSo = ketQua
        };
    }
}
