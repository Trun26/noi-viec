import 'package:flutter/material.dart';

class TheTaiKhoan extends StatelessWidget {
  final String? ten, email, vaiTro;
  final VoidCallback dangNhap, dangKy;
  const TheTaiKhoan({
    super.key,
    this.ten,
    this.email,
    this.vaiTro,
    required this.dangNhap,
    required this.dangKy,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xffede8f7)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: const Color(0xffeee8ff),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 34,
                color: Color(0xff6250d8),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ten ?? 'Xin chào bạn!',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    ten == null ? 'Cơ hội mới đang chờ bạn' : (vaiTro ?? ''),
                    style: const TextStyle(
                      color: Color(0xff837a94),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          ten == null
              ? 'Lưu công việc yêu thích, quản lý CV và theo dõi hành trình ứng tuyển tại một nơi.'
              : (email ?? ''),
          style: const TextStyle(height: 1.6, color: Color(0xff716a80)),
        ),
        if (ten == null) ...[
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: dangNhap,
              child: const Text(
                'Đăng nhập',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: dangKy,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xffddd4f5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Tạo tài khoản mới'),
            ),
          ),
        ],
      ],
    ),
  );
}

class NhomTaiKhoan extends StatelessWidget {
  final List<Widget> children;
  const NhomTaiKhoan({super.key, required this.children});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xffede8f7)),
    ),
    child: Column(
      children: [
        for (int i = 0; i < children.length; i++) ...[
          if (i > 0)
            const Divider(
              height: 1,
              indent: 64,
              endIndent: 18,
              color: Color(0xfff0ecf6),
            ),
          children[i],
        ],
      ],
    ),
  );
}

class MucTaiKhoan extends StatelessWidget {
  final String ten, phu;
  final IconData icon;
  final VoidCallback bam;
  const MucTaiKhoan({
    super.key,
    required this.ten,
    required this.phu,
    required this.icon,
    required this.bam,
  });
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
    leading: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xfff4f0ff),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 22, color: const Color(0xff6250d8)),
    ),
    title: Text(
      ten,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
    ),
    subtitle: Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        phu,
        style: const TextStyle(fontSize: 12, color: Color(0xff8b829d)),
      ),
    ),
    trailing: const Icon(
      Icons.chevron_right,
      size: 20,
      color: Color(0xffa69cb5),
    ),
    onTap: bam,
  );
}
