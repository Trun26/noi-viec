import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ung_dung/du_lieu/may_chu.dart';
import 'package:ung_dung/nghiep_vu/trang_thai.dart';
import 'ho_tro.dart';

void dung(bool d, String loi) {
  if (!d) throw StateError(loi);
}

Future<void> coLoi(Future<dynamic> viec, {int? ma}) async {
  try {
    await viec;
  } on LoiApi catch (e) {
    if (ma != null) dung(e.ma == ma, 'Mã lỗi ${e.ma}, mong đợi $ma');
    return;
  }
  throw StateError('Lẽ ra thao tác phải bị từ chối.');
}

Future<void> main() async {
  final cacCa = <String, Future<void> Function()>{
    'Mất mạng chỉ đọc bộ nhớ của đúng tài khoản': () async {
      final kho = KhoThu();
      await kho.luu('A', 'gio-hang', [
        {'soLuong': 2},
      ]);
      final api = MayChu(
        kho,
        KhoPhienThu(),
        client: MockClient((_) async => throw http.ClientException('Mất mạng')),
      )..taiKhoanId = 'A';
      dung(
        (await api.doc('gio-hang') as List).length == 1,
        'Không đọc được bản lưu A',
      );
      dung(api.duLieuCu, 'Thiếu nhãn dữ liệu cũ');
      api.taiKhoanId = 'B';
      await coLoi(api.doc('gio-hang'));
    },
    'Lỗi 403 không được thay bằng cache riêng tư': () async {
      final kho = KhoThu();
      await kho.luu('A', 'ho-so', [
        {'id': 'rieng-tu'},
      ]);
      final api = MayChu(
        kho,
        KhoPhienThu(),
        client: MockClient(
          (_) async => phanHoi('{"thongBao":"Không có quyền"}', 403),
        ),
      )..taiKhoanId = 'A';
      await coLoi(api.doc('ho-so'), ma: 403);
    },
    'Badge giỏ đếm năm gói thay vì mười ba lượt': () async {
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
      final u = TrangThaiUngDung(api);
      await u.capNhatGio();
      dung(u.soGoi == 5, 'Sai số lượng gói');
    },
    'Mất phản hồi đặt đơn phải dùng lại cùng khóa': () async {
      final khoa = <String>[];
      var lan = 0;
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
      final u = TrangThaiUngDung(api);
      await coLoi(u.datDon());
      await u.datDon();
      dung(
        khoa.length == 2 && khoa[0] == khoa[1],
        'Đổi khóa khi chưa biết kết quả',
      );
      dung(u.khoaDon == null, 'Không dọn khóa sau xác nhận');
    },
    'Mở lại ứng dụng vẫn giữ khóa đơn chưa có xác nhận': () async {
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
      await coLoi(TrangThaiUngDung(api).datDon());
      await coLoi(TrangThaiUngDung(api).datDon());
      dung(khoa[0] == khoa[1], 'Mất khóa đặt đơn sau mở lại');
    },
    'Không tự gửi lại thao tác quan trọng': () async {
      var lan = 0;
      final api = MayChu(
        KhoThu(),
        KhoPhienThu(),
        client: MockClient((_) async {
          lan++;
          throw http.ClientException('Mất mạng');
        }),
      );
      await coLoi(api.gui('tin-tuyen-dung/x/ung-tuyen', {}));
      dung(lan == 1, 'Đã âm thầm gửi lại');
    },
    'Phản hồi tài khoản cũ không lọt sang tài khoản mới': () async {
      final daGui = Completer<void>();
      final traVe = Completer<http.Response>();
      final kho = KhoThu();
      final api = MayChu(
        kho,
        KhoPhienThu(),
        client: MockClient((_) async {
          daGui.complete();
          return traVe.future;
        }),
      );
      await api.luuPhien('token-A', 'A');
      final dangDoc = api.doc('ho-so');
      await daGui.future;
      await api.xoaPhien();
      await api.luuPhien('token-B', 'B');
      final batLoi = coLoi(dangDoc, ma: 401);
      traVe.complete(phanHoi('{"hoTen":"Dữ liệu riêng A"}', 200));
      await batLoi;
      dung(await kho.doc('B', 'ho-so') == null, 'Dữ liệu A bị lưu vào B');
      dung(
        await kho.doc('A', 'ho-so') == null,
        'Phản hồi muộn ghi lại dữ liệu sau đăng xuất',
      );
    },
    'Đăng xuất khi mất mạng vẫn xóa phiên và cache': () async {
      final kho = KhoThu();
      final phien = KhoPhienThu();
      final api = MayChu(
        kho,
        phien,
        client: MockClient((_) async => throw http.ClientException('Mất mạng')),
      );
      await api.luuPhien('token-A', 'A');
      await kho.luu('A', 'ho-so', {'ten': 'A'});
      final u = TrangThaiUngDung(api)..nguoi = {'id': 'A'};
      await coLoi(u.dangXuat());
      dung(
        u.nguoi == null && api.maTruyCap == null && api.taiKhoanId == 'khach',
        'Phiên chưa kết thúc',
      );
      dung(await kho.doc('A', 'ho-so') == null, 'Chưa xóa cache');
      dung(phien.duLieu.isEmpty, 'Chưa xóa token đã lưu');
    },
    'Bấm đặt đơn lần hai trong lúc chờ không gửi thêm': () async {
      final daGui = Completer<void>();
      final traVe = Completer<http.Response>();
      var soDon = 0;
      final api = MayChu(
        KhoThu(),
        KhoPhienThu(),
        client: MockClient((r) async {
          if (r.url.path.endsWith('don-hang')) {
            soDon++;
            daGui.complete();
            return traVe.future;
          }
          return phanHoi('[]', 200);
        }),
      );
      final u = TrangThaiUngDung(api);
      final lanDau = u.datDon();
      await daGui.future;
      await coLoi(u.datDon());
      traVe.complete(phanHoi('{"id":"don-1"}', 200));
      await lanDau;
      dung(soDon == 1, 'Đã gửi hai đơn đồng thời');
    },
    'Phiên được khôi phục bằng cặp token/tài khoản đồng nhất': () async {
      final phien = KhoPhienThu();
      final a = MayChu(KhoThu(), phien);
      await a.luuPhien('token-A', 'A');
      final b = MayChu(KhoThu(), phien);
      await b.khoiTao();
      dung(
        b.maTruyCap == 'token-A' && b.taiKhoanId == 'A',
        'Mất thông tin phiên',
      );
      phien.duLieu['phien_lam_viec'] = 'khong-phai-json';
      final c = MayChu(KhoThu(), phien);
      await c.khoiTao();
      dung(
        c.maTruyCap == null && c.taiKhoanId == 'khach',
        'Phiên hỏng vẫn được dùng',
      );
    },
  };
  var dat = 0;
  for (final ca in cacCa.entries) {
    try {
      await ca.value();
      dat++;
      stdout.writeln('ĐẠT: ${ca.key}');
    } catch (e, st) {
      stderr.writeln('KHÔNG ĐẠT: ${ca.key}\n$e\n$st');
      exitCode = 1;
    }
  }
  stdout.writeln(
    'Kết quả: $dat/${cacCa.length} ca nghiệp vụ đạt. HTTP/kho lưu được thay thế để kiểm tra logic; không phải nghiệm thu API, SQLite hoặc Android.',
  );
}
