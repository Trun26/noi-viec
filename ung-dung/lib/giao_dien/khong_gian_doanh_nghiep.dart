import 'dart:convert';

import 'package:flutter/material.dart';

import '../nghiep_vu/ung_dung.dart';
import 'chuc_nang.dart';
import 'thanh_phan.dart';
import 'bieu_mau.dart';

class KhongGianDoanhNghiep extends StatefulWidget {
  final UngDung ung;
  final bool chiDoanhNghiep;
  final Widget Function() taiKhoan;
  const KhongGianDoanhNghiep({
    super.key,
    required this.ung,
    required this.taiKhoan,
    this.chiDoanhNghiep = false,
  });
  @override
  State<KhongGianDoanhNghiep> createState() => _KhongGianDoanhNghiepState();
}

class _KhongGianDoanhNghiepState extends State<KhongGianDoanhNghiep> {
  int tab = 0, ngayXem = 7;
  String nganhId = '', luong = '', viecId = '';
  bool nhomHoSo = false;
  late Future<void> duLieu;
  Map<String, dynamic> dn = {};
  List<Map<String, dynamic>> tin = [], hoSo = [], nganh = [], goiDaMua = [];
  bool get coDoanhNghiep => widget.ung.nguoi?['doanhNghiepId'] != null;
  bool get duocHoatDong => coDoanhNghiep && dn['trangThai'] == 'DaDuyet';
  ChucNang get cn => ChucNang(context, widget.ung);
  @override
  void initState() {
    super.initState();
    duLieu = tai();
  }

  Future<List<Map<String, dynamic>>> layHet(String dd) async {
    final ds = <Map<String, dynamic>>[];
    var trang = 1;
    while (true) {
      final d = await widget.ung.danhSach(
        '$dd${dd.contains('?') ? '&' : '?'}trang=$trang',
      );
      ds.addAll((d['duLieu'] as List).map((x) => Map<String, dynamic>.from(x)));
      if (trang * (d['kichThuoc'] as num) >= (d['tong'] as num)) break;
      trang++;
    }
    return ds;
  }

  Future<void> tai() async {
    if (!coDoanhNghiep) {
      dn = {};
      tin = [];
      hoSo = [];
      nganh = [];
      goiDaMua = [];
      return;
    }
    final thongTin = Map<String, dynamic>.from(
      await widget.ung.danhSach('doanh-nghiep/toi'),
    );
    if (widget.chiDoanhNghiep) {
      dn = thongTin;
      return;
    }
    if (thongTin['trangThai'] != 'DaDuyet') {
      dn = thongTin;
      if (mounted) setState(() {});
      tin = [];
      hoSo = [];
      nganh = [];
      goiDaMua = [];
      return;
    }
    final kq = await Future.wait<dynamic>([
      widget.ung.danhSach('doanh-nghiep/toi'),
      layHet('tin-tuyen-dung?quanLy=true'),
      layHet('ho-so'),
      layHet('danh-muc?loai=NganhNghe'),
      layHet('don-hang?trangThai=DaThanhToan'),
    ]);
    final dsGoi = <String, Map<String, dynamic>>{};
    for (final don in kq[4] as List<Map<String, dynamic>>) {
      final ct = await widget.ung.danhSach('don-hang/${don['id']}');
      for (final x in ct['chiTiet'] as List) {
        final id = x['goiLuotId'].toString();
        final g = dsGoi.putIfAbsent(
          id,
          () => <String, dynamic>{'id': id, 'ten': x['tenGoi'], 'tong': 0},
        );
        g['tong'] =
            (g['tong'] as num) + (x['soLuong'] as num) * (x['soLuot'] as num);
      }
    }
    if (!mounted) return;
    dn = Map<String, dynamic>.from(kq[0]);
    tin = kq[1];
    hoSo = kq[2];
    nganh = kq[3];
    goiDaMua = dsGoi.values.toList();
    if (mounted) setState(() {});
  }

  void taiLai() {
    setState(() => duLieu = tai());
  }

  Future<void> thaoTac(Future<void> Function() f) async {
    await thucHien(context, () async {
      await f();
      if (mounted) taiLai();
    });
  }

  bool dangChay(Map<String, dynamic> t) =>
      dn['trangThai'] == 'DaDuyet' &&
      t['trangThai'] == 'DangTuyen' &&
      (DateTime.tryParse(t['hanNhan'] ?? '')?.isAfter(DateTime.now()) ?? false);
  Widget theSo(String nhan, String so) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            so,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: Color(0xff6250d8),
            ),
          ),
          const SizedBox(height: 6),
          Text(nhan),
        ],
      ),
    ),
  );
  List<Map<String, dynamic>> hoSoTrongNgay(DateTime ngay) => hoSo.where((h) {
    final d = DateTime.tryParse(h['taoLuc'] ?? '')?.toLocal();
    return d != null &&
        d.year == ngay.year &&
        d.month == ngay.month &&
        d.day == ngay.day;
  }).toList();
  Widget bieuDo() {
    final homNay = DateUtils.dateOnly(DateTime.now());
    final ds = List.generate(ngayXem, (i) {
      final d = homNay.subtract(Duration(days: ngayXem - 1 - i));
      return (d, hoSoTrongNgay(d).map((h) => h['ungVienId']).toSet().length);
    });
    final max = ds.fold<int>(1, (a, b) => b.$2 > a ? b.$2 : a);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Người nộp CV theo thời gian',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final n in [7, 14, 30])
                  ChoiceChip(
                    label: Text('$n ngày'),
                    selected: ngayXem == n,
                    onSelected: (_) => setState(() => ngayXem = n),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                height: 210,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final x in ds)
                      SizedBox(
                        width: 42,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('${x.$2}'),
                            const SizedBox(height: 6),
                            Container(
                              width: 22,
                              height: x.$2 == 0 ? 2 : 135 * x.$2 / max,
                              decoration: BoxDecoration(
                                color: const Color(0xff7964e8),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${x.$1.day}/${x.$1.month}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget theTin(Map<String, dynamic> d) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      title: Text(
        d['tieuDe'],
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${d['diaDiem']}\n${d['luongMin'] == null ? 'Lương thỏa thuận' : '${tien(d['luongMin'])} – ${tien(d['luongMax'])}'}\n${tenNhan(d['trangThai'])}',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => thaoTac(() => cn.chiTietTin(d['id'])),
    ),
  );
  List<Widget> cacGoi() => [
    if (goiDaMua.isEmpty)
      const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Chưa có gói đã thanh toán.'),
      ),
    for (final g in goiDaMua)
      Card(
        child: ListTile(
          title: Text(g['ten']),
          subtitle: Text(
            'Đã mua: ${g['tong']} lượt\nLượt còn lại theo gói: chưa được phân bổ',
          ),
          trailing: const Icon(Icons.info_outline),
          onTap: () => showDialog<void>(
            context: context,
            builder: (c) => AlertDialog(
              title: Text(g['ten']),
              content: Text(
                'Đã mua ${g['tong']} lượt. Hiện lượt được dùng chung cho doanh nghiệp; dữ liệu chưa ghi tin sử dụng gói nào, nên chưa thể liệt kê chính xác.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: const Text('Đóng'),
                ),
              ],
            ),
          ),
        ),
      ),
  ];
  Widget trangDau() {
    final moc = DateUtils.dateOnly(DateTime.now())
        .subtract(const Duration(days: 6));
    final tuan = hoSo
        .where(
          (h) =>
              DateTime.tryParse(h['taoLuc'] ?? '')?.toLocal().isBefore(moc) ==
              false,
        )
        .map((h) => h['ungVienId'])
        .toSet()
        .length;
    final con = (dn['soLuotConLai'] as num?) ?? 0;
    final tong =
        con +
        ((dn['soLuotDangGiu'] as num?) ?? 0) +
        ((dn['soLuotDaDung'] as num?) ?? 0);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Icon(Icons.work_rounded, color: Color(0xff6250d8), size: 32),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Nối Việc',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
              ),
            ),
            IconButton(
              tooltip: 'Thông báo',
              onPressed: () => cn.mo(cn.thongBao()),
              icon: const Icon(Icons.notifications_outlined),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          dn['ten'] ?? '',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        if (dn['trangThai'] != 'DaDuyet')
          Text('Doanh nghiệp: ${tenNhan(dn['trangThai'])}'),
        LayoutBuilder(
          builder: (c, box) => Wrap(
            children: [
              for (final x in [
                ('Lượt còn lại / tổng', '$con/$tong'),
                ('Tin đang chạy', '${tin.where(dangChay).length}'),
                ('Người nộp CV trong 7 ngày', '$tuan'),
              ])
                SizedBox(
                  width: box.maxWidth >= 600
                      ? box.maxWidth / 3
                      : box.maxWidth / 2,
                  child: theSo(x.$1, x.$2),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '3 tin tuyển dụng mới nhất',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
        ),
        if (tin.isEmpty) const Text('Chưa có tin tuyển dụng.'),
        for (final d in tin.take(3)) theTin(d),
        const SizedBox(height: 16),
        bieuDo(),
        const SizedBox(height: 16),
        const Text(
          'Gói đã đăng ký',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
        ),
        ...cacGoi(),
      ],
    );
  }

  bool khopTin(Map<String, dynamic> d) {
    if (nganhId.isNotEmpty && d['nganhId'] != nganhId) return false;
    final max = d['luongMax'] as num?;
    return luong.isEmpty || max != null && max >= (num.tryParse(luong) ?? 0);
  }

  List<Map<String, dynamic>> nhomTin(int i) => tin
      .where(
        (d) => switch (i) {
          1 => d['trangThai'] == 'ChoDuyet' || d['banSuaJson'] != null,
          2 => d['trangThai'] == 'BiTuChoi',
          _ => d['trangThai'] != 'ChoDuyet' && d['trangThai'] != 'BiTuChoi',
        },
      )
      .toList();
  Widget viecLam() => DefaultTabController(
    length: 3,
    child: Column(
      children: [
        TabBar(
          isScrollable: true,
          tabs: [
            for (var i = 0; i < 3; i++)
              Tab(
                text:
                    '${['Tin', 'Gửi đi', 'Bị từ chối'][i]} (${nhomTin(i).length})',
              ),
          ],
        ),
        Expanded(
          child: TabBarView(
            children: [
              for (var i = 0; i < 3; i++)
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Đang chạy: ${tin.where(dangChay).length} • Tạm ngừng: ${tin.where((d) => ['DaDong', 'BiAn'].contains(d['trangThai'])).length}',
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (c, box) => Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          SizedBox(
                            width: (box.maxWidth - 10) / 2,
                            child: DropdownButtonFormField<String>(
                              initialValue: nganhId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                isDense: true,
                                labelText: 'Ngành nghề',
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: '',
                                  child: Text('Tất cả'),
                                ),
                                for (final n in nganh)
                                  DropdownMenuItem(
                                    value: n['id'].toString(),
                                    child: Text(
                                      n['ten'],
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: (v) =>
                                  setState(() => nganhId = v ?? ''),
                            ),
                          ),
                          SizedBox(
                            width: (box.maxWidth - 10) / 2,
                            child: DropdownButtonFormField<String>(
                              initialValue: luong,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                isDense: true,
                                labelText: 'Lương từ',
                              ),
                              items: [
                                for (final e in {
                                  '': 'Tất cả',
                                  '10000000': '10 triệu',
                                  '20000000': '20 triệu',
                                  '30000000': '30 triệu',
                                }.entries)
                                  DropdownMenuItem(
                                    value: e.key,
                                    child: Text(e.value),
                                  ),
                              ],
                              onChanged: (v) => setState(() => luong = v ?? ''),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: () => thaoTac(() => cn.suaTin()),
                        icon: const Icon(Icons.add),
                        label: const Text('Tạo tin'),
                      ),
                    ),
                    for (final d in nhomTin(i).where(khopTin))
                      Column(
                        children: [
                          theTin(d),
                          Wrap(
                            spacing: 6,
                            children: [
                              if ([
                                'BanNhap',
                                'BiTuChoi',
                                'DangTuyen',
                              ].contains(d['trangThai']))
                                cn.nut(
                                  'Sửa',
                                  () => thaoTac(() => cn.suaTin(d)),
                                ),
                              if ([
                                'BanNhap',
                                'BiTuChoi',
                              ].contains(d['trangThai']))
                                cn.nut(
                                  'Gửi duyệt',
                                  () => cn.trangThai(
                                    'tin-tuyen-dung/${d['id']}',
                                    'ChoDuyet',
                                    taiLai,
                                  ),
                                ),
                              if (d['trangThai'] == 'ChoDuyet')
                                cn.nut(
                                  'Rút tin',
                                  () => cn.trangThai(
                                    'tin-tuyen-dung/${d['id']}',
                                    'BanNhap',
                                    taiLai,
                                  ),
                                ),
                              if (d['trangThai'] == 'DangTuyen')
                                cn.nut(
                                  'Tạm ngừng',
                                  () => cn.trangThai(
                                    'tin-tuyen-dung/${d['id']}',
                                    'DaDong',
                                    taiLai,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    ),
  );
  String tenViec(dynamic id) =>
      tin
          .where((t) => t['id'] == id)
          .map((t) => t['tieuDe'].toString())
          .firstOrNull ??
      'Tin tuyển dụng';
  String tenUngVien(Map<String, dynamic> h) {
    try {
      return jsonDecode(h['banHoSoJson'])['HoTen'] ?? 'Ứng viên';
    } catch (_) {
      return 'Ứng viên';
    }
  }

  Future<void> xet(Map<String, dynamic> h) async {
    final tt = h['trangThai'];
    final chon = <String, String>{
      if (tt == 'DaGui') 'DangXemXet': 'Duyệt hồ sơ / đang xem xét',
      if (['DaGui', 'DangXemXet'].contains(tt)) 'MoiPhongVan': 'Mời phỏng vấn',
      if (tt == 'MoiPhongVan') 'DaTuyen': 'Đã tuyển',
      if (['DaGui', 'DangXemXet', 'MoiPhongVan'].contains(tt))
        'TuChoi': 'Từ chối',
    };
    if (chon.isEmpty) return;
    await moBieuMau(
      context,
      widget.ung,
      'Xét hồ sơ',
      [
        TruongNhap('trangThai', 'Kết quả', chon: chon),
        const TruongNhap('ghiChu', 'Ghi chú', batBuoc: false),
        const TruongNhap(
          'gioPhongVan',
          'Giờ phỏng vấn (yyyy-MM-dd HH:mm)',
          batBuoc: false,
        ),
        const TruongNhap('hinhThuc', 'Hình thức', batBuoc: false),
        const TruongNhap('diaDiem', 'Địa điểm / đường dẫn', batBuoc: false),
      ],
      luu: (d) async {
        final gio = DateTime.tryParse(d['gioPhongVan'] ?? '');
        if (d['trangThai'] == 'MoiPhongVan' && gio == null)
          throw Exception('Nhập giờ phỏng vấn hợp lệ.');
        d['gioPhongVan'] = d['trangThai'] == 'MoiPhongVan'
            ? gio!.toUtc().toIso8601String()
            : null;
        await widget.ung.xuLy('ho-so/${h['id']}/trang-thai', d);
      },
    );
    if (mounted) taiLai();
  }

  Widget theHoSo(Map<String, dynamic> h) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            tenUngVien(h),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          Text(tenViec(h['tinId'])),
          Text('${tenNhan(h['trangThai'])} • ${ngay(h['taoLuc'])}'),
          Wrap(
            spacing: 8,
            children: [
              cn.nut(
                'Xem hồ sơ / CV',
                () => cn.chiTietHoSo(h['id'], taiLai: taiLai),
              ),
              if (!['DaTuyen', 'TuChoi', 'DaRut'].contains(h['trangThai']))
                cn.nut('Xét hồ sơ', () => xet(h)),
            ],
          ),
        ],
      ),
    ),
  );
  Widget hoSoUngTuyen() {
    final ds = hoSo
        .where(
          (h) =>
              h['trangThai'] != 'DaRut' &&
              (viecId.isEmpty || h['tinId'] == viecId),
        )
        .toList();
    final nhom = [
      ds
          .where(
            (h) => [
              'DangXemXet',
              'MoiPhongVan',
              'DaTuyen',
            ].contains(h['trangThai']),
          )
          .toList(),
      ds.where((h) => h['trangThai'] == 'DaGui').toList(),
      ds.where((h) => h['trangThai'] == 'TuChoi').toList(),
    ];
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              initialValue: viecId,
              isExpanded: true,
              decoration: const InputDecoration(
                isDense: true,
                labelText: 'Lọc theo việc làm',
              ),
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: Text('Tất cả việc làm'),
                ),
                for (final t in tin)
                  DropdownMenuItem(
                    value: t['id'].toString(),
                    child: Text(t['tieuDe'], overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => setState(() => viecId = v ?? ''),
            ),
          ),
          SwitchListTile(
            dense: true,
            title: const Text('Nhóm theo việc làm'),
            value: nhomHoSo,
            onChanged: (v) => setState(() => nhomHoSo = v),
          ),
          TabBar(
            tabs: [
              for (var i = 0; i < 3; i++)
                Tab(
                  text:
                      '${['Đã duyệt', 'Chờ duyệt', 'Từ chối'][i]} (${nhom[i].length})',
                ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                for (final n in nhom)
                  ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      if (n.isEmpty) const Text('Chưa có hồ sơ phù hợp.'),
                      if (!nhomHoSo) ...[
                        for (final h in n) theHoSo(h),
                      ] else ...[
                        for (final id in n.map((h) => h['tinId']).toSet())
                          ExpansionTile(
                            title: Text(tenViec(id)),
                            subtitle: Text(
                              '${n.where((h) => h['tinId'] == id).map((h) => h['ungVienId']).toSet().length} người nộp',
                            ),
                            children: [
                              for (final h in n.where((h) => h['tinId'] == id))
                                theHoSo(h),
                            ],
                          ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget oThongTin(String nhan, String giaTri, IconData icon) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xffeeeaff),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xff6250d8)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nhan, style: const TextStyle(color: Colors.blueGrey)),
                const SizedBox(height: 6),
                Text(
                  giaTri.isEmpty ? 'Chưa cung cấp' : giaTri,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  Widget doanhNghiep() {
    if (!coDoanhNghiep)
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(
            Icons.business_outlined,
            size: 60,
            color: Color(0xff6250d8),
          ),
          const SizedBox(height: 16),
          const Text(
            'Đăng ký doanh nghiệp',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          const Text(
            'Điền thông tin doanh nghiệp và gửi quản trị xét duyệt. Các chức năng tuyển dụng sẽ mở sau khi doanh nghiệp được duyệt.',
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => thaoTac(cn.congTyToi),
            icon: const Icon(Icons.add_business_outlined),
            label: const Text('Điền thông tin đăng ký'),
          ),
        ],
      );
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xff6250d8), Color(0xff9381ec)],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.business_rounded, size: 40, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                dn['ten'] ?? '',
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tenNhan(dn['trangThai']),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        oThongTin('Mã số thuế', dn['maSoThue'] ?? '', Icons.badge_outlined),
        oThongTin('Địa chỉ', dn['diaChi'] ?? '', Icons.location_on_outlined),
        oThongTin('Giới thiệu', dn['gioiThieu'] ?? '', Icons.info_outline),
        if (dn['lyDo']?.toString().isNotEmpty == true)
          oThongTin(
            'Phản hồi của quản trị',
            dn['lyDo'],
            Icons.chat_bubble_outline,
          ),
        if (dn['nguoiPhuTrachId'] == widget.ung.nguoi?['id']) ...[
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.edit_outlined,
                color: Color(0xff6250d8),
              ),
              title: const Text('Thông tin doanh nghiệp'),
              subtitle: const Text('Chỉnh sửa và gửi xét duyệt lại'),
              trailing: const Icon(Icons.chevron_right),
              onTap: dn['trangThai'] == 'TamKhoa'
                  ? null
                  : () => thaoTac(cn.congTyToi),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.groups_outlined,
                color: Color(0xff6250d8),
              ),
              title: const Text('Nhân viên'),
              subtitle: const Text('Quản lý thành viên trong doanh nghiệp'),
              trailing: const Icon(Icons.chevron_right),
              onTap: duocHoatDong ? () => cn.mo(cn.thanhVienCongTy()) : null,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> muaThem() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (c) => ChucNang(c, widget.ung).goi()),
    );
    if (mounted) taiLai();
  }

  Future<void> gioYeuCau() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) {
          final f = ChucNang(c, widget.ung);
          return DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Giỏ hàng'),
                bottom: const TabBar(
                  tabs: [
                    Tab(text: 'Trong giỏ'),
                    Tab(text: 'Đơn đã đặt'),
                  ],
                ),
              ),
              body: TabBarView(children: [f.gioTrong(), f.don()]),
            ),
          );
        },
      ),
    );
    if (mounted) taiLai();
  }

  Widget donHang() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Row(
        children: [
          const Expanded(
            child: Text(
              'Đơn hàng',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            tooltip: 'Giỏ hàng và đơn đã đặt',
            onPressed: gioYeuCau,
            icon: const Icon(Icons.shopping_bag_outlined),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          const Expanded(
            child: Text(
              'Các gói đang có',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
          ),
          FilledButton.icon(
            onPressed: muaThem,
            icon: const Icon(Icons.add),
            label: const Text('Mua thêm'),
          ),
        ],
      ),
      const SizedBox(height: 12),
      ...cacGoi(),
    ],
  );
  Widget thongKe() {
    final daDuyet = hoSo
        .where(
          (h) =>
              ['DangXemXet', 'MoiPhongVan', 'DaTuyen'].contains(h['trangThai']),
        )
        .length;
    final soNguoi = hoSo.map((h) => h['ungVienId']).toSet().length;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Thống kê tuyển dụng',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        theSo('Người đã nộp CV toàn doanh nghiệp', '$soNguoi'),
        theSo(
          'Tỷ lệ hồ sơ được duyệt',
          hoSo.isEmpty
              ? 'Chưa có dữ liệu'
              : '${(daDuyet * 100 / hoSo.length).toStringAsFixed(1)}%',
        ),
        const Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            'Tỷ lệ duyệt = số hồ sơ đang xem xét, được mời phỏng vấn hoặc đã tuyển / tổng hồ sơ đã nộp. Hồ sơ đã rút vẫn thuộc tổng hồ sơ từng nộp.',
          ),
        ),
        bieuDo(),
        const SizedBox(height: 16),
        const Text(
          'Theo gói đăng tin',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        if (goiDaMua.isEmpty) const Text('Chưa có gói đã mua.'),
        for (final g in goiDaMua)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    g['ten'],
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Người nộp / tỷ lệ duyệt / chi phí trung bình: chưa xác định.',
                  ),
                  const Text(
                    'Dữ liệu chưa gắn tin tuyển dụng với gói đã dùng. Không lấy số liệu toàn doanh nghiệp thay cho số liệu của gói.',
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget trangKhoa() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        'Nối Việc',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 20),
      const Icon(Icons.lock_outline, size: 54, color: Colors.blueGrey),
      const SizedBox(height: 16),
      Text(
        coDoanhNghiep
            ? 'Doanh nghiệp chưa được duyệt hoặc đang bị khóa.'
            : 'Bạn chưa thuộc doanh nghiệp.',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 10),
      const Text(
        'Mở Tài khoản → Doanh nghiệp để đăng ký hoặc xem kết quả xét duyệt.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 20),
      Opacity(
        opacity: .45,
        child: IgnorePointer(
          child: Column(
            children: [
              theSo('Lượt đăng còn lại / tổng', '— / —'),
              theSo('Tin đang chạy', '—'),
              theSo('Người nộp CV trong tuần', '—'),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.bar_chart),
                  title: Text('Thống kê tuyển dụng'),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
  @override
  Widget build(BuildContext c) {
    const nhan = ['Tổng quan', 'Tin tuyển', 'Ứng viên', 'Gói', 'Tài khoản'];
    const icons = [
      Icons.space_dashboard_outlined,
      Icons.work_outline,
      Icons.people_alt_outlined,
      Icons.inventory_2_outlined,
      Icons.person_outline,
    ];
    return Scaffold(
      appBar: widget.chiDoanhNghiep
          ? AppBar(title: const Text('Doanh nghiệp'))
          : null,
      bottomNavigationBar: widget.chiDoanhNghiep
          ? null
          : Material(
              color: Colors.white,
              elevation: 8,
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    for (var i = 0; i < nhan.length; i++)
                      Expanded(
                        flex: tab == i ? 2 : 1,
                        child: Tooltip(
                          message: nhan[i],
                          child: InkWell(
                            onTap: (i == 4 || duocHoatDong)
                                ? () {
                                    setState(() => tab = i);
                                    if (i != 4) taiLai();
                                  }
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    icons[i],
                                    color: tab == i
                                        ? const Color(0xff6250d8)
                                        : Colors.blueGrey,
                                  ),
                                  if (tab == i)
                                    Text(
                                      nhan[i],
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
      body: SafeArea(
        child: tab == 4 && !widget.chiDoanhNghiep
            ? widget.taiKhoan()
            : FutureBuilder<void>(
                future: duLieu,
                builder: (c, s) {
                  if (s.hasError)
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(s.error.toString()),
                          TextButton(
                            onPressed: taiLai,
                            child: const Text('Tải lại'),
                          ),
                        ],
                      ),
                    );
                  if (s.connectionState != ConnectionState.done)
                    return const Center(child: CircularProgressIndicator());
                  if (widget.chiDoanhNghiep) return doanhNghiep();
                  if (!duocHoatDong) return trangKhoa();
                  return switch (tab) {
                    1 => viecLam(),
                    2 => hoSoUngTuyen(),
                    3 => cn.goi(),
                    _ => RefreshIndicator(
                      onRefresh: () async {
                        taiLai();
                        await duLieu;
                      },
                      child: trangDau(),
                    ),
                  };
                },
              ),
      ),
    );
  }
}
