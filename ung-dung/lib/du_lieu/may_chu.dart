import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'kho_luu.dart';

class LoiApi implements Exception {
  final String thongBao;
  final int ma;
  LoiApi(this.thongBao, [this.ma = 0]);
  @override
  String toString() => thongBao;
}

class MayChu {
  final KhoLuu kho;
  final http.Client client;
  MayChu(this.kho, this.baoMat, {http.Client? client})
    : client = client ?? http.Client();
  final KhoPhien baoMat;
  int _phienSo = 0;
  String diaChi = const String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:5080/api/v1',
  );
  String? maTruyCap;
  String taiKhoanId = 'khach';
  bool duLieuCu = false;
  String? capNhat;
  Map<String, String> get dau => {
    'Content-Type': 'application/json',
    if (maTruyCap != null) 'Authorization': 'Bearer $maTruyCap',
  };
  Future<void> khoiTao() async {
    final daLuu = await baoMat.read(key: 'phien_lam_viec');
    if (daLuu == null) return;
    try {
      final d = jsonDecode(daLuu) as Map<String, dynamic>;
      maTruyCap = d['maTruyCap'] as String;
      taiKhoanId = d['taiKhoanId'] as String;
    } catch (_) {
      maTruyCap = null;
      taiKhoanId = 'khach';
      await baoMat.delete(key: 'phien_lam_viec');
    }
  }

  void _kiemPhien(String id, String? ma, int so) {
    if (id != taiKhoanId || ma != maTruyCap || so != _phienSo) {
      throw LoiApi('Phiên làm việc đã thay đổi. Vui lòng tải lại.', 401);
    }
  }

  dynamic giaiMa(int ma, String nd) {
    if (ma >= 200 && ma < 300 && nd.trim().isEmpty) return null;
    dynamic kq;
    try {
      kq = jsonDecode(nd);
    } catch (_) {
      if (ma == 404) {
        throw LoiApi(
          'Không tìm thấy chức năng trên máy chủ (404). Hãy khởi động lại máy chủ bằng mã mới.',
          ma,
        );
      }
      if (ma >= 500) {
        throw LoiApi(
          'Máy chủ gặp lỗi ($ma). Kiểm tra cửa sổ chạy máy chủ.',
          ma,
        );
      }
      throw LoiApi('Máy chủ trả dữ liệu không hợp lệ (HTTP $ma).', ma);
    }
    if (ma >= 400) {
      throw LoiApi(
        (kq is Map ? kq['thongBao'] : null) ??
            (ma == 400
                ? 'Thông tin nhập chưa hợp lệ.'
                : 'Không xử lý được yêu cầu.'),
        ma,
      );
    }
    return kq;
  }

  Future<dynamic> doc(String duongDan, {bool luu = true}) async {
    final id = taiKhoanId;
    final ma = maTruyCap;
    final so = _phienSo;
    try {
      final r = await client
          .get(Uri.parse('$diaChi/$duongDan'), headers: dau)
          .timeout(const Duration(seconds: 15));
      final kq = giaiMa(r.statusCode, utf8.decode(r.bodyBytes));
      _kiemPhien(id, ma, so);
      duLieuCu = false;
      capNhat = DateTime.now().toIso8601String();
      if (luu) await kho.luu(id, duongDan, kq);
      _kiemPhien(id, ma, so);
      return kq;
    } on SocketException {
      return _duLieuDaLuu(duongDan, luu, id, ma, so);
    } on http.ClientException {
      return _duLieuDaLuu(duongDan, luu, id, ma, so);
    } on TimeoutException {
      return _duLieuDaLuu(duongDan, luu, id, ma, so);
    }
  }

  Future<dynamic> _duLieuDaLuu(
    String dd,
    bool choPhep,
    String id,
    String? ma,
    int so,
  ) async {
    _kiemPhien(id, ma, so);
    final cu = choPhep ? await kho.doc(id, dd) : null;
    _kiemPhien(id, ma, so);
    if (cu == null) {
      throw LoiApi(
        'Không kết nối được máy chủ. Kiểm tra mạng và địa chỉ kết nối.',
      );
    }
    duLieuCu = true;
    capNhat = cu['capNhat'];
    return cu['duLieu'];
  }

  Future<dynamic> gui(
    String dd,
    Map<String, dynamic> d, {
    String cach = 'POST',
  }) async {
    final id = taiKhoanId;
    final ma = maTruyCap;
    final so = _phienSo;
    try {
      final r = await client
          .send(
            http.Request(cach, Uri.parse('$diaChi/$dd'))
              ..headers.addAll(dau)
              ..body = jsonEncode(d),
          )
          .timeout(const Duration(seconds: 20));
      final noiDung = await r.stream.bytesToString().timeout(
        const Duration(seconds: 20),
      );
      _kiemPhien(id, ma, so);
      return giaiMa(r.statusCode, noiDung);
    } on SocketException {
      throw LoiApi('Thao tác cần kết nối mạng. Chưa xác nhận thành công.');
    } on http.ClientException {
      throw LoiApi(
        'Mất kết nối. Hãy tải lại để kiểm tra kết quả trước khi thử lại.',
      );
    } on TimeoutException {
      throw LoiApi('Chưa nhận được xác nhận. Hãy tải lại để kiểm tra kết quả.');
    }
  }

  Future<dynamic> taiTep(String ten, List<int> bytes, String loai) async {
    final id = taiKhoanId;
    final ma = maTruyCap;
    final so = _phienSo;
    final yeuCau = http.MultipartRequest('POST', Uri.parse('$diaChi/tep'));
    yeuCau.headers.addAll({
      if (maTruyCap != null) 'Authorization': 'Bearer $maTruyCap',
    });
    yeuCau.fields['loai'] = loai;
    yeuCau.files.add(http.MultipartFile.fromBytes('tep', bytes, filename: ten));
    final r = await client.send(yeuCau).timeout(const Duration(seconds: 60));
    final noiDung = await r.stream.bytesToString().timeout(
      const Duration(seconds: 60),
    );
    _kiemPhien(id, ma, so);
    return giaiMa(r.statusCode, noiDung);
  }

  Future<List<int>> taiXuong(String id) async {
    final taiKhoan = taiKhoanId;
    final ma = maTruyCap;
    final so = _phienSo;
    final r = await client
        .get(Uri.parse('$diaChi/tep/$id'), headers: dau)
        .timeout(const Duration(seconds: 30));
    _kiemPhien(taiKhoan, ma, so);
    if (r.statusCode != 200) giaiMa(r.statusCode, utf8.decode(r.bodyBytes));
    return r.bodyBytes;
  }

  Future<void> luuPhien(String ma, String id) async {
    await baoMat.write(
      key: 'phien_lam_viec',
      value: jsonEncode({'maTruyCap': ma, 'taiKhoanId': id}),
    );
    _phienSo++;
    maTruyCap = ma;
    taiKhoanId = id;
  }

  Future<void> xoaPhien() async {
    final idCu = taiKhoanId;
    _phienSo++;
    maTruyCap = null;
    taiKhoanId = 'khach';
    await baoMat.delete(key: 'phien_lam_viec');
    await kho.xoaTaiKhoan(idCu);
  }
}
