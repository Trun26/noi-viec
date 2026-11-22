import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'kho_luu.dart';

class KhoPhienAnToan implements KhoPhien {
  final _kho = const FlutterSecureStorage();
  @override
  Future<String?> read({required String key}) => _kho.read(key: key);
  @override
  Future<void> write({required String key, required String value}) =>
      _kho.write(key: key, value: value);
  @override
  Future<void> delete({required String key}) => _kho.delete(key: key);
}
