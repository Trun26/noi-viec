abstract interface class KhoLuu {
  Future<void> luu(String taiKhoan, String khoa, dynamic duLieu);
  Future<Map<String, dynamic>?> doc(String taiKhoan, String khoa);
  Future<void> xoaTaiKhoan(String id);
}

abstract interface class KhoPhien {
  Future<String?> read({required String key});
  Future<void> write({required String key, required String value});
  Future<void> delete({required String key});
}
