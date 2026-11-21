using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;

namespace MayChu.DuLieu;

public class BanGhi
{
    public Guid Id { get; set; } = Guid.NewGuid(); public DateTime TaoLuc { get; set; } = DateTime.UtcNow;
}
public class TaiKhoan : BanGhi
{
    public string Email { get; set; } = ""; public string HoTen { get; set; } = "";
    public string MatKhauBam { get; set; } = ""; public string VaiTro { get; set; } = "ThanhVien";
    public string Loai { get; set; } = "UngVien"; public bool BiKhoa
    {
        get; set;
    }
    public Guid? DoanhNghiepId
    {
        get; set;
    }
    public string HoSoJson { get; set; } = "{}";
}
public class Phien : BanGhi
{
    public Guid TaiKhoanId
    {
        get; set;
    }
    public string MaBam { get; set; } = ""; public DateTime HetHan
    {
        get; set;
    }
}
public class DoanhNghiep : BanGhi
{
    public string Ten { get; set; } = ""; public string MaSoThue { get; set; } = "";
    public string DiaChi { get; set; } = ""; public string GioiThieu { get; set; } = "";
    public string TrangThai { get; set; } = "ChoDuyet"; public string LyDo { get; set; } = "";
    public Guid NguoiPhuTrachId
    {
        get; set;
    }
    public bool DaCapMienPhi
    {
        get; set;
    }
    public int SoLuotConLai
    {
        get; set;
    }
    public int SoLuotDangGiu
    {
        get; set;
    }
    public int SoLuotDaDung
    {
        get; set;
    }
}
public class DanhMuc : BanGhi
{
    public string Ten { get; set; } = ""; public string TenChuan { get; set; } = ""; public string MoTa { get; set; } = ""; public Guid? AnhId
    {
        get; set;
    }
    public bool HoatDong { get; set; } = true; public string Loai { get; set; } = "DichVu";
}
public class GoiLuot : BanGhi
{
    public string Ten { get; set; } = ""; public string MoTa { get; set; } = ""; public Guid DanhMucId
    {
        get; set;
    }
    public Guid AnhId
    {
        get; set;
    }
    public int SoLuot
    {
        get; set;
    }
    public decimal Gia
    {
        get; set;
    }
    public bool DangBan { get; set; } = true;
}
public class DongGio : BanGhi
{
    public Guid TaiKhoanId
    {
        get; set;
    }
    public Guid GoiLuotId
    {
        get; set;
    }
    public int SoLuong
    {
        get; set;
    }
    public decimal GiaDaXem
    {
        get; set;
    }
}
public class DonHang : BanGhi
{
    public string Ma { get; set; } = ""; public Guid DoanhNghiepId
    {
        get; set;
    }
    public Guid NguoiMuaId
    {
        get; set;
    }
    public string KhoaLap { get; set; } = ""; public string TrangThai { get; set; } = "ChoThanhToan";
    public decimal TongTien
    {
        get; set;
    }
    public int TongLuot
    {
        get; set;
    }
    public DateTime? XacNhanLuc
    {
        get; set;
    }
    public Guid? NguoiXacNhanId
    {
        get; set;
    }
    public List<ChiTietDon> ChiTiet { get; set; } = [];
}
public class ChiTietDon : BanGhi
{
    public Guid DonHangId
    {
        get; set;
    }
    public Guid GoiLuotId
    {
        get; set;
    }
    public string TenGoi { get; set; } = ""; public int SoLuong
    {
        get; set;
    }
    public int SoLuot
    {
        get; set;
    }
    public decimal DonGia
    {
        get; set;
    }
}
public class SoLuot : BanGhi
{
    public Guid DoanhNghiepId
    {
        get; set;
    }
    public Guid NguoiId
    {
        get; set;
    }
    public Guid ThamChieuId
    {
        get; set;
    }
    public string SuKien { get; set; } = ""; public int ConLai
    {
        get; set;
    }
    public int DangGiu
    {
        get; set;
    }
    public int DaDung
    {
        get; set;
    }
}
public class TinTuyenDung : BanGhi
{
    public Guid DoanhNghiepId
    {
        get; set;
    }
    public Guid NguoiTaoId
    {
        get; set;
    }
    public Guid NganhId
    {
        get; set;
    }
    public string TieuDe { get; set; } = ""; public string DiaDiem { get; set; } = ""; public string HinhThuc { get; set; } = "ToanThoiGian";
    public string KinhNghiem { get; set; } = ""; public string TrinhDo { get; set; } = ""; public string MoTa { get; set; } = "";
    public string YeuCau { get; set; } = ""; public string QuyenLoi { get; set; } = ""; public int SoNguoi { get; set; } = 1;
    public decimal? LuongMin
    {
        get; set;
    }
    public decimal? LuongMax
    {
        get; set;
    }
    public DateTime HanNhan
    {
        get; set;
    }
    public string TrangThai { get; set; } = "BanNhap"; public string LyDo { get; set; } = ""; public string? BanSuaJson
    {
        get; set;
    }
}
public class Tep : BanGhi
{
    public Guid ChuSoHuuId
    {
        get; set;
    }
    public string Ten { get; set; } = ""; public string Loai { get; set; } = ""; public string DuongDan { get; set; } = ""; public string Mime { get; set; } = "";
}
public class HoSoUngTuyen : BanGhi
{
    public Guid TinId
    {
        get; set;
    }
    public Guid UngVienId
    {
        get; set;
    }
    public Guid CvId
    {
        get; set;
    }
    public string BanHoSoJson { get; set; } = "{}"; public string ThuGioiThieu { get; set; } = "";
    public string TrangThai { get; set; } = "DaGui"; public string? PhongVanJson
    {
        get; set;
    }
}
public class LichSuHoSo : BanGhi
{
    public Guid HoSoId
    {
        get; set;
    }
    public Guid NguoiId
    {
        get; set;
    }
    public string TrangThai { get; set; } = ""; public string GhiChu { get; set; } = "";
}
public class ViecDaLuu : BanGhi
{
    public Guid TaiKhoanId
    {
        get; set;
    }
    public Guid TinId
    {
        get; set;
    }
}
public class ThongBao : BanGhi
{
    public Guid TaiKhoanId
    {
        get; set;
    }
    public string NoiDung { get; set; } = ""; public string DuongDan { get; set; } = ""; public bool DaDoc
    {
        get; set;
    }
}

public class KhoDuLieu(DbContextOptions<KhoDuLieu> options) : DbContext(options)
{
    public DbSet<TaiKhoan> TaiKhoan => Set<TaiKhoan>(); public DbSet<Phien> Phien => Set<Phien>();
    public DbSet<DoanhNghiep> DoanhNghiep => Set<DoanhNghiep>(); public DbSet<DanhMuc> DanhMuc => Set<DanhMuc>();
    public DbSet<GoiLuot> GoiLuot => Set<GoiLuot>(); public DbSet<DongGio> DongGio => Set<DongGio>();
    public DbSet<DonHang> DonHang => Set<DonHang>(); public DbSet<ChiTietDon> ChiTietDon => Set<ChiTietDon>();
    public DbSet<SoLuot> SoLuot => Set<SoLuot>(); public DbSet<TinTuyenDung> Tin => Set<TinTuyenDung>();
    public DbSet<Tep> Tep => Set<Tep>(); public DbSet<HoSoUngTuyen> HoSo => Set<HoSoUngTuyen>();
    public DbSet<LichSuHoSo> LichSuHoSo => Set<LichSuHoSo>(); public DbSet<ViecDaLuu> ViecDaLuu => Set<ViecDaLuu>(); public DbSet<ThongBao> ThongBao => Set<ThongBao>();
    protected override void OnModelCreating(ModelBuilder m)
    {
        m.Entity<TaiKhoan>().HasIndex(x => x.Email).IsUnique();
        m.Entity<Phien>().HasIndex(x => x.MaBam).IsUnique();
        m.Entity<DanhMuc>().HasIndex(x => new { x.Loai, x.TenChuan }).IsUnique();
        m.Entity<DongGio>().HasIndex(x => new { x.TaiKhoanId, x.GoiLuotId }).IsUnique();
        m.Entity<DonHang>().HasIndex(x => new { x.NguoiMuaId, x.KhoaLap }).IsUnique();
        m.Entity<HoSoUngTuyen>().HasIndex(x => new { x.UngVienId, x.TinId }).IsUnique();
        m.Entity<ViecDaLuu>().HasIndex(x => new { x.TaiKhoanId, x.TinId }).IsUnique();
        m.Entity<DoanhNghiep>().ToTable(t => { t.HasCheckConstraint("CK_luot_khong_am", "[so_luot_con_lai] >= 0 AND [so_luot_dang_giu] >= 0 AND [so_luot_da_dung] >= 0"); });
        m.Entity<DongGio>().ToTable(t => t.HasCheckConstraint("CK_so_luong_gio", "[so_luong] BETWEEN 1 AND 99"));
        m.Entity<DonHang>().HasMany(x => x.ChiTiet).WithOne().HasForeignKey(x => x.DonHangId).OnDelete(DeleteBehavior.Restrict);
        m.Entity<GoiLuot>().HasOne<DanhMuc>().WithMany().HasForeignKey(x => x.DanhMucId).OnDelete(DeleteBehavior.Restrict);
        m.Entity<GoiLuot>().HasOne<Tep>().WithMany().HasForeignKey(x => x.AnhId).OnDelete(DeleteBehavior.Restrict);
        m.Entity<HoSoUngTuyen>().HasOne<TinTuyenDung>().WithMany().HasForeignKey(x => x.TinId).OnDelete(DeleteBehavior.Restrict);
        m.Entity<HoSoUngTuyen>().HasOne<Tep>().WithMany().HasForeignKey(x => x.CvId).OnDelete(DeleteBehavior.Restrict);
        m.Entity<TinTuyenDung>().HasOne<DoanhNghiep>().WithMany().HasForeignKey(x => x.DoanhNghiepId).OnDelete(DeleteBehavior.Restrict);
        m.Entity<TinTuyenDung>().HasOne<DanhMuc>().WithMany().HasForeignKey(x => x.NganhId).OnDelete(DeleteBehavior.Restrict);
        m.Entity<TaiKhoan>().HasOne<DoanhNghiep>().WithMany().HasForeignKey(x => x.DoanhNghiepId).OnDelete(DeleteBehavior.Restrict);
        m.Entity<Phien>().HasOne<TaiKhoan>().WithMany().HasForeignKey(x => x.TaiKhoanId).OnDelete(DeleteBehavior.Restrict);
        m.Entity<DongGio>().HasOne<TaiKhoan>().WithMany().HasForeignKey(x => x.TaiKhoanId).OnDelete(DeleteBehavior.Restrict);
        m.Entity<DongGio>().HasOne<GoiLuot>().WithMany().HasForeignKey(x => x.GoiLuotId).OnDelete(DeleteBehavior.Restrict);
        m.Entity<ChiTietDon>().HasOne<GoiLuot>().WithMany().HasForeignKey(x => x.GoiLuotId).OnDelete(DeleteBehavior.Restrict);
        m.Entity<DonHang>().HasOne<DoanhNghiep>().WithMany().HasForeignKey(x => x.DoanhNghiepId).OnDelete(DeleteBehavior.Restrict);
        m.Entity<DonHang>().HasOne<TaiKhoan>().WithMany().HasForeignKey(x => x.NguoiMuaId).OnDelete(DeleteBehavior.Restrict);
        m.Entity<SoLuot>().HasOne<DoanhNghiep>().WithMany().HasForeignKey(x => x.DoanhNghiepId).OnDelete(DeleteBehavior.Restrict);
        m.Entity<HoSoUngTuyen>().HasOne<TaiKhoan>().WithMany().HasForeignKey(x => x.UngVienId).OnDelete(DeleteBehavior.Restrict);
        m.Entity<ViecDaLuu>().HasOne<TaiKhoan>().WithMany().HasForeignKey(x => x.TaiKhoanId).OnDelete(DeleteBehavior.Restrict);
        m.Entity<ViecDaLuu>().HasOne<TinTuyenDung>().WithMany().HasForeignKey(x => x.TinId).OnDelete(DeleteBehavior.Restrict);
        m.Entity<Tep>().HasOne<TaiKhoan>().WithMany().HasForeignKey(x => x.ChuSoHuuId).OnDelete(DeleteBehavior.Restrict);
        m.Entity<ThongBao>().HasOne<TaiKhoan>().WithMany().HasForeignKey(x => x.TaiKhoanId).OnDelete(DeleteBehavior.Restrict);
        m.Entity<LichSuHoSo>().HasOne<HoSoUngTuyen>().WithMany().HasForeignKey(x => x.HoSoId).OnDelete(DeleteBehavior.Restrict);
        m.Entity<GoiLuot>().ToTable(t => t.HasCheckConstraint("CK_goi_hop_le", "[gia] > 0 AND [so_luot] > 0"));
        m.Entity<TinTuyenDung>().HasIndex(x => new { x.TrangThai, x.HanNhan });
        m.Entity<ThongBao>().HasIndex(x => new { x.TaiKhoanId, x.TaoLuc });
        foreach (var e in m.Model.GetEntityTypes())
        {
            e.SetTableName(TenRan(e.ClrType.Name));
            foreach (var p in e.GetProperties())
            {
                p.SetColumnName(TenRan(p.Name));
                if (p.ClrType == typeof(DateTime) || p.ClrType == typeof(DateTime?))
                {
                    // SQL Server datetime2 không giữ DateTime.Kind; API luôn trả giờ UTC có hậu tố Z.
                    // https://learn.microsoft.com/ef/core/modeling/value-conversions
                    p.SetValueConverter(new ValueConverter<DateTime, DateTime>(
                        v => v.Kind == DateTimeKind.Local ? v.ToUniversalTime() : v,
                        v => DateTime.SpecifyKind(v, DateTimeKind.Utc)));
                }
                if (p.ClrType == typeof(string) && (p.Name == "Email" || p.Name == "MaBam" || p.Name == "KhoaLap" || p.Name == "TenChuan" || p.Name == "Loai"))
                    p.SetMaxLength(256);
                if (p.ClrType == typeof(decimal) || p.ClrType == typeof(decimal?))
                {
                    p.SetPrecision(18);
                    p.SetScale(2);
                }
            }
        }
    }
    private static string TenRan(string s) => System.Text.RegularExpressions.Regex.Replace(s, "(?<!^)([A-Z])", "_$1").ToLowerInvariant();
}
