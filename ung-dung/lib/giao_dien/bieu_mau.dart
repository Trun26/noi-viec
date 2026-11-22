import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../nghiep_vu/ung_dung.dart';
import 'thanh_phan.dart';

class TruongNhap {
  final String khoa, nhan;
  final bool batBuoc, so, an, nhieuDong;
  final Map<String, String>? chon;
  const TruongNhap(
    this.khoa,
    this.nhan, {
    this.batBuoc = true,
    this.so = false,
    this.an = false,
    this.nhieuDong = false,
    this.chon,
  });
}

Future<Map<String, dynamic>?> moBieuMau(
  BuildContext c,
  UngDung ung,
  String tieuDe,
  List<TruongNhap> truong, {
  Map<String, dynamic>? giaTri,
  String? khoaNhap,
  bool anh = false,
  bool cv = false,
  bool hoSoCaNhan = false,
  Future<void> Function(Map<String, dynamic>)? luu,
}) => Navigator.push<Map<String, dynamic>>(
  c,
  MaterialPageRoute(
    builder: (_) => ManBieuMau(
      ung: ung,
      tieuDe: tieuDe,
      truong: truong,
      giaTri: giaTri ?? {},
      khoaNhap: khoaNhap,
      anh: anh,
      cv: cv,
      hoSoCaNhan: hoSoCaNhan,
      luu: luu,
    ),
  ),
);

class ManBieuMau extends StatefulWidget {
  final UngDung ung;
  final String tieuDe;
  final List<TruongNhap> truong;
  final Map<String, dynamic> giaTri;
  final String? khoaNhap;
  final bool anh, cv, hoSoCaNhan;
  final Future<void> Function(Map<String, dynamic>)? luu;
  const ManBieuMau({
    super.key,
    required this.ung,
    required this.tieuDe,
    required this.truong,
    required this.giaTri,
    this.khoaNhap,
    this.anh = false,
    this.cv = false,
    this.hoSoCaNhan = false,
    this.luu,
  });
  @override
  State<ManBieuMau> createState() => _ManBieuMauState();
}

class _ManBieuMauState extends State<ManBieuMau> {
  final khoa = GlobalKey<FormState>();
  final nhap = <String, TextEditingController>{};
  bool gui = false;
  String? anhId, tenTep, loi;
  @override
  void initState() {
    super.initState();
    for (final t in widget.truong) {
      nhap[t.khoa] = TextEditingController(
        text: widget.giaTri[t.khoa]?.toString() ?? '',
      );
    }
    anhId = widget.giaTri[widget.cv ? 'cvId' : 'anhId'];
  }

  @override
  void dispose() {
    for (final c in nhap.values) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> giaTri() => {
    for (final t in widget.truong)
      t.khoa: t.so
          ? num.tryParse(nhap[t.khoa]!.text.replaceAll(',', '.'))
          : nhap[t.khoa]!.text.trim(),
    if (anhId != null) (widget.cv ? 'cvId' : 'anhId'): anhId,
  };
  Future<void> chonTep() async {
    setState(() => gui = true);
    try {
      final ds = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: widget.cv ? ['pdf'] : ['png', 'jpg', 'jpeg'],
      );
      if (ds.isNotEmpty) {
        final f = ds.single;
        if ((await f.length() ?? 0) > (widget.cv ? 10 : 5) * 1024 * 1024) {
          throw Exception('Tập tin vượt giới hạn cho phép.');
        }
        final id = await widget.ung.taiTep(
          f.name,
          await f.readAsBytes(),
          widget.cv ? 'CV' : 'Anh',
        );
        if (mounted) {
          setState(() {
            anhId = id;
            tenTep = f.name;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => loi = e.toString());
    } finally {
      if (mounted) setState(() => gui = false);
    }
  }

  Future<void> luu() async {
    if (!khoa.currentState!.validate()) return;
    if ((widget.anh || widget.cv) && anhId == null) {
      setState(() => loi = 'Vui lòng chọn tập tin.');
      return;
    }
    setState(() {
      gui = true;
      loi = null;
    });
    try {
      final d = giaTri();
      if (widget.luu != null) await widget.luu!(d);
      if (mounted) Navigator.pop(context, d);
    } catch (e) {
      if (mounted) setState(() => loi = e.toString());
    } finally {
      if (mounted) setState(() => gui = false);
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: Text(widget.tieuDe)),
    body: Form(
      key: khoa,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (widget.hoSoCaNhan)
            Card(
              color: const Color(0xfff2efff),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.badge_outlined,
                        color: Color(0xff6250d8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hồ sơ ứng viên',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Thông tin này giúp nhà tuyển dụng hiểu rõ kinh nghiệm và định hướng của bạn.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (widget.hoSoCaNhan) ...[
            const SizedBox(height: 14),
            const Text(
              'THÔNG TIN LIÊN HỆ',
              style: TextStyle(
                color: Color(0xff6250d8),
                fontWeight: FontWeight.w800,
                letterSpacing: .5,
              ),
            ),
          ],
          for (var i = 0; i < widget.truong.length; i++) ...[
            if (widget.hoSoCaNhan && i == 2) ...[
              const SizedBox(height: 6),
              const Text(
                'NĂNG LỰC VÀ ĐỊNH HƯỚNG',
                style: TextStyle(
                  color: Color(0xff6250d8),
                  fontWeight: FontWeight.w800,
                  letterSpacing: .5,
                ),
              ),
            ],
            for (final t in [widget.truong[i]])
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: t.chon != null
                    ? DropdownButtonFormField<String>(
                        initialValue: t.chon!.containsKey(nhap[t.khoa]!.text)
                            ? nhap[t.khoa]!.text
                            : null,
                        isExpanded: true,
                        decoration: InputDecoration(labelText: t.nhan),
                        items: t.chon!.entries
                            .map(
                              (e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(
                                  e.value,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: gui
                            ? null
                            : (s) => nhap[t.khoa]!.text = s ?? '',
                        validator: (v) => t.batBuoc && (v == null || v.isEmpty)
                            ? 'Vui lòng chọn ${t.nhan.toLowerCase()}'
                            : null,
                      )
                    : TextFormField(
                        controller: nhap[t.khoa],
                        enabled: !gui,
                        obscureText: t.an,
                        maxLines: t.nhieuDong ? 5 : 1,
                        keyboardType: t.so
                            ? const TextInputType.numberWithOptions(
                                decimal: true,
                              )
                            : TextInputType.text,
                        decoration: InputDecoration(labelText: t.nhan),
                        validator: (v) {
                          if (t.batBuoc && (v == null || v.trim().isEmpty)) {
                            return 'Vui lòng nhập ${t.nhan.toLowerCase()}';
                          }
                          if (t.so &&
                              v != null &&
                              v.isNotEmpty &&
                              num.tryParse(v.replaceAll(',', '.')) == null) {
                            return 'Nhập số hợp lệ';
                          }
                          return null;
                        },
                      ),
              ),
          ],
          if (widget.anh || widget.cv)
            OutlinedButton.icon(
              onPressed: gui ? null : chonTep,
              icon: const Icon(Icons.upload_file),
              label: Text(
                tenTep ??
                    (anhId != null
                        ? 'Đã có tập tin • chọn để thay'
                        : widget.cv
                        ? 'Tải CV PDF (tối đa 10 MB)'
                        : 'Tải ảnh PNG/JPEG (tối đa 5 MB)'),
              ),
            ),
          if (loi != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                loi!,
                style: TextStyle(color: Theme.of(c).colorScheme.error),
              ),
            ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: gui ? null : luu,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(gui ? 'Đang lưu…' : 'Lưu thông tin'),
            ),
          ),
          if (widget.khoaNhap != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: gui
                  ? null
                  : () => thucHien(c, () async {
                      await widget.ung.luuNhap(widget.khoaNhap!, giaTri());
                      if (c.mounted) bao(c, 'Đã lưu nháp trên điện thoại.');
                    }),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Lưu nháp trên điện thoại'),
            ),
            TextButton(
              onPressed: () => thucHien(c, () async {
                final d = await widget.ung.docNhap(widget.khoaNhap!);
                if (d != null && mounted) {
                  setState(() {
                    for (final e in d.entries) {
                      nhap[e.key]?.text = e.value?.toString() ?? '';
                    }
                  });
                }
              }),
              child: const Text('Khôi phục bản nháp'),
            ),
          ],
        ],
      ),
    ),
  );
}
