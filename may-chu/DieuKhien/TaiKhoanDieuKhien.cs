using MayChu.DuLieu;
using MayChu.NghiepVu;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Cryptography;
using static MayChu.NghiepVu.PhienLamViec;
namespace MayChu.DieuKhien;

public record DangKy(string Email, string HoTen, string MatKhau, string Loai);
public record DangNhap(string Email, string MatKhau);
public record DoiMatKhau(string MatKhauCu, string MatKhauMoi);
public record SuaCaNhan(string HoTen, string HoSoJson);
public record SuaQuyen(bool BiKhoa, string VaiTro);
[ApiController, Route("api/v1/tai-khoan")]
public class TaiKhoanDieuKhien(KhoDuLieu db, PhienLamViec phien, PasswordHasher<TaiKhoan> bam) : ControllerBase
{
    [HttpPost("dang-ky")]
    public async Task<object> Tao(DangKy d)
    {
        var email = d.Email.Trim().ToLowerInvariant();
        KiemTra(System.Net.Mail.MailAddress.TryCreate(email, out var diaChiEmail) && email.Length <= 254 && diaChiEmail.Address.Equals(email, StringComparison.OrdinalIgnoreCase), "Email không hợp lệ.");
        KiemTra(d.MatKhau.Length is >= 8 and <= 128, "Mật khẩu cần 8–128 ký tự.");
        KiemTra(!string.IsNullOrWhiteSpace(d.HoTen), "Nhập họ tên.");
        KiemTra(d.Loai is "UngVien" or "NhaTuyenDung", "Loại thành viên không hợp lệ.");
        KiemTra(!await db.TaiKhoan.AnyAsync(x => x.Email == email), "Email đã được đăng ký.", 409);
        var tk = new TaiKhoan { Email = email, HoTen = d.HoTen.Trim(), Loai = d.Loai };
        tk.MatKhauBam = bam.HashPassword(tk, d.MatKhau);
        db.Add(tk);
        await db.SaveChangesAsync();
        return CongKhai(tk);
    }
    [HttpPost("dang-nhap")]
    public async Task<object> Vao(DangNhap d)
    {
        var tk = await db.TaiKhoan.SingleOrDefaultAsync(x => x.Email == d.Email.Trim().ToLowerInvariant());
        KiemTra(tk != null && !tk.BiKhoa && bam.VerifyHashedPassword(tk, tk.MatKhauBam, d.MatKhau) != PasswordVerificationResult.Failed, "Email hoặc mật khẩu không đúng, hoặc tài khoản đã khóa.", 401);
        var ma = Convert.ToHexString(RandomNumberGenerator.GetBytes(32));
        db.Phien.Add(new()
        {
            TaiKhoanId = tk!.Id,
            MaBam = Bam(ma),
            HetHan = DateTime.UtcNow.AddDays(7)
        });
        await db.SaveChangesAsync();
        return new
        {
            maTruyCap = ma,
            taiKhoan = CongKhai(tk)
        };
    }
    [HttpGet("toi")] public async Task<object> Toi() => CongKhai(await phien.Nguoi(Request));
    [HttpPut("toi")]
    public async Task<object> Sua(SuaCaNhan d)
    {
        var tk = await phien.Nguoi(Request);
        KiemTra(!string.IsNullOrWhiteSpace(d.HoTen), "Nhập họ tên.");
        KiemTra(d.HoSoJson.Length <= 50000, "Hồ sơ quá dài.");
        try
        {
            using var hoSo = System.Text.Json.JsonDocument.Parse(d.HoSoJson);
            KiemTra(hoSo.RootElement.ValueKind == System.Text.Json.JsonValueKind.Object, "Hồ sơ không hợp lệ.");
        }
        catch (System.Text.Json.JsonException) { throw new LoiNghiepVu("Hồ sơ không hợp lệ."); }
        tk.HoTen = d.HoTen.Trim();
        tk.HoSoJson = d.HoSoJson;
        await db.SaveChangesAsync();
        return CongKhai(tk);
    }
    [HttpPost("doi-mat-khau")]
    public async Task<object> Doi(DoiMatKhau d)
    {
        var tk = await phien.Nguoi(Request);
        KiemTra(bam.VerifyHashedPassword(tk, tk.MatKhauBam, d.MatKhauCu) != PasswordVerificationResult.Failed, "Mật khẩu hiện tại không đúng.");
        KiemTra(d.MatKhauMoi.Length is >= 8 and <= 128, "Mật khẩu mới cần 8–128 ký tự.");
        tk.MatKhauBam = bam.HashPassword(tk, d.MatKhauMoi);
        db.Phien.RemoveRange(await db.Phien.Where(x => x.TaiKhoanId == tk.Id).ToListAsync());
        await db.SaveChangesAsync();
        return new
        {
            thongBao = "Đã đổi mật khẩu. Vui lòng đăng nhập lại."
        };
    }
    [HttpPost("dang-xuat")]
    public async Task<object> Ra()
    {
        var tk = await phien.Nguoi(Request);
        var ma = Bam(Request.Headers.Authorization.ToString()[7..]);
        db.Phien.RemoveRange(await db.Phien.Where(x => x.TaiKhoanId == tk.Id && x.MaBam == ma).ToListAsync());
        await db.SaveChangesAsync();
        return new
        {
            thongBao = "Đã đăng xuất."
        };
    }
    [HttpGet]
    public async Task<object> DanhSach(string? q, int trang = 1)
    {
        await phien.Nguoi(Request, "QuanTri");
        return await Trang(db.TaiKhoan.Where(x => q == null || x.HoTen.Contains(q) || x.Email.Contains(q)).OrderByDescending(x => x.TaoLuc).Select(x => new { x.Id, x.Email, x.HoTen, x.VaiTro, x.Loai, x.BiKhoa }), trang, 20);
    }
    [HttpPut("{id:guid}/quyen")]
    public async Task<object> Quyen(Guid id, SuaQuyen d)
    {
        var qt = await phien.Nguoi(Request, "QuanTri");
        KiemTra(id != qt.Id, "Không tự khóa hoặc đổi quyền của mình.");
        KiemTra(d.VaiTro is "ThanhVien" or "QuanTri", "Vai trò không hợp lệ.");
        var tk = await db.TaiKhoan.FindAsync(id) ?? throw new LoiNghiepVu("Không tìm thấy tài khoản.", 404);
        tk.BiKhoa = d.BiKhoa;
        tk.VaiTro = d.VaiTro;
        db.Phien.RemoveRange(await db.Phien.Where(x => x.TaiKhoanId == id).ToListAsync());
        await db.SaveChangesAsync();
        return CongKhai(tk);
    }
}

