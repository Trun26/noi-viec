import 'package:flutter/material.dart';

import '../nghiep_vu/ung_dung.dart';
import 'man_xac_thuc.dart';
import 'thanh_phan.dart';

class ChiTietViec extends StatelessWidget {
  final Map<String, dynamic> d;
  final UngDung ung;
  final List<Widget> hanhDong;
  const ChiTietViec({
    super.key,
    required this.d,
    required this.ung,
    required this.hanhDong,
  });

  @override
  Widget build(BuildContext c) =>
      ListenableBuilder(listenable: ung, builder: (c, _) => noiDung(c));
  Widget noiDung(BuildContext c) {
    final dong = DateTime.tryParse(d['hanNhan']?.toString() ?? '');
    final hetHan = dong != null && dong.isBefore(DateTime.now());
    final dangTuyen = d['trangThai'] == 'DangTuyen' && !hetHan;
    final luong = d['luongMin'] == null && d['luongMax'] == null
        ? 'L\u01b0\u01a1ng th\u1ecfa thu\u1eadn'
        : d['luongMin'] == null
        ? '\u0110\u1ebfn ${tien(d['luongMax'])}'
        : d['luongMax'] == null
        ? 'T\u1eeb ${tien(d['luongMin'])}'
        : '${tien(d['luongMin'])} \u2013 ${tien(d['luongMax'])}';
    return Scaffold(
      appBar: AppBar(title: const Text('Chi ti\u1ebft vi\u1ec7c l\u00e0m')),
      bottomNavigationBar: ung.nguoi == null || ung.ungVien
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!dangTuyen)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Tin tuy\u1ec3n d\u1ee5ng hi\u1ec7n kh\u00f4ng nh\u1eadn h\u1ed3 s\u01a1.',
                        ),
                      ),
                    if (dangTuyen && ung.nguoi == null)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: () async {
                            await Navigator.push(
                              c,
                              MaterialPageRoute(
                                builder: (_) => ManXacThuc(ung: ung),
                              ),
                            );
                            if (c.mounted && ung.nguoi != null)
                              Navigator.pop(c);
                          },
                          child: const Text(
                            '\u0110\u0103ng nh\u1eadp \u0111\u1ec3 \u1ee9ng tuy\u1ec3n',
                          ),
                        ),
                      ),
                    if (ung.ungVien &&
                        ung.tinDaGui.contains(d['id'].toString()))
                      const FilledButton(
                        onPressed: null,
                        child: Text('Đã gửi'),
                      ),
                    if (dangTuyen &&
                        ung.ungVien &&
                        !ung.tinDaGui.contains(d['id'].toString()) &&
                        hanhDong.isNotEmpty)
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xffeae5ff),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: hanhDong.first,
                      ),
                  ],
                ),
              ),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xffece9f5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xffeee9ff),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.business_center_outlined,
                    size: 30,
                    color: Color(0xff6250d8),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  d['tieuDe'] ?? '',
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                const SizedBox(height: 14),
                Text(
                  luong,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff6250d8),
                  ),
                ),
                const SizedBox(height: 18),
                for (final e in {
                  Icons.location_on_outlined: d['diaDiem'],
                  Icons.schedule: tenNhan(d['hinhThuc']),
                  Icons.event_outlined:
                      'H\u1ea1n nh\u1eadn: ${ngay(d['hanNhan'])}',
                }.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(e.key, size: 19, color: const Color(0xff8b829d)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            e.value?.toString() ??
                                'Ch\u01b0a c\u1eadp nh\u1eadt',
                            style: const TextStyle(color: Color(0xff716a80)),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (d['tenDoanhNghiep'] != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xffece9f5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: const Color(0xfff0ebff),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.business_outlined,
                      color: Color(0xff6250d8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d['tenDoanhNghiep'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        if (d['diaChiDoanhNghiep'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            d['diaChiDoanhNghiep'],
                            style: const TextStyle(color: Color(0xff716a80)),
                          ),
                        ],
                        if (d['gioiThieuDoanhNghiep'] != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            d['gioiThieuDoanhNghiep'],
                            style: const TextStyle(
                              height: 1.45,
                              color: Color(0xff716a80),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _chiSo('Kinh nghi\u1ec7m', d['kinhNghiem']),
              _chiSo('Tr\u00ecnh \u0111\u1ed9', d['trinhDo']),
              _chiSo(
                'S\u1ed1 l\u01b0\u1ee3ng',
                '${d['soNguoi'] ?? '\u2014'} ng\u01b0\u1eddi',
              ),
            ],
          ),
          for (final e in {
            'moTa': 'M\u00f4 t\u1ea3 c\u00f4ng vi\u1ec7c',
            'yeuCau': 'Y\u00eau c\u1ea7u \u1ee9ng vi\u00ean',
            'quyenLoi': 'Quy\u1ec1n l\u1ee3i c\u1ee7a b\u1ea1n',
          }.entries) ...[
            const SizedBox(height: 26),
            Text(
              e.value,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            SelectableText(
              d[e.key]?.toString() ?? 'Ch\u01b0a c\u1eadp nh\u1eadt',
              style: const TextStyle(height: 1.7, color: Color(0xff716a80)),
            ),
          ],
          const SizedBox(height: 24),
          ...hanhDong.skip(ung.ungVien ? 1 : 0),
        ],
      ),
    );
  }

  Widget _chiSo(String ten, dynamic giaTri) => Container(
    width: 145,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ten,
          style: const TextStyle(color: Color(0xff8b829d), fontSize: 12),
        ),
        const SizedBox(height: 6),
        Text(
          giaTri?.toString().isNotEmpty == true
              ? giaTri.toString()
              : 'Ch\u01b0a c\u1eadp nh\u1eadt',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class TheViecLam extends StatelessWidget {
  final String tieuDe;
  final String? phu, trangThai;
  final VoidCallback? mo;
  final List<Widget> hanhDong;
  const TheViecLam({
    super.key,
    required this.tieuDe,
    this.phu,
    this.trangThai,
    this.mo,
    this.hanhDong = const [],
  });
  @override
  Widget build(BuildContext c) => Card(
    margin: EdgeInsets.zero,
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xffeee9ff),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.business_center_outlined,
                    color: Color(0xff6250d8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tieuDe,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      height: 1.35,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xffa198b1)),
              ],
            ),
            const SizedBox(height: 16),
            if (phu != null)
              Text(
                phu!,
                style: const TextStyle(height: 1.7, color: Color(0xff716a80)),
              ),
            if (trangThai != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: NhanTrangThai(trangThai!),
              ),
            if (hanhDong.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(color: Color(0xfff0ecf6)),
              Wrap(spacing: 8, children: hanhDong),
            ],
          ],
        ),
      ),
    ),
  );
}
