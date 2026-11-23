using System.Data;
using MayChu.DuLieu;
using MayChu.NghiepVu;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
namespace MayChu.DuLieuMau;

public static class TaoBoMauNghiemThu
{
    public static async Task Tao(KhoDuLieu db, PasswordHasher<TaiKhoan> bam, PhienLamViec phien, string goc, string matKhau)
    {
        PhienLamViec.KiemTra(matKhau.Length is >= 12 and <= 128, "Mật khẩu mẫu cần 12–128 ký tự.");
        await db.Database.EnsureCreatedAsync();
        await using var tx = await db.Database.BeginTransactionAsync(IsolationLevel.Serializable);
        if (await db.DoanhNghiep.AnyAsync(x => x.MaSoThue == "MAUMOI-01"))
        {
            Console.WriteLine("Bộ mẫu đã tồn tại. Không tạo trùng hoặc đặt lại mật khẩu.");
            return;
        }
        PhienLamViec.KiemTra(!await db.DoanhNghiep.AnyAsync() && !await db.DonHang.AnyAsync() && !await db.Tin.AnyAsync() && !await db.TaiKhoan.AnyAsync(),
            "Chỉ tạo bộ mẫu trong cơ sở dữ liệu trống. Dùng Database=mobi_mau_moi; không xóa dữ liệu hiện có.");
        var qt = new TaiKhoan { Email = "quantri@maumoi.example", HoTen = "Quản trị bộ mẫu", VaiTro = "QuanTri", Loai = "QuanTri" };
        qt.MatKhauBam = bam.HashPassword(qt, matKhau); db.Add(qt);
        var ten = new[] { "Nguyễn Minh Anh", "Trần Hoàng Nam", "Lê Thu Hà", "Phạm Đức Huy", "Võ Ngọc Mai", "Đặng Quốc Bảo", "Bùi Thảo Vy", "Đỗ Gia Hân", "Hồ Tuấn Kiệt", "Ngô Khánh Linh", "Dương Nhật Minh", "Lý Phương Anh", "Mai Thanh Tùng", "Đinh Bảo Ngọc", "Tạ Hải Đăng", "Phan Quỳnh Như", "Cao Minh Khang", "Vũ Thanh Trúc", "Trịnh Đức Anh" };
        for (var i = 2; i <= 20; i++)
        {
            var q = new TaiKhoan { Email = $"quantri{i:00}@maumoi.example", HoTen = $"Quản trị mẫu {i:00}", VaiTro = "QuanTri", Loai = "QuanTri" };
            q.MatKhauBam = bam.HashPassword(q, matKhau); db.Add(q);
        }
        var nguoi = new List<TaiKhoan>();
        for (var i = 0; i < 60; i++)
        {
            var tk = new TaiKhoan { Email = $"nguoi{i + 1:00}@maumoi.example", HoTen = ten[i % ten.Length] + $" {i + 1:00}", Loai = i < 40 ? "NhaTuyenDung" : "UngVien" };
            tk.MatKhauBam = bam.HashPassword(tk, matKhau); nguoi.Add(tk); db.Add(tk);
        }
        await db.SaveChangesAsync();
        var tenDn = new[] { "Công nghệ Ánh Dương", "Thương mại Minh An", "Thiết kế Sao Việt", "Giải pháp Hưng Thịnh", "Truyền thông Phương Nam", "Dịch vụ Đại Việt", "Phần mềm An Khang", "Sáng tạo Bình Minh", "Thương mại Hoàng Gia", "Công nghệ Thiên Long", "Thiết kế Hòa Bình", "Giải pháp Nam Việt" };
        var dns = new List<DoanhNghiep>();
        for (var i = 0; i < 12; i++)
        {
            var dn = new DoanhNghiep { Ten = tenDn[i], MaSoThue = $"MAUMOI-{i + 1:00}", DiaChi = "TP. Hồ Chí Minh — địa chỉ minh họa",
                GioiThieu = "Doanh nghiệp minh họa dùng kiểm thử, không phải thông tin doanh nghiệp thật.",
                NguoiPhuTrachId = nguoi[i].Id, TrangThai = i < 6 ? "DaDuyet" : i < 9 ? "ChoDuyet" : "BiTuChoi", LyDo = i >= 9 ? "Thông tin đăng ký minh họa chưa đầy đủ, cần bổ sung." : "", DaCapMienPhi = i < 6 };
            db.Add(dn); dns.Add(dn); nguoi[i].DoanhNghiepId = dn.Id;
            if (i < 6) phien.GhiLuot(dn, qt.Id, dn.Id, "MienPhiLanDau", 3, 0, 0);
        }
        for (var i = 12; i < 20; i++) nguoi[i].DoanhNghiepId = dns[(i - 12) % 6].Id;
        var nganh = new List<DanhMuc>();
        foreach (var t in new[] { "Công nghệ thông tin", "Kinh doanh", "Thiết kế" })
        {
            var dm = new DanhMuc { Ten = t, TenChuan = t.ToUpperInvariant(), Loai = "NganhNghe", MoTa = "Phân loại tin tuyển dụng." };
            db.Add(dm); nganh.Add(dm);
        }
        var dichVu = new DanhMuc { Ten = "Dịch vụ đăng tuyển", TenChuan = "DỊCH VỤ ĐĂNG TUYỂN", Loai = "DichVu", MoTa = "Các gói mua lượt đăng tin." }; db.Add(dichVu);
        var gois = new List<GoiLuot>();
        var tepMoi = new List<string>();
        try
        {
            var kho = Path.Combine(goc, "kho-tep"); Directory.CreateDirectory(kho);
            for (var i = 0; i < 9; i++)
            {
                var luot = new[] { 1, 5, 10 }[i % 3];
                var tep = new Tep { ChuSoHuuId = qt.Id, Ten = $"goi-{luot}.png", Loai = "Anh", Mime = "image/png" };
                tep.DuongDan = Path.Combine(kho, tep.Id + ".png");
                File.Copy(Path.Combine(goc, "DuLieuMau", "anh", $"goi-{luot}.png"), tep.DuongDan);
                tepMoi.Add(tep.DuongDan); db.Add(tep);
                var goi = new GoiLuot { Ten = $"Gói {luot} lượt đăng tin — lựa chọn {i + 1}", DanhMucId = dichVu.Id, AnhId = tep.Id, SoLuot = luot, Gia = new[] { 20000m, 90000m, 160000m }[i % 3], MoTa = "Gói minh họa; xác nhận thanh toán ở chế độ trình diễn." };
                db.Add(goi); gois.Add(goi);
            }
            for (var i = 0; i < 24; i++)
            {
                var j = i % 6; var g = gois[i % gois.Count]; var dn = dns[j];
                var ngay = DateTime.UtcNow.AddMonths(-(i % 6)).AddDays(-1);
                var don = new DonHang { Ma = $"DH-MAUMOI-{i + 1:00}", DoanhNghiepId = dn.Id, NguoiMuaId = nguoi[j].Id,
                    KhoaLap = $"maumoi-don-{i + 1}", TrangThai = i < 18 ? "DaThanhToan" : "ChoThanhToan",
                    TongTien = g.Gia, TongLuot = g.SoLuot, TaoLuc = i < 18 ? ngay : DateTime.UtcNow.AddMinutes(-i),
                    XacNhanLuc = i < 18 ? ngay : null, NguoiXacNhanId = i < 18 ? qt.Id : null };
                don.ChiTiet.Add(new ChiTietDon { GoiLuotId = g.Id, TenGoi = g.Ten, SoLuong = 1, SoLuot = g.SoLuot, DonGia = g.Gia });
                db.Add(don);
                if (i < 18) phien.GhiLuot(dn, qt.Id, don.Id, "MuaLuot", g.SoLuot, 0, 0);
            }
            var tieuDe = new[] { "Lập trình viên Flutter", "Nhân viên kinh doanh", "Chuyên viên thiết kế", "Lập trình viên C# ASP.NET Core" };
            for (var i = 0; i < 18; i++)
            {
                var j = i % 6; var dn = dns[j];
                var tin = new TinTuyenDung { TieuDe = tieuDe[i % tieuDe.Length] + $" — vị trí {i + 1}", DoanhNghiepId = dn.Id, NguoiTaoId = nguoi[j].Id, NganhId = nganh[i % 3].Id,
                    DiaDiem = "TP. Hồ Chí Minh", KinhNghiem = "Dưới 1 năm", TrinhDo = "Cao đẳng/Đại học", SoNguoi = 2,
                    LuongMin = 10000000, LuongMax = 18000000, MoTa = "Tin tuyển dụng minh họa cho kiểm thử ứng dụng.",
                    YeuCau = "Có kỹ năng phù hợp với vị trí.", QuyenLoi = "Đào tạo và phát triển kỹ năng.",
                    TrangThai = "DangTuyen", HanNhan = DateTime.UtcNow.AddDays(45) };
                db.Add(tin); phien.GhiLuot(dn, nguoi[j].Id, tin.Id, "GiuLuot", -1, 1, 0);
                phien.GhiLuot(dn, qt.Id, tin.Id, "SuDungLuot", 0, -1, 1);
            }
            await db.SaveChangesAsync();
            PhienLamViec.KiemTra(await db.TaiKhoan.CountAsync() == 80 && await db.DoanhNghiep.CountAsync() == 12 && await db.DonHang.CountAsync() == 24 && await db.Tin.CountAsync() == 18, "Số lượng mẫu không đúng, hủy giao dịch.");
            await tx.CommitAsync();
            Console.WriteLine("Đã tạo: 80 tài khoản, chia đều 20 quản trị / 20 ứng viên / 20 nhà tuyển dụng chưa có doanh nghiệp / 20 nhân viên (gồm người phụ trách). 12 doanh nghiệp: 6 đã duyệt, 3 chờ, 3 từ chối. 24 đơn, 18 tin, 9 gói.");
            Console.WriteLine("Quản trị: quantri@maumoi.example. Thành viên: nguoi01@maumoi.example đến nguoi60@maumoi.example. Mật khẩu là giá trị bạn vừa nhập.");
        }
        catch
        {
            foreach (var t in tepMoi) if (File.Exists(t)) File.Delete(t);
            throw;
        }
    }
}
