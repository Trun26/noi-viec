import 'package:flutter/material.dart';
import 'du_lieu/kho_cuc_bo.dart';
import 'du_lieu/may_chu.dart';
import 'du_lieu/kho_phien_an_toan.dart';
import 'nghiep_vu/ung_dung.dart';
import 'giao_dien/trang_chu.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(Mobi(ung: UngDung(MayChu(KhoCucBo(), KhoPhienAnToan()))));
}

class Mobi extends StatelessWidget {
  final UngDung ung;
  const Mobi({super.key, required this.ung});
  @override
  Widget build(BuildContext c) => MaterialApp(
    title: 'Nối Việc • Cơ hội mới mỗi ngày',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: Color(0xffeae5ff),
      ),
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff6250d8)),
      scaffoldBackgroundColor: const Color(0xfff8f7fc),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xfff8f7fc),
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xffece9f5)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xffcbd5e1)),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ),
    home: TrangChu(ung: ung),
  );
}
