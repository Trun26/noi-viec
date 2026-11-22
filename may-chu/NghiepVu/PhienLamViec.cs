using System.Data;
using System.Security.Cryptography;
using System.Text;
using MayChu.DuLieu;
using Microsoft.EntityFrameworkCore;
namespace MayChu.NghiepVu;

public class LoiNghiepVu(string thongBao, int ma = 400) : Exception(thongBao)
{
    public int Ma { get; } = ma;
}
public class PhienLamViec(KhoDuLieu db)
{
    public static void KiemTra(bool dung, string loi, int ma = 400)
    {
        if (!dung)
            throw new LoiNghiepVu(loi, ma);
    }
    public static string Bam(string s) => Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(s)));
    public async Task<TaiKhoan> Nguoi(HttpRequest r, string? loai = null)
    {
        var ma = r.Headers.Authorization.ToString();
        KiemTra(ma.StartsWith("Bearer "), "Bạn cần đăng nhập.", 401);
        var bam = Bam(ma[7..]);
        var p = await db.Phien.SingleOrDefaultAsync(x => x.MaBam == bam && x.HetHan > DateTime.UtcNow);
        KiemTra(p != null, "Phiên đã hết hạn. Vui lòng đăng nhập lại.", 401);
        var tk = await db.TaiKhoan.FindAsync(p!.TaiKhoanId);
        KiemTra(tk != null && !tk.BiKhoa, "Tài khoản không khả dụng.", 403);
        if (loai != null)
            KiemTra(loai == "QuanTri" ? tk!.VaiTro == "QuanTri" : tk!.Loai == loai, "Bạn không có quyền thực hiện.", 403);
        return tk!;
    }
    public async Task<DoanhNghiep> CongTy(TaiKhoan tk, bool canDuyet = true)
    {
        KiemTra(tk.Loai == "NhaTuyenDung" && tk.DoanhNghiepId != null, "Bạn chưa thuộc doanh nghiệp.", 403);
        var dn = await db.DoanhNghiep.FindAsync(tk.DoanhNghiepId);
        KiemTra(dn != null, "Không tìm thấy doanh nghiệp.", 404);
        if (canDuyet)
            KiemTra(dn!.TrangThai == "DaDuyet", "Doanh nghiệp chưa được duyệt hoặc đang tạm khóa.", 403);
        return dn!;
    }
    public async Task<T> GiaoDich<T>(Func<Task<T>> ham)
    {
        await using var tx = await db.Database.BeginTransactionAsync(IsolationLevel.Serializable);
        var kq = await ham();
        await db.SaveChangesAsync();
        await tx.CommitAsync();
        return kq;
    }
    public void GhiLuot(DoanhNghiep dn, Guid nguoi, Guid thamChieu, string sk, int con, int giu, int dung)
    {
        KiemTra(dn.SoLuotConLai + con >= 0 && dn.SoLuotDangGiu + giu >= 0, "Không đủ lượt đăng tin.", 409);
        dn.SoLuotConLai += con;
        dn.SoLuotDangGiu += giu;
        dn.SoLuotDaDung += dung;
        db.SoLuot.Add(new()
        {
            DoanhNghiepId = dn.Id,
            NguoiId = nguoi,
            ThamChieuId = thamChieu,
            SuKien = sk,
            ConLai = con,
            DangGiu = giu,
            DaDung = dung
        });
    }
    public void Bao(Guid nguoi, string nd, string dd) => db.ThongBao.Add(new() { TaiKhoanId = nguoi, NoiDung = nd, DuongDan = dd });
    public static object CongKhai(TaiKhoan tk) => new { tk.Id, tk.Email, tk.HoTen, tk.VaiTro, tk.Loai, tk.DoanhNghiepId, tk.HoSoJson, tk.BiKhoa };
    public static async Task<object> Trang<T>(IQueryable<T> q, int trang, int kichThuoc)
    {
        trang = Math.Max(1, trang);
        kichThuoc = Math.Clamp(kichThuoc, 1, 50);
        return new
        {
            duLieu = await q.Skip((trang - 1) * kichThuoc).Take(kichThuoc).ToListAsync(),
            tong = await q.CountAsync(),
            trang,
            kichThuoc
        };
    }
}
