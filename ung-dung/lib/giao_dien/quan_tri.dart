import 'package:flutter/material.dart';

import '../nghiep_vu/ung_dung.dart';
import 'thanh_phan.dart';
import 'chuc_nang.dart';

class TongQuanQuanTri extends StatefulWidget {
  final UngDung ung;
  final VoidCallback thongBao;
  const TongQuanQuanTri({super.key, required this.ung, required this.thongBao});
  @override
  State<TongQuanQuanTri> createState() => _TongQuanQuanTriState();
}

class _TongQuanQuanTriState extends State<TongQuanQuanTri> {
  late Future<dynamic> duLieu;
  @override
  void initState() {
    super.initState();
    tai();
  }

  void tai() {
    duLieu = widget.ung.danhSach('quan-tri/tong-quan');
  }

  @override
  Widget build(BuildContext c) => RefreshIndicator(
    onRefresh: () async {
      setState(tai);
      await duLieu;
    },
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xff6250d8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.work_rounded, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Nối Việc',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
              ),
            ),
            IconButton(
              tooltip: 'Thông báo',
              onPressed: widget.thongBao,
              icon: const Icon(Icons.notifications_outlined),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Tổng quan quản trị',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        FutureBuilder<dynamic>(
          future: duLieu,
          builder: (c, s) {
            if (s.hasError)
              return Column(
                children: [
                  Text(s.error.toString()),
                  TextButton(
                    onPressed: () => setState(tai),
                    child: const Text('Tải lại'),
                  ),
                ],
              );
            if (!s.hasData)
              return const Center(child: CircularProgressIndicator());
            final d = s.data as Map;
            final cot = List<Map<String, dynamic>>.from(
              (d['doanhThu'] as List).map((x) => Map<String, dynamic>.from(x)),
            );
            final caoNhat = cot.fold<double>(
              0,
              (a, b) => (b['tien'] as num).toDouble() > a
                  ? (b['tien'] as num).toDouble()
                  : a,
            );
            final tong = cot.fold<num>(0, (a, b) => a + (b['tien'] as num));
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (c, box) => Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final e in {
                        'nguoiDung': 'Người dùng',
                        'doanhNghiep': 'Doanh nghiệp hoạt động',
                        'donMoi': 'Đơn mua chờ thanh toán',
                        'tinDang': 'Tin đang đăng',
                      }.entries)
                        SizedBox(
                          width: (box.maxWidth - 10) / 2,
                          child: Card(
                            margin: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${d[e.key]}',
                                    style: const TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xff6250d8),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(e.value),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Doanh thu đơn mua',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  tien(tong),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xff6250d8),
                  ),
                ),
                const Text(
                  '6 tháng gần nhất • tính theo ngày xác nhận thanh toán',
                ),
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (caoNhat == 0)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Text('Chưa có doanh thu đã thanh toán.'),
                          ),
                        SizedBox(
                          height: 200,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              for (final x in cot)
                                Expanded(
                                  child: Tooltip(
                                    message: '${x['nhan']}: ${tien(x['tien'])}',
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Container(
                                            height:
                                                caoNhat == 0 || x['tien'] == 0
                                                ? 2
                                                : 150 *
                                                      (x['tien'] as num) /
                                                      caoNhat,
                                            decoration: BoxDecoration(
                                              color: const Color(0xff7964e8),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            x['nhan'],
                                            style: const TextStyle(
                                              fontSize: 10,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        for (final x in cot)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(child: Text(x['nhan'])),
                                Text(tien(x['tien'])),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const Text(
                  'Đơn chờ thanh toán và đơn đã hủy không được tính vào doanh thu. Thanh toán hiện ở chế độ trình diễn.',
                  style: TextStyle(color: Colors.blueGrey),
                ),
              ],
            );
          },
        ),
      ],
    ),
  );
}
class NguoiDungQuanTri extends StatefulWidget {
  final UngDung ung;
  const NguoiDungQuanTri({super.key, required this.ung});
  @override
  State<NguoiDungQuanTri> createState() => _NguoiDungQuanTriState();
}

String vaiTroNguoi(Map<String, dynamic> d) => d['vaiTro'] == 'QuanTri'
    ? 'Quản trị'
    : d['loai'] == 'UngVien'
    ? 'Ứng viên'
    : d['doanhNghiepId'] == null
    ? 'Tuyển dụng'
    : d['phuTrach'] == true
    ? 'Phụ trách'
    : 'Nhân viên';

class _NguoiDungQuanTriState extends State<NguoiDungQuanTri> {
  final tim = TextEditingController();
  String nhom = '';
  late Future<void> duLieu;
  List<Map<String, dynamic>> nguoi = [], doanhNghiep = [];
  @override
  void initState() {
    super.initState();
    duLieu = tai();
  }

  @override
  void dispose() {
    tim.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> layHet(String dd) async {
    final ds = <Map<String, dynamic>>[];
    var trang = 1;
    while (true) {
      final kq = await widget.ung.danhSach(
        '$dd${dd.contains('?') ? '&' : '?'}trang=$trang',
      );
      ds.addAll(
        (kq['duLieu'] as List).map((x) => Map<String, dynamic>.from(x)),
      );
      if (trang * (kq['kichThuoc'] as num) >= (kq['tong'] as num)) break;
      trang++;
    }
    return ds;
  }

  Future<void> tai() async {
    final kq = await Future.wait([
      layHet('quan-tri/nguoi-dung'),
      layHet('doanh-nghiep?quanLy=true'),
    ]);
    if (!mounted) return;
    nguoi = kq[0];
    doanhNghiep = kq[1];
  }

  void taiLai() {
    setState(() => duLieu = tai());
  }

  Future<void> moNguoi([Map<String, dynamic>? d]) async {
    final doi = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          HopNguoiDung(ung: widget.ung, nguoi: d, doanhNghiep: doanhNghiep),
    );
    if (doi == true && mounted) taiLai();
  }

  bool khop(Map<String, dynamic> d) {
    if (!'${d['hoTen']} ${d['email']} ${d['tenDoanhNghiep'] ?? ''}'
        .toLowerCase()
        .contains(tim.text.trim().toLowerCase()))
      return false;
    return switch (nhom) {
      'QuanTri' => d['vaiTro'] == 'QuanTri',
      'UngVien' => d['loai'] == 'UngVien' && d['vaiTro'] != 'QuanTri',
      'ChuaGan' =>
        d['loai'] == 'NhaTuyenDung' &&
            d['doanhNghiepId'] == null &&
            d['vaiTro'] != 'QuanTri',
      'NhanVien' =>
        d['loai'] == 'NhaTuyenDung' &&
            d['doanhNghiepId'] != null &&
            d['vaiTro'] != 'QuanTri',
      _ => true,
    };
  }

  Widget theNguoi(Map<String, dynamic> d) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => moNguoi(d),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.person_outline, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d['hoTen'] ?? '', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(vaiTroNguoi(d), style: const TextStyle(fontSize: 16)),
                  if (d['tenDoanhNghiep'] != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      d['tenDoanhNghiep'],
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                  if (d['biKhoa'] == true)
                    const Text('Đã khóa', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext c) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Người dùng',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              tooltip: 'Tải lại',
              onPressed: taiLai,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextField(
          controller: tim,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Tìm tên, email hoặc doanh nghiệp',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              tooltip: 'Xóa tìm kiếm',
              onPressed: () {
                tim.clear();
                setState(() {});
              },
              icon: const Icon(Icons.close),
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final x in {
                      'UngVien': 'Ứng viên',
                      'ChuaGan': 'Tuyển dụng',
                      'NhanVien': 'Doanh nghiệp',
                      'QuanTri': 'Quản trị',
                    }.entries)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(x.value),
                          selected: nhom == x.key,
                          onSelected: (v) =>
                              setState(() => nhom = v ? x.key : ''),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            FutureBuilder<void>(
              future: duLieu,
              builder: (c, s) => IconButton.filled(
                tooltip: 'Thêm mới',
                onPressed:
                    s.connectionState == ConnectionState.done && !s.hasError
                    ? () => moNguoi()
                    : null,
                icon: const Icon(Icons.add),
              ),
            ),
          ],
        ),
      ),
      Expanded(
        child: FutureBuilder<void>(
          future: duLieu,
          builder: (c, s) {
            if (s.hasError)
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(s.error.toString()),
                      TextButton(
                        onPressed: taiLai,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              );
            if (s.connectionState != ConnectionState.done)
              return const Center(child: CircularProgressIndicator());
            final ds = nguoi.where(khop).toList();
            return RefreshIndicator(
              onRefresh: () async {
                taiLai();
                await duLieu;
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                children: [
                  if (nhom == 'NhanVien')
                    _NguoiPhanTrang(
                      key: ValueKey('doanh-nghiep-${tim.text}'),
                      donVi: 'doanh nghiệp',
                      ds: doanhNghiep
                          .where(
                            (dn) =>
                                tim.text.trim().isEmpty ||
                                ds.any((x) => x['doanhNghiepId'] == dn['id']) ||
                                dn['ten'].toString().toLowerCase().contains(
                                  tim.text.trim().toLowerCase(),
                                ),
                          )
                          .toList(),
                      ve: (dn) => Card(
                        child: ExpansionTile(
                          key: PageStorageKey('dn-${dn['id']}'),
                          title: Text(
                            dn['ten'],
                            style: const TextStyle(
                              color: Color(0xff6250d8),
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          children: [
                            for (final d in ds.where(
                              (d) => d['doanhNghiepId'] == dn['id'],
                            ))
                              theNguoi(d),
                            if (!ds.any((d) => d['doanhNghiepId'] == dn['id']))
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('Chưa có nhân viên phù hợp.'),
                              ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    if (ds.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Không có người dùng phù hợp.'),
                      ),
                    _NguoiPhanTrang(
                      key: ValueKey('$nhom-${tim.text}'),
                      ds: ds,
                      ve: theNguoi,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    ],
  );
}

class HopNguoiDung extends StatefulWidget {
  final UngDung ung;
  final Map<String, dynamic>? nguoi;
  final List<Map<String, dynamic>> doanhNghiep;
  const HopNguoiDung({
    super.key,
    required this.ung,
    required this.nguoi,
    required this.doanhNghiep,
  });
  @override
  State<HopNguoiDung> createState() => _HopNguoiDungState();
}

class _HopNguoiDungState extends State<HopNguoiDung> {
  final form = GlobalKey<FormState>();
  late final TextEditingController ten, email;
  final matKhau = TextEditingController();
  late String loai, quyen, doanhNghiepId;
  late bool khoa, sua;
  bool gui = false;
  String? loi;
  bool get moi => widget.nguoi == null;
  bool get chinhMinh => !moi && widget.nguoi?['id'] == widget.ung.nguoi?['id'];
  @override
  void initState() {
    super.initState();
    final d = widget.nguoi;
    ten = TextEditingController(text: d?['hoTen'] ?? '');
    email = TextEditingController(text: d?['email'] ?? '');
    loai = d?['loai'] ?? 'UngVien';
    quyen = d?['vaiTro'] ?? 'ThanhVien';
    doanhNghiepId = d?['doanhNghiepId'] ?? '';
    khoa = d?['biKhoa'] ?? false;
    sua = moi;
  }

  @override
  void dispose() {
    ten.dispose();
    email.dispose();
    matKhau.dispose();
    super.dispose();
  }

  Future<void> luu() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      gui = true;
      loi = null;
    });
    try {
      await widget.ung.xuLy(
        'quan-tri/nguoi-dung${moi ? '' : '/${widget.nguoi!['id']}'}',
        {
          'hoTen': ten.text.trim(),
          'email': email.text.trim(),
          'matKhau': matKhau.text,
          'loai': loai,
          'vaiTro': quyen,
          'doanhNghiepId': doanhNghiepId.isEmpty ? null : doanhNghiepId,
          'biKhoa': khoa,
        },
        cach: moi ? 'POST' : 'PUT',
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => loi = e.toString());
    } finally {
      if (mounted) setState(() => gui = false);
    }
  }

  Future<void> xoa() async {
    if (!await xacNhan(
      context,
      'Xóa tài khoản ${ten.text}? Tài khoản có dữ liệu liên quan sẽ được giữ lại.',
    ))
      return;
    if (!mounted) return;
    setState(() {
      gui = true;
      loi = null;
    });
    try {
      await widget.ung.xuLy(
        'quan-tri/nguoi-dung/${widget.nguoi!['id']}',
        {},
        cach: 'DELETE',
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => loi = e.toString());
    } finally {
      if (mounted) setState(() => gui = false);
    }
  }

  InputDecoration nhan(String t) => InputDecoration(
    labelText: t,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );
  Widget chon(
    String t,
    String v,
    Map<String, String> ds,
    void Function(String) doi,
  ) => DropdownButtonFormField<String>(
    key: ValueKey('$t-$v'),
    initialValue: ds.containsKey(v) ? v : null,
    isExpanded: true,
    decoration: nhan(t),
    items: ds.entries
        .map((x) => DropdownMenuItem(value: x.key, child: Text(x.value)))
        .toList(),
    onChanged: gui
        ? null
        : (x) {
            if (x != null) setState(() => doi(x));
          },
  );
  @override
  Widget build(BuildContext c) => Dialog(
    insetPadding: const EdgeInsets.all(16),
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 680,
        maxHeight: MediaQuery.sizeOf(c).height * .85,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    moi
                        ? 'Thêm người dùng'
                        : sua
                        ? 'Sửa người dùng'
                        : 'Thông tin người dùng',
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (!moi && !sua && !chinhMinh) ...[
                  IconButton(
                    tooltip: 'Sửa',
                    onPressed: gui ? null : () => setState(() => sua = true),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Xóa',
                    onPressed: gui ? null : xoa,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
                IconButton(
                  tooltip: 'Đóng',
                  onPressed: gui ? null : () => Navigator.pop(c, false),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: sua
                    ? Form(
                        key: form,
                        child: LayoutBuilder(
                          builder: (c, box) {
                            final rong = box.maxWidth >= 480
                                ? (box.maxWidth - 14) / 2
                                : box.maxWidth;
                            final ds = <Widget>[
                              TextFormField(
                                controller: ten,
                                decoration: nhan('Họ và tên'),
                                enabled: !gui,
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Nhập họ tên'
                                    : null,
                              ),
                              TextFormField(
                                controller: email,
                                decoration: nhan('Email'),
                                enabled: !gui,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) =>
                                    v == null ||
                                        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                            .hasMatch(v.trim())
                                    ? 'Email không hợp lệ'
                                    : null,
                              ),
                              chon(
                                'Loại tài khoản',
                                loai,
                                {
                                  'UngVien': 'Ứng viên',
                                  'NhaTuyenDung': 'Tuyển dụng',
                                },
                                (v) {
                                  loai = v;
                                  if (v == 'UngVien') doanhNghiepId = '';
                                },
                              ),
                              chon('Quyền hệ thống', quyen, {
                                'ThanhVien': 'Thành viên',
                                'QuanTri': 'Quản trị',
                              }, (v) => quyen = v),
                              if (loai == 'NhaTuyenDung')
                                chon('Doanh nghiệp', doanhNghiepId, {
                                  '': 'Chưa có doanh nghiệp',
                                  for (final d in widget.doanhNghiep)
                                    d['id']: d['ten'],
                                }, (v) => doanhNghiepId = v),
                              chon('Trạng thái', khoa.toString(), {
                                'false': 'Hoạt động',
                                'true': 'Đã khóa',
                              }, (v) => khoa = v == 'true'),
                              TextFormField(
                                controller: matKhau,
                                obscureText: true,
                                enabled: !gui,
                                decoration: nhan(
                                  moi
                                      ? 'Mật khẩu'
                                      : 'Mật khẩu mới (không bắt buộc)',
                                ),
                                validator: (v) {
                                  final s = v ?? '';
                                  if ((!moi && s.isEmpty) ||
                                      (s.length >= 8 && s.length <= 128))
                                    return null;
                                  return 'Mật khẩu cần 8–128 ký tự';
                                },
                              ),
                            ];
                            return Wrap(
                              spacing: 14,
                              runSpacing: 16,
                              children: [
                                for (final x in ds)
                                  SizedBox(width: rong, child: x),
                              ],
                            );
                          },
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final x in {
                            'Họ và tên': ten.text,
                            'Email': email.text,
                            'Vai trò': vaiTroNguoi(widget.nguoi!),
                            'Doanh nghiệp':
                                widget.nguoi?['tenDoanhNghiep'] ??
                                'Không thuộc doanh nghiệp',
                            'Trạng thái': khoa ? 'Đã khóa' : 'Hoạt động',
                          }.entries)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    x.key,
                                    style: const TextStyle(
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  SelectableText(
                                    x.value,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          if (chinhMinh)
                            const Text(
                              'Chỉnh sửa thông tin cá nhân tại mục Tài khoản.',
                            ),
                        ],
                      ),
              ),
            ),
            if (loi != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  loi!,
                  style: TextStyle(color: Theme.of(c).colorScheme.error),
                ),
              ),
            if (sua) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: gui
                        ? null
                        : () => moi
                              ? Navigator.pop(c, false)
                              : setState(() {
                                  ten.text = widget.nguoi!['hoTen'];
                                  email.text = widget.nguoi!['email'];
                                  loai = widget.nguoi!['loai'];
                                  quyen = widget.nguoi!['vaiTro'];
                                  doanhNghiepId =
                                      widget.nguoi!['doanhNghiepId'] ?? '';
                                  khoa = widget.nguoi!['biKhoa'];
                                  matKhau.clear();
                                  sua = false;
                                  loi = null;
                                }),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: gui ? null : luu,
                    icon: const Icon(Icons.check),
                    label: Text(gui ? 'Đang lưu…' : 'Lưu'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class DanhMucQuanTri extends StatelessWidget {
  final UngDung ung;
  const DanhMucQuanTri({super.key, required this.ung});
  @override
  Widget build(BuildContext c) {
    final cn = ChucNang(c, ung);
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Danh mục',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const TabBar(
            tabs: [
              Tab(text: 'Gói đăng tin'),
              Tab(text: 'Dịch vụ'),
              Tab(text: 'Ngành nghề'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                cn.goi(quanLy: true),
                cn.danhMuc('DichVu'),
                cn.danhMuc('NganhNghe'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NguoiPhanTrang extends StatefulWidget {
  final List<Map<String, dynamic>> ds;
  final Widget Function(Map<String, dynamic>) ve;
  final String donVi;
  const _NguoiPhanTrang({
    super.key,
    required this.ds,
    required this.ve,
    this.donVi = 'người',
  });
  @override
  State<_NguoiPhanTrang> createState() => _NguoiPhanTrangState();
}

class _NguoiPhanTrangState extends State<_NguoiPhanTrang> {
  int trang = 0;
  @override
  Widget build(BuildContext c) {
    final tongTrang = (widget.ds.length / 20).ceil();
    final hienTai = tongTrang == 0 ? 0 : trang.clamp(0, tongTrang - 1).toInt();
    final ds = widget.ds.skip(hienTai * 20).take(20);
    return Column(
      children: [
        for (final d in ds) widget.ve(d),
        if (widget.ds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Trang trước',
                  onPressed: hienTai > 0
                      ? () => setState(() => trang = hienTai - 1)
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Flexible(
                  child: Text(
                    'Trang ${hienTai + 1}/$tongTrang • ${widget.ds.length} ${widget.donVi}',
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  tooltip: 'Trang sau',
                  onPressed: hienTai + 1 < tongTrang
                      ? () => setState(() => trang = hienTai + 1)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

