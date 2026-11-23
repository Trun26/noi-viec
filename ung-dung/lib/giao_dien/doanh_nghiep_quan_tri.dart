import 'package:flutter/material.dart';

import '../nghiep_vu/ung_dung.dart';
import 'thanh_phan.dart';

class DoanhNghiepQuanTri extends StatefulWidget {
  final UngDung ung;
  const DoanhNghiepQuanTri({super.key, required this.ung});
  @override
  State<DoanhNghiepQuanTri> createState() => _DoanhNghiepQuanTriState();
}

class _DoanhNghiepQuanTriState extends State<DoanhNghiepQuanTri> {
  late Future<dynamic> duLieu;
  final tim = TextEditingController();
  @override
  void initState() {
    super.initState();
    tai();
  }

  void tai() {
    duLieu = widget.ung.danhSach('quan-tri/doanh-nghiep');
  }

  @override
  void dispose() {
    tim.dispose();
    super.dispose();
  }

  Future<void> chiTiet(Map<String, dynamic> d) async {
    final doi = await showDialog<bool>(
      context: context,
      builder: (_) => _ChiTietDoanhNghiep(ung: widget.ung, d: d),
    );
    if (doi == true && mounted) setState(tai);
  }

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
                  'Doanh nghiệp',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                tooltip: 'Tải lại',
                onPressed: () => setState(tai),
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
              hintText: 'Tìm doanh nghiệp, mã số thuế, người phụ trách',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: FutureBuilder<dynamic>(
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
                          onPressed: () => setState(tai),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                );
              if (!s.hasData)
                return const Center(child: CircularProgressIndicator());
              final ds = (s.data as List)
                  .map((x) => Map<String, dynamic>.from(x))
                  .toList();
              final nhom = [
                ds
                    .where(
                      (d) =>
                          d['trangThai'] == 'DaDuyet' ||
                          d['trangThai'] == 'TamKhoa',
                    )
                    .toList(),
                ds.where((d) => d['trangThai'] == 'ChoDuyet').toList(),
                ds.where((d) => d['trangThai'] == 'BiTuChoi').toList(),
              ];
              return Column(
                children: [
                  TabBar(
                    tabs: [
                      for (var i = 0; i < 3; i++)
                        Tab(
                          height: 62,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${nhom[i].length}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                              Text(['Đã duyệt', 'Chờ duyệt', 'Từ chối'][i]),
                            ],
                          ),
                        ),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        for (final n in nhom)
                          RefreshIndicator(
                            onRefresh: () async {
                              setState(tai);
                              await duLieu;
                            },
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(12),
                              children: [
                                if (n.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Text('Chưa có doanh nghiệp.'),
                                  ),
                                for (final d in n.where(
                                  (d) =>
                                      '${d['ten']} ${d['maSoThue']} ${d['tenNguoiPhuTrach']}'
                                          .toLowerCase()
                                          .contains(
                                            tim.text.trim().toLowerCase(),
                                          ),
                                ))
                                  Card(
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(16),
                                      title: Text(
                                        d['ten'],
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          '${d['tenNguoiPhuTrach'] ?? 'Chưa có người phụ trách'}\n${d['diaChi']}${d['trangThai'] == 'TamKhoa' ? '\nĐang tạm khóa' : ''}',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                      trailing: const Icon(Icons.chevron_right),
                                      onTap: () => chiTiet(d),
                                    ),
                                  ),
                                if (n.isNotEmpty &&
                                    !n.any(
                                      (d) =>
                                          '${d['ten']} ${d['maSoThue']} ${d['tenNguoiPhuTrach']}'
                                              .toLowerCase()
                                              .contains(
                                                tim.text.trim().toLowerCase(),
                                              ),
                                    ))
                                  const Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Text('Không có kết quả phù hợp.'),
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

class _ChiTietDoanhNghiep extends StatefulWidget {
  final UngDung ung;
  final Map<String, dynamic> d;
  const _ChiTietDoanhNghiep({required this.ung, required this.d});
  @override
  State<_ChiTietDoanhNghiep> createState() => _ChiTietDoanhNghiepState();
}

class _ChiTietDoanhNghiepState extends State<_ChiTietDoanhNghiep> {
  bool gui = false;
  String? loi;
  final lyDo = TextEditingController();
  @override
  void dispose() {
    lyDo.dispose();
    super.dispose();
  }

  Future<void> xuLy(String tt) async {
    if (tt != 'DaDuyet' && lyDo.text.trim().isEmpty) {
      setState(() => loi = 'Nhập lý do trước khi từ chối hoặc tạm khóa.');
      return;
    }
    if (!mounted) return;
    setState(() {
      gui = true;
      loi = null;
    });
    try {
      await widget.ung.xuLy('doanh-nghiep/${widget.d['id']}/trang-thai', {
        'trangThai': tt,
        'lyDo': tt == 'DaDuyet' ? '' : lyDo.text.trim(),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => loi = e.toString());
    } finally {
      if (mounted) setState(() => gui = false);
    }
  }

  @override
  Widget build(BuildContext c) {
    final d = widget.d;
    final thongTin = {
      'Tên doanh nghiệp': d['ten'],
      'Mã số thuế': d['maSoThue'],
      'Địa chỉ': d['diaChi'],
      'Giới thiệu': d['gioiThieu'],
      'Người phụ trách': d['tenNguoiPhuTrach'],
      'Email người phụ trách': d['emailNguoiPhuTrach'],
      'Trạng thái': tenNhan(d['trangThai']),
      'Lý do xét duyệt': d['lyDo'],
      'Số nhân viên (gồm người phụ trách)': d['soNhanVien'],
      'Lượt còn lại': d['soLuotConLai'],
      'Lượt đang giữ': d['soLuotDangGiu'],
      'Lượt đã dùng': d['soLuotDaDung'],
      'Đã cấp lượt miễn phí': d['daCapMienPhi'] == true ? 'Đã cấp' : 'Chưa cấp',
    };
    return PopScope(
      canPop: !gui,
      child: Dialog(
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
                    const Expanded(
                      child: Text(
                        'Chi tiết yêu cầu doanh nghiệp',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Đóng',
                      onPressed: gui ? null : () => Navigator.pop(c),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final e in thongTin.entries)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e.key,
                                  style: const TextStyle(
                                    color: Colors.blueGrey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SelectableText(
                                  e.value == null ||
                                          e.value.toString().trim().isEmpty
                                      ? 'Chưa cung cấp'
                                      : e.value.toString(),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        TextField(
                          controller: lyDo,
                          enabled: !gui,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            isDense: true,
                            labelText: 'Lý do từ chối / tạm khóa',
                          ),
                        ),
                        if (loi != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              loi!,
                              style: TextStyle(
                                color: Theme.of(c).colorScheme.error,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (gui) const LinearProgressIndicator(),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    if (d['trangThai'] != 'DaDuyet')
                      FilledButton(
                        onPressed: gui ? null : () => xuLy('DaDuyet'),
                        child: const Text('Duyệt'),
                      ),
                    if (d['trangThai'] == 'ChoDuyet')
                      OutlinedButton(
                        onPressed: gui ? null : () => xuLy('BiTuChoi'),
                        child: const Text('Từ chối'),
                      ),
                    if (d['trangThai'] == 'DaDuyet')
                      OutlinedButton(
                        onPressed: gui ? null : () => xuLy('TamKhoa'),
                        child: const Text('Tạm khóa'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
