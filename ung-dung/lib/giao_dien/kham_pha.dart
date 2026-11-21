import 'package:flutter/material.dart';
import '../nghiep_vu/ung_dung.dart';
import 'chuc_nang.dart';
import 'thanh_phan.dart';

class KhamPha extends StatefulWidget {
  final UngDung ung;
  final VoidCallback chonViec;
  const KhamPha({super.key, required this.ung, required this.chonViec});
  @override
  State<KhamPha> createState() => _KhamPhaState();
}

class _KhamPhaState extends State<KhamPha> {
  final tim = TextEditingController();
  late Future<dynamic> viec = widget.ung.danhSach('tin-tuyen-dung?trang=1');
  void timViec() => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) =>
          ChucNang(context, widget.ung).tin(tuKhoa: tim.text.trim()),
    ),
  );
  @override
  void dispose() {
    tim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'BƯỚC TIẾP THEO CỦA BẠN',
        style: TextStyle(
          fontSize: 10,
          letterSpacing: 1.8,
          fontWeight: FontWeight.w800,
          color: Color(0xff8a80ab),
        ),
      ),
      const SizedBox(height: 10),
      const Text(
        'Tìm việc hợp ý.\nChạm tới tương lai.',
        style: TextStyle(
          fontSize: 31,
          height: 1.2,
          fontWeight: FontWeight.w800,
          color: Color(0xff28233f),
          letterSpacing: -0.8,
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        'Khám phá cơ hội mới, bắt đầu từ hôm nay.',
        style: TextStyle(color: Color(0xff807a91), height: 1.5),
      ),
      const SizedBox(height: 22),
      TextField(
        controller: tim,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => timViec(),
        decoration: InputDecoration(
          hintText: 'Vị trí, kỹ năng hoặc từ khóa',
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xff6250d8),
          ),
          suffixIcon: IconButton(
            tooltip: 'Tìm việc làm',
            onPressed: timViec,
            icon: const Icon(Icons.arrow_forward_rounded),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xffe4def5)),
          ),
        ),
      ),
      const SizedBox(height: 22),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xff6250d8), Color(0xff8c74e8)],
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Một cơ hội mới,\nmột khởi đầu tốt hơn.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: widget.chonViec,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Khám phá việc làm',
                            style: TextStyle(
                              color: Color(0xffffd3a5),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward,
                            size: 17,
                            color: Color(0xffffd3a5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Transform.rotate(
              angle: -0.15,
              child: Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.17),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.work_outline_rounded,
                  size: 40,
                  color: Color(0xffffd3a5),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      Row(
        children: [
          const Expanded(
            child: Text(
              'Việc làm mới nhất',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          TextButton(
            onPressed: widget.chonViec,
            child: const Text('Xem tất cả'),
          ),
        ],
      ),
      FutureBuilder(
        future: viec,
        builder: (c, s) {
          if (s.hasError) {
            return TextButton.icon(
              onPressed: () => setState(
                () => viec = widget.ung.danhSach('tin-tuyen-dung?trang=1'),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Tải lại việc làm'),
            );
          }
          if (!s.hasData) return const LinearProgressIndicator();
          final ds = (s.data['duLieu'] as List).take(3).toList();
          if (ds.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text('Chưa có việc làm mới. Hãy quay lại sau nhé.'),
            );
          }
          return Column(
            children: [
              for (final d in ds)
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => thucHien(
                      c,
                      () => ChucNang(c, widget.ung).chiTietTin(d['id']),
                    ),
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
                                  color: const Color(0xfff0ebff),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.business_center_outlined,
                                  color: Color(0xff6250d8),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  d['tieuDe'] ?? 'Cơ hội việc làm',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.arrow_outward,
                                size: 18,
                                color: Color(0xffa19aac),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            d['luongMin'] == null
                                ? 'Lương thỏa thuận'
                                : '${tien(d['luongMin'])} – ${tien(d['luongMax'])}',
                            style: const TextStyle(
                              color: Color(0xff6250d8),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              for (final text in [
                                d['diaDiem'],
                                tenNhan(d['hinhThuc']),
                              ])
                                if (text != null && text.toString().isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xfff7f6fa),
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: Text(
                                      text.toString(),
                                      style: const TextStyle(
                                        color: Color(0xff807a91),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                            ],
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
  );
}

class GoiTrangChu extends StatefulWidget {
  final UngDung ung;
  const GoiTrangChu({super.key, required this.ung});
  @override
  State<GoiTrangChu> createState() => _GoiTrangChuState();
}

class _GoiTrangChuState extends State<GoiTrangChu> {
  int trang = 1;
  late Future<dynamic> duLieu = doc();
  Future<dynamic> doc() =>
      widget.ung.danhSach('goi-luot?trang=$trang&kichThuoc=3');
  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: duLieu,
    builder: (c, s) {
      if (s.hasError) {
        return TextButton(
          onPressed: () => setState(() => duLieu = doc()),
          child: const Text('Tải lại gói đăng tin'),
        );
      }
      if (!s.hasData) return const LinearProgressIndicator();
      final ds = s.data['duLieu'] as List;
      final tong = s.data['tong'] as int;
      return Column(
        children: [
          for (final d in ds)
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(14),
                leading: SizedBox(
                  width: 48,
                  height: 48,
                  child: ChucNang(c, widget.ung).anh(d['anhId']),
                ),
                title: Text(
                  d['ten'],
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text('${d['soLuot']} lượt đăng • ${tien(d['gia'])}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => thucHien(
                  c,
                  () => ChucNang(c, widget.ung).chiTietGoi(d['id']),
                ),
              ),
            ),
          if (ds.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Chưa có gói đăng tin.'),
            ),
          if (tong > 3)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Trang trước',
                  onPressed: trang > 1
                      ? () => setState(() {
                          trang--;
                          duLieu = doc();
                        })
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('Trang $trang'),
                IconButton(
                  tooltip: 'Trang tiếp theo',
                  onPressed: trang * 3 < tong
                      ? () => setState(() {
                          trang++;
                          duLieu = doc();
                        })
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
        ],
      );
    },
  );
}
