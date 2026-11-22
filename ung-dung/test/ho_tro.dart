import 'package:ung_dung/du_lieu/kho_luu.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

http.Response phanHoi(String noiDung, int ma) => http.Response.bytes(
  utf8.encode(noiDung),
  ma,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

class KhoThu implements KhoLuu {
  final duLieu = <String, dynamic>{};
  @override
  Future<void> luu(String tk, String khoa, dynamic d) async {
    duLieu['$tk/$khoa'] = d;
  }

  @override
  Future<Map<String, dynamic>?> doc(String tk, String khoa) async {
    final key = '$tk/$khoa';
    return duLieu.containsKey(key)
        ? {'duLieu': duLieu[key], 'capNhat': '2026-11-21T00:00:00Z'}
        : null;
  }

  @override
  Future<void> xoaTaiKhoan(String id) async {
    duLieu.removeWhere((k, _) => k.startsWith('$id/'));
  }
}

class KhoPhienThu implements KhoPhien {
  final duLieu = <String, String>{};
  @override
  Future<String?> read({required String key}) async => duLieu[key];
  @override
  Future<void> write({required String key, required String value}) async {
    duLieu[key] = value;
  }

  @override
  Future<void> delete({required String key}) async {
    duLieu.remove(key);
  }
}
