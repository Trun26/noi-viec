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
        var doanhNghiepMau = await db.DoanhNghiep.SingleOrDefaultAsync(x => x.MaSoThue == "DU-LIEU-MAU-MOBI");
        if (doanhNghiepMau != null)
        {
            var quanTriMau = await db.TaiKhoan.FirstOrDefaultAsync(x => x.VaiTro == "QuanTri")
                ?? throw new LoiNghiepVu("H\u00e3y t\u1ea1o t\u00e0i kho\u1ea3n qu\u1ea3n tr\u1ecb tr\u01b0\u1edbc khi b\u1ed5 sung d\u1eef li\u1ec7u m\u1eabu.");
            var nhaTuyenDungMau = await db.TaiKhoan.SingleOrDefaultAsync(x => x.Email == "tuyendung@mobi.example")
                ?? throw new LoiNghiepVu("Kh\u00f4ng t\u00ecm th\u1ea5y t\u00e0i kho\u1ea3n nh\u00e0 tuy\u1ec3n d\u1ee5ng m\u1eabu.");
            await BoSungTinTuyenDungMau(db, phien, doanhNghiepMau, nhaTuyenDungMau, quanTriMau);
            await db.SaveChangesAsync();
            await tx.CommitAsync();
            return;
        }
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
            await BoSungTinTuyenDungMau(db, phien, dn, ntd, qt);
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

    private sealed record MauTin(string TieuDe, string Nganh, string Noi, string HinhThuc,
        string KinhNghiem, int SoNguoi, decimal Min, decimal Max, string MoTa, string YeuCau, string QuyenLoi);

    private static async Task BoSungTinTuyenDungMau(KhoDuLieu db, PhienLamViec phien, DoanhNghiep dn, TaiKhoan ntd, TaiKhoan qt)
    {
        var cacTin = new[]
        {
            new MauTin("L\u1eadp tr\u00ecnh vi\u00ean Flutter \u2014 V\u1eca TR\u00cd M\u1eaaU", "C\u00f4ng ngh\u1ec7 th\u00f4ng tin", "TP. H\u1ed3 Ch\u00ed Minh", "ToanThoiGian", "1\u20133 n\u0103m", 2, 18000000m, 30000000m,
                "Ph\u00e1t tri\u1ec3n \u1ee9ng d\u1ee5ng Flutter cho s\u1ea3n ph\u1ea9m di \u0111\u1ed9ng. Ph\u1ed1i h\u1ee3p v\u1edbi thi\u1ebft k\u1ebf v\u00e0 backend \u0111\u1ec3 ho\u00e0n thi\u1ec7n t\u00ednh n\u0103ng, c\u1ea3i thi\u1ec7n hi\u1ec7u n\u0103ng v\u00e0 ch\u1ea5t l\u01b0\u1ee3ng ph\u00e1t h\u00e0nh.",
                "C\u00f3 kinh nghi\u1ec7m Flutter, Dart, REST API v\u00e0 qu\u1ea3n l\u00fd tr\u1ea1ng th\u00e1i. Bi\u1ebft vi\u1ebft ki\u1ec3m th\u1eed v\u00e0 s\u1eed d\u1ee5ng Git l\u00e0 l\u1ee3i th\u1ebf.",
                "L\u01b0\u01a1ng theo n\u0103ng l\u1ef1c, thi\u1ebft b\u1ecb l\u00e0m vi\u1ec7c, ng\u00e2n s\u00e1ch h\u1ecdc t\u1eadp v\u00e0 \u0111\u00e1nh gi\u00e1 l\u01b0\u01a1ng \u0111\u1ecbnh k\u1ef3."),
            new MauTin("K\u1ef9 s\u01b0 Backend .NET \u2014 V\u1eca TR\u00cd M\u1eaaU", "C\u00f4ng ngh\u1ec7 th\u00f4ng tin", "TP. H\u1ed3 Ch\u00ed Minh", "ToanThoiGian", "2\u20134 n\u0103m", 2, 22000000m, 36000000m,
                "Thi\u1ebft k\u1ebf API b\u1eb1ng ASP.NET Core, l\u00e0m vi\u1ec7c v\u1edbi SQL Server v\u00e0 t\u1ed1i \u01b0u truy v\u1ea5n. Ph\u1ed1i h\u1ee3p tri\u1ec3n khai d\u1ecbch v\u1ee5 qua Docker v\u00e0 CI/CD.",
                "N\u1eafm v\u1eefng C#, ASP.NET Core, REST, SQL v\u00e0 b\u1ea3o m\u1eadt API. C\u00f3 t\u01b0 duy ki\u1ec3m th\u1eed v\u00e0 x\u1eed l\u00fd s\u1ef1 c\u1ed1.",
                "Th\u01b0\u1edfng theo hi\u1ec7u qu\u1ea3, b\u1ea3o hi\u1ec3m \u0111\u1ea7y \u0111\u1ee7 v\u00e0 l\u1ed9 tr\u00ecnh ph\u00e1t tri\u1ec3n k\u1ef9 thu\u1eadt."),
            new MauTin("Chuy\u00ean vi\u00ean thi\u1ebft k\u1ebf UI/UX \u2014 V\u1eca TR\u00cd M\u1eaaU", "Thi\u1ebft k\u1ebf & s\u00e1ng t\u1ea1o", "TP. H\u1ed3 Ch\u00ed Minh", "ToanThoiGian", "1\u20133 n\u0103m", 1, 16000000m, 26000000m,
                "Nghi\u00ean c\u1ee9u nhu c\u1ea7u ng\u01b0\u1eddi d\u00f9ng, thi\u1ebft k\u1ebf lu\u1ed3ng thao t\u00e1c v\u00e0 giao di\u1ec7n \u1ee9ng d\u1ee5ng, website. B\u00e0n giao thi\u1ebft k\u1ebf r\u00f5 r\u00e0ng cho nh\u00f3m ph\u00e1t tri\u1ec3n.",
                "S\u1eed d\u1ee5ng Figma, c\u00f3 portfolio th\u1ef1c t\u1ebf, hi\u1ec3u responsive v\u00e0 kh\u1ea3 n\u0103ng ti\u1ebfp c\u1eadn.",
                "Tham gia c\u00f9ng nh\u00f3m s\u1ea3n ph\u1ea9m t\u1eeb kh\u00e2u \u00fd t\u01b0\u1edfng, c\u00f3 ng\u00e2n s\u00e1ch h\u1ecdc t\u1eadp."),
            new MauTin("Chuy\u00ean vi\u00ean Digital Marketing \u2014 V\u1eca TR\u00cd M\u1eaaU", "Marketing", "TP. H\u1ed3 Ch\u00ed Minh", "ToanThoiGian", "1\u20133 n\u0103m", 1, 15000000m, 25000000m,
                "L\u1eadp k\u1ebf ho\u1ea1ch chi\u1ebfn d\u1ecbch s\u1ed1, theo d\u00f5i hi\u1ec7u qu\u1ea3, t\u1ed1i \u01b0u qu\u1ea3ng c\u00e1o v\u00e0 ph\u1ed1i h\u1ee3p v\u1edbi nh\u00f3m n\u1ed9i dung \u0111\u1ec3 t\u0103ng nh\u1eadn di\u1ec7n s\u1ea3n ph\u1ea9m.",
                "C\u00f3 kinh nghi\u1ec7m qu\u1ea3ng c\u00e1o s\u1ed1, ph\u00e2n t\u00edch d\u1eef li\u1ec7u v\u00e0 l\u1eadp b\u00e1o c\u00e1o. Bi\u1ebft Google Analytics l\u00e0 l\u1ee3i th\u1ebf.",
                "Th\u01b0\u1edfng KPI, m\u00f4i tr\u01b0\u1eddng s\u00e1ng t\u1ea1o v\u00e0 \u0111\u01b0\u1ee3c ch\u1ee7 \u0111\u1ed9ng th\u1eed nghi\u1ec7m \u00fd t\u01b0\u1edfng."),
            new MauTin("Nh\u00e2n vi\u00ean s\u00e1ng t\u1ea1o n\u1ed9i dung \u2014 V\u1eca TR\u00cd M\u1eaaU", "Marketing", "L\u00e0m vi\u1ec7c t\u1eeb xa", "TuXa", "D\u01b0\u1edbi 1 n\u0103m", 2, 12000000m, 19000000m,
                "Vi\u1ebft b\u00e0i website v\u00e0 m\u1ea1ng x\u00e3 h\u1ed9i, x\u00e2y d\u1ef1ng l\u1ecbch n\u1ed9i dung v\u00e0 ph\u1ed1i h\u1ee3p s\u1ea3n xu\u1ea5t h\u00ecnh \u1ea3nh, video cho c\u00e1c chi\u1ebfn d\u1ecbch.",
                "Vi\u1ebft ti\u1ebfng Vi\u1ec7t t\u1ed1t, bi\u1ebft t\u00ecm hi\u1ec3u ch\u1ee7 \u0111\u1ec1 v\u00e0 \u0111i\u1ec1u ch\u1ec9nh gi\u1ecdng v\u0103n. C\u00f3 s\u1ea3n ph\u1ea9m m\u1eabu ho\u1eb7c portfolio.",
                "L\u00e0m vi\u1ec7c t\u1eeb xa, gi\u1edd linh ho\u1ea1t, \u0111\u01b0\u1ee3c h\u01b0\u1edbng d\u1eabn v\u00e0 th\u01b0\u1edfng theo ch\u1ea5t l\u01b0\u1ee3ng."),
            new MauTin("Chuy\u00ean vi\u00ean kinh doanh B2B \u2014 V\u1eca TR\u00cd M\u1eaaU", "Kinh doanh & b\u00e1n h\u00e0ng", "TP. H\u1ed3 Ch\u00ed Minh", "ToanThoiGian", "1\u20133 n\u0103m", 2, 14000000m, 28000000m,
                "T\u01b0 v\u1ea5n kh\u00e1ch h\u00e0ng doanh nghi\u1ec7p, gi\u1edbi thi\u1ec7u gi\u1ea3i ph\u00e1p tuy\u1ec3n d\u1ee5ng, ch\u0103m s\u00f3c c\u01a1 h\u1ed9i b\u00e1n h\u00e0ng v\u00e0 theo d\u00f5i h\u1ee3p \u0111\u1ed3ng.",
                "Giao ti\u1ebfp t\u1ed1t, y\u00eau th\u00edch kinh doanh v\u00e0 theo s\u00e1t m\u1ee5c ti\u00eau. Kinh nghi\u1ec7m B2B l\u00e0 l\u1ee3i th\u1ebf.",
                "L\u01b0\u01a1ng c\u1ee9ng c\u1ed9ng hoa h\u1ed3ng, th\u01b0\u1edfng doanh s\u1ed1 v\u00e0 h\u1ed7 tr\u1ee3 chi ph\u00ed g\u1eb7p kh\u00e1ch h\u00e0ng."),
            new MauTin("K\u1ebf to\u00e1n t\u1ed5ng h\u1ee3p \u2014 V\u1eca TR\u00cd M\u1eaaU", "K\u1ebf to\u00e1n", "TP. H\u1ed3 Ch\u00ed Minh", "ToanThoiGian", "2\u20134 n\u0103m", 1, 16000000m, 24000000m,
                "Theo d\u00f5i ch\u1ee9ng t\u1eeb, c\u00f4ng n\u1ee3 v\u00e0 d\u00f2ng ti\u1ec1n; l\u1eadp b\u00e1o c\u00e1o \u0111\u1ecbnh k\u1ef3; ph\u1ed1i h\u1ee3p chu\u1ea9n b\u1ecb h\u1ed3 s\u01a1 thu\u1ebf v\u00e0 ki\u1ec3m to\u00e1n.",
                "T\u1ed1t nghi\u1ec7p chuy\u00ean ng\u00e0nh k\u1ebf to\u00e1n, n\u1eafm nghi\u1ec7p v\u1ee5 thu\u1ebf v\u00e0 d\u00f9ng th\u00e0nh th\u1ea1o Excel. C\u1ea9n th\u1eadn, b\u1ea3o m\u1eadt s\u1ed1 li\u1ec7u.",
                "\u0110\u1ea7y \u0111\u1ee7 b\u1ea3o hi\u1ec3m, ph\u1ee5 c\u1ea5p \u0103n tr\u01b0a v\u00e0 th\u01b0\u1edfng cu\u1ed1i n\u0103m."),
            new MauTin("Chuy\u00ean vi\u00ean ch\u0103m s\u00f3c kh\u00e1ch h\u00e0ng \u2014 V\u1eca TR\u00cd M\u1eaaU", "Kinh doanh & b\u00e1n h\u00e0ng", "\u0110\u00e0 N\u1eb5ng", "ToanThoiGian", "D\u01b0\u1edbi 1 n\u0103m", 2, 11000000m, 17000000m,
                "Ti\u1ebfp nh\u1eadn c\u00e2u h\u1ecfi qua \u0111i\u1ec7n tho\u1ea1i v\u00e0 k\u00eanh tr\u1ef1c tuy\u1ebfn, h\u01b0\u1edbng d\u1eabn s\u1eed d\u1ee5ng d\u1ecbch v\u1ee5, ghi nh\u1eadn ph\u1ea3n h\u1ed3i v\u00e0 ph\u1ed1i h\u1ee3p x\u1eed l\u00fd y\u00eau c\u1ea7u.",
                "Giao ti\u1ebfp r\u00f5 r\u00e0ng, ki\u00ean nh\u1eabn, s\u1eed d\u1ee5ng c\u00f4ng c\u1ee5 v\u0103n ph\u00f2ng v\u00e0 s\u1eb5n s\u00e0ng h\u1ecdc quy tr\u00ecnh.",
                "\u0110\u01b0\u1ee3c \u0111\u00e0o t\u1ea1o c\u00f3 l\u01b0\u01a1ng, ph\u1ee5 c\u1ea5p ca v\u00e0 l\u1ed9 tr\u00ecnh l\u00ean tr\u01b0\u1edfng nh\u00f3m."),
            new MauTin("Chuy\u00ean vi\u00ean tuy\u1ec3n d\u1ee5ng n\u1ed9i b\u1ed9 \u2014 V\u1eca TR\u00cd M\u1eaaU", "Nh\u00e2n s\u1ef1", "TP. H\u1ed3 Ch\u00ed Minh", "ToanThoiGian", "1\u20133 n\u0103m", 1, 15000000m, 23000000m,
                "Ti\u1ebfp nh\u1eadn nhu c\u1ea7u tuy\u1ec3n d\u1ee5ng, \u0111\u0103ng tin, s\u00e0ng l\u1ecdc h\u1ed3 s\u01a1, s\u1eafp x\u1ebfp ph\u1ecfng v\u1ea5n v\u00e0 ph\u1ed1i h\u1ee3p n\u00e2ng cao tr\u1ea3i nghi\u1ec7m \u1ee9ng vi\u00ean.",
                "C\u00f3 k\u1ef9 n\u0103ng ph\u1ecfng v\u1ea5n, giao ti\u1ebfp v\u00e0 qu\u1ea3n l\u00fd nhi\u1ec1u v\u1ecb tr\u00ed. Bi\u1ebft h\u1ec7 th\u1ed1ng theo d\u00f5i \u1ee9ng vi\u00ean l\u00e0 l\u1ee3i th\u1ebf.",
                "Th\u01b0\u1edfng tuy\u1ec3n d\u1ee5ng, ng\u00e2n s\u00e1ch h\u1ecdc t\u1eadp v\u00e0 c\u01a1 h\u1ed9i x\u00e2y d\u1ef1ng quy tr\u00ecnh nh\u00e2n s\u1ef1.")
        };

        var nganhDaDoc = new Dictionary<string, Guid>(StringComparer.Ordinal);
        async Task<Guid> NganhId(string ten)
        {
            var tenChuan = ten.ToUpperInvariant();
            if (nganhDaDoc.TryGetValue(tenChuan, out var id))
                return id;
            var dm = await db.DanhMuc.SingleOrDefaultAsync(x => x.TenChuan == tenChuan && x.Loai == "NganhNghe");
            if (dm == null)
            {
                dm = new DanhMuc { Ten = ten, TenChuan = tenChuan, Loai = "NganhNghe", MoTa = "Ng\u00e0nh ngh\u1ec1 cho d\u1eef li\u1ec7u tuy\u1ec3n d\u1ee5ng m\u1eabu." };
                db.DanhMuc.Add(dm);
            }
            nganhDaDoc[tenChuan] = dm.Id;
            return dm.Id;
        }

        foreach (var mau in cacTin)
        {
            if (await db.Tin.AnyAsync(x => x.TieuDe == mau.TieuDe))
                continue;
            var tin = new TinTuyenDung
            {
                DoanhNghiepId = dn.Id,
                NguoiTaoId = ntd.Id,
                NganhId = await NganhId(mau.Nganh),
                TieuDe = mau.TieuDe,
                DiaDiem = mau.Noi,
                HinhThuc = mau.HinhThuc,
                KinhNghiem = mau.KinhNghiem,
                TrinhDo = "Cao \u0111\u1eb3ng/\u0110\u1ea1i h\u1ecdc",
                SoNguoi = mau.SoNguoi,
                LuongMin = mau.Min,
                LuongMax = mau.Max,
                MoTa = mau.MoTa + "\n\nTin m\u1eabu trong m\u00f4i tr\u01b0\u1eddng demo N\u1ed1i Vi\u1ec7c.",
                YeuCau = mau.YeuCau,
                QuyenLoi = mau.QuyenLoi,
                HanNhan = DateTime.UtcNow.AddDays(30),
                TrangThai = "DangTuyen"
            };
            db.Tin.Add(tin);
            phien.GhiLuot(dn, qt.Id, tin.Id, "DuLieuMau", 1, 0, 0);
            phien.GhiLuot(dn, ntd.Id, tin.Id, "GiuLuot", -1, 1, 0);
            phien.GhiLuot(dn, qt.Id, tin.Id, "SuDungLuot", 0, -1, 1);
        }
    }

}
