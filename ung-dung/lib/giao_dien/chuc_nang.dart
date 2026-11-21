import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../nghiep_vu/ung_dung.dart';
import 'bieu_mau.dart';
import 'thanh_phan.dart';
import 'chi_tiet_viec.dart';

class ChucNang {
  final BuildContext c;
  final UngDung u;
  ChucNang(this.c, this.u);
  void mo(Widget w) => Navigator.push(c, MaterialPageRoute(builder: (_) => w));
  Widget nut(String ten, Future<void> Function() f) => TextButton(
    onPressed: u.dangGui ? null : () => thucHien(c, f),
    child: Text(ten),
  );
  Future<void> xoa(String dd, VoidCallback taiLai) async {
    if (await xacNhan(
      c,
      'Xóa mục này? Dữ liệu đang sử dụng sẽ được giữ lại.',
    )) {
      await u.xuLy(dd, {}, cach: 'DELETE');
      taiLai();
    }
  }

  Future<void> trangThai(
    String dd,
    String tt,
    VoidCallback taiLai, {
    bool lyDo = false,
  }) async {
    Map<String, dynamic> d = {'trangThai': tt, 'lyDo': ''};
    if (lyDo) {
      final kq = await moBieuMau(c, u, tenNhan(tt), const [
        TruongNhap('lyDo', 'Lý do'),
      ]);
      if (kq == null) return;
      d.addAll(kq);
    } else {
      if (!await xacNhan(c, 'Xác nhận ${tenNhan(tt).toLowerCase()}?')) return;
    }
    await u.xuLy('$dd/trang-thai', d);
    taiLai();
  }

  Future<Map<String, String>> luaChon(String dd) async {
    final kq = await u.danhSach(dd);
    final ds = kq is List ? kq : kq['duLieu'] as List;
    return {
      for (final x in ds)
        if (x['hoatDong'] != false) x['id']: x['ten'] ?? x['hoTen'] ?? x['id'],
    };
  }

  Widget anh(dynamic id) => ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: Image.network(
      '${u.api.diaChi}/tep/$id',
      width: 64,
      height: 64,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const SizedBox(
        width: 64,
        height: 64,
        child: Icon(Icons.image_outlined, color: Colors.blueGrey),
      ),
    ),
  );
  Future<void> thongTin(
    String td,
    Map<String, dynamic> d,
    Map<String, String> nhan, {
    List<Widget> hanhDong = const [],
  }) async {
    if (!c.mounted) return;
    await Navigator.push(
      c,
      MaterialPageRoute(
        builder: (c) => Scaffold(
          appBar: AppBar(title: Text(td)),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              for (final e in nhan.entries)
                if (d[e.key] != null) ...[
                  Text(
                    e.value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xff6250d8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    tenNhan(d[e.key]),
                    style: const TextStyle(fontSize: 16, height: 1.6),
                  ),
                  const SizedBox(height: 20),
                ],
              ...hanhDong,
            ],
          ),
        ),
      ),
    );
  }

  Widget danhMuc(String loai) => ManDanhSach(
    ung: u,
    tieuDe: loai == 'DichVu' ? 'Danh mục dịch vụ' : 'Ngành nghề',
    duongDan: 'danh-muc?loai=$loai&quanLy=true',
    them: () => suaDanhMuc(loai),
    ve: (d, tai) => TheNoiDung(
      tieuDe: d['ten'],
      phu: d['moTa'],
      anh: d['anhId'] == null ? null : anh(d['anhId']),
      hanhDong: [
        nut('Chỉnh sửa', () async {
          await suaDanhMuc(loai, d);
          tai();
        }),
        nut('Xóa', () => xoa('danh-muc/${d['id']}', tai)),
      ],
    ),
  );
  Future<void> suaDanhMuc(String loai, [Map<String, dynamic>? cu]) async {
    await moBieuMau(
      c,
      u,
      cu == null ? 'Thêm danh mục' : 'Sửa danh mục',
      const [
        TruongNhap('ten', 'Tên danh mục'),
        TruongNhap('moTa', 'Mô tả', batBuoc: false, nhieuDong: true),
        TruongNhap(
          'hoatDong',
          'Trạng thái',
          chon: {'true': 'Đang sử dụng', 'false': 'Ngừng sử dụng'},
        ),
      ],
      giaTri: {...?(cu), 'hoatDong': (cu?['hoatDong'] ?? true).toString()},
      anh: loai == 'DichVu',
      luu: (d) async {
        d['loai'] = loai;
        d['hoatDong'] = d['hoatDong'] == 'true';
        await u.xuLy(
          'danh-muc${cu == null ? '' : '/${cu['id']}'}',
          d,
          cach: cu == null ? 'POST' : 'PUT',
        );
      },
    );
  }

  Widget goi({
    bool quanLy = false,
    String? danhMucId,
    String? boQuaId,
  }) => ManDanhSach(
    hanhDong: [
      if (u.nhaTuyen)
        ListenableBuilder(
          listenable: u,
          builder: (c, _) => IconButton(
            onPressed: () => mo(gio()),
            tooltip: 'Giỏ hàng',
            icon: Badge(
              label: Text('${u.soGoi}'),
              isLabelVisible: u.soGoi > 0,
              child: const Icon(Icons.shopping_bag_outlined),
            ),
          ),
        ),
    ],
    ung: u,
    tieuDe: quanLy ? 'Quản lý gói đăng tin' : 'Gói đăng tin',
    duongDan:
        'goi-luot?quanLy=$quanLy${danhMucId == null ? '' : '&danhMucId=$danhMucId'}${boQuaId == null ? '' : '&boQuaId=$boQuaId'}',
    them: quanLy ? () => suaGoi() : null,
    ve: (d, tai) => TheGoiDangTin(
      tieuDe: d['ten'],
      moTa: d['moTa'] ?? '',
      gia: tien(d['gia']),
      soLuot: d['soLuot'],
      dangBan: d['dangBan'] ?? true,
      anh: anh(d['anhId']),
      mo: () => thucHien(c, () => chiTietGoi(d['id'])),
      hanhDong: [
        if (u.nhaTuyen)
          nut('Thêm vào giỏ', () async {
            await u.themGio(d);
            if (c.mounted) bao(c, 'Đã thêm vào giỏ (${u.soGoi} gói).');
          }),
        if (quanLy) ...[
          nut('Chỉnh sửa', () async {
            await suaGoi(d);
            tai();
          }),
          nut('Xóa', () => xoa('goi-luot/${d['id']}', tai)),
        ],
        nut('Danh mục', () async {
          mo(
            ManDanhSach(
              ung: u,
              tieuDe: 'Danh mục dịch vụ',
              duongDan: 'danh-muc',
              ve: (m, _) => TheNoiDung(
                tieuDe: m['ten'],
                phu: m['moTa'],
                mo: () => mo(goi(danhMucId: m['id'])),
              ),
            ),
          );
        }),
      ],
    ),
  );
  Future<void> chiTietGoi(String id) async {
    final ct = Map<String, dynamic>.from(
      await u.danhSach('goi-luot/$id${u.quanTri ? '?quanLy=true' : ''}'),
    );
    if (!c.mounted) return;
    await Navigator.push(
      c,
      MaterialPageRoute(
        builder: (_) => _ManChiTietGoi(
          goi: ct,
          api: u.api.diaChi,
          themDuoc: u.nhaTuyen,
          dangGui: u.dangGui,
          them: () async {
            await u.themGio(ct);
            if (c.mounted) bao(c, 'Đã thêm gói vào giỏ (${u.soGoi} gói).');
          },
          xemCungDanhMuc: () =>
              mo(goi(danhMucId: ct['danhMucId'], boQuaId: ct['id'])),
        ),
      ),
    );
  }

  Future<void> suaGoi([Map<String, dynamic>? cu]) async {
    final dm = await luaChon('danh-muc');
    if (!c.mounted) return;
    await moBieuMau(
      c,
      u,
      cu == null ? 'Thêm gói đăng tin' : 'Sửa gói đăng tin',
      [
        const TruongNhap('ten', 'Tên gói'),
        const TruongNhap('moTa', 'Mô tả', nhieuDong: true),
        TruongNhap('danhMucId', 'Danh mục', chon: dm),
        const TruongNhap('soLuot', 'Số lượt/gói', so: true),
        const TruongNhap('gia', 'Giá (đ)', so: true),
        const TruongNhap(
          'dangBan',
          'Trạng thái',
          chon: {'true': 'Đang bán', 'false': 'Ngừng bán'},
        ),
      ],
      giaTri: {...?cu, 'dangBan': (cu?['dangBan'] ?? true).toString()},
      anh: true,
      luu: (d) async {
        d['dangBan'] = d['dangBan'] == 'true';
        await u.xuLy(
          'goi-luot${cu == null ? '' : '/${cu['id']}'}',
          d,
          cach: cu == null ? 'POST' : 'PUT',
        );
      },
    );
  }

  Widget gio() => ManDanhSach(
    phanDau: (ds, tai) {
      num goi = 0, luot = 0, tong = 0;
      for (final d in ds) {
        goi += d['soLuong'];
        luot += d['soLuong'] * d['soLuot'];
        tong += d['soLuong'] * d['gia'];
      }
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Card(
          color: const Color(0xfff2efff),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tóm tắt giỏ hàng',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _SoLieuGio(nhan: 'Số gói', giaTri: '$goi'),
                    ),
                    Expanded(
                      child: _SoLieuGio(nhan: 'Lượt đăng', giaTri: '$luot'),
                    ),
                    Expanded(
                      child: _SoLieuGio(nhan: 'Tạm tính', giaTri: tien(tong)),
                    ),
                  ],
                ),
                if (ds.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: u.dangGui
                          ? null
                          : () => thucHien(c, () => datDonTuGio(tai)),
                      icon: const Icon(Icons.lock_outline),
                      label: const Text('Kiểm tra và đặt đơn'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
    ung: u,
    tieuDe: 'Giỏ hàng',
    duongDan: 'gio-hang',
    timKiem: false,
    ve: (d, tai) => TheDongGioHang(
      tieuDe: d['ten'],
      chiTiet:
          '${d['soLuong']} gói × ${tien(d['gia'])} / gói\n${d['soLuong'] * d['soLuot']} lượt • Thành tiền ${tien(d['soLuong'] * d['gia'])}',
      doiGia: d['gia'] != d['giaDaXem'],
      anh: anh(d['anhId']),
      hanhDong: [
        nut('Sửa số lượng / xác nhận giá', () async {
          await moBieuMau(
            c,
            u,
            'Cập nhật giỏ',
            const [TruongNhap('soLuong', 'Số gói (1–99)', so: true)],
            giaTri: {'soLuong': d['soLuong']},
            luu: (v) async {
              await u.xuLy('gio-hang', {
                'goiLuotId': d['goiLuotId'],
                'soLuong': v['soLuong'],
                'giaDaXem': d['gia'],
              }, cach: 'PUT');
              await u.capNhatGio();
            },
          );
          tai();
        }),
        nut('Xóa', () async {
          await xoa('gio-hang/${d['id']}', tai);
          await u.capNhatGio();
        }),
      ],
    ),
  );
  Future<void> datDonTuGio(VoidCallback tai) async {
    final ds = await u.danhSach('gio-hang') as List;
    num tong = 0, luot = 0, goi = 0;
    for (final x in ds) {
      tong += x['gia'] * x['soLuong'];
      luot += x['soLuot'] * x['soLuong'];
      goi += x['soLuong'];
    }
    if (!c.mounted || ds.isEmpty) return;
    if (await xacNhan(
      c,
      'Đặt $goi gói, $luot lượt với tổng ${tien(tong)}? Giá được máy chủ kiểm tra lại.',
    )) {
      final don = await u.datDon();
      await u.capNhatGio();
      tai();
      await chiTietDon(don['id']);
    }
  }

  Future<void> locDon() async {
    final loc = await moBieuMau(c, u, 'Lọc đơn mua lượt', const [
      TruongNhap(
        'trangThai',
        'Trạng thái',
        batBuoc: false,
        chon: {
          '': 'Tất cả',
          'ChoThanhToan': 'Chờ thanh toán',
          'DaThanhToan': 'Đã thanh toán',
          'DaHuy': 'Đã hủy',
        },
      ),
      TruongNhap('tuNgay', 'Từ ngày (yyyy-MM-dd)', batBuoc: false),
      TruongNhap('denNgay', 'Đến trước ngày (yyyy-MM-dd)', batBuoc: false),
    ]);
    if (loc != null) {
      mo(
        don(
          boLoc:
              '?${loc.entries.where((e) => e.value.toString().isNotEmpty).map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}',
        ),
      );
    }
  }

  Widget don({String boLoc = ''}) => ManDanhSach(
    hanhDong: [
      IconButton(
        onPressed: () => thucHien(c, locDon),
        icon: const Icon(Icons.filter_list),
        tooltip: 'Lọc đơn',
      ),
    ],
    ung: u,
    tieuDe: 'Đơn hàng',
    duongDan: 'don-hang$boLoc',
    them: null,
    ve: (d, tai) => TheDonMuaLuot(
      ma: d['ma'],
      tongTien: tien(d['tongTien']),
      tongLuot: d['tongLuot'],
      taoLuc: ngay(d['taoLuc']),
      trangThai: d['trangThai'],
      mo: () => thucHien(c, () => chiTietDon(d['id'])),
      hanhDong: [
        if (d['trangThai'] == 'ChoThanhToan') ...[
          if (u.quanTri)
            nut(
              'Xác nhận • TRÌNH DIỄN',
              () => trangThai('don-hang/${d['id']}', 'DaThanhToan', tai),
            ),
          nut('Hủy đơn', () => trangThai('don-hang/${d['id']}', 'DaHuy', tai)),
        ],
      ],
    ),
  );
  Future<void> chiTietDon(String id) async {
    final d = Map<String, dynamic>.from(await u.danhSach('don-hang/$id'));
    if (!c.mounted) return;
    await Navigator.push(
      c,
      MaterialPageRoute(builder: (_) => _ManChiTietDon(don: d)),
    );
  }

  Widget doanhNghiep() => ManDanhSach(
    ung: u,
    tieuDe: 'Doanh nghiệp',
    duongDan: 'doanh-nghiep?quanLy=${u.quanTri}',
    ve: (d, tai) => TheNoiDung(
      tieuDe: d['ten'],
      phu: '${d['diaChi']}\n${d['gioiThieu']}',
      trangThai: d['trangThai'],
      hanhDong: !u.quanTri
          ? []
          : [
              nut(
                'Duyệt / khôi phục',
                () => trangThai('doanh-nghiep/${d['id']}', 'DaDuyet', tai),
              ),
              nut(
                'Từ chối',
                () => trangThai(
                  'doanh-nghiep/${d['id']}',
                  'BiTuChoi',
                  tai,
                  lyDo: true,
                ),
              ),
              nut(
                'Tạm khóa',
                () => trangThai(
                  'doanh-nghiep/${d['id']}',
                  'TamKhoa',
                  tai,
                  lyDo: true,
                ),
              ),
            ],
    ),
  );
  Future<void> congTyToi() async {
    Map<String, dynamic>? dn;
    if (u.nguoi?['doanhNghiepId'] != null) {
      dn = Map<String, dynamic>.from(await u.danhSach('doanh-nghiep/toi'));
    }
    if (!c.mounted) return;
    await moBieuMau(
      c,
      u,
      dn == null
          ? 'Đăng ký doanh nghiệp'
          : 'Doanh nghiệp • ${tenNhan(dn['trangThai'])}',
      const [
        TruongNhap('ten', 'Tên doanh nghiệp'),
        TruongNhap('maSoThue', 'Mã số thuế', batBuoc: false),
        TruongNhap('diaChi', 'Địa chỉ'),
        TruongNhap('gioiThieu', 'Giới thiệu', nhieuDong: true),
      ],
      giaTri: dn,
      luu: (d) async {
        final kq = await u.xuLy(
          dn == null ? 'doanh-nghiep' : 'doanh-nghiep/toi',
          d,
          cach: dn == null ? 'POST' : 'PUT',
        );
        u.nguoi!['doanhNghiepId'] = kq['id'];
      },
    );
  }

  Widget thanhVienCongTy() => ManDanhSach(
    ung: u,
    tieuDe: 'Thành viên doanh nghiệp',
    duongDan: 'doanh-nghiep/thanh-vien',
    timKiem: false,
    them: () async {
      await moBieuMau(
        c,
        u,
        'Thêm nhà tuyển dụng',
        const [TruongNhap('email', 'Email tài khoản đã đăng ký')],
        luu: (d) async {
          await u.xuLy('doanh-nghiep/thanh-vien', d);
        },
      );
    },
    ve: (d, tai) => TheNoiDung(
      tieuDe: d['hoTen'],
      phu: d['email'],
      hanhDong: [
        nut('Gỡ khỏi doanh nghiệp', () async {
          if (await xacNhan(c, 'Gỡ thành viên khỏi doanh nghiệp?')) {
            await u.xuLy('doanh-nghiep/thanh-vien', {
              'email': d['email'],
              'xoa': true,
            });
            tai();
          }
        }),
      ],
    ),
  );
  Widget thanhVien() => ManDanhSach(
    ung: u,
    tieuDe: 'Thành viên & phân quyền',
    duongDan: 'tai-khoan',
    ve: (d, tai) => TheNoiDung(
      tieuDe: d['hoTen'],
      phu:
          '${d['email']}\n${tenNhan(d['loai'])} • ${tenNhan(d['vaiTro'])} • ${d['biKhoa'] ? 'Đã khóa' : 'Hoạt động'}',
      hanhDong: [
        nut('Quyền & khóa', () async {
          await moBieuMau(
            c,
            u,
            'Quản lý tài khoản',
            const [
              TruongNhap(
                'vaiTro',
                'Vai trò',
                chon: {'ThanhVien': 'Thành viên', 'QuanTri': 'Quản trị viên'},
              ),
              TruongNhap(
                'biKhoa',
                'Trạng thái',
                chon: {'true': 'Khóa', 'false': 'Hoạt động'},
              ),
            ],
            giaTri: {'vaiTro': d['vaiTro'], 'biKhoa': d['biKhoa'].toString()},
            luu: (v) async {
              v['biKhoa'] = v['biKhoa'] == 'true';
              await u.xuLy('tai-khoan/${d['id']}/quyen', v, cach: 'PUT');
            },
          );
          tai();
        }),
      ],
    ),
  );
  Future<void> soLuot() async {
    final kq = await u.danhSach('so-luot');
    if (!c.mounted) return;
    await thongTin(
      'Sổ lượt đăng tin',
      {
        'con': kq['soLuotConLai'],
        'giu': kq['soLuotDangGiu'],
        'dung': kq['soLuotDaDung'],
        'lichSu': (kq['lichSu']['duLieu'] as List)
            .map(
              (x) =>
                  '${ngay(x['taoLuc'])} • ${tenNhan(x['suKien'])}\nCòn lại ${x['conLai'] >= 0 ? '+' : ''}${x['conLai']}, giữ ${x['dangGiu']}, đã dùng ${x['daDung']}',
            )
            .join('\n\n'),
      },
      {
        'con': 'Lượt còn lại',
        'giu': 'Lượt đang giữ',
        'dung': 'Lượt đã dùng',
        'lichSu': 'Lịch sử phát sinh gần nhất',
      },
    );
  }

  Widget thongBao() => ManDanhSach(
    ung: u,
    tieuDe: 'Thông báo',
    duongDan: 'thong-bao',
    timKiem: false,
    ve: (d, tai) => TheNoiDung(
      tieuDe: d['noiDung'],
      phu: '${ngay(d['taoLuc'])} • ${d['daDoc'] ? 'Đã đọc' : 'Chưa đọc'}',
      hanhDong: [
        nut('Mở nội dung', () async {
          await u.xuLy('thong-bao/${d['id']}/da-doc', {}, cach: 'PUT');
          tai();
          final dd = d['duongDan'] as String;
          if (dd.startsWith('don-hang/')) {
            await chiTietDon(dd.split('/').last);
          } else if (dd.startsWith('ho-so/')) {
            await chiTietHoSo(dd.split('/').last);
          } else if (dd.startsWith('tin-tuyen-dung/')) {
            await chiTietTin(dd.split('/').last);
          } else if (dd == 'doanh-nghiep/toi') {
            await congTyToi();
          }
        }),
      ],
    ),
  );
  Widget thongKe() => _ThongKe(u: u);
  Widget tin({
    bool quanLy = false,
    bool daLuu = false,
    String? loc,
    String? tuKhoa,
  }) => ManDanhSach(
    ung: u,
    hanhDong: [
      if (!quanLy && !daLuu)
        IconButton(
          tooltip: 'Lọc việc làm',
          onPressed: () => thucHien(c, locViec),
          icon: const Icon(Icons.tune_rounded),
        ),
    ],
    tuKhoaBanDau: tuKhoa,
    tieuDe: daLuu
        ? 'Việc đã lưu'
        : quanLy
        ? 'Quản lý tin tuyển dụng'
        : 'Khám phá việc làm',
    duongDan: daLuu
        ? 'viec-da-luu'
        : 'tin-tuyen-dung?quanLy=$quanLy${loc ?? ''}',
    them: u.nhaTuyen && quanLy ? () => suaTin() : null,
    ve: (d, tai) => TheViecLam(
      tieuDe: d['tieuDe'],
      phu:
          '${d['diaDiem']} • ${tenNhan(d['hinhThuc'])}\n${d['luongMin'] == null ? 'Lương thỏa thuận' : '${tien(d['luongMin'])} – ${tien(d['luongMax'])}'}\nHạn nhận: ${ngay(d['hanNhan'])}',
      trangThai: DateTime.parse(d['hanNhan']).isBefore(DateTime.now())
          ? 'Hết hạn'
          : d['trangThai'],
      mo: () => thucHien(c, () => chiTietTin(d['id'])),
      hanhDong: [
        if (u.ungVien)
          nut(daLuu ? 'Bỏ lưu' : 'Lưu việc', () async {
            await u.xuLy(
              'viec-da-luu/${d['id']}',
              {},
              cach: daLuu ? 'DELETE' : 'PUT',
            );
            tai();
          }),
        if (quanLy && u.nhaTuyen) ...[
          if (['BanNhap', 'BiTuChoi', 'DangTuyen'].contains(d['trangThai']))
            nut('Sửa tin', () async {
              await suaTin(d);
              tai();
            }),
          if (['BanNhap', 'BiTuChoi'].contains(d['trangThai']))
            nut(
              'Gửi duyệt • 1 lượt',
              () => trangThai('tin-tuyen-dung/${d['id']}', 'ChoDuyet', tai),
            ),
          if (d['trangThai'] == 'ChoDuyet')
            nut(
              'Rút tin',
              () => trangThai('tin-tuyen-dung/${d['id']}', 'BanNhap', tai),
            ),
          if (d['trangThai'] == 'DangTuyen')
            nut(
              'Đóng tin',
              () => trangThai('tin-tuyen-dung/${d['id']}', 'DaDong', tai),
            ),
          nut('Hồ sơ ứng tuyển', () async {
            mo(hoSo(tinId: d['id']));
          }),
        ],
        if (quanLy && u.quanTri) ...[
          if (d['trangThai'] == 'ChoDuyet' || d['banSuaJson'] != null) ...[
            nut(
              'Duyệt',
              () => trangThai('tin-tuyen-dung/${d['id']}', 'DangTuyen', tai),
            ),
            nut(
              'Từ chối',
              () => trangThai(
                'tin-tuyen-dung/${d['id']}',
                'BiTuChoi',
                tai,
                lyDo: true,
              ),
            ),
          ],
          if (d['trangThai'] == 'DangTuyen')
            nut(
              'Ẩn tin',
              () => trangThai(
                'tin-tuyen-dung/${d['id']}',
                'BiAn',
                tai,
                lyDo: true,
              ),
            ),
        ],
      ],
    ),
  );
  Future<void> locViec() async {
    final nganh = await luaChon('danh-muc?loai=NganhNghe');
    if (!c.mounted) return;
    final l = await moBieuMau(c, u, 'Lọc việc làm', [
      TruongNhap(
        'nganhId',
        'Ngành nghề',
        batBuoc: false,
        chon: {'': 'Tất cả', ...nganh},
      ),
      const TruongNhap('diaDiem', 'Địa điểm', batBuoc: false),
      const TruongNhap('luongMin', 'Lương tối thiểu', so: true, batBuoc: false),
      const TruongNhap('kinhNghiem', 'Kinh nghiệm', batBuoc: false),
      const TruongNhap(
        'hinhThuc',
        'Hình thức',
        batBuoc: false,
        chon: {
          '': 'Tất cả',
          'ToanThoiGian': 'Toàn thời gian',
          'BanThoiGian': 'Bán thời gian',
          'TuXa': 'Từ xa',
        },
      ),
    ]);
    if (l != null) {
      mo(
        tin(
          loc: l.entries
              .where((e) => e.value != null && e.value.toString().isNotEmpty)
              .map(
                (e) => '&${e.key}=${Uri.encodeComponent(e.value.toString())}',
              )
              .join(),
        ),
      );
    }
  }

  Future<void> suaTin([Map<String, dynamic>? cu]) async {
    final nganh = await luaChon('danh-muc?loai=NganhNghe');
    if (!c.mounted) return;
    await moBieuMau(
      c,
      u,
      cu == null ? 'Tạo tin tuyển dụng' : 'Sửa tin tuyển dụng',
      [
        const TruongNhap('tieuDe', 'Tiêu đề / vị trí'),
        TruongNhap('nganhId', 'Ngành nghề', chon: nganh),
        const TruongNhap('diaDiem', 'Địa điểm'),
        const TruongNhap(
          'hinhThuc',
          'Hình thức',
          chon: {
            'ToanThoiGian': 'Toàn thời gian',
            'BanThoiGian': 'Bán thời gian',
            'TuXa': 'Từ xa',
          },
        ),
        const TruongNhap('kinhNghiem', 'Kinh nghiệm'),
        const TruongNhap('trinhDo', 'Trình độ'),
        const TruongNhap('soNguoi', 'Số người cần tuyển', so: true),
        const TruongNhap(
          'luongMin',
          'Lương tối thiểu (bỏ trống nếu thỏa thuận)',
          so: true,
          batBuoc: false,
        ),
        const TruongNhap('luongMax', 'Lương tối đa', so: true, batBuoc: false),
        const TruongNhap('hanNhan', 'Hạn nhận (yyyy-MM-dd)'),
        const TruongNhap('moTa', 'Mô tả công việc', nhieuDong: true),
        const TruongNhap('yeuCau', 'Yêu cầu', nhieuDong: true),
        const TruongNhap('quyenLoi', 'Quyền lợi', nhieuDong: true),
      ],
      giaTri: cu ?? {'hinhThuc': 'ToanThoiGian', 'soNguoi': 1},
      khoaNhap: 'tin-${cu?['id'] ?? 'moi'}',
      luu: (d) async {
        final han = DateTime.tryParse(d['hanNhan']);
        if (han == null) throw Exception('Hạn nhận cần có dạng yyyy-MM-dd.');
        d['hanNhan'] = han.toUtc().toIso8601String();
        await u.xuLy(
          'tin-tuyen-dung${cu == null ? '' : '/${cu['id']}'}',
          d,
          cach: cu == null ? 'POST' : 'PUT',
        );
      },
    );
  }

  Future<void> chiTietTin(String id) async {
    final d = Map<String, dynamic>.from(await u.danhSach('tin-tuyen-dung/$id'));
    if (!c.mounted) return;
    await Navigator.push(
      c,
      MaterialPageRoute(
        builder: (_) => ChiTietViec(
          d: d,
          ung: u,
          hanhDong: [
            if (u.ungVien)
              nut('Ứng tuyển', () async {
                final cv = await luaChon('tep');
                if (cv.isEmpty) {
                  if (!c.mounted) return;
                  await Navigator.push(
                    c,
                    MaterialPageRoute(builder: (_) => this.cv()),
                  );
                  return;
                }
                if (!c.mounted) return;
                final kq = await moBieuMau(c, u, 'Chuẩn bị ứng tuyển', [
                  TruongNhap('cvId', 'Chọn CV đã tải', chon: cv),
                  const TruongNhap(
                    'thuGioiThieu',
                    'Thư giới thiệu',
                    nhieuDong: true,
                    batBuoc: false,
                  ),
                ]);
                if (kq != null &&
                    c.mounted &&
                    await xacNhan(
                      c,
                      'Nộp hồ sơ cho tin “${d['tieuDe']}”? Hồ sơ và CV tại thời điểm nộp sẽ được lưu lại.',
                    )) {
                  await u.xuLy('tin-tuyen-dung/$id/ung-tuyen', kq);
                  if (c.mounted) bao(c, 'Đã nộp hồ sơ thành công.');
                }
              }),
            nut('Việc cùng ngành', () async {
              mo(tin(loc: '&nganhId=${d['nganhId']}'));
            }),
            if (u.quanTri && d['banSuaJson'] != null)
              nut('Xem bản sửa chờ duyệt', () async {
                await thongTin(
                  'Bản sửa chờ duyệt',
                  Map<String, dynamic>.from(jsonDecode(d['banSuaJson'])),
                  {
                    'TieuDe': 'Tiêu đề',
                    'DiaDiem': 'Địa điểm',
                    'MoTa': 'Mô tả',
                    'YeuCau': 'Yêu cầu',
                    'QuyenLoi': 'Quyền lợi',
                    'HanNhan': 'Hạn nhận',
                  },
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget cv() => ManDanhSach(
    ung: u,
    tieuDe: 'CV của tôi',
    duongDan: 'tep',
    timKiem: false,
    them: () async {
      await moBieuMau(c, u, 'Tải CV', const [], cv: true);
    },
    ve: (d, tai) => TheCvCaNhan(
      ten: d['ten'],
      ngayTai: ngay(d['taoLuc']),
      hanhDong: [
        nut('Tải xuống', () => taiCv(d['id'])),
        nut('Xóa', () => xoa('tep/${d['id']}', tai)),
      ],
    ),
  );
  Future<void> taiCv(String id) async {
    final bytes = await u.api.taiXuong(id);
    await FilePicker.saveFile(
      dialogTitle: 'Lưu CV riêng tư',
      fileName: 'CV-$id.pdf',
      bytes: Uint8List.fromList(bytes),
    );
  }

  Widget hoSo({String? tinId}) => ManDanhSach(
    ung: u,
    tieuDe: 'Hồ sơ ứng tuyển',
    duongDan: 'ho-so${tinId == null ? '' : '?tinId=$tinId'}',
    timKiem: false,
    ve: (d, tai) => TheHoSoUngTuyen(
      tieuDe: u.nhaTuyen ? 'Hồ sơ ứng viên' : 'Hồ sơ đã gửi',
      ngayNop: ngay(d['taoLuc']),
      trangThai: d['trangThai'],
      thuGioiThieu: d['thuGioiThieu'],
      mo: () => thucHien(c, () => chiTietHoSo(d['id'])),
      hanhDong: [
        nut('Xem hồ sơ / CV', () => chiTietHoSo(d['id'])),
        if (u.ungVien &&
            ['DaGui', 'DangXemXet', 'MoiPhongVan'].contains(d['trangThai']))
          nut('Rút hồ sơ', () async {
            if (await xacNhan(
              c,
              'Rút hồ sơ? Bản đầu không cho nộp lại tin này.',
            )) {
              await u.xuLy('ho-so/${d['id']}/trang-thai', {
                'trangThai': 'DaRut',
                'ghiChu': '',
              });
              tai();
            }
          }),
        if (u.nhaTuyen)
          nut('Xét hồ sơ', () async {
            final chon = <String, String>{
              if (d['trangThai'] == 'DaGui') 'DangXemXet': 'Đang xem xét',
              if (['DaGui', 'DangXemXet'].contains(d['trangThai']))
                'MoiPhongVan': 'Mời phỏng vấn',
              if (d['trangThai'] == 'MoiPhongVan') 'DaTuyen': 'Đã tuyển',
              if ([
                'DaGui',
                'DangXemXet',
                'MoiPhongVan',
              ].contains(d['trangThai']))
                'TuChoi': 'Từ chối',
            };
            if (chon.isEmpty) return;
            await moBieuMau(
              c,
              u,
              'Xử lý hồ sơ',
              [
                TruongNhap('trangThai', 'Kết quả', chon: chon),
                const TruongNhap(
                  'ghiChu',
                  'Ghi chú',
                  batBuoc: false,
                  nhieuDong: true,
                ),
                const TruongNhap(
                  'gioPhongVan',
                  'Giờ phỏng vấn (yyyy-MM-dd HH:mm)',
                  batBuoc: false,
                ),
                const TruongNhap(
                  'hinhThuc',
                  'Hình thức phỏng vấn',
                  batBuoc: false,
                ),
                const TruongNhap(
                  'diaDiem',
                  'Địa điểm / đường dẫn',
                  batBuoc: false,
                ),
              ],
              luu: (v) async {
                if (v['trangThai'] == 'MoiPhongVan') {
                  final gio = DateTime.tryParse(v['gioPhongVan']);
                  if (gio == null) {
                    throw Exception('Nhập giờ phỏng vấn hợp lệ.');
                  }
                  v['gioPhongVan'] = gio.toUtc().toIso8601String();
                } else {
                  v['gioPhongVan'] = null;
                }
                await u.xuLy('ho-so/${d['id']}/trang-thai', v);
              },
            );
            tai();
          }),
      ],
    ),
  );
  Future<void> chiTietHoSo(String id) async {
    final kq = await u.danhSach('ho-so/$id');
    final d = Map<String, dynamic>.from(kq['hoSo']);
    final hs = Map<String, dynamic>.from(jsonDecode(d['banHoSoJson']));
    Map<String, dynamic> ct = {};
    try {
      ct = Map<String, dynamic>.from(jsonDecode(hs['HoSoJson'] ?? '{}'));
    } catch (_) {}
    if (!c.mounted) return;
    await thongTin(
      'Hồ sơ đã nộp',
      {
        'hoTen': hs['HoTen'],
        'email': hs['Email'],
        ...ct,
        'trangThai': d['trangThai'],
        'thuGioiThieu': d['thuGioiThieu'],
        'lichSu': (kq['lichSu'] as List)
            .map(
              (x) =>
                  '${ngay(x['taoLuc'])} • ${tenNhan(x['trangThai'])}\n${x['ghiChu']}',
            )
            .join('\n'),
        'phongVan': d['phongVanJson'] == null
            ? ''
            : _phongVan(d['phongVanJson']),
      },
      {
        'hoTen': 'Họ tên khi nộp',
        'email': 'Email',
        'lienHe': 'Liên hệ',
        'gioiThieu': 'Giới thiệu',
        'hocVan': 'Học vấn',
        'kinhNghiem': 'Kinh nghiệm',
        'kyNang': 'Kỹ năng',
        'viTriMongMuon': 'Vị trí mong muốn',
        'thuGioiThieu': 'Thư giới thiệu',
        'trangThai': 'Trạng thái',
        'phongVan': 'Thông tin phỏng vấn',
        'lichSu': 'Lịch sử',
      },
      hanhDong: [nut('Tải CV đã nộp', () => taiCv(d['cvId']))],
    );
  }

  String _phongVan(String json) {
    final d = jsonDecode(json);
    return '${ngay(d['GioPhongVan'])}\n${d['HinhThuc']}\n${d['DiaDiem']}\n${d['GhiChu']}';
  }
}

class _ManChiTietGoi extends StatelessWidget {
  final Map<String, dynamic> goi;
  final String api;
  final bool themDuoc, dangGui;
  final Future<void> Function() them;
  final VoidCallback xemCungDanhMuc;
  const _ManChiTietGoi({
    required this.goi,
    required this.api,
    required this.themDuoc,
    required this.dangGui,
    required this.them,
    required this.xemCungDanhMuc,
  });

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Chi tiết gói đăng tin')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.network(
            '$api/tep/${goi['anhId']}',
            height: 190,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              height: 190,
              color: const Color(0xffeeeaff),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 56,
                color: Color(0xff6250d8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          goi['ten'],
          style: Theme.of(
            c,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 14),
        Card(
          color: const Color(0xfff2efff),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.bolt_rounded,
                  color: Color(0xff6250d8),
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${goi['soLuot']} lượt đăng tin',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  tien(goi['gia']),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xff4338ca),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Giới thiệu gói',
          style: Theme.of(
            c,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          goi['moTa']?.toString().isNotEmpty == true
              ? goi['moTa']
              : 'Gói lượt đăng tin dành cho nhà tuyển dụng.',
          style: const TextStyle(height: 1.6, color: Color(0xff526177)),
        ),
        const SizedBox(height: 20),
        if (themDuoc)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: dangGui ? null : () => thucHien(c, them),
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Thêm vào giỏ hàng'),
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: xemCungDanhMuc,
          icon: const Icon(Icons.category_outlined),
          label: const Text('Xem các gói cùng danh mục'),
        ),
      ],
    ),
  );
}

class _ManChiTietDon extends StatelessWidget {
  final Map<String, dynamic> don;
  const _ManChiTietDon({required this.don});

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Chi tiết đơn hàng')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          color: const Color(0xfff2efff),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.receipt_long,
                  color: Color(0xff6250d8),
                  size: 30,
                ),
                const SizedBox(height: 10),
                Text(
                  don['ma'],
                  style: Theme.of(
                    c,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                NhanTrangThai(don['trangThai']),
                const SizedBox(height: 14),
                Text(
                  'Đặt lúc ${ngay(don['taoLuc'])}',
                  style: const TextStyle(color: Color(0xff687385)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _SoLieuGio(
                    nhan: 'Tổng thanh toán',
                    giaTri: tien(don['tongTien']),
                  ),
                ),
                Expanded(
                  child: _SoLieuGio(
                    nhan: 'Lượt đăng',
                    giaTri: '${don['tongLuot']}',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gói trong đơn',
                  style: Theme.of(c).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                for (final x in (don['chiTiet'] as List)) ...[
                  const Divider(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        color: Color(0xff6250d8),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              x['tenGoi'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${x['soLuong']} gói × ${tien(x['donGia'])} • ${x['soLuot']} lượt/gói',
                            ),
                          ],
                        ),
                      ),
                      Text(
                        tien(x['soLuong'] * x['donGia']),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Color(0xff6250d8)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Thanh toán trong bản này do quản trị xác nhận ở chế độ trình diễn; đây không phải giao dịch trực tuyến.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _ThongKe extends StatefulWidget {
  final UngDung u;
  const _ThongKe({required this.u});
  @override
  State<_ThongKe> createState() => _ThongKeState();
}

class _ThongKeState extends State<_ThongKe> {
  late Future<dynamic> duLieu;
  final tu = TextEditingController(), den = TextEditingController();
  @override
  void initState() {
    super.initState();
    tai();
  }

  void tai() {
    duLieu = widget.u.danhSach(
      'thong-ke?${tu.text.isEmpty ? '' : 'tuNgay=${tu.text}&'}${den.text.isEmpty ? '' : 'denNgay=${den.text}'}',
    );
  }

  @override
  void dispose() {
    tu.dispose();
    den.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Thống kê')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        TextField(
          controller: tu,
          decoration: const InputDecoration(labelText: 'Từ ngày (yyyy-MM-dd)'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: den,
          decoration: const InputDecoration(
            labelText: 'Đến trước ngày (yyyy-MM-dd)',
          ),
        ),
        TextButton(
          onPressed: () => setState(tai),
          child: const Text('Áp dụng bộ lọc'),
        ),
        FutureBuilder(
          future: duLieu,
          builder: (c, s) {
            if (s.hasError) return Text(s.error.toString());
            if (!s.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final d = s.data as Map;
            return Column(
              children: [
                for (final e in {
                  'taiKhoan': 'Tài khoản toàn hệ thống',
                  'doanhNghiep': 'Doanh nghiệp toàn hệ thống',
                  'tin': 'Tin toàn hệ thống',
                  'doanhThu': 'Doanh thu đã thanh toán',
                }.entries)
                  if (d[e.key] != null)
                    TheNoiDung(
                      tieuDe: e.value,
                      phu: e.key == 'doanhThu'
                          ? tien(d[e.key])
                          : d[e.key].toString(),
                    ),
                for (final hs in d['hoSo'] ?? [])
                  TheNoiDung(
                    tieuDe: tenNhan(hs['trangThai']),
                    phu: '${hs['soLuong']} hồ sơ',
                  ),
              ],
            );
          },
        ),
      ],
    ),
  );
}

class _SoLieuGio extends StatelessWidget {
  final String nhan, giaTri;
  const _SoLieuGio({required this.nhan, required this.giaTri});

  @override
  Widget build(BuildContext c) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        nhan,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12, color: Color(0xff687385)),
      ),
      const SizedBox(height: 3),
      Text(
        giaTri,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ],
  );
}
