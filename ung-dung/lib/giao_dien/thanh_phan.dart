import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../nghiep_vu/ung_dung.dart';

String tien(dynamic n) => NumberFormat.currency(
  locale: 'vi_VN',
  symbol: 'đ',
  decimalDigits: 0,
).format(n ?? 0);
String ngay(dynamic s) {
  final d = DateTime.tryParse(s?.toString() ?? '');
  return d == null
      ? ''
      : DateFormat('dd/MM/yyyy HH:mm')
            .format(d.toUtc().add(const Duration(hours: 7)));
}

const nhan = {
  'ThanhVien': 'Thành viên',
  'QuanTri': 'Quản trị viên',
  'UngVien': 'Ứng viên',
  'NhaTuyenDung': 'Nhà tuyển dụng',
  'ChoDuyet': 'Chờ duyệt',
  'DaDuyet': 'Đã duyệt',
  'BiTuChoi': 'Bị từ chối',
  'TamKhoa': 'Tạm khóa',
  'BanNhap': 'Bản nháp',
  'DangTuyen': 'Đang tuyển',
  'DaDong': 'Đã đóng',
  'BiAn': 'Bị ẩn',
  'ChoThanhToan': 'Chờ thanh toán',
  'DaThanhToan': 'Đã thanh toán',
  'DaHuy': 'Đã hủy',
  'DaGui': 'Đã gửi',
  'DangXemXet': 'Đang xem xét',
  'MoiPhongVan': 'Mời phỏng vấn',
  'TuChoi': 'Từ chối',
  'DaRut': 'Đã rút',
  'DaTuyen': 'Đã tuyển',
  'ToanThoiGian': 'Toàn thời gian',
  'BanThoiGian': 'Bán thời gian',
  'TuXa': 'Từ xa',
  'DichVu': 'Dịch vụ',
  'NganhNghe': 'Ngành nghề',
  'MienPhiLanDau': 'Tặng lượt lần đầu',
  'DuLieuMau': 'C\u1ea5p l\u01b0\u1ee3t cho tin tuy\u1ec3n d\u1ee5ng m\u1eabu',
  'MuaLuot': 'Mua lượt',
  'GiuLuot': 'Giữ lượt',
  'SuDungLuot': 'Sử dụng lượt',
  'TraLuotTuChoi': 'Trả lượt do từ chối',
  'TraLuotRut': 'Trả lượt khi rút',
};
String tenNhan(dynamic v) => nhan[v] ?? v?.toString() ?? '';
void bao(BuildContext c, Object e) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(e.toString())));
Future<bool> xacNhan(BuildContext c, String nd) async =>
    await showDialog<bool>(
      context: c,
      builder: (c) => AlertDialog(
        title: const Text('Xác nhận thao tác'),
        content: Text(nd),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    ) ??
    false;
Future<void> thucHien(BuildContext c, Future<void> Function() f) async {
  try {
    await f();
  } catch (e) {
    if (c.mounted) bao(c, e);
  }
}

class NhanTrangThai extends StatelessWidget {
  final String giaTri;
  const NhanTrangThai(this.giaTri, {super.key});
  @override
  Widget build(BuildContext c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xffeef2ff),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      tenNhan(giaTri),
      style: const TextStyle(
        fontSize: 12,
        color: Color(0xff4338ca),
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class ManDanhSach extends StatefulWidget {
  final Widget Function(List<dynamic>, VoidCallback)? phanDau;
  final List<Widget> hanhDong;
  final UngDung ung;
  final String tieuDe, duongDan;
  final String? thamSo, tuKhoaBanDau;
  final Widget Function(Map<String, dynamic>, VoidCallback) ve;
  final Future<void> Function()? them;
  final bool timKiem;
  const ManDanhSach({
    super.key,
    required this.ung,
    required this.tieuDe,
    required this.duongDan,
    required this.ve,
    this.them,
    this.thamSo,
    this.tuKhoaBanDau,
    this.timKiem = true,
    this.hanhDong = const [],
    this.phanDau,
  });
  @override
  State<ManDanhSach> createState() => _ManDanhSachState();
}

class _ManDanhSachState extends State<ManDanhSach> {
  int lanDoc = 0;
  final tim = TextEditingController();
  int trang = 1, tong = 0, kichThuoc = 12;
  List ds = [];
  bool tai = true, cu = false;
  String? loi, capNhat;
  @override
  void initState() {
    super.initState();
    tim.text = widget.tuKhoaBanDau ?? '';
    doc();
  }

  @override
  void didUpdateWidget(covariant ManDanhSach old) {
    super.didUpdateWidget(old);
    if (old.duongDan != widget.duongDan || old.thamSo != widget.thamSo) {
      trang = 1;
      tim.clear();
      doc();
    }
  }

  @override
  void dispose() {
    tim.dispose();
    super.dispose();
  }

  Future<void> doc() async {
    final lan = ++lanDoc;
    setState(() => tai = true);
    try {
      final sep = widget.duongDan.contains('?') ? '&' : '?';
      final kq = await widget.ung.danhSach(
        '${widget.duongDan}${sep}trang=$trang&q=${Uri.encodeComponent(tim.text)}${widget.thamSo ?? ''}',
      );
      if (!mounted || lan != lanDoc) return;
      setState(() {
        ds = kq is List ? kq : kq['duLieu'] ?? [];
        tong = kq is List ? ds.length : kq['tong'] ?? 0;
        kichThuoc = kq is List ? ds.length : kq['kichThuoc'] ?? 12;
        loi = null;
        cu = widget.ung.api.duLieuCu;
        capNhat = widget.ung.api.capNhat;
      });
    } catch (e) {
      if (mounted && lan == lanDoc) setState(() => loi = e.toString());
    } finally {
      if (mounted && lan == lanDoc) setState(() => tai = false);
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: Text(widget.tieuDe),
      actions: [
        ...widget.hanhDong,
        IconButton(
          onPressed: tai ? null : doc,
          icon: const Icon(Icons.refresh),
          tooltip: 'Tải lại',
        ),
      ],
    ),
    floatingActionButton: widget.them == null
        ? null
        : FloatingActionButton.extended(
            onPressed: () => thucHien(c, () async {
              await widget.them!();
              await doc();
            }),
            label: const Text('Thêm mới'),
            icon: const Icon(Icons.add),
          ),
    body: Column(
      children: [
        if (widget.timKiem)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: TextField(
              controller: tim,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm ${widget.tieuDe.toLowerCase()}',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: () {
                    trang = 1;
                    doc();
                  },
                  icon: const Icon(Icons.arrow_forward),
                ),
              ),
              onSubmitted: (_) {
                trang = 1;
                doc();
              },
            ),
          ),
        if (cu)
          Container(
            width: double.infinity,
            color: Colors.amber.shade100,
            padding: const EdgeInsets.all(12),
            child: Text(
              'Dữ liệu đã lưu • ${ngay(capNhat)}. Thao tác cần mạng.',
            ),
          ),
        if (!tai && loi == null && widget.phanDau != null)
          widget.phanDau!(ds, doc),
        Expanded(
          child: tai
              ? const Center(child: CircularProgressIndicator())
              : loi != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off, size: 48),
                        const SizedBox(height: 16),
                        Text(loi!, textAlign: TextAlign.center),
                        TextButton(
                          onPressed: doc,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                )
              : ds.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 56,
                        color: Colors.blueGrey,
                      ),
                      SizedBox(height: 12),
                      Text('Chưa có dữ liệu phù hợp'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: doc,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                    itemCount: ds.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (c, i) =>
                        widget.ve(Map<String, dynamic>.from(ds[i]), doc),
                  ),
                ),
        ),
        if (tong > ds.length || trang > 1)
          SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: trang > 1 && !tai
                      ? () {
                          trang--;
                          doc();
                        }
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('Trang $trang • $tong kết quả'),
                IconButton(
                  onPressed: !tai && trang * kichThuoc < tong
                      ? () {
                          trang++;
                          doc();
                        }
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class TheNoiDung extends StatelessWidget {
  final String tieuDe;
  final String? phu, trangThai;
  final Widget? anh;
  final List<Widget> hanhDong;
  final VoidCallback? mo;
  const TheNoiDung({
    super.key,
    required this.tieuDe,
    this.phu,
    this.trangThai,
    this.anh,
    this.hanhDong = const [],
    this.mo,
  });
  @override
  Widget build(BuildContext c) => Card(
    child: InkWell(
      onTap: mo,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (anh != null) ...[anh!, const SizedBox(width: 12)],
                Expanded(
                  child: Text(
                    tieuDe,
                    style: Theme.of(c).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (trangThai != null)
                  Flexible(child: NhanTrangThai(trangThai!)),
              ],
            ),
            if (phu != null) ...[
              const SizedBox(height: 10),
              Text(
                phu!,
                style: const TextStyle(color: Color(0xff526177), height: 1.5),
              ),
            ],
            if (hanhDong.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 4, children: hanhDong),
            ],
          ],
        ),
      ),
    ),
  );
}

class TheGoiDangTin extends StatelessWidget {
  final String tieuDe, moTa, gia;
  final int soLuot;
  final Widget? anh;
  final bool dangBan;
  final List<Widget> hanhDong;
  final VoidCallback? mo;
  const TheGoiDangTin({
    super.key,
    required this.tieuDe,
    required this.moTa,
    required this.gia,
    required this.soLuot,
    this.anh,
    this.dangBan = true,
    this.hanhDong = const [],
    this.mo,
  });

  @override
  Widget build(BuildContext c) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: mo,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (anh != null) ...[anh!, const SizedBox(width: 14)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tieuDe,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(c).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        moTa.isEmpty ? 'Gói lượt đăng tin' : moTa,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xff647084),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  dangBan ? Icons.check_circle : Icons.pause_circle_outline,
                  color: dangBan ? const Color(0xff21845a) : Colors.blueGrey,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xfff4f1ff),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded, color: Color(0xff6250d8)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$soLuot lượt đăng tin',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    gia,
                    style: const TextStyle(
                      color: Color(0xff4338ca),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            if (hanhDong.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 4, children: hanhDong),
            ],
          ],
        ),
      ),
    ),
  );
}

class TheDongGioHang extends StatelessWidget {
  final String tieuDe, chiTiet;
  final Widget? anh;
  final bool doiGia;
  final List<Widget> hanhDong;
  const TheDongGioHang({
    super.key,
    required this.tieuDe,
    required this.chiTiet,
    required this.hanhDong,
    this.anh,
    this.doiGia = false,
  });

  @override
  Widget build(BuildContext c) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (anh != null) ...[anh!, const SizedBox(width: 12)],
              Expanded(
                child: Text(
                  tieuDe,
                  style: Theme.of(c).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const Icon(Icons.shopping_bag_outlined, color: Color(0xff6250d8)),
            ],
          ),
          const SizedBox(height: 10),
          Text(chiTiet, style: const TextStyle(height: 1.5)),
          if (doiGia) ...[
            const SizedBox(height: 10),
            const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xffa15c00), size: 18),
                SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Giá đã thay đổi. Cập nhật và xác nhận giá mới trước khi đặt.',
                    style: TextStyle(color: Color(0xff8a4b00)),
                  ),
                ),
              ],
            ),
          ],
          if (hanhDong.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 4, children: hanhDong),
          ],
        ],
      ),
    ),
  );
}

class TheDonMuaLuot extends StatelessWidget {
  final String ma, taoLuc, trangThai, tongTien;
  final int tongLuot;
  final VoidCallback mo;
  final List<Widget> hanhDong;
  const TheDonMuaLuot({
    super.key,
    required this.ma,
    required this.taoLuc,
    required this.trangThai,
    required this.tongTien,
    required this.tongLuot,
    required this.mo,
    this.hanhDong = const [],
  });

  @override
  Widget build(BuildContext c) => Card(
    child: InkWell(
      onTap: mo,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xffeeeaff),
                  child: Icon(Icons.receipt_long, color: Color(0xff6250d8)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    ma,
                    style: Theme.of(c).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                NhanTrangThai(trangThai),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tổng thanh toán',
                        style: TextStyle(color: Color(0xff687385)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tongTien,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xfff4f1ff),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$tongLuot lượt',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(taoLuc, style: const TextStyle(color: Color(0xff687385))),
            if (hanhDong.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 4, children: hanhDong),
            ],
          ],
        ),
      ),
    ),
  );
}

class TheHoSoUngTuyen extends StatelessWidget {
  final String tieuDe, ngayNop, trangThai;
  final String? thuGioiThieu;
  final List<Widget> hanhDong;
  final VoidCallback? mo;
  const TheHoSoUngTuyen({
    super.key,
    required this.tieuDe,
    required this.ngayNop,
    required this.trangThai,
    required this.hanhDong,
    this.thuGioiThieu,
    this.mo,
  });

  @override
  Widget build(BuildContext c) => Card(
    child: InkWell(
      onTap: mo,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xffedf4ff),
                  child: Icon(
                    Icons.assignment_ind_outlined,
                    color: Color(0xff385f9f),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tieuDe,
                        style: Theme.of(c).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Nộp ngày $ngayNop',
                        style: const TextStyle(color: Color(0xff687385)),
                      ),
                    ],
                  ),
                ),
                NhanTrangThai(trangThai),
              ],
            ),
            if (thuGioiThieu?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Text(
                thuGioiThieu!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(height: 1.5),
              ),
            ],
            if (hanhDong.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 4, children: hanhDong),
            ],
          ],
        ),
      ),
    ),
  );
}

class TheCvCaNhan extends StatelessWidget {
  final String ten, ngayTai;
  final List<Widget> hanhDong;
  const TheCvCaNhan({
    super.key,
    required this.ten,
    required this.ngayTai,
    required this.hanhDong,
  });

  @override
  Widget build(BuildContext c) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xffffefef),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_outlined,
                  color: Color(0xffbd4141),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ten,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(c).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PDF • Tải lên $ngayTai',
                      style: const TextStyle(color: Color(0xff687385)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hanhDong.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 4, children: hanhDong),
          ],
        ],
      ),
    ),
  );
}

class TacVuQuanTri {
  final String ten;
  final IconData bieuTuong;
  final VoidCallback bam;
  const TacVuQuanTri(this.ten, this.bieuTuong, this.bam);
}

class NhomTacVuQuanTri extends StatelessWidget {
  final String tieuDe, moTa;
  final List<TacVuQuanTri> tacVu;
  const NhomTacVuQuanTri({
    super.key,
    required this.tieuDe,
    required this.moTa,
    required this.tacVu,
  });

  @override
  Widget build(BuildContext c) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tieuDe,
            style: Theme.of(c).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(moTa, style: const TextStyle(color: Color(0xff687385))),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (c, box) {
              final rong = (box.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final muc in tacVu)
                    SizedBox(
                      width: rong,
                      child: InkWell(
                        onTap: muc.bam,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 82),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xfff7f5ff),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xffebe7f8)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(
                                muc.bieuTuong,
                                color: const Color(0xff6250d8),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                muc.ten,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
}
