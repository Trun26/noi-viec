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
  Widget build(BuildContext c) {
    final dong = DateTime.tryParse(d['hanNhan']?.toString() ?? '');
    final hetHan = dong != null && dong.isBefore(DateTime.now());
    final dangTuyen = d['trangThai'] == 'DangTuyen' && !hetHan;
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết việc làm')),
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
                        child: Text('Tin tuyển dụng hiện không nhận hồ sơ.'),
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
                            if (c.mounted && ung.nguoi != null) {
                              Navigator.pop(c);
                            }
                          },
                          child: const Text('Đăng nhập để ứng tuyển'),
                        ),
                      ),
                    if (dangTuyen && ung.ungVien && hanhDong.isNotEmpty)
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
        padding: const EdgeInsets.all(22),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xffeee9ff),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.business_center_outlined,
                    size: 32,
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
                const SizedBox(height: 14),
                Text(
                  d['luongMin'] == null
                      ? 'Lương thỏa thuận'
                      : '${tien(d['luongMin'])} – ${tien(d['luongMax'])}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff6250d8),
                  ),
                ),
                const SizedBox(height: 18),
                for (final e in {
                  Icons.location_on_outlined: d['diaDiem'],
                  Icons.schedule: tenNhan(d['hinhThuc']),
                  Icons.event_outlined: 'Hạn nhận: ${ngay(d['hanNhan'])}',
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
                            e.value?.toString() ?? 'Chưa cập nhật',
                            style: const TextStyle(color: Color(0xff716a80)),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _chiSo('Kinh nghiệm', d['kinhNghiem']),
              _chiSo('Trình độ', d['trinhDo']),
              _chiSo('Số lượng', '${d['soNguoi'] ?? '—'} người'),
            ],
          ),
          for (final e in {
            'moTa': 'Mô tả công việc',
            'yeuCau': 'Yêu cầu ứng viên',
            'quyenLoi': 'Quyền lợi của bạn',
          }.entries) ...[
            const SizedBox(height: 26),
            Text(
              e.value,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            SelectableText(
              d[e.key]?.toString() ?? 'Chưa cập nhật',
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
              : 'Chưa cập nhật',
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
