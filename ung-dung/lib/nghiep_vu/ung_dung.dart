import 'package:flutter/foundation.dart';
import 'trang_thai.dart';

class UngDung extends TrangThaiUngDung implements Listenable {
  final _thayDoi = _ThongBaoTrangThai();
  UngDung(super.api) {
    khiThayDoi = _thayDoi.phat;
  }
  @override
  void addListener(VoidCallback listener) => _thayDoi.addListener(listener);
  @override
  void removeListener(VoidCallback listener) =>
      _thayDoi.removeListener(listener);
  void dispose() {
    khiThayDoi = null;
    _thayDoi.dispose();
  }
}

class _ThongBaoTrangThai extends ChangeNotifier {
  void phat() => notifyListeners();
}
