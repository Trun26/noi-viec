import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'kho_luu.dart';

class KhoCucBo implements KhoLuu {
  Database? _db;
  Future<Database> get db async => _db ??= await openDatabase(
    join(await getDatabasesPath(), 'mobi.db'),
    version: 1,
    onCreate: (d, _) async {
      await d.execute(
        'CREATE TABLE bo_nho (tai_khoan TEXT NOT NULL, khoa TEXT NOT NULL, noi_dung TEXT NOT NULL, cap_nhat TEXT NOT NULL, PRIMARY KEY(tai_khoan, khoa))',
      );
    },
  );
  @override
  Future<void> luu(String taiKhoan, String khoa, dynamic duLieu) async {
    await (await db).insert('bo_nho', {
      'tai_khoan': taiKhoan,
      'khoa': khoa,
      'noi_dung': jsonEncode(duLieu),
      'cap_nhat': DateTime.now().toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<Map<String, dynamic>?> doc(String taiKhoan, String khoa) async {
    final ds = await (await db).query(
      'bo_nho',
      where: 'tai_khoan = ? AND khoa = ?',
      whereArgs: [taiKhoan, khoa],
    );
    if (ds.isEmpty) return null;
    return {
      'duLieu': jsonDecode(ds.first['noi_dung'] as String),
      'capNhat': ds.first['cap_nhat'],
    };
  }

  @override
  Future<void> xoaTaiKhoan(String id) async =>
      (await db).delete('bo_nho', where: 'tai_khoan = ?', whereArgs: [id]);
}
