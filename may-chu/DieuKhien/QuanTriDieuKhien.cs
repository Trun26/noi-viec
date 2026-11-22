using MayChu.DuLieu;
using MayChu.NghiepVu;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using static MayChu.NghiepVu.PhienLamViec;
namespace MayChu.DieuKhien;

public record QuanTriSuaNguoi(string Email, string HoTen, string Loai, string VaiTro, bool BiKhoa, Guid? DoanhNghiepId, string? MatKhau);
[ApiController, Route("api/v1/quan-tri")]
public class QuanTriDieuKhien(KhoDuLieu db, PhienLamViec phien, PasswordHasher<TaiKhoan> bam) : ControllerBase
{
    [HttpGet("tong-quan")]
    public async Task<object> TongQuan()
    {
        await phien.Nguoi(Request, "QuanTri");
        var nay = DateTime.UtcNow;
        var dau = new DateTime(nay.Year, nay.Month, 1, 0, 0, 0, DateTimeKind.Utc).AddMonths(-5);
        var cuoi = dau.AddMonths(6);
        var doanhThu = await db.DonHang.Where(x => x.TrangThai == "DaThanhToan" && x.XacNhanLuc >= dau && x.XacNhanLuc < cuoi)
            .GroupBy(x => new { x.XacNhanLuc!.Value.Year, x.XacNhanLuc.Value.Month })
            .Select(g => new { Nam = g.Key.Year, Thang = g.Key.Month, Tien = g.Sum(x => x.TongTien) }).ToListAsync();
        return new {
            nguoiDung = await db.TaiKhoan.CountAsync(),
            doanhNghiep = await db.DoanhNghiep.CountAsync(x => x.TrangThai == "DaDuyet"),
            donMoi = await db.DonHang.CountAsync(x => x.TrangThai == "ChoThanhToan"),
            tinDang = await db.Tin.CountAsync(x => x.TrangThai == "DangTuyen" && x.HanNhan > nay && db.DoanhNghiep.Any(d => d.Id == x.DoanhNghiepId && d.TrangThai == "DaDuyet")),
            doanhThu = Enumerable.Range(0, 6).Select(i => {
                var thang = dau.AddMonths(i);
                return new { nhan = thang.ToString("MM/yyyy"), tien = doanhThu.FirstOrDefault(x => x.Nam == thang.Year && x.Thang == thang.Month)?.Tien ?? 0m };
            }).ToList()
        };
    }
    [HttpGet("nguoi-dung")]
    public async Task<object> DanhSach(string? q, string? nhom, int trang = 1)
    {
        await phien.Nguoi(Request, "QuanTri");
        var ds = db.TaiKhoan.AsQueryable();
        if (!string.IsNullOrWhiteSpace(q)) ds = ds.Where(x => x.HoTen.Contains(q) || x.Email.Contains(q));
        if (nhom == "UngVien") ds = ds.Where(x => x.Loai == "UngVien" && x.VaiTro != "QuanTri");
        else if (nhom == "NhanVien") ds = ds.Where(x => x.Loai == "NhaTuyenDung" && x.DoanhNghiepId != null && x.VaiTro != "QuanTri");
        else if (nhom == "ChuaGan") ds = ds.Where(x => x.Loai == "NhaTuyenDung" && x.DoanhNghiepId == null && x.VaiTro != "QuanTri");
        else if (nhom == "QuanTri") ds = ds.Where(x => x.VaiTro == "QuanTri");
        return await Trang(ds.OrderByDescending(x => x.TaoLuc).Select(x => new {
            x.Id, x.HoTen, x.Email, x.Loai, x.VaiTro, x.BiKhoa, x.DoanhNghiepId,
            tenDoanhNghiep = db.DoanhNghiep.Where(d => d.Id == x.DoanhNghiepId).Select(d => d.Ten).FirstOrDefault(),
            phuTrach = db.DoanhNghiep.Any(d => d.NguoiPhuTrachId == x.Id)
        }), trang, 20);
    }
    private async Task Gan(TaiKhoan tk, QuanTriSuaNguoi d, bool moi)
    {
        var email = d.Email.Trim().ToLowerInvariant();
        KiemTra(System.Net.Mail.MailAddress.TryCreate(email, out var dc) && email.Length <= 254 && dc.Address.Equals(email, StringComparison.OrdinalIgnoreCase), "Email không hợp lệ.");
        KiemTra(!string.IsNullOrWhiteSpace(d.HoTen), "Nhập họ tên.");
        KiemTra(d.Loai is "UngVien" or "NhaTuyenDung", "Loại tài khoản không hợp lệ.");
        KiemTra(d.VaiTro is "ThanhVien" or "QuanTri", "Vai trò không hợp lệ.");
        KiemTra(!await db.TaiKhoan.AnyAsync(x => x.Id != tk.Id && x.Email == email), "Email đã được sử dụng.", 409);
        KiemTra(d.DoanhNghiepId == null || d.Loai == "NhaTuyenDung", "Chỉ nhà tuyển dụng được gắn doanh nghiệp.");
        if (d.DoanhNghiepId != null) KiemTra(await db.DoanhNghiep.AnyAsync(x => x.Id == d.DoanhNghiepId), "Doanh nghiệp không tồn tại.");
        if (!moi) {
            KiemTra(!await db.DoanhNghiep.AnyAsync(x => x.NguoiPhuTrachId == tk.Id) || (tk.Loai == d.Loai && tk.DoanhNghiepId == d.DoanhNghiepId), "Không chuyển người phụ trách khỏi doanh nghiệp.", 409);
            KiemTra(tk.Loai == d.Loai || (!await db.HoSo.AnyAsync(x => x.UngVienId == tk.Id) && !await db.Tin.AnyAsync(x => x.NguoiTaoId == tk.Id) && !await db.DonHang.AnyAsync(x => x.NguoiMuaId == tk.Id)), "Tài khoản đã có nghiệp vụ; không đổi loại.", 409);
        }
        if (moi || !string.IsNullOrWhiteSpace(d.MatKhau)) {
            KiemTra(d.MatKhau != null && d.MatKhau.Length is >= 8 and <= 128, "Mật khẩu cần 8–128 ký tự.");
            tk.MatKhauBam = bam.HashPassword(tk, d.MatKhau!);
        }
        tk.Email = email; tk.HoTen = d.HoTen.Trim(); tk.Loai = d.Loai; tk.VaiTro = d.VaiTro; tk.BiKhoa = d.BiKhoa; tk.DoanhNghiepId = d.DoanhNghiepId;
    }
    [HttpPost("nguoi-dung")]
    public async Task<object> Them(QuanTriSuaNguoi d)
    {
        await phien.Nguoi(Request, "QuanTri");
        return await phien.GiaoDich<object>(async () => { var tk = new TaiKhoan(); await Gan(tk, d, true); db.Add(tk); return CongKhai(tk); });
    }
    [HttpPut("nguoi-dung/{id:guid}")]
    public async Task<object> Sua(Guid id, QuanTriSuaNguoi d)
    {
        var qt = await phien.Nguoi(Request, "QuanTri");
        KiemTra(id != qt.Id, "Sửa tài khoản của mình ở mục Tài khoản; không tự đổi quyền.");
        return await phien.GiaoDich<object>(async () => {
            var tk = await db.TaiKhoan.FindAsync(id) ?? throw new LoiNghiepVu("Không tìm thấy tài khoản.", 404);
            await Gan(tk, d, false);
            db.Phien.RemoveRange(await db.Phien.Where(x => x.TaiKhoanId == id).ToListAsync());
            return CongKhai(tk);
        });
    }
    [HttpDelete("nguoi-dung/{id:guid}")]
    public async Task<object> Xoa(Guid id)
    {
        var qt = await phien.Nguoi(Request, "QuanTri");
        KiemTra(id != qt.Id, "Không tự xóa tài khoản đang đăng nhập.");
        return await phien.GiaoDich<object>(async () => {
            var tk = await db.TaiKhoan.FindAsync(id) ?? throw new LoiNghiepVu("Không tìm thấy tài khoản.", 404);
            var lienQuan = tk.DoanhNghiepId != null || await db.DoanhNghiep.AnyAsync(x => x.NguoiPhuTrachId == id)
                || await db.Tin.AnyAsync(x => x.NguoiTaoId == id) || await db.HoSo.AnyAsync(x => x.UngVienId == id)
                || await db.DonHang.AnyAsync(x => x.NguoiMuaId == id || x.NguoiXacNhanId == id)
                || await db.SoLuot.AnyAsync(x => x.NguoiId == id) || await db.LichSuHoSo.AnyAsync(x => x.NguoiId == id)
                || await db.Tep.AnyAsync(x => x.ChuSoHuuId == id);
            KiemTra(!lienQuan, "Tài khoản có dữ liệu liên quan. Hãy khóa tài khoản để giữ lịch sử.", 409);
            db.Phien.RemoveRange(await db.Phien.Where(x => x.TaiKhoanId == id).ToListAsync());
            db.DongGio.RemoveRange(await db.DongGio.Where(x => x.TaiKhoanId == id).ToListAsync());
            db.ViecDaLuu.RemoveRange(await db.ViecDaLuu.Where(x => x.TaiKhoanId == id).ToListAsync());
            db.ThongBao.RemoveRange(await db.ThongBao.Where(x => x.TaiKhoanId == id).ToListAsync());
            db.Remove(tk);
            return new { thongBao = "Đã xóa tài khoản." };
        });
    }
}
