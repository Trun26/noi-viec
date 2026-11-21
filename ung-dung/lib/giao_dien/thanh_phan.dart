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
      : DateFormat(
          'dd/MM/yyyy HH:mm',
        ).format(d.toUtc().add(const Duration(hours: 7)));
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
                    style: Theme.of(c).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
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
