import 'package:flutter/material.dart';

import '../nghiep_vu/ung_dung.dart';
import 'chuc_nang.dart';
import 'thanh_phan.dart';

class TinQuanTri extends StatefulWidget {
  final UngDung ung;
  const TinQuanTri({super.key, required this.ung});
  @override
  State<TinQuanTri> createState() => _TinQuanTriState();
}

class _TinQuanTriState extends State<TinQuanTri> {
  late Future<void> duLieu;
  List<Map<String, dynamic>> tin = [], nganh = [];
  String nganhId = '', mucLuong = '';
  final tim = TextEditingController();
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
      final kq = await widget.ung.danhSach('$dd&trang=$trang');
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
      layHet('tin-tuyen-dung?quanLy=true'),
      layHet('danh-muc?loai=NganhNghe&quanLy=true'),
    ]);
    if (!mounted) return;
    tin = kq[0];
    nganh = kq[1];
  }

  void taiLai() {
    setState(() => duLieu = tai());
  }

  bool khop(Map<String, dynamic> d) {
    if (nganhId.isNotEmpty && d['nganhId'] != nganhId) return false;
    if (!'${d['tieuDe']} ${d['diaDiem']}'.toLowerCase().contains(
      tim.text.trim().toLowerCase(),
    ))
      return false;
    final min = d['luongMin'] as num?, max = d['luongMax'] as num?;
    if (mucLuong == 'ThoaThuan') return min == null && max == null;
    if (mucLuong.isEmpty) return true;
    if (min == null || max == null) return false;
    // Giữ tin có khoảng lương giao với khoảng đang chọn.
    return switch (mucLuong) {
      'Duoi10' => min < 10000000,
      '10Den20' => max >= 10000000 && min < 20000000,
      '20Den30' => max >= 20000000 && min < 30000000,
      'Tu30' => max >= 30000000,
      _ => true,
    };
  }

  Widget boLoc() => LayoutBuilder(
    builder: (c, box) {
      final rong = (box.maxWidth - 10) / 2;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          SizedBox(
            width: rong,
            child: DropdownButtonFormField<String>(
              key: ValueKey('nganh-$nganhId'),
              initialValue: nganh.any((x) => x['id'] == nganhId) ? nganhId : '',
              isExpanded: true,
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'Ngành nghề',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
              ),
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: Text('Ngành nghề', overflow: TextOverflow.ellipsis),
                ),
                for (final x in nganh)
                  DropdownMenuItem(
                    value: x['id'].toString(),
                    child: Text(x['ten'], overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => setState(() => nganhId = v ?? ''),
            ),
          ),
          SizedBox(
            width: rong,
            child: DropdownButtonFormField<String>(
              initialValue: mucLuong,
              isExpanded: true,
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'Mức lương',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
              ),
              items: [
                for (final x in {
                  '': 'Mức lương',
                  'ThoaThuan': 'Thỏa thuận',
                  'Duoi10': 'Dưới 10 triệu',
                  '10Den20': '10 – dưới 20 triệu',
                  '20Den30': '20 – dưới 30 triệu',
                  'Tu30': 'Từ 30 triệu',
                }.entries)
                  DropdownMenuItem(
                    value: x.key,
                    child: Text(x.value, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => setState(() => mucLuong = v ?? ''),
            ),
          ),
        ],
      );
    },
  );
  @override
  Widget build(BuildContext c) => DefaultTabController(
    length: 3,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Quản lý tin tuyển dụng',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
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
            decoration: const InputDecoration(
              isDense: true,
              hintText: 'Tìm tiêu đề, địa điểm',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        const SizedBox(height: 12),
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
              final ds = tin.where(khop).toList();
              final nhom = [
                ds
                    .where(
                      (d) => [
                        'DangTuyen',
                        'DaDong',
                        'BiAn',
                      ].contains(d['trangThai']),
                    )
                    .toList(),
                ds
                    .where(
                      (d) =>
                          d['trangThai'] == 'ChoDuyet' ||
                          d['banSuaJson'] != null,
                    )
                    .toList(),
                ds.where((d) => d['trangThai'] == 'BiTuChoi').toList(),
              ];
              final cn = ChucNang(c, widget.ung);
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: boLoc(),
                  ),
                  const SizedBox(height: 8),
                  TabBar(
                    tabs: [
                      for (var i = 0; i < 3; i++)
                        Tab(
                          text:
                              '${['Duyệt', 'Chờ duyệt', 'Từ chối'][i]} (${nhom[i].length})',
                        ),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        for (final n in nhom)
                          RefreshIndicator(
                            onRefresh: () async {
                              taiLai();
                              await duLieu;
                            },
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(12),
                              children: [
                                if (n.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Text('Không có tin phù hợp.'),
                                  ),
                                for (final d in n)
                                  Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          InkWell(
                                            onTap: () => thucHien(
                                              c,
                                              () => cn.chiTietTin(d['id']),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  d['tieuDe'],
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  nganh
                                                          .where(
                                                            (x) =>
                                                                x['id'] ==
                                                                d['nganhId'],
                                                          )
                                                          .map((x) => x['ten'])
                                                          .firstOrNull
                                                          ?.toString() ??
                                                      'Chưa có ngành nghề',
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  d['tenDoanhNghiep'] ?? 'Chưa có tên doanh nghiệp',
                                                ),
                                                const SizedBox(height: 6),
                                                Text(d['diaDiem'] ?? ''),
                                                const SizedBox(height: 6),
                                                Text(
                                                  d['luongMin'] == null
                                                      ? 'Lương thỏa thuận'
                                                      : '${tien(d['luongMin'])} – ${tien(d['luongMax'])}',
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  '${tenNhan(d['trangThai'])}${d['banSuaJson'] != null ? ' • Có bản sửa chờ duyệt' : ''}',
                                                ),
                                                if (d['lyDo']
                                                        ?.toString()
                                                        .isNotEmpty ==
                                                    true)
                                                  Text('Lý do: ${d['lyDo']}'),
                                              ],
                                            ),
                                          ),
                                          Wrap(
                                            spacing: 8,
                                            children: [
                                              cn.nut(
                                                'Chi tiết',
                                                () => cn.chiTietTin(d['id']),
                                              ),
                                              if (d['trangThai'] ==
                                                      'ChoDuyet' ||
                                                  d['banSuaJson'] != null) ...[
                                                cn.nut(
                                                  'Duyệt',
                                                  () => cn.trangThai(
                                                    'tin-tuyen-dung/${d['id']}',
                                                    'DangTuyen',
                                                    taiLai,
                                                  ),
                                                ),
                                                cn.nut(
                                                  'Từ chối',
                                                  () => cn.trangThai(
                                                    'tin-tuyen-dung/${d['id']}',
                                                    'BiTuChoi',
                                                    taiLai,
                                                    lyDo: true,
                                                  ),
                                                ),
                                              ],
                                              if (d['trangThai'] == 'DangTuyen')
                                                cn.nut(
                                                  'Ẩn tin',
                                                  () => cn.trangThai(
                                                    'tin-tuyen-dung/${d['id']}',
                                                    'BiAn',
                                                    taiLai,
                                                    lyDo: true,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
}
