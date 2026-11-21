using System.Data;
using MayChu.DuLieu;
using MayChu.NghiepVu;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace MayChu.DuLieuMau;

public static class TaoDuLieuMau
{
    public static async Task Tao(KhoDuLieu db, PasswordHasher<TaiKhoan> bam,
        PhienLamViec phien, string goc, string matKhau)
    {
        if (matKhau.Length < 12)
            throw new LoiNghiepVu("Mật khẩu tài khoản mẫu cần ít nhất 12 ký tự.");
        await using var tx = await db.Database.BeginTransactionAsync(IsolationLevel.Serializable);
        if (await db.DoanhNghiep.AnyAsync(x => x.MaSoThue == "DU-LIEU-MAU-MOBI"))
            return;
        var qt = await db.TaiKhoan.FirstOrDefaultAsync(x => x.VaiTro == "QuanTri")
            ?? throw new LoiNghiepVu("Hãy tạo tài khoản quản trị trước khi tạo dữ liệu mẫu.");
        if (await db.TaiKhoan.AnyAsync(x => x.Email == "tuyendung@mobi.example" || x.Email == "ungvien@mobi.example"))
            throw new LoiNghiepVu("Email mẫu đã tồn tại. Không ghi đè tài khoản có sẵn.");

        var ntd = new TaiKhoan { Email = "tuyendung@mobi.example", HoTen = "Nhà tuyển dụng MẪU", Loai = "NhaTuyenDung" };
        var uv = new TaiKhoan
        {
            Email = "ungvien@mobi.example",
            HoTen = "Ứng viên MẪU",
            Loai = "UngVien",
            HoSoJson = "{\"gioiThieu\":\"Hồ sơ minh họa, không phải thông tin cá nhân thật.\",\"kyNang\":\"Flutter, C#, SQL Server\"}"
        };
        ntd.MatKhauBam = bam.HashPassword(ntd, matKhau);
        uv.MatKhauBam = bam.HashPassword(uv, matKhau);
        db.AddRange(ntd, uv);
        await db.SaveChangesAsync();
        var dn = new DoanhNghiep
        {
            Ten = "Mobi Studio — DOANH NGHIỆP MẪU",
            MaSoThue = "DU-LIEU-MAU-MOBI",
            DiaChi = "TP. Hồ Chí Minh — địa chỉ minh họa",
            GioiThieu = "Doanh nghiệp minh họa phục vụ bài tập tuyển dụng.",
            NguoiPhuTrachId = ntd.Id,
            TrangThai = "DaDuyet",
            DaCapMienPhi = true
        };
        db.Add(dn);
        ntd.DoanhNghiepId = dn.Id;
        phien.GhiLuot(dn, qt.Id, dn.Id, "MienPhiLanDau", 3, 0, 0);

        async Task<DanhMuc> Nhom(string ten, string loai)
        {
            var chuan = ten.ToUpperInvariant();
            var cu = await db.DanhMuc.SingleOrDefaultAsync(x => x.TenChuan == chuan && x.Loai == loai);
            if (cu != null)
                return cu;
            var dm = new DanhMuc { Ten = ten, TenChuan = chuan, Loai = loai, MoTa = "Danh mục minh họa cho bài tập." };
            db.Add(dm);
            return dm;
        }
        var nhom = new[] { await Nhom("Đăng tin cơ bản", "DichVu"), await Nhom("Gói tiết kiệm", "DichVu"), await Nhom("Tuyển dụng theo đợt", "DichVu") };
        var nganh = await Nhom("Công nghệ thông tin", "NganhNghe");
        await Nhom("Kinh doanh & bán hàng", "NganhNghe");
        await Nhom("Thiết kế & sáng tạo", "NganhNghe");
        var khoTep = Path.Combine(goc, "kho-tep");
        Directory.CreateDirectory(khoTep);
        var tepMoi = new List<string>();
        try
        {
            for (var i = 0; i < 15; i++)
            {
                var bac = i % 3;
                var soLuot = new[] { 1, 5, 10 }[bac];
                var ten = i < 3 ? new[] { "Cơ bản", "Tiết kiệm", "Theo đợt" }[bac] : $"Gói tuyển dụng {i + 1:00}";
                var tep = new Tep { ChuSoHuuId = qt.Id, Ten = $"goi-{i + 1:00}.png", Loai = "Anh", Mime = "image/png" };
                tep.DuongDan = Path.Combine(khoTep, tep.Id + ".png");
                File.Copy(Path.Combine(goc, "DuLieuMau", "anh", $"goi-{soLuot}.png"), tep.DuongDan);
                tepMoi.Add(tep.DuongDan);
                db.Add(tep);
                db.Add(new GoiLuot
                {
                    Ten = ten,
                    MoTa = $"DỮ LIỆU MẪU — {soLuot} lượt đăng tin. Lượt thuộc doanh nghiệp, quản trị xác nhận đơn trong chế độ trình diễn.",
                    AnhId = tep.Id,
                    DanhMucId = nhom[bac].Id,
                    SoLuot = soLuot,
                    Gia = new[] { 20000m, 90000m, 160000m }[bac],
                    TaoLuc = DateTime.UtcNow.AddMinutes(-i)
                });
            }
            foreach (var ten in new[] { "Lập trình viên Flutter", "Lập trình viên C# ASP.NET Core" })
            {
                var tin = new TinTuyenDung
                {
                    DoanhNghiepId = dn.Id,
                    NguoiTaoId = ntd.Id,
                    NganhId = nganh.Id,
                    TieuDe = ten + " — TIN MẪU",
                    DiaDiem = "TP. Hồ Chí Minh",
                    KinhNghiem = "Dưới 1 năm",
                    TrinhDo = "Cao đẳng/Đại học",
                    SoNguoi = 2,
                    LuongMin = 10000000,
                    LuongMax = 18000000,
                    MoTa = "Phát triển ứng dụng và phối hợp cùng nhóm. Đây là nội dung minh họa, không phải lời mời tuyển dụng thật.",
                    YeuCau = "Có kiến thức lập trình, cơ sở dữ liệu và Git.",
                    QuyenLoi = "Môi trường học hỏi và phát triển kỹ năng (minh họa).",
                    HanNhan = DateTime.UtcNow.AddDays(30),
                    TrangThai = "DangTuyen"
                };
                db.Add(tin);
                phien.GhiLuot(dn, ntd.Id, tin.Id, "GiuLuot", -1, 1, 0);
                phien.GhiLuot(dn, qt.Id, tin.Id, "SuDungLuot", 0, -1, 1);
            }
            await db.SaveChangesAsync();
            await tx.CommitAsync();
        }
        catch
        {
            foreach (var tep in tepMoi)
                if (File.Exists(tep))
                    File.Delete(tep);
            throw;
        }
    }
}
