using MayChu.DuLieu;
using MayChu.NghiepVu;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using static MayChu.NghiepVu.PhienLamViec;
namespace MayChu.DieuKhien;

public record SuaDanhMuc(string Ten, string MoTa, string Loai, bool HoatDong, Guid? AnhId);
public record SuaGoi(string Ten, string MoTa, Guid DanhMucId, Guid AnhId, int SoLuot, decimal Gia, bool DangBan);
public record SuaGio(Guid GoiLuotId, int SoLuong, decimal GiaDaXem);
public record TaoDon(string KhoaLap);
public record DoiTrangThai(string TrangThai, string LyDo = "");
[ApiController, Route("api/v1")]
public class ThuongMaiDieuKhien(KhoDuLieu db, PhienLamViec phien, IConfiguration cauHinh) : ControllerBase
{
    private const string MauDanhMucKiemThu =
        "GÓI MẪU [0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F]" +
        "[0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F]";

    [HttpGet("danh-muc")]
    public async Task<object> DanhMuc(string loai = "DichVu", string? q = null, int trang = 1, bool quanLy = false)
    {
        if (quanLy)
            await phien.Nguoi(Request, "QuanTri");
        var ds = db.DanhMuc
            .Where(x => x.Loai == loai &&
                (quanLy || x.HoatDong && !EF.Functions.Like(x.TenChuan, MauDanhMucKiemThu)) &&
                (q == null || x.Ten.Contains(q)))
            .OrderBy(x => x.Ten);
        return await Trang(ds, trang, 50);
    }
    private async Task GanDanhMuc(DanhMuc m, SuaDanhMuc d)
    {
        KiemTra(!string.IsNullOrWhiteSpace(d.Ten) && d.Ten.Length <= 150, "Tên danh mục cần 1–150 ký tự.");
        KiemTra(d.Loai is "DichVu" or "NganhNghe", "Loại danh mục không hợp lệ.");
        if (d.AnhId != null)
            KiemTra(await db.Tep.AnyAsync(x => x.Id == d.AnhId && x.Loai == "Anh"), "Ảnh không hợp lệ.");
        m.Ten = d.Ten.Trim();
        m.TenChuan = string.Join(' ', m.Ten.Split(' ', StringSplitOptions.RemoveEmptyEntries)).ToUpperInvariant();
        m.MoTa = d.MoTa;
        m.Loai = d.Loai;
        m.HoatDong = d.HoatDong;
        m.AnhId = d.AnhId;
    }
    [HttpPost("danh-muc")]
    public async Task<object> ThemDanhMuc(SuaDanhMuc d)
    {
        await phien.Nguoi(Request, "QuanTri");
        var m = new DanhMuc();
        await GanDanhMuc(m, d);
        db.Add(m);
        await db.SaveChangesAsync();
        return m;
    }
    [HttpPut("danh-muc/{id:guid}")]
    public async Task<object> SuaDanhMuc(Guid id, SuaDanhMuc d)
    {
        await phien.Nguoi(Request, "QuanTri");
        var m = await db.DanhMuc.FindAsync(id) ?? throw new LoiNghiepVu("Không tìm thấy danh mục.", 404);
        var cu = m.AnhId;
        KiemTra(m.Loai == d.Loai, "Không đổi loại danh mục đã tạo.");
        await GanDanhMuc(m, d);
        await db.SaveChangesAsync();
        await DonAnh(cu);
        return m;
    }
    [HttpDelete("danh-muc/{id:guid}")]
    public async Task<object> XoaDanhMuc(Guid id)
    {
        await phien.Nguoi(Request, "QuanTri");
        KiemTra(!await db.GoiLuot.AnyAsync(x => x.DanhMucId == id) && !await db.Tin.AnyAsync(x => x.NganhId == id), "Danh mục đang có gói hoặc tin; hãy ngừng sử dụng.", 409);
        var m = await db.DanhMuc.FindAsync(id) ?? throw new LoiNghiepVu("Không tìm thấy danh mục.", 404);
        db.Remove(m);
        await db.SaveChangesAsync();
        await DonAnh(m.AnhId);
        return new
        {
            thongBao = "Đã xóa danh mục."
        };
    }
    [HttpGet("goi-luot")]
    public async Task<object> Goi(Guid? danhMucId, string? q, Guid? boQuaId, int trang = 1, int kichThuoc = 12, bool quanLy = false)
    {
        if (quanLy)
            await phien.Nguoi(Request, "QuanTri");
        var ds = db.GoiLuot
            .Where(x => (quanLy || x.DangBan && db.DanhMuc.Any(m =>
                    m.Id == x.DanhMucId && m.HoatDong &&
                    !EF.Functions.Like(m.TenChuan, MauDanhMucKiemThu))) &&
                (danhMucId == null || x.DanhMucId == danhMucId) &&
                (boQuaId == null || x.Id != boQuaId) &&
                (q == null || x.Ten.Contains(q)))
            .OrderByDescending(x => x.TaoLuc);
        return await Trang(ds, trang, kichThuoc);
    }
    [HttpGet("goi-luot/{id:guid}")]
    public async Task<object> ChiTietGoi(Guid id, bool quanLy = false)
    {
        if (quanLy)
            await phien.Nguoi(Request, "QuanTri");
        var goi = await db.GoiLuot.SingleOrDefaultAsync(x =>
            x.Id == id && (quanLy || x.DangBan && db.DanhMuc.Any(m =>
                m.Id == x.DanhMucId && m.HoatDong &&
                !EF.Functions.Like(m.TenChuan, MauDanhMucKiemThu))));
        return goi ?? throw new LoiNghiepVu("Không tìm thấy gói.", 404);
    }
    private async Task GanGoi(GoiLuot m, SuaGoi d)
    {
        KiemTra(!string.IsNullOrWhiteSpace(d.Ten) && d.Gia > 0 && d.Gia <= 100000000 && d.SoLuot is > 0 and <= 10000, "Tên, giá hoặc số lượt không hợp lệ.");
        KiemTra(await db.DanhMuc.AnyAsync(x => x.Id == d.DanhMucId && (x.HoatDong || !d.DangBan) && x.Loai == "DichVu"), "Danh mục không khả dụng.");
        KiemTra(await db.Tep.AnyAsync(x => x.Id == d.AnhId && x.Loai == "Anh"), "Cần tải ảnh gói lên trước.");
        m.Ten = d.Ten.Trim();
        m.MoTa = d.MoTa;
        m.DanhMucId = d.DanhMucId;
        m.AnhId = d.AnhId;
        m.Gia = d.Gia;
        m.SoLuot = d.SoLuot;
        m.DangBan = d.DangBan;
    }
    [HttpPost("goi-luot")]
    public async Task<object> ThemGoi(SuaGoi d)
    {
        await phien.Nguoi(Request, "QuanTri");
        var g = new GoiLuot();
        await GanGoi(g, d);
        db.Add(g);
        await db.SaveChangesAsync();
        return g;
    }
    [HttpPut("goi-luot/{id:guid}")]
    public async Task<object> SuaGoi(Guid id, SuaGoi d)
    {
        await phien.Nguoi(Request, "QuanTri");
        var g = await db.GoiLuot.FindAsync(id) ?? throw new LoiNghiepVu("Không tìm thấy gói.", 404);
        var cu = g.AnhId;
        await GanGoi(g, d);
        await db.SaveChangesAsync();
        if (cu != g.AnhId)
            await DonAnh(cu);
        return g;
    }
    [HttpDelete("goi-luot/{id:guid}")]
    public async Task<object> XoaGoi(Guid id)
    {
        await phien.Nguoi(Request, "QuanTri");
        KiemTra(!await db.ChiTietDon.AnyAsync(x => x.GoiLuotId == id), "Gói đã có trong đơn; hãy ngừng bán.", 409);
        var g = await db.GoiLuot.FindAsync(id) ?? throw new LoiNghiepVu("Không tìm thấy gói.", 404);
        db.DongGio.RemoveRange(await db.DongGio.Where(x => x.GoiLuotId == id).ToListAsync());
        db.Remove(g);
        await db.SaveChangesAsync();
        await DonAnh(g.AnhId);
        return new
        {
            thongBao = "Đã xóa gói và ảnh không còn sử dụng."
        };
    }
    private async Task DonAnh(Guid? id)
    {
        if (id == null || await db.GoiLuot.AnyAsync(x => x.AnhId == id) || await db.DanhMuc.AnyAsync(x => x.AnhId == id))
            return;
        var t = await db.Tep.FindAsync(id);
        if (t == null || t.Loai != "Anh")
            return;
        db.Remove(t);
        await db.SaveChangesAsync();
        if (System.IO.File.Exists(t.DuongDan))
            System.IO.File.Delete(t.DuongDan);
    }
    [HttpGet("gio-hang")]
    public async Task<object> Gio()
    {
        var tk = await phien.Nguoi(Request, "NhaTuyenDung");
        return await (from d in db.DongGio join g in db.GoiLuot on d.GoiLuotId equals g.Id where d.TaiKhoanId == tk.Id select new { d.Id, d.GoiLuotId, d.SoLuong, d.GiaDaXem, g.Ten, g.Gia, g.SoLuot, g.DangBan, g.AnhId }).ToListAsync();
    }
    [HttpPut("gio-hang")]
    public async Task<object> CapNhatGio(SuaGio d)
    {
        var tk = await phien.Nguoi(Request, "NhaTuyenDung");
        await phien.CongTy(tk);
        KiemTra(d.SoLuong is >= 1 and <= 99, "Số lượng phải từ 1 đến 99.");
        var g = await db.GoiLuot.FindAsync(d.GoiLuotId);
        KiemTra(g != null && g.DangBan, "Gói đã ngừng bán.");
        KiemTra(g!.Gia == d.GiaDaXem, "Giá đã đổi. Hãy tải lại và xác nhận giá mới.", 409);
        var dong = await db.DongGio.SingleOrDefaultAsync(x => x.TaiKhoanId == tk.Id && x.GoiLuotId == d.GoiLuotId);
        if (dong == null)
        {
            dong = new()
            {
                TaiKhoanId = tk.Id,
                GoiLuotId = g.Id
            };
            db.Add(dong);
        }
        dong.SoLuong = d.SoLuong;
        dong.GiaDaXem = g.Gia;
        await db.SaveChangesAsync();
        return dong;
    }
    [HttpDelete("gio-hang/{id:guid}")]
    public async Task<object> XoaDong(Guid id)
    {
        var tk = await phien.Nguoi(Request, "NhaTuyenDung");
        var d = await db.DongGio.SingleOrDefaultAsync(x => x.Id == id && x.TaiKhoanId == tk.Id) ?? throw new LoiNghiepVu("Không tìm thấy dòng giỏ.", 404);
        db.Remove(d);
        await db.SaveChangesAsync();
        return new
        {
            thongBao = "Đã xóa khỏi giỏ."
        };
    }
    [HttpPost("don-hang")]
    public async Task<object> DatDon(TaoDon d)
    {
        var tk = await phien.Nguoi(Request, "NhaTuyenDung");
        KiemTra(Guid.TryParse(d.KhoaLap, out _), "Khóa đặt hàng không hợp lệ.");
        return await phien.GiaoDich<object>(async () => { var cu = await db.DonHang.Include(x => x.ChiTiet).SingleOrDefaultAsync(x => x.NguoiMuaId == tk.Id && x.KhoaLap == d.KhoaLap); if (cu != null) return cu; var dn = await phien.CongTy(tk); var gio = await db.DongGio.Where(x => x.TaiKhoanId == tk.Id).ToListAsync(); KiemTra(gio.Count > 0, "Giỏ hàng đang trống."); var don = new DonHang { Ma = "DH-" + Guid.NewGuid().ToString("N")[..12].ToUpperInvariant(), DoanhNghiepId = dn.Id, NguoiMuaId = tk.Id, KhoaLap = d.KhoaLap }; foreach (var dong in gio) { var g = await db.GoiLuot.FindAsync(dong.GoiLuotId); KiemTra(g != null && g.DangBan, "Có gói đã ngừng bán. Vui lòng cập nhật giỏ.", 409); KiemTra(g!.Gia == dong.GiaDaXem, "Giá đã đổi. Vui lòng xem và xác nhận lại trong giỏ.", 409); don.ChiTiet.Add(new() { GoiLuotId = g.Id, TenGoi = g.Ten, SoLuong = dong.SoLuong, SoLuot = g.SoLuot, DonGia = g.Gia }); don.TongTien += g.Gia * dong.SoLuong; don.TongLuot += g.SoLuot * dong.SoLuong; } db.Add(don); db.RemoveRange(gio); return don; });
    }
    [HttpGet("don-hang")]
    public async Task<object> Don(string? q, string? trangThai, DateTime? tuNgay, DateTime? denNgay, int trang = 1)
    {
        var tk = await phien.Nguoi(Request);
        var ds = db.DonHang.Where(x => tk.VaiTro == "QuanTri" || x.DoanhNghiepId == tk.DoanhNghiepId && tk.Loai == "NhaTuyenDung");
        return await Trang(ds.Where(x => (q == null || x.Ma.Contains(q)) && (trangThai == null || x.TrangThai == trangThai) && (tuNgay == null || x.TaoLuc >= tuNgay) && (denNgay == null || x.TaoLuc < denNgay)).OrderByDescending(x => x.TaoLuc), trang, 20);
    }
    [HttpGet("don-hang/{id:guid}")]
    public async Task<object> ChiTietDon(Guid id)
    {
        var tk = await phien.Nguoi(Request);
        return await db.DonHang.Include(x => x.ChiTiet).SingleOrDefaultAsync(x => x.Id == id && (tk.VaiTro == "QuanTri" || tk.Loai == "NhaTuyenDung" && x.DoanhNghiepId == tk.DoanhNghiepId)) ?? throw new LoiNghiepVu("Không tìm thấy đơn.", 404);
    }
    [HttpPost("don-hang/{id:guid}/trang-thai")]
    public async Task<object> TrangThaiDon(Guid id, DoiTrangThai d)
    {
        var tk = await phien.Nguoi(Request);
        return await phien.GiaoDich<object>(async () => { var don = await db.DonHang.FindAsync(id) ?? throw new LoiNghiepVu("Không tìm thấy đơn.", 404); KiemTra(tk.VaiTro == "QuanTri" || tk.Loai == "NhaTuyenDung" && tk.DoanhNghiepId == don.DoanhNghiepId, "Bạn không có quyền.", 403); if (don.TrangThai == d.TrangThai) return don; KiemTra(don.TrangThai == "ChoThanhToan", "Đơn đã kết thúc, không thể thay đổi.", 409); KiemTra(d.TrangThai is "DaThanhToan" or "DaHuy", "Trạng thái không hợp lệ."); if (d.TrangThai == "DaThanhToan") { KiemTra(tk.VaiTro == "QuanTri", "Chỉ quản trị được xác nhận.", 403); KiemTra(cauHinh.GetValue<bool>("TrinhDien"), "Chế độ trình diễn chưa được bật."); var dn = await db.DoanhNghiep.FindAsync(don.DoanhNghiepId) ?? throw new LoiNghiepVu("Không tìm thấy doanh nghiệp."); KiemTra(dn.TrangThai == "DaDuyet", "Doanh nghiệp không đủ điều kiện nhận lượt."); phien.GhiLuot(dn, tk.Id, don.Id, "MuaLuot", don.TongLuot, 0, 0); don.XacNhanLuc = DateTime.UtcNow; don.NguoiXacNhanId = tk.Id; } don.TrangThai = d.TrangThai; phien.Bao(don.NguoiMuaId, "Đơn " + don.Ma + ": " + (d.TrangThai == "DaThanhToan" ? "đã xác nhận thanh toán (trình diễn)" : "đã hủy"), "don-hang/" + id); return don; });
    }
}
