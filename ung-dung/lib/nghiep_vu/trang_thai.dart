import 'dart:convert';
import 'dart:math';

import '../du_lieu/may_chu.dart';
import '../du_lieu/kho_luu.dart';

class TrangThaiUngDung {
  final MayChu api;
  TrangThaiUngDung(this.api);
  void Function()? khiThayDoi;
  void notifyListeners() => khiThayDoi?.call();
  Map<String, dynamic>? nguoi;
  int soGoi = 0;
  bool dangGui = false;
  String? khoaDon;
  bool get quanTri => nguoi?['vaiTro'] == 'QuanTri';
  bool get nhaTuyen => nguoi?['loai'] == 'NhaTuyenDung';
  bool get ungVien => nguoi?['loai'] == 'UngVien';
  KhoLuu get kho => api.kho;
  Future<void> khoiTao() async {
    await api.khoiTao();
    if (api.maTruyCap != null) {
      try {
        nguoi = Map<String, dynamic>.from(await api.doc('tai-khoan/toi'));
      } on LoiApi catch (e) {
        if (e.ma == 401 || e.ma == 403) await api.xoaPhien();
      }
      if (nhaTuyen) {
        try {
          await capNhatGio();
        } catch (_) {}
      }
    }
    notifyListeners();
  }

  Future<dynamic> danhSach(String dd) => api.doc(dd);
  Future<dynamic> xuLy(
    String dd,
    Map<String, dynamic> d, {
    String cach = 'POST',
  }) async {
    if (dangGui) throw LoiApi('Đang xử lý yêu cầu trước.');
    dangGui = true;
    notifyListeners();
    try {
      return await api.gui(dd, d, cach: cach);
    } finally {
      dangGui = false;
      notifyListeners();
    }
  }

  Future<void> dangNhap(String email, String matKhau) async {
    final kq = await xuLy('tai-khoan/dang-nhap', {
      'email': email,
      'matKhau': matKhau,
    });
    final taiKhoan = Map<String, dynamic>.from(kq['taiKhoan']);
    await api.luuPhien(kq['maTruyCap'], taiKhoan['id']);
    nguoi = taiKhoan;
    if (nhaTuyen) {
      try {
        await capNhatGio();
      } catch (_) {
        soGoi = 0;
      }
    }
    notifyListeners();
  }

  Future<void> dangXuat() async {
    try {
      await api.gui('tai-khoan/dang-xuat', {});
    } finally {
      await ketThucPhien();
    }
  }

  Future<void> ketThucPhien() async {
    try {
      await api.xoaPhien();
    } finally {
      nguoi = null;
      soGoi = 0;
      khoaDon = null;
      notifyListeners();
    }
  }

  Future<void> capNhatGio() async {
    final ds = await api.doc('gio-hang');
    soGoi = (ds as List).fold<int>(0, (s, d) => s + (d['soLuong'] as int));
    notifyListeners();
  }

  Future<void> themGio(Map<String, dynamic> goi) async {
    final ds = await api.doc('gio-hang', luu: false) as List;
    final cu = ds.where((x) => x['goiLuotId'] == goi['id']).firstOrNull;
    await xuLy('gio-hang', {
      'goiLuotId': goi['id'],
      'soLuong': (cu?['soLuong'] ?? 0) + 1,
      'giaDaXem': goi['gia'],
    }, cach: 'PUT');
    await capNhatGio();
  }

  Future<dynamic> datDon() async {
    final cu = await kho.doc(api.taiKhoanId, 'khoa-dat-don');
    khoaDon ??= cu?['duLieu'] as String? ?? _uuid();
    await kho.luu(api.taiKhoanId, 'khoa-dat-don', khoaDon);
    final kq = await xuLy('don-hang', {'khoaLap': khoaDon});
    khoaDon = null;
    await kho.luu(api.taiKhoanId, 'khoa-dat-don', null);
    await capNhatGio();
    return kq;
  }

  String _uuid() {
    final r = Random.secure();
    final b = List.generate(16, (_) => r.nextInt(256));
    b[6] = (b[6] & 15) | 64;
    b[8] = (b[8] & 63) | 128;
    final s = b.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
    return '${s.substring(0, 8)}-${s.substring(8, 12)}-${s.substring(12, 16)}-${s.substring(16, 20)}-${s.substring(20)}';
  }

  Future<void> suaCaNhan(Map<String, dynamic> d) async {
    nguoi = Map<String, dynamic>.from(
      await xuLy('tai-khoan/toi', d, cach: 'PUT'),
    );
    notifyListeners();
  }

  Future<String> taiTep(String ten, List<int> bytes, String loai) async {
    final kq = await api.taiTep(ten, bytes, loai);
    return kq['id'];
  }

  Future<void> luuNhap(String khoa, Map<String, dynamic> d) =>
      kho.luu(api.taiKhoanId, 'nhap/$khoa', d);
  Future<Map<String, dynamic>?> docNhap(String khoa) async {
    final kq = await kho.doc(api.taiKhoanId, 'nhap/$khoa');
    return kq == null ? null : Map<String, dynamic>.from(kq['duLieu']);
  }

  String hoSoHienTai() => nguoi?['hoSoJson'] ?? jsonEncode({});
}
