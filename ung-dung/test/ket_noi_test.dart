import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'ho_tro.dart';
import 'package:ung_dung/du_lieu/may_chu.dart';
import 'package:ung_dung/nghiep_vu/ung_dung.dart';

void main() {
  test('Mất mạng chỉ dùng dữ liệu của đúng tài khoản', () async {
    final kho = KhoThu();
    await kho.luu('A', 'gio-hang', [
      {'soLuong': 2},
    ]);
    final api = MayChu(
      kho,
      KhoPhienThu(),
      client: MockClient((_) async => throw http.ClientException('mất mạng')),
    )..taiKhoanId = 'A';
    expect((await api.doc('gio-hang') as List).length, 1);
    expect(api.duLieuCu, isTrue);
    api.taiKhoanId = 'B';
    await expectLater(api.doc('gio-hang'), throwsA(isA<LoiApi>()));
  });
  test('Bị từ chối quyền không được thay bằng bản lưu cũ', () async {
    final kho = KhoThu();
    await kho.luu('A', 'ho-so', [
      {'id': 'riêng tư'},
    ]);
    final api = MayChu(
      kho,
      KhoPhienThu(),
      client: MockClient(
        (_) async => phanHoi(jsonEncode({'thongBao': 'Không có quyền'}), 403),
      ),
    )..taiKhoanId = 'A';
    await expectLater(
      api.doc('ho-so'),
      throwsA(isA<LoiApi>().having((e) => e.ma, 'mã', 403)),
    );
  });
  test(
    'Giỏ dùng số lượng gói, không dùng số lượt làm số trên biểu tượng',
    () async {
      final api = MayChu(
        KhoThu(),
        KhoPhienThu(),
        client: MockClient(
          (_) async => phanHoi(
            jsonEncode([
              {'soLuong': 3, 'soLuot': 1},
              {'soLuong': 2, 'soLuot': 5},
            ]),
            200,
          ),
        ),
      );
      final u = UngDung(api);
      await u.capNhatGio();
      expect(u.soGoi, 5);
    },
  );
  test('Đặt lại sau mất phản hồi giữ cùng khóa chống tạo đơn lặp', () async {
    final khoa = <String>[];
    int lan = 0;
    final api = MayChu(
      KhoThu(),
      KhoPhienThu(),
      client: MockClient((r) async {
        if (r.url.path.endsWith('don-hang')) {
          khoa.add(jsonDecode(r.body)['khoaLap']);
          if (lan++ == 0) throw http.ClientException('Mất phản hồi');
          return phanHoi('{"id":"don-1"}', 200);
        }
        return phanHoi('[]', 200);
      }),
    );
    final u = UngDung(api);
    await expectLater(u.datDon(), throwsA(isA<LoiApi>()));
    await u.datDon();
    expect(khoa.length, 2);
    expect(khoa[0], khoa[1]);
    expect(u.khoaDon, isNull);
  });
  test('Khóa chống lặp còn nguyên khi ứng dụng được mở lại', () async {
    final kho = KhoThu();
    final khoa = <String>[];
    final api = MayChu(
      kho,
      KhoPhienThu(),
      client: MockClient((r) async {
        khoa.add(jsonDecode(r.body)['khoaLap']);
        throw http.ClientException('Mất mạng');
      }),
    );
    await expectLater(UngDung(api).datDon(), throwsA(isA<LoiApi>()));
    await expectLater(UngDung(api).datDon(), throwsA(isA<LoiApi>()));
    expect(khoa[0], khoa[1]);
  });
  test('Không tự gửi lại thao tác quan trọng khi mất mạng', () async {
    int lan = 0;
    final api = MayChu(
      KhoThu(),
      KhoPhienThu(),
      client: MockClient((_) async {
        lan++;
        throw http.ClientException('Mất mạng');
      }),
    );
    await expectLater(
      api.gui('tin-tuyen-dung/x/ung-tuyen', {}),
      throwsA(isA<LoiApi>()),
    );
    expect(lan, 1);
  });
}
