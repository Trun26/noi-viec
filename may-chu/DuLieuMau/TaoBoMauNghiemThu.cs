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
        if (await db.DoanhNghiep.AnyAsync(x => x.MaSoThue == "MAU20-01"))
        {
            Console.WriteLine("Bộ mẫu đã tồn tại. Không tạo trùng hoặc đặt lại mật khẩu.");
            return;
        }
        PhienLamViec.KiemTra(!await db.DoanhNghiep.AnyAsync() && !await db.DonHang.AnyAsync() && !await db.Tin.AnyAsync() && !await db.TaiKhoan.AnyAsync(),
            "Chỉ tạo bộ mẫu trong cơ sở dữ liệu trống. Dùng Database=mobi_mau20; không xóa dữ liệu hiện có.");
        var qt = new TaiKhoan { Email = "quantri@mau20.example", HoTen = "Quản trị bộ mẫu", VaiTro = "QuanTri", Loai = "QuanTri" };
        qt.MatKhauBam = bam.HashPassword(qt, matKhau); db.Add(qt);
        var ten = new[] { "Nguyễn Minh Anh", "Trần Hoàng Nam", "Lê Thu Hà", "Phạm Đức Huy", "Võ Ngọc Mai", "Đặng Quốc Bảo", "Bùi Thảo Vy", "Đỗ Gia Hân", "Hồ Tuấn Kiệt", "Ngô Khánh Linh", "Dương Nhật Minh", "Lý Phương Anh", "Mai Thanh Tùng", "Đinh Bảo Ngọc", "Tạ Hải Đăng", "Phan Quỳnh Như", "Cao Minh Khang", "Vũ Thanh Trúc", "Trịnh Đức Anh" };
        var nguoi = new List<TaiKhoan>();
        for (var i = 0; i < 19; i++)
        {
            var tk = new TaiKhoan { Email = $"nguoi{i + 1:00}@mau20.example", HoTen = ten[i], Loai = i < 8 ? "NhaTuyenDung" : "UngVien" };
            tk.MatKhauBam = bam.HashPassword(tk, matKhau); nguoi.Add(tk); db.Add(tk);
        }
        await db.SaveChangesAsync();
        var tenDn = new[] { "Công nghệ Ánh Dương", "Thương mại Minh An", "Thiết kế Sao Việt", "Giải pháp Hưng Thịnh", "Truyền thông Phương Nam" };
        var dns = new List<DoanhNghiep>();
        for (var i = 0; i < 5; i++)
        {
            var dn = new DoanhNghiep { Ten = tenDn[i], MaSoThue = $"MAU20-{i + 1:00}", DiaChi = "TP. Hồ Chí Minh — địa chỉ minh họa",
                GioiThieu = "Doanh nghiệp minh họa dùng kiểm thử, không phải thông tin doanh nghiệp thật.",
                NguoiPhuTrachId = nguoi[i].Id, TrangThai = i < 3 ? "DaDuyet" : "ChoDuyet", DaCapMienPhi = i < 3 };
            db.Add(dn); dns.Add(dn); nguoi[i].DoanhNghiepId = dn.Id;
            if (i < 3) phien.GhiLuot(dn, qt.Id, dn.Id, "MienPhiLanDau", 3, 0, 0);
        }
        for (var i = 5; i < 8; i++) nguoi[i].DoanhNghiepId = dns[i - 5].Id;
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
            for (var i = 0; i < 3; i++)
            {
                var luot = new[] { 1, 5, 10 }[i];
                var tep = new Tep { ChuSoHuuId = qt.Id, Ten = $"goi-{luot}.png", Loai = "Anh", Mime = "image/png" };
                tep.DuongDan = Path.Combine(kho, tep.Id + ".png");
                File.Copy(Path.Combine(goc, "DuLieuMau", "anh", $"goi-{luot}.png"), tep.DuongDan);
                tepMoi.Add(tep.DuongDan); db.Add(tep);
                var goi = new GoiLuot { Ten = $"Gói {luot} lượt đăng tin", DanhMucId = dichVu.Id, AnhId = tep.Id, SoLuot = luot, Gia = new[] { 20000m, 90000m, 160000m }[i], MoTa = "Gói minh họa; xác nhận thanh toán ở chế độ trình diễn." };
                db.Add(goi); gois.Add(goi);
            }
            for (var i = 0; i < 5; i++)
            {
                var j = i % 3; var g = gois[j]; var dn = dns[j];
                var ngay = DateTime.UtcNow.AddMonths(i - 4).AddDays(-1);
                var don = new DonHang { Ma = $"DH-MAU20-{i + 1:00}", DoanhNghiepId = dn.Id, NguoiMuaId = nguoi[j].Id,
                    KhoaLap = $"mau20-don-{i + 1}", TrangThai = i < 3 ? "DaThanhToan" : "ChoThanhToan",
                    TongTien = g.Gia, TongLuot = g.SoLuot, TaoLuc = i < 3 ? ngay : DateTime.UtcNow.AddMinutes(-i),
                    XacNhanLuc = i < 3 ? ngay : null, NguoiXacNhanId = i < 3 ? qt.Id : null };
                don.ChiTiet.Add(new ChiTietDon { GoiLuotId = g.Id, TenGoi = g.Ten, SoLuong = 1, SoLuot = g.SoLuot, DonGia = g.Gia });
                db.Add(don);
                if (i < 3) phien.GhiLuot(dn, qt.Id, don.Id, "MuaLuot", g.SoLuot, 0, 0);
            }
            var tieuDe = new[] { "Lập trình viên Flutter", "Nhân viên kinh doanh", "Chuyên viên thiết kế", "Lập trình viên C# ASP.NET Core" };
            for (var i = 0; i < 4; i++)
            {
                var j = i % 3; var dn = dns[j];
                var tin = new TinTuyenDung { TieuDe = tieuDe[i], DoanhNghiepId = dn.Id, NguoiTaoId = nguoi[j].Id, NganhId = nganh[j].Id,
                    DiaDiem = "TP. Hồ Chí Minh", KinhNghiem = "Dưới 1 năm", TrinhDo = "Cao đẳng/Đại học", SoNguoi = 2,
                    LuongMin = 10000000, LuongMax = 18000000, MoTa = "Tin tuyển dụng minh họa cho kiểm thử ứng dụng.",
                    YeuCau = "Có kỹ năng phù hợp với vị trí.", QuyenLoi = "Đào tạo và phát triển kỹ năng.",
                    TrangThai = "DangTuyen", HanNhan = DateTime.UtcNow.AddDays(45) };
                db.Add(tin); phien.GhiLuot(dn, nguoi[j].Id, tin.Id, "GiuLuot", -1, 1, 0);
                phien.GhiLuot(dn, qt.Id, tin.Id, "SuDungLuot", 0, -1, 1);
            }
            await db.SaveChangesAsync();
            PhienLamViec.KiemTra(await db.TaiKhoan.CountAsync() == 20 && await db.DoanhNghiep.CountAsync() == 5 && await db.DonHang.CountAsync() == 5 && await db.Tin.CountAsync() == 4, "Số lượng mẫu không đúng, hủy giao dịch.");
            await tx.CommitAsync();
            Console.WriteLine("Đã tạo: 20 tài khoản (1 quản trị, 8 nhà tuyển dụng, 11 ứng viên); 3 doanh nghiệp hoạt động, 2 chờ duyệt; 5 đơn (3 đã thanh toán, 2 chờ); 4 tin đang tuyển.");
            Console.WriteLine("Quản trị: quantri@mau20.example. Thành viên: nguoi01@mau20.example đến nguoi19@mau20.example. Mật khẩu là giá trị bạn vừa nhập.");
        }
        catch
        {
            foreach (var t in tepMoi) if (File.Exists(t)) File.Delete(t);
            throw;
        }
    }
}
