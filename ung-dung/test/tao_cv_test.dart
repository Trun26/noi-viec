import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:ung_dung/du_lieu/may_chu.dart';
import 'package:ung_dung/nghiep_vu/ung_dung.dart';
import 'package:ung_dung/giao_dien/tao_cv.dart';
import 'ho_tro.dart';

class UngDungCvThu extends UngDung {
  int soLanTai = 0;
  bool loiTai = false;
  String? tenTai, loaiTai;
  UngDungCvThu(KhoThu kho)
    : super(
        MayChu(
          kho,
          KhoPhienThu(),
          client: MockClient((_) async => phanHoi('{}', 200)),
        )..taiKhoanId = 'A',
      ) {
    nguoi = {
      'id': 'A',
      'hoTen': 'Nguyễn Thị Ánh',
      'email': 'anh@example.invalid',
      'loai': 'UngVien',
      'hoSoJson': jsonEncode({
        'viTriMongMuon': 'Lập trình viên Flutter',
        'kyNang': 'Dart, Flutter',
      }),
    };
  }
  @override
  Future<String> taiTep(String ten, List<int> bytes, String loai) async {
    soLanTai++;
    tenTai = ten;
    loaiTai = loai;
    if (loiTai) throw Exception('Mất mạng khi lưu CV');
    expect(utf8.decode(bytes.take(5).toList()), '%PDF-');
    return 'cv-created';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Map<dynamic, dynamic>? noiDungPdf;
  setUp(() {
    noiDungPdf = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(kenhCv, (call) async {
          if (call.method == 'taoPdf') {
            noiDungPdf = call.arguments;
            return {
              'pdf': Uint8List.fromList(utf8.encode('%PDF-test')),
              'soTrang': 1,
            };
          }
          return base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jZrkAAAAASUVORK5CYII=',
          );
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(kenhCv, null),
  );
  Future<void> mo(WidgetTester t, UngDungCvThu u) async {
    t.view.physicalSize = const Size(400, 850);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                c,
                MaterialPageRoute(builder: (_) => TaoCv(ung: u)),
              ),
              child: const Text('Mở tạo CV'),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('Mở tạo CV'));
    await t.pumpAndSettle();
  }

  Future<void> xem(WidgetTester t) async {
    await t.scrollUntilVisible(
      find.text('Xem trước CV'),
      350,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('cv-editor-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await t.tap(find.text('Xem trước CV'));
    await t.pumpAndSettle();
  }

  testWidgets('Điền hồ sơ, chọn mẫu, xem PDF và lưu CV đúng loại', (t) async {
    final kho = KhoThu();
    final u = UngDungCvThu(kho);
    await mo(t, u);
    expect(find.text('Nguyễn Thị Ánh'), findsOneWidget);
    await t.tap(find.text('Tối giản'));
    await t.pumpAndSettle();
    await xem(t);
    expect(noiDungPdf?['mau'], 'toiGian');
    expect((noiDungPdf?['duLieu'] as Map)['hoTen'], 'Nguyễn Thị Ánh');
    expect(find.text('Xem CV • 1 trang'), findsOneWidget);
    await t.tap(find.text('Lưu vào CV của tôi'));
    await t.pumpAndSettle();
    expect(u.soLanTai, 1);
    expect(u.loaiTai, 'CV');
    expect(u.tenTai, 'CV-Nguyễn Thị Ánh.pdf');
    expect(find.text('Mở tạo CV'), findsOneWidget);
    expect(kho.duLieu['A/nhap/tao-cv']['kyNang'], 'Dart, Flutter');
    expect(t.takeException(), isNull);
  });
  testWidgets('Lỗi mạng giữ bản xem trước để thử lưu lại', (t) async {
    final u = UngDungCvThu(KhoThu())..loiTai = true;
    await mo(t, u);
    await xem(t);
    await t.tap(find.text('Lưu vào CV của tôi'));
    await t.pumpAndSettle();
    expect(find.textContaining('Mất mạng khi lưu CV'), findsOneWidget);
    expect(find.text('Xem CV • 1 trang'), findsOneWidget);
    u.loiTai = false;
    await t.tap(find.text('Lưu vào CV của tôi'));
    await t.pumpAndSettle();
    expect(find.text('Mở tạo CV'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets('Không xuất CV khi thiếu tên và không đọc nháp tài khoản khác', (
    t,
  ) async {
    final kho = KhoThu();
    await kho.luu('B', 'nhap/tao-cv', {'hoTen': 'Riêng tư tài khoản B'});
    final u = UngDungCvThu(kho);
    u.nguoi!['hoTen'] = '';
    await mo(t, u);
    expect(find.text('Riêng tư tài khoản B'), findsNothing);
    await xem(t);
    expect(noiDungPdf, isNull);
    expect(u.soLanTai, 0);
    expect(t.takeException(), isNull);
  });
}
