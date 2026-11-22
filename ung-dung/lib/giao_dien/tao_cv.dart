import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../nghiep_vu/ung_dung.dart';
import 'thanh_phan.dart';

const kenhCv = MethodChannel('vn.noiviec/cv');
const truongCv = <String, String>{
  'hoTen': 'Họ và tên',
  'viTriMongMuon': 'Vị trí ứng tuyển',
  'email': 'Email',
  'lienHe': 'Số điện thoại',
  'diaChi': 'Địa chỉ',
  'lienKet': 'Portfolio / LinkedIn',
  'gioiThieu': 'Giới thiệu bản thân',
  'kinhNghiem': 'Kinh nghiệm làm việc',
  'hocVan': 'Học vấn',
  'kyNang': 'Kỹ năng',
  'duAn': 'Dự án',
  'chungChi': 'Chứng chỉ & thành tích',
};
const nhieuDongCv = {
  'gioiThieu',
  'kinhNghiem',
  'hocVan',
  'kyNang',
  'duAn',
  'chungChi',
};

class TaoCv extends StatefulWidget {
  final UngDung ung;
  const TaoCv({super.key, required this.ung});
  @override
  State<TaoCv> createState() => _TaoCvState();
}

class _TaoCvState extends State<TaoCv> {
  final form = GlobalKey<FormState>();
  final nhap = <String, TextEditingController>{};
  String mau = 'tim';
  bool dangTai = true, dangXuLy = false;
  String? loi;
  String? taiKhoan;
  bool get dungPhien =>
      taiKhoan != null && widget.ung.nguoi?['id']?.toString() == taiKhoan;
  @override
  void initState() {
    super.initState();
    taiKhoan = widget.ung.nguoi?['id']?.toString();
    Map<String, dynamic> hs = {};
    try {
      hs = Map<String, dynamic>.from(jsonDecode(widget.ung.hoSoHienTai()));
    } catch (_) {}
    for (final key in truongCv.keys) {
      nhap[key] = TextEditingController(
        text:
            (key == 'hoTen' || key == 'email'
                    ? (widget.ung.nguoi?[key])
                    : hs[key])
                ?.toString() ??
            '',
      );
    }
    widget.ung.addListener(capNhatPhien);
    docNhap();
  }

  void capNhatPhien() {
    if (mounted) setState(() {});
  }

  Future<void> docNhap() async {
    try {
      final draft = await widget.ung.docNhap('tao-cv');
      if (!mounted || !dungPhien) return;
      if (draft != null) {
        for (final key in nhap.keys) {
          if (draft[key] is String) nhap[key]!.text = draft[key];
        }
        if (draft['mau'] == 'tim' || draft['mau'] == 'toiGian') {
          mau = draft['mau'];
        }
      }
    } catch (e) {
      if (mounted) loi = 'Chưa đọc được bản nháp: $e';
    } finally {
      if (mounted) setState(() => dangTai = false);
    }
  }

  @override
  void dispose() {
    widget.ung.removeListener(capNhatPhien);
    for (final c in nhap.values) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> get duLieu => {
    for (final e in nhap.entries) e.key: e.value.text.trim(),
    'mau': mau,
  };
  Future<void> xuLy(Future<void> Function() f) async {
    if (dangXuLy) return;
    if (!dungPhien) {
      bao(context, 'Phiên đăng nhập đã thay đổi. Hãy mở lại mục tạo CV.');
      return;
    }
    setState(() {
      dangXuLy = true;
      loi = null;
    });
    try {
      await f();
    } on MissingPluginException {
      if (mounted) {
        setState(
          () => loi =
              'Hãy dừng app và chạy lại từ source để bật chức năng tạo PDF mới.',
        );
      }
    } on PlatformException catch (e) {
      if (mounted) setState(() => loi = e.message ?? 'Không xử lý được PDF.');
    } catch (e) {
      if (mounted) setState(() => loi = e.toString());
    } finally {
      if (mounted) setState(() => dangXuLy = false);
    }
  }

  Future<void> xemTruoc() async {
    // Validate controller values as well: long forms lazily dispose off-screen fields.
    for (final key in ['hoTen', 'viTriMongMuon', 'email']) {
      if (nhap[key]!.text.trim().isEmpty) {
        setState(() => loi = 'Vui lòng nhập ${truongCv[key]!.toLowerCase()}');
        form.currentState!.validate();
        return;
      }
    }
    if (!RegExp(
      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
    ).hasMatch(nhap['email']!.text.trim())) {
      setState(() => loi = 'Email chưa hợp lệ');
      return;
    }
    if (!form.currentState!.validate()) return;
    if (nhap.values.fold<int>(0, (n, c) => n + c.text.length) > 24000) {
      setState(() => loi = 'Nội dung quá dài, vui lòng rút gọn CV.');
      return;
    }
    await xuLy(() async {
      await widget.ung.luuNhap('tao-cv', duLieu);
      final result = await kenhCv.invokeMapMethod<String, dynamic>('taoPdf', {
        'duLieu': {for (final e in nhap.entries) e.key: e.value.text.trim()},
        'mau': mau,
      });
      if (!mounted || !dungPhien) return;
      if (result == null || result['pdf'] is! Uint8List) {
        throw Exception('Không tạo được PDF.');
      }
      final daLuu = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => XemCv(
            ung: widget.ung,
            pdf: result['pdf'],
            soTrang: result['soTrang'] as int,
            ten: nhap['hoTen']!.text.trim(),
            taiKhoan: taiKhoan!,
          ),
        ),
      );
      if (mounted && daLuu == true) Navigator.pop(context, true);
    });
  }

  @override
  Widget build(BuildContext context) => !dungPhien
      ? Scaffold(
          appBar: AppBar(title: const Text('CV của tôi')),
          body: const Center(
            child: Text('Phiên đăng nhập đã thay đổi. Hãy mở lại CV.'),
          ),
        )
      : PopScope(
          canPop: !dangXuLy,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Tạo CV của bạn'),
              actions: [
                TextButton(
                  onPressed: dangTai || dangXuLy
                      ? null
                      : () => xuLy(() async {
                          await widget.ung.luuNhap('tao-cv', duLieu);
                          if (context.mounted) {
                            bao(context, 'Đã lưu bản nháp trên thiết bị.');
                          }
                        }),
                  child: const Text('Lưu nháp'),
                ),
              ],
            ),
            body: dangTai
                ? const Center(child: CircularProgressIndicator())
                : Form(
                    key: form,
                    child: ListView(
                      key: const Key('cv-editor-scroll'),
                      padding: const EdgeInsets.all(22),
                      children: [
                        const Text(
                          'Kể câu chuyện nghề nghiệp của bạn',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Thông tin hồ sơ được điền sẵn. Các mục để trống sẽ không xuất hiện trong PDF.',
                          style: TextStyle(
                            height: 1.5,
                            color: Color(0xff80788e),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Chọn phong cách',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('Tím chàm'),
                              avatar: const Icon(
                                Icons.article_outlined,
                                color: Color(0xff6250d8),
                              ),
                              selected: mau == 'tim',
                              onSelected: dangXuLy
                                  ? null
                                  : (_) => setState(() => mau = 'tim'),
                            ),
                            ChoiceChip(
                              label: const Text('Tối giản'),
                              avatar: const Icon(Icons.article_outlined),
                              selected: mau == 'toiGian',
                              onSelected: dangXuLy
                                  ? null
                                  : (_) => setState(() => mau = 'toiGian'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        for (final e in truongCv.entries)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: TextFormField(
                              controller: nhap[e.key],
                              enabled: !dangXuLy,
                              maxLength: nhieuDongCv.contains(e.key)
                                  ? 4000
                                  : 180,
                              maxLines: nhieuDongCv.contains(e.key) ? 5 : 1,
                              keyboardType: e.key == 'email'
                                  ? TextInputType.emailAddress
                                  : e.key == 'lienHe'
                                  ? TextInputType.phone
                                  : nhieuDongCv.contains(e.key)
                                  ? TextInputType.multiline
                                  : TextInputType.text,
                              decoration: InputDecoration(
                                labelText:
                                    '${e.value}${['hoTen', 'viTriMongMuon', 'email'].contains(e.key) ? ' *' : ''}',
                                alignLabelWithHint: true,
                              ),
                              validator: (v) {
                                final text = v?.trim() ?? '';
                                if ([
                                      'hoTen',
                                      'viTriMongMuon',
                                      'email',
                                    ].contains(e.key) &&
                                    text.isEmpty) {
                                  return 'Vui lòng nhập ${e.value.toLowerCase()}';
                                }
                                if (e.key == 'email' &&
                                    !RegExp(
                                      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                    ).hasMatch(text)) {
                                  return 'Email chưa hợp lệ';
                                }
                                return null;
                              },
                            ),
                          ),
                        if (loi != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              loi!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        FilledButton.icon(
                          onPressed: dangXuLy ? null : xemTruoc,
                          icon: Icon(
                            dangXuLy
                                ? Icons.hourglass_top
                                : Icons.preview_outlined,
                          ),
                          label: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Text(
                              dangXuLy ? 'Đang tạo PDF…' : 'Xem trước CV',
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
          ),
        );
}

class XemCv extends StatefulWidget {
  final UngDung ung;
  final Uint8List pdf;
  final int soTrang;
  final String ten, taiKhoan;
  const XemCv({
    super.key,
    required this.ung,
    required this.pdf,
    required this.soTrang,
    required this.ten,
    required this.taiKhoan,
  });
  @override
  State<XemCv> createState() => _XemCvState();
}

class _XemCvState extends State<XemCv> {
  @override
  void initState() {
    super.initState();
    widget.ung.addListener(capNhatPhien);
  }

  void capNhatPhien() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.ung.removeListener(capNhatPhien);
    super.dispose();
  }

  bool gui = false;
  String? loi;
  late final List<Future<Uint8List?>?> trang = List.filled(
    widget.soTrang,
    null,
  );
  String get tenTep =>
      'CV-${widget.ten.replaceAll(RegExp(r'[\\/:*?"<>|]'), '').trim()}.pdf';
  bool get dungPhien => widget.ung.nguoi?['id']?.toString() == widget.taiKhoan;
  Future<void> xuLy(Future<void> Function() f) async {
    if (gui) return;
    if (!dungPhien) {
      bao(context, 'Phiên đăng nhập đã thay đổi. Hãy mở lại CV.');
      return;
    }
    setState(() {
      gui = true;
      loi = null;
    });
    try {
      await f();
    } on MissingPluginException {
      if (mounted) {
        setState(
          () => loi =
              'Hãy dừng app và chạy lại từ source để bật chức năng tạo PDF mới.',
        );
      }
    } on PlatformException catch (e) {
      if (mounted) setState(() => loi = e.message ?? 'Không xử lý được PDF.');
    } catch (e) {
      if (mounted) setState(() => loi = e.toString());
    } finally {
      if (mounted) setState(() => gui = false);
    }
  }

  @override
  Widget build(BuildContext context) => !dungPhien
      ? Scaffold(
          appBar: AppBar(title: const Text('CV của tôi')),
          body: const Center(
            child: Text('Phiên đăng nhập đã thay đổi. Hãy mở lại CV.'),
          ),
        )
      : PopScope(
          canPop: !gui,
          child: Scaffold(
            appBar: AppBar(
              title: Text('Xem CV • ${widget.soTrang} trang'),
              actions: [
                IconButton(
                  tooltip: 'Lưu PDF vào thiết bị',
                  onPressed: gui
                      ? null
                      : () => xuLy(() async {
                          final path = await FilePicker.saveFile(
                            dialogTitle: 'Lưu CV PDF',
                            fileName: tenTep,
                            bytes: widget.pdf,
                          );
                          if (path != null && context.mounted) {
                            bao(context, 'Đã xuất PDF vào vị trí bạn chọn.');
                          }
                        }),
                  icon: const Icon(Icons.download_outlined),
                ),
              ],
            ),
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (loi != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          loi!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: gui
                            ? null
                            : () => xuLy(() async {
                                await widget.ung.taiTep(
                                  tenTep,
                                  widget.pdf,
                                  'CV',
                                );
                                if (context.mounted && dungPhien) {
                                  Navigator.pop(context, true);
                                }
                              }),
                        icon: Icon(
                          gui
                              ? Icons.hourglass_top
                              : Icons.cloud_upload_outlined,
                        ),
                        label: Text(gui ? 'Đang lưu…' : 'Lưu vào CV của tôi'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            body: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.soTrang,
              itemBuilder: (c, i) {
                trang[i] ??= kenhCv.invokeMethod<Uint8List>('xemTrang', {
                  'pdf': widget.pdf,
                  'trang': i,
                });
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: FutureBuilder<Uint8List?>(
                    future: trang[i],
                    builder: (c, s) {
                      if (s.hasError) {
                        return Column(
                          children: [
                            const Text('Chưa hiển thị được trang PDF.'),
                            TextButton(
                              onPressed: () => setState(() => trang[i] = null),
                              child: const Text('Thử lại'),
                            ),
                          ],
                        );
                      }
                      if (!s.hasData) {
                        return const AspectRatio(
                          aspectRatio: 595 / 842,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return Semantics(
                        label: 'Trang ${i + 1} của CV',
                        child: Image.memory(s.data!, fit: BoxFit.contain),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        );
}
