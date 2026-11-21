import 'dart:convert';

import 'package:flutter/material.dart';

import '../nghiep_vu/ung_dung.dart';
import 'bieu_mau.dart';
import 'thanh_phan.dart';
import 'chuc_nang.dart';
import 'man_xac_thuc.dart';
import 'kham_pha.dart';
import 'tai_khoan.dart';

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
    final noiDung = tab == 1
        ? cn.tin()
        : tab == 2
        ? cn.goi()
        : tab == 3
        ? taiKhoan(cn)
        : trangDau(cn);
    return Scaffold(
      body: SafeArea(child: noiDung),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline),
            selectedIcon: Icon(Icons.work),
            label: 'Việc làm',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            label: 'Gói đăng tin',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }

  Widget trangDau(ChucNang cn) => ListView(
    padding: const EdgeInsets.all(22),
    children: [
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xff6250d8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.work_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Text(
            'Nối Việc',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 30,
              letterSpacing: -1,
            ),
          ),
          const Spacer(),
          if (u.nguoi != null)
            IconButton(
              onPressed: () => mo(cn.thongBao()),
              icon: const Icon(Icons.notifications_outlined),
            ),
        ],
      ),
      const SizedBox(height: 24),
      KhamPha(ung: u, chonViec: () => setState(() => tab = 1)),
      if (loi != null) Text(loi!),
      if (u.quanTri || u.nhaTuyen) ...[
        const SizedBox(height: 24),
        Text(
          u.quanTri ? 'Quản trị hệ thống' : 'Không gian tuyển dụng',
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
        ),
      ],
      if (u.quanTri) ...[
        NhomTacVuQuanTri(
          tieuDe: 'Tài khoản và danh mục',
          moTa: 'Quản lý quyền truy cập và nội dung nền tảng.',
          tacVu: [
            TacVuQuanTri(
              'Thành viên & phân quyền',
              Icons.manage_accounts,
              () => mo(cn.thanhVien()),
            ),
            TacVuQuanTri(
              'Duyệt doanh nghiệp',
              Icons.business,
              () => mo(cn.doanhNghiep()),
            ),
            TacVuQuanTri(
              'Danh mục dịch vụ',
              Icons.category_outlined,
              () => mo(cn.danhMuc('DichVu')),
            ),
            TacVuQuanTri(
              'Ngành nghề',
              Icons.account_tree_outlined,
              () => mo(cn.danhMuc('NganhNghe')),
            ),
          ],
        ),
        NhomTacVuQuanTri(
          tieuDe: 'Gói, tin tuyển dụng và báo cáo',
          moTa: 'Theo dõi hoạt động thương mại và tuyển dụng.',
          tacVu: [
            TacVuQuanTri(
              'Quản lý gói đăng tin',
              Icons.inventory_2_outlined,
              () => mo(cn.goi(quanLy: true)),
            ),
            TacVuQuanTri(
              'Duyệt tin tuyển dụng',
              Icons.fact_check_outlined,
              () => mo(cn.tin(quanLy: true)),
            ),
            TacVuQuanTri(
              'Đơn mua lượt',
              Icons.receipt_long,
              () => mo(cn.don()),
            ),
            TacVuQuanTri('Thống kê', Icons.insights, () => mo(cn.thongKe())),
          ],
        ),
      ] else if (u.nhaTuyen) ...[
        muc(
          'Doanh nghiệp của tôi',
          Icons.business_outlined,
          () => thucHien(context, cn.congTyToi),
        ),
        muc(
          'Tin tuyển dụng',
          Icons.article_outlined,
          () => mo(cn.tin(quanLy: true)),
        ),
        muc('Hồ sơ ứng tuyển', Icons.people_outline, () => mo(cn.hoSo())),
        muc(
          'Giỏ hàng',
          Icons.shopping_bag_outlined,
          () => mo(cn.gio()),
          phu: '${u.soGoi} gói trong giỏ',
        ),
        muc('Đơn hàng', Icons.receipt_long, () => mo(cn.don())),
        muc(
          'Sổ lượt đăng tin',
          Icons.history,
          () => thucHien(context, cn.soLuot),
        ),
        muc(
          'Thành viên doanh nghiệp',
          Icons.groups_outlined,
          () => mo(cn.thanhVienCongTy()),
        ),
        muc('Thống kê', Icons.insights, () => mo(cn.thongKe())),
      ] else ...[
        if (u.ungVien) ...[
          muc(
            'Việc đã lưu',
            Icons.bookmark_border,
            () => mo(cn.tin(daLuu: true)),
          ),
          muc('Hồ sơ đã nộp', Icons.send_outlined, () => mo(cn.hoSo())),
          muc('CV của tôi', Icons.description_outlined, () => mo(cn.cv())),
          muc('Thống kê ứng tuyển', Icons.insights, () => mo(cn.thongKe())),
        ],
        muc(
          'Khám phá doanh nghiệp',
          Icons.business_outlined,
          () => mo(cn.doanhNghiep()),
        ),
      ],
      const SizedBox(height: 24),
      const Text(
        'Dịch vụ tuyển dụng',
        style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 12),
      DanhMucTrangChu(
        ung: u,
        chon: (id) => mo(cn.goi(danhMucId: id)),
      ),
      muc(
        'Danh mục gói đăng tin',
        Icons.category_outlined,
        () => mo(
          ManDanhSach(
            ung: u,
            tieuDe: 'Danh mục dịch vụ',
            duongDan: 'danh-muc',
            ve: (d, _) => TheNoiDung(
              tieuDe: d['ten'],
              phu: d['moTa'],
              mo: () => mo(cn.goi(danhMucId: d['id'])),
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        'Gói mới nhất',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      GoiTrangChu(ung: u),
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
            if (await xacNhan(
              context,
              'Đăng xuất và xóa dữ liệu riêng đã lưu trên máy?',
            )) {
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
