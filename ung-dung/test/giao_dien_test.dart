import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:ung_dung/du_lieu/may_chu.dart';
import 'package:ung_dung/nghiep_vu/ung_dung.dart';
import 'package:ung_dung/main.dart';
import 'ho_tro.dart';
import 'package:ung_dung/giao_dien/chi_tiet_viec.dart';

class UngDungThu extends UngDung {
  UngDungThu(super.api);
  @override
  Future<void> khoiTao() async {}
}

void main() {
  testWidgets(
    'Chi tiết việc làm có nút đăng nhập và không nhận hồ sơ hết hạn',
    (t) async {
      t.view.physicalSize = const Size(360, 800);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final u = UngDungThu(MayChu(KhoThu(), KhoPhienThu()));
      final d = <String, dynamic>{
        'tieuDe': 'Lập trình viên ứng dụng di động Flutter',
        'trangThai': 'DangTuyen',
        'hanNhan': DateTime.now()
            .add(const Duration(days: 7))
            .toIso8601String(),
        'diaDiem': 'TP. Hồ Chí Minh',
        'hinhThuc': 'ToanThoiGian',
      };
      await t.pumpWidget(
        MaterialApp(
          home: ChiTietViec(d: d, ung: u, hanhDong: const []),
        ),
      );
      expect(find.text('Đăng nhập để ứng tuyển'), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(
        MaterialApp(
          home: ChiTietViec(
            d: {...d, 'hanNhan': '2020-01-01'},
            ung: u,
            hanhDong: const [],
          ),
        ),
      );
      expect(find.text('Đăng nhập để ứng tuyển'), findsNothing);
      expect(
        find.text('Tin tuyển dụng hiện không nhận hồ sơ.'),
        findsOneWidget,
      );
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('Trang chủ điện thoại và tìm kiếm dịch vụ không tràn bố cục', (
    t,
  ) async {
    t.view.physicalSize = const Size(360, 800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final u = UngDungThu(
      MayChu(
        KhoThu(),
        KhoPhienThu(),
        client: MockClient(
          (_) async => phanHoi(
            jsonEncode({
              'duLieu': [
                {
                  'id': 'g1',
                  'ten': 'Gói cơ bản',
                  'tieuDe': 'Lập trình viên Flutter',
                  'diaDiem': 'TP. Hồ Chí Minh',
                  'hinhThuc': 'ToanThoiGian',
                  'danhMucId': 'dm1',
                  'moTa': 'Một lượt đăng tin',
                  'gia': 20000,
                  'soLuot': 1,
                  'anhId': 'anh',
                },
              ],
              'tong': 1,
              'trang': 1,
              'kichThuoc': 12,
            }),
            200,
          ),
        ),
      ),
    );
    await t.pumpWidget(Mobi(ung: u));
    await t.pumpAndSettle();
    expect(find.text('Chào mừng trở lại!'), findsOneWidget);
    expect(t.takeException(), isNull, reason: 'Màn đăng nhập ban đầu');
    await t.tap(find.text('Khám phá việc làm trước'));
    await t.pumpAndSettle();
    expect(find.text('Nối Việc'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsNothing);
    expect(find.text('Tạo tài khoản'), findsNothing);
    expect(
      t.takeException(),
      isNull,
      reason: 'Trang chủ phải vừa màn hình 360 px',
    );
    await t.tap(find.text('Gói đăng tin'));
    await t.pumpAndSettle();
    expect(find.text('Gói cơ bản'), findsOneWidget);
    expect(t.takeException(), isNull);
    expect(find.text('Thêm vào giỏ'), findsNothing);
    await t.tap(find.text('Tài khoản'));
    await t.pumpAndSettle();
    await t.tap(find.text('Đăng nhập'));
    await t.pumpAndSettle();
    expect(find.text('Chào mừng trở lại!'), findsOneWidget);
    expect(find.text('Lưu thông tin'), findsNothing);
    expect(t.takeException(), isNull);
  });
}
