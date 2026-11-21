import 'package:flutter/material.dart';
import '../nghiep_vu/ung_dung.dart';

class ManXacThuc extends StatefulWidget {
  final UngDung ung;
  final bool dangKy, laCongVao;
  final VoidCallback? xemKhach;
  const ManXacThuc({
    super.key,
    required this.ung,
    this.dangKy = false,
    this.laCongVao = false,
    this.xemKhach,
  });
  @override
  State<ManXacThuc> createState() => _ManXacThucState();
}

class _ManXacThucState extends State<ManXacThuc> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(),
      matKhau = TextEditingController(),
      ten = TextEditingController();
  late bool tao = widget.dangKy;
  bool an = true, gui = false;
  String loai = 'UngVien';
  String? loi;
  @override
  void dispose() {
    email.dispose();
    matKhau.dispose();
    ten.dispose();
    super.dispose();
  }

  Future<void> nop() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      gui = true;
      loi = null;
    });
    try {
      if (tao) {
        await widget.ung.xuLy('tai-khoan/dang-ky', {
          'hoTen': ten.text.trim(),
          'email': email.text.trim(),
          'matKhau': matKhau.text,
          'loai': loai,
        });
        if (mounted) setState(() => tao = false);
      }
      await widget.ung.dangNhap(email.text.trim(), matKhau.text);
      if (mounted && !widget.laCongVao) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => loi = e.toString());
    } finally {
      if (mounted) setState(() => gui = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(automaticallyImplyLeading: !widget.laCongVao),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 32),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xffeae5ff),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.work_rounded,
                  size: 34,
                  color: Color(0xff6250d8),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nối Việc',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xff6250d8),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              tao ? 'Bắt đầu hành trình mới' : 'Chào mừng trở lại!',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              tao
                  ? 'Tạo tài khoản để kết nối với cơ hội phù hợp.'
                  : 'Đăng nhập để tiếp tục hành trình nghề nghiệp của bạn.',
              style: const TextStyle(color: Color(0xff77758a), height: 1.6),
            ),
            const SizedBox(height: 30),
            Form(
              key: form,
              child: AutofillGroup(
                child: Column(
                  children: [
                    if (tao) ...[
                      TextFormField(
                        controller: ten,
                        decoration: const InputDecoration(
                          labelText: 'Họ và tên',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) =>
                            v!.trim().isEmpty ? 'Nhập họ và tên' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: loai,
                        decoration: const InputDecoration(
                          labelText: 'Bạn muốn',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'UngVien',
                            child: Text('Tìm việc làm'),
                          ),
                          DropdownMenuItem(
                            value: 'NhaTuyenDung',
                            child: Text('Tuyển dụng nhân sự'),
                          ),
                        ],
                        onChanged: gui
                            ? null
                            : (v) => setState(() => loai = v!),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: (v) =>
                          !RegExp(
                            r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                          ).hasMatch(v!.trim())
                          ? 'Nhập địa chỉ email hợp lệ'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: matKhau,
                      obscureText: an,
                      autofillHints: [
                        tao
                            ? AutofillHints.newPassword
                            : AutofillHints.password,
                      ],
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: an ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                          onPressed: () => setState(() => an = !an),
                          icon: Icon(
                            an
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (v) => v!.isEmpty
                          ? 'Nhập mật khẩu'
                          : tao && (v.length < 8 || v.length > 128)
                          ? 'Mật khẩu cần từ 8 đến 128 ký tự'
                          : null,
                      onFieldSubmitted: (_) {
                        if (!gui) nop();
                      },
                    ),
                  ],
                ),
              ),
            ),
            if (loi != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  loi!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: gui ? null : nop,
                child: gui
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        tao ? 'Tạo tài khoản' : 'Đăng nhập',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                tao ? 'Bạn đã có tài khoản?' : 'Bạn chưa có tài khoản?',
                style: const TextStyle(color: Color(0xff77758a)),
              ),
            ),
            TextButton(
              onPressed: gui
                  ? null
                  : () => setState(() {
                      tao = !tao;
                      loi = null;
                    }),
              child: Text(tao ? 'Đăng nhập' : 'Đăng ký ngay'),
            ),
            if (widget.xemKhach != null)
              TextButton.icon(
                onPressed: gui ? null : widget.xemKhach,
                icon: const Icon(Icons.travel_explore, size: 18),
                label: const Text('Khám phá việc làm trước'),
              ),
          ],
        ),
      ),
    ),
  );
}
