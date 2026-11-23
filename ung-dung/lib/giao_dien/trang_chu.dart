import 'dart:convert';

import 'package:flutter/material.dart';

import '../nghiep_vu/ung_dung.dart';
import 'bieu_mau.dart';
import 'thanh_phan.dart';
import 'chuc_nang.dart';
import 'man_xac_thuc.dart';
import 'kham_pha.dart';
import 'tai_khoan.dart';
import 'quan_tri.dart';
import 'khong_gian_doanh_nghiep.dart';
import 'doanh_nghiep_quan_tri.dart';
import 'tin_quan_tri.dart';

class TrangChu extends StatefulWidget {
  final UngDung ung;
  const TrangChu({super.key, required this.ung});
  @override
  State<TrangChu> createState() => _TrangChuState();
}

class _TrangChuState extends State<TrangChu> {
  bool khoiTao = true;
  int tab = 0;
  bool xemKhach = false;
  bool daDangNhap = false;
  String? loi;
  UngDung get u => widget.ung;
  @override
  void initState() {
    super.initState();
    u.addListener(capNhat);
    batDau();
  }

  void capNhat() {
    if (mounted) {
      setState(() {
        if (daDangNhap && u.nguoi == null) {
          xemKhach = false;
          tab = 0;
        }
        daDangNhap = u.nguoi != null;
      });
    }
  }

  @override
  void dispose() {
    u.removeListener(capNhat);
    super.dispose();
  }

  Future<void> batDau() async {
    try {
      await u.khoiTao();
    } catch (e) {
      loi = e.toString();
    }
    if (mounted) setState(() => khoiTao = false);
  }

  void mo(Widget w) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => w));
  Future<void> dangNhap() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ManXacThuc(ung: u)),
    );
    if (mounted && u.nguoi != null) setState(() => tab = 0);
  }

  Future<void> dangKy() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ManXacThuc(ung: u, dangKy: true)),
    );
    if (mounted && u.nguoi != null) setState(() => tab = 0);
  }

  Widget muc(String ten, IconData icon, VoidCallback bam, {String? phu}) =>
      Card(
        child: ListTile(
          leading: Icon(icon, color: const Color(0xff6250d8)),
          title: Text(ten),
          subtitle: phu == null ? null : Text(phu),
          trailing: const Icon(Icons.chevron_right),
          onTap: bam,
        ),
      );
  @override
  Widget build(BuildContext c) {
    if (khoiTao) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (u.nguoi == null && !xemKhach) {
      return ManXacThuc(
        ung: u,
        laCongVao: true,
        xemKhach: () => setState(() => xemKhach = true),
      );
    }
    final cn = ChucNang(c, u);
    if (u.quanTri) {
      final noiDungQuanTri = switch (tab) {
        1 => NguoiDungQuanTri(ung: u),
        2 => DoanhNghiepQuanTri(ung: u),
        3 => TinQuanTri(ung: u),
        4 => DanhMucQuanTri(ung: u),
        5 => DonMuaQuanTri(ung: u),
        6 => taiKhoan(cn),
        _ => TongQuanQuanTri(ung: u, thongBao: () => mo(cn.thongBao())),
      };
      const nhan = [
        'Trang ch\u1ee7',
        'Ng\u01b0\u1eddi d\u00f9ng',
        'Doanh nghi\u1ec7p',
        'Tin',
        'Danh m\u1ee5c',
        '\u0110\u01a1n mua',
        'T\u00e0i kho\u1ea3n',
      ];
      const bieuTuong = [
        Icons.grid_view_rounded,
        Icons.people_outline,
        Icons.business_outlined,
        Icons.article_outlined,
        Icons.category_outlined,
        Icons.receipt_long,
        Icons.person_outline,
      ];
      return Scaffold(
        body: SafeArea(
          child: KeyedSubtree(
            key: ValueKey('quan-tri-$tab'),
            child: noiDungQuanTri,
          ),
        ),
        bottomNavigationBar: Material(
          color: Colors.white,
          elevation: 8,
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                for (var i = 0; i < nhan.length; i++)
                  Expanded(
                    flex: tab == i ? 2 : 1,
                    child: Tooltip(
                      message: nhan[i],
                      child: InkWell(
                        onTap: () => setState(() => tab = i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                bieuTuong[i],
                                color: tab == i
                                    ? const Color(0xff6250d8)
                                    : Colors.blueGrey,
                              ),
                              const SizedBox(height: 5),
                              if (tab == i)
                                Text(
                                  nhan[i],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xff6250d8),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    final laNhaTuyenDung = u.nhaTuyen;
    final laUngVien = u.ungVien;
    late final Widget noiDung;
    late final List<String> nhanTab;
    late final List<IconData> bieuTuongTab;
    if (laNhaTuyenDung) {
      return KhongGianDoanhNghiep(ung: u, taiKhoan: () => taiKhoan(cn));
    } else if (laUngVien) {
      nhanTab = [
        'Kh\u00e1m ph\u00e1',
        'Vi\u1ec7c l\u00e0m',
        'Đã lưu (${u.soDaLuu})',
        'Ứng tuyển (${u.soUngTuyen})',
        'T\u00e0i kho\u1ea3n',
      ];
      bieuTuongTab = const [
        Icons.explore_outlined,
        Icons.search,
        Icons.bookmark_outline,
        Icons.assignment_outlined,
        Icons.person_outline,
      ];
      noiDung = switch (tab) {
        1 => cn.tin(),
        2 => cn.tin(daLuu: true),
        3 => cn.hoSo(),
        4 => taiKhoan(cn),
        _ => trangDau(cn),
      };
    } else {
      nhanTab = const [
        'Kh\u00e1m ph\u00e1',
        'Vi\u1ec7c l\u00e0m',
        'T\u00e0i kho\u1ea3n',
      ];
      bieuTuongTab = const [
        Icons.explore_outlined,
        Icons.search,
        Icons.person_outline,
      ];
      noiDung = switch (tab) {
        1 => cn.tin(),
        2 => taiKhoan(cn),
        _ => trangDau(cn),
      };
    }
    return Scaffold(
      body: SafeArea(
        child: KeyedSubtree(
          key: ValueKey('nguoi-dung-$tab-${u.nguoi?['loai']}'),
          child: noiDung,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab.clamp(0, nhanTab.length - 1) as int,
        onDestinationSelected: (i) {
          setState(() => tab = i);
          if (u.ungVien) u.thuCapNhatTimViec();
        },
        destinations: [
          for (var i = 0; i < nhanTab.length; i++)
            NavigationDestination(
              icon: Icon(bieuTuongTab[i]),
              selectedIcon: Icon(bieuTuongTab[i]),
              label: nhanTab[i],
            ),
        ],
      ),
    );
  }

  Widget tongQuanTuyenDung(ChucNang cn) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
    children: [
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xff6250d8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.work_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'N\u1ed1i Vi\u1ec7c',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
          ),
          IconButton(
            tooltip: 'Th\u00f4ng b\u00e1o',
            onPressed: () => mo(cn.thongBao()),
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      const SizedBox(height: 28),
      Text(
        'Xin ch\u00e0o, ${u.nguoi?['hoTen'] ?? 'Nh\u00e0 tuy\u1ec3n d\u1ee5ng'}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 6),
      const Text(
        'T\u1ea1o tin tuy\u1ec3n, theo d\u00f5i h\u1ed3 s\u01a1 v\u00e0 k\u1ebft n\u1ed1i v\u1edbi \u1ee9ng vi\u00ean ph\u00f9 h\u1ee3p.',
        style: TextStyle(color: Color(0xff716a80), height: 1.5),
      ),
      const SizedBox(height: 22),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xff5141c4), Color(0xff806de2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.rocket_launch_outlined,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(height: 14),
            const Text(
              'T\u00ecm \u0111\u00fang ng\u01b0\u1eddi cho v\u1ecb tr\u00ed c\u1ee7a b\u1ea1n',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'T\u1ea1o tin tuy\u1ec3n d\u1ee5ng r\u00f5 r\u00e0ng \u0111\u1ec3 ti\u1ebfp c\u1eadn \u1ee9ng vi\u00ean ph\u00f9 h\u1ee3p.',
              style: TextStyle(color: Colors.white70, height: 1.45),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => thucHien(context, () => cn.suaTin()),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xff5141c4),
              ),
              icon: const Icon(Icons.add),
              label: const Text('\u0110\u0103ng tin tuy\u1ec3n d\u1ee5ng'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 26),
      const Text(
        'Trung t\u00e2m tuy\u1ec3n d\u1ee5ng',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 10),
      muc(
        'Tin tuy\u1ec3n d\u1ee5ng',
        Icons.work_outline,
        () => mo(cn.tin(quanLy: true)),
        phu: 'T\u1ea1o tin m\u1edbi, theo d\u00f5i duy\u1ec7t v\u00e0 c\u1eadp nh\u1eadt tin \u0111ang tuy\u1ec3n.',
      ),
      muc(
        'H\u1ed3 s\u01a1 \u1ee9ng tuy\u1ec3n',
        Icons.people_alt_outlined,
        () => mo(cn.hoSo()),
        phu: 'Xem h\u1ed3 s\u01a1, c\u1eadp nh\u1eadt tr\u1ea1ng th\u00e1i v\u00e0 m\u1eddi ph\u1ecfng v\u1ea5n.',
      ),
      muc(
        'H\u1ed3 s\u01a1 doanh nghi\u1ec7p',
        Icons.business_outlined,
        () => thucHien(context, cn.congTyToi),
        phu: 'C\u1eadp nh\u1eadt th\u00f4ng tin v\u00e0 h\u00ecnh \u1ea3nh doanh nghi\u1ec7p.',
      ),
      muc(
        'G\u00f3i v\u00e0 l\u01b0\u1ee3t \u0111\u0103ng tin',
        Icons.inventory_2_outlined,
        () => mo(cn.goi()),
        phu: '${u.soGoi} g\u00f3i trong gi\u1ecf h\u00e0ng',
      ),
      const SizedBox(height: 20),
      const Text(
        'Qu\u1ea3n l\u00fd doanh nghi\u1ec7p',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 10),
      muc('Giỏ hàng', Icons.shopping_cart_outlined, () => mo(cn.gio())),
      muc('Thành viên', Icons.groups_outlined, () => mo(cn.thanhVienCongTy())),
      muc(
        '\u0110\u01a1n mua v\u00e0 thanh to\u00e1n',
        Icons.receipt_long,
        () => mo(cn.don()),
      ),
      muc(
        'L\u1ecbch s\u1eed l\u01b0\u1ee3t \u0111\u0103ng',
        Icons.history,
        () => thucHien(context, cn.soLuot),
      ),
    ],
  );

  Widget trangDau(ChucNang cn) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
    children: [
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xff6250d8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.work_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'N\u1ed1i Vi\u1ec7c',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26),
            ),
          ),
          if (u.nguoi != null)
            IconButton(
              tooltip: 'Th\u00f4ng b\u00e1o',
              onPressed: () => mo(cn.thongBao()),
              icon: const Icon(Icons.notifications_outlined),
            ),
        ],
      ),
      if (u.ungVien) ...[
        const SizedBox(height: 24),
        Text(
          'Xin ch\u00e0o, ${u.nguoi?['hoTen'] ?? '\u1ee9ng vi\u00ean'}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const Text(
          'C\u01a1 h\u1ed9i ti\u1ebfp theo c\u1ee7a b\u1ea1n b\u1eaft \u0111\u1ea7u t\u1eeb \u0111\u00e2y.',
          style: TextStyle(color: Color(0xff716a80)),
        ),
      ],
      const SizedBox(height: 18),
      KhamPha(ung: u, chonViec: () => setState(() => tab = 1)),
      if (u.ungVien) ...[
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xffece9f5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'H\u1ed3 s\u01a1 s\u1eb5n s\u00e0ng, c\u01a1 h\u1ed9i g\u1ea7n h\u01a1n',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 5),
              const Text(
                'C\u1eadp nh\u1eadt CV v\u00e0 theo d\u00f5i c\u00e1c l\u1ea7n \u1ee9ng tuy\u1ec3n ngay trong app.',
                style: TextStyle(color: Color(0xff716a80), height: 1.45),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => mo(cn.cv()),
                    icon: const Icon(Icons.description_outlined),
                    label: const Text('CV c\u1ee7a t\u00f4i'),
                  ),
                  FilledButton.icon(
                    onPressed: () => mo(cn.hoSo()),
                    icon: const Icon(Icons.assignment_outlined),
                    label: const Text('H\u1ed3 s\u01a1 \u0111\u00e3 n\u1ed9p'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        muc(
          'Vi\u1ec7c \u0111\u00e3 l\u01b0u',
          Icons.bookmark_outline,
          () => mo(cn.tin(daLuu: true)),
          phu: 'Nh\u1eefng v\u1ecb tr\u00ed b\u1ea1n mu\u1ed1n xem l\u1ea1i.',
        ),
        muc(
          'Kh\u00e1m ph\u00e1 doanh nghi\u1ec7p',
          Icons.business_outlined,
          () => mo(cn.doanhNghiep()),
          phu: 'T\u00ecm hi\u1ec3u n\u01a1i l\u00e0m vi\u1ec7c tr\u01b0\u1edbc khi \u1ee9ng tuy\u1ec3n.',
        ),
      ] else if (u.nguoi == null) ...[
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xfff0ecff),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'L\u01b0u vi\u1ec7c hay. \u1ee8ng tuy\u1ec3n d\u1ec5 d\u00e0ng.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'T\u1ea1o t\u00e0i kho\u1ea3n \u0111\u1ec3 qu\u1ea3n l\u00fd CV v\u00e0 theo d\u00f5i h\u1ed3 s\u01a1.',
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                children: [
                  FilledButton(
                    onPressed: dangKy,
                    child: const Text('\u0110\u0103ng k\u00fd'),
                  ),
                  TextButton(
                    onPressed: dangNhap,
                    child: const Text('\u0110\u0103ng nh\u1eadp'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
      if (loi != null) ...[
        const SizedBox(height: 12),
        Text(
          loi!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ],
    ],
  );

  Widget taiKhoan(ChucNang cn) => ListView(
    padding: const EdgeInsets.all(22),
    children: [
      const Text(
        'Tài khoản',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 24),
      TheTaiKhoan(
        ten: u.nguoi?['hoTen'],
        email: u.nguoi?['email'],
        vaiTro: u.quanTri ? 'Quản trị viên' : tenNhan(u.nguoi?['loai']),
        dangNhap: dangNhap,
        dangKy: dangKy,
      ),
      if (u.nguoi == null) ...[
        const SizedBox(height: 26),
        const Text(
          'Không gian của bạn',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        NhomTaiKhoan(
          children: [
            MucTaiKhoan(
              ten: 'CV của tôi',
              phu: 'Chuẩn bị hồ sơ cho cơ hội tiếp theo',
              icon: Icons.description_outlined,
              bam: dangNhap,
            ),
            MucTaiKhoan(
              ten: 'Việc đã lưu',
              phu: 'Giữ lại những công việc bạn quan tâm',
              icon: Icons.bookmark_outline,
              bam: dangNhap,
            ),
            MucTaiKhoan(
              ten: 'Theo dõi ứng tuyển',
              phu: 'Cập nhật tiến trình hồ sơ đã nộp',
              icon: Icons.assignment_outlined,
              bam: dangNhap,
            ),
          ],
        ),
        const SizedBox(height: 26),
        const Text(
          'Dành cho nhà tuyển dụng',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        NhomTaiKhoan(
          children: [
            MucTaiKhoan(
              ten: 'Kết nối nhân tài',
              phu: 'Tạo tài khoản và đăng tin tuyển dụng',
              icon: Icons.business_center_outlined,
              bam: dangKy,
            ),
          ],
        ),
      ] else ...[
        const SizedBox(height: 20),
        if (u.ungVien) ...[
          const Text(
            'Hành trình tìm việc',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          muc('CV của tôi', Icons.description_outlined, () => mo(cn.cv())),
          muc(
            'Việc đã lưu',
            Icons.bookmark_outline,
            () => mo(cn.tin(daLuu: true)),
          ),
          muc(
            'Theo dõi ứng tuyển',
            Icons.assignment_outlined,
            () => mo(cn.hoSo()),
          ),
          const SizedBox(height: 20),
        ],
        if (u.nhaTuyen) ...[
          muc(
            'Doanh nghiệp',
            Icons.business_outlined,
            () => mo(
              KhongGianDoanhNghiep(
                ung: u,
                taiKhoan: () => taiKhoan(cn),
                chiDoanhNghiep: true,
              ),
            ),
          ),
          if (u.nguoi?['doanhNghiepId'] != null)
            muc(
              'Nhân viên',
              Icons.groups_outlined,
              () => thucHien(context, cn.moNhanVienCongTy),
            ),
          const SizedBox(height: 16),
        ],
        const Text(
          'Thông tin & bảo mật',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        muc(
          'Chỉnh sửa hồ sơ cá nhân',
          Icons.edit_outlined,
          () => thucHien(context, () async {
            Map<String, dynamic> hs = {};
            try {
              hs = Map<String, dynamic>.from(jsonDecode(u.hoSoHienTai()));
            } catch (_) {}
            await moBieuMau(
              context,
              u,
              'Hồ sơ cá nhân',
              const [
                TruongNhap('hoTen', 'Họ và tên'),
                TruongNhap('lienHe', 'Số điện thoại', batBuoc: false),
                TruongNhap(
                  'gioiThieu',
                  'Giới thiệu',
                  nhieuDong: true,
                  batBuoc: false,
                ),
                TruongNhap(
                  'hocVan',
                  'Học vấn',
                  nhieuDong: true,
                  batBuoc: false,
                ),
                TruongNhap(
                  'kinhNghiem',
                  'Kinh nghiệm',
                  nhieuDong: true,
                  batBuoc: false,
                ),
                TruongNhap(
                  'kyNang',
                  'Kỹ năng',
                  nhieuDong: true,
                  batBuoc: false,
                ),
                TruongNhap('viTriMongMuon', 'Vị trí mong muốn', batBuoc: false),
              ],
              giaTri: {...hs, 'hoTen': u.nguoi!['hoTen']},
              khoaNhap: 'ho-so-ca-nhan',
              hoSoCaNhan: true,
              luu: (d) =>
                  u.suaCaNhan({'hoTen': d['hoTen'], 'hoSoJson': jsonEncode(d)}),
            );
          }),
        ),
        muc(
          'Đổi mật khẩu',
          Icons.lock_outline,
          () => thucHien(context, () async {
            await moBieuMau(
              context,
              u,
              'Đổi mật khẩu',
              const [
                TruongNhap('matKhauCu', 'Mật khẩu hiện tại', an: true),
                TruongNhap('matKhauMoi', 'Mật khẩu mới', an: true),
              ],
              luu: (d) async {
                await u.xuLy('tai-khoan/doi-mat-khau', d);
                await u.ketThucPhien();
              },
            );
          }),
        ),
        muc('Thông báo', Icons.notifications_none, () => mo(cn.thongBao())),
        muc(
          'Đăng xuất',
          Icons.logout,
          () => thucHien(context, () async {
            if (await xacNhan(context, 'Bạn xác nhận đăng xuất?')) {
              await u.dangXuat();
            }
          }),
        ),
      ],
      const SizedBox(height: 28),
      const Text(
        'Nối Việc • Cơ hội mới mỗi ngày',
        style: TextStyle(color: Colors.blueGrey),
      ),
    ],
  );
}

class DanhMucTrangChu extends StatefulWidget {
  final UngDung ung;
  final void Function(String) chon;
  const DanhMucTrangChu({super.key, required this.ung, required this.chon});
  @override
  State<DanhMucTrangChu> createState() => _DanhMucTrangChuState();
}

class _DanhMucTrangChuState extends State<DanhMucTrangChu> {
  late Future<dynamic> duLieu;
  @override
  void initState() {
    super.initState();
    duLieu = widget.ung.danhSach('danh-muc');
  }

  @override
  Widget build(BuildContext c) => FutureBuilder(
    future: duLieu,
    builder: (c, s) {
      if (s.hasError) {
        return TextButton.icon(
          onPressed: () =>
              setState(() => duLieu = widget.ung.danhSach('danh-muc')),
          icon: const Icon(Icons.refresh),
          label: const Text('Tải lại danh mục dịch vụ'),
        );
      }
      if (!s.hasData) return const LinearProgressIndicator();
      final ds = (s.data['duLieu'] as List)
          .where((d) => d['hoatDong'] != false)
          .toList();
      if (ds.isEmpty) return const Text('Chưa có danh mục dịch vụ.');
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final d in ds)
            ActionChip(
              label: Text(d['ten']),
              avatar: const Icon(Icons.category_outlined, size: 18),
              onPressed: () => widget.chon(d['id']),
            ),
        ],
      );
    },
  );
}

class DonMuaQuanTri extends StatefulWidget {
  final UngDung ung;
  const DonMuaQuanTri({super.key, required this.ung});
  @override
  State<DonMuaQuanTri> createState() => _DonMuaQuanTriState();
}

class _DonMuaQuanTriState extends State<DonMuaQuanTri> {
  Map<String, dynamic> so = {};
  String? loi;
  int lan = 0;
  @override
  void initState() {
    super.initState();
    widget.ung.addListener(capNhat);
    tai();
  }

  @override
  void dispose() {
    widget.ung.removeListener(capNhat);
    super.dispose();
  }

  void capNhat() {
    if (!widget.ung.dangGui) tai();
  }

  Future<void> tai() async {
    final ma = ++lan;
    try {
      final d = await widget.ung.danhSach('quan-tri/don-hang/so-luong');
      if (mounted && ma == lan)
        setState(() {
          so = Map<String, dynamic>.from(d);
          loi = null;
        });
    } catch (e) {
      if (mounted && ma == lan) setState(() => loi = e.toString());
    }
  }

  @override
  Widget build(BuildContext c) {
    final cn = ChucNang(c, widget.ung);
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Đơn mua',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                onPressed: tai,
                tooltip: 'Cập nhật số lượng',
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          if (loi != null) Text(loi!),
          TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Đã duyệt (${so['daDuyet'] ?? '…'})'),
              Tab(text: 'Chờ duyệt (${so['choDuyet'] ?? '…'})'),
              Tab(text: 'Từ chối (${so['tuChoi'] ?? '…'})'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                cn.don(boLoc: '?trangThai=DaThanhToan'),
                cn.don(boLoc: '?trangThai=ChoThanhToan'),
                cn.don(boLoc: '?trangThai=TuChoi'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
