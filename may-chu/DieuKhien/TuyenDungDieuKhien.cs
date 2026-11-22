using MayChu.DuLieu;
using MayChu.NghiepVu;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Text.Json;
using static MayChu.NghiepVu.PhienLamViec;
namespace MayChu.DieuKhien;

public record SuaDoanhNghiep(string Ten, string MaSoThue, string DiaChi, string GioiThieu);
public record ThemThanhVien(string Email, bool Xoa = false);
public record SuaTin(string TieuDe, Guid NganhId, string DiaDiem, string HinhThuc, string KinhNghiem, string TrinhDo, string MoTa, string YeuCau, string QuyenLoi, int SoNguoi, decimal? LuongMin, decimal? LuongMax, DateTime HanNhan);
public record UngTuyen(Guid CvId, string ThuGioiThieu);
public record XetHoSo(string TrangThai, string GhiChu, DateTime? GioPhongVan, string? HinhThuc, string? DiaDiem);
[ApiController, Route("api/v1")]
public class TuyenDungDieuKhien(KhoDuLieu db, PhienLamViec phien) : ControllerBase
{
    [HttpGet("doanh-nghiep")]
    public async Task<object> DoanhNghiep(string? q, int trang = 1, bool quanLy = false)
    {
        if (quanLy)
            await phien.Nguoi(Request, "QuanTri");
        return await Trang(db.DoanhNghiep.Where(x => (quanLy || x.TrangThai == "DaDuyet") && (q == null || x.Ten.Contains(q))).OrderByDescending(x => x.TaoLuc).Select(x => new { x.Id, x.Ten, x.DiaChi, x.GioiThieu, x.TrangThai, x.LyDo }), trang, 20);
    }
    [HttpGet("doanh-nghiep/toi")]
    public async Task<object> CongTyToi()
    {
        var tk = await phien.Nguoi(Request, "NhaTuyenDung");
        return await phien.CongTy(tk, false);
    }
    [HttpPost("doanh-nghiep")]
    public async Task<object> TaoCongTy(SuaDoanhNghiep d)
    {
        var tk = await phien.Nguoi(Request, "NhaTuyenDung");
        KiemTra(tk.DoanhNghiepId == null, "Bạn đã thuộc doanh nghiệp.");
        KiemTra(!string.IsNullOrWhiteSpace(d.Ten) && !string.IsNullOrWhiteSpace(d.DiaChi), "Nhập tên và địa chỉ doanh nghiệp.");
        var dn = new DoanhNghiep { Ten = d.Ten.Trim(), MaSoThue = d.MaSoThue, DiaChi = d.DiaChi, GioiThieu = d.GioiThieu, NguoiPhuTrachId = tk.Id };
        db.Add(dn);
        tk.DoanhNghiepId = dn.Id;
        await db.SaveChangesAsync();
        return dn;
    }
    [HttpPut("doanh-nghiep/toi")]
    public async Task<object> SuaCongTy(SuaDoanhNghiep d)
    {
        var tk = await phien.Nguoi(Request, "NhaTuyenDung");
        var dn = await phien.CongTy(tk, false);
        KiemTra(dn.NguoiPhuTrachId == tk.Id && dn.TrangThai != "TamKhoa", "Chỉ người phụ trách được sửa khi không bị khóa.", 403);
        KiemTra(!string.IsNullOrWhiteSpace(d.Ten) && !string.IsNullOrWhiteSpace(d.DiaChi), "Nhập tên và địa chỉ.");
        dn.Ten = d.Ten.Trim();
        dn.MaSoThue = d.MaSoThue;
        dn.DiaChi = d.DiaChi;
        dn.GioiThieu = d.GioiThieu;
        dn.TrangThai = "ChoDuyet";
        dn.LyDo = "";
        await db.SaveChangesAsync();
        return dn;
    }
    [HttpPost("doanh-nghiep/{id:guid}/trang-thai")]
    public async Task<object> DuyetCongTy(Guid id, DoiTrangThai d)
    {
        var tk = await phien.Nguoi(Request, "QuanTri");
        return await phien.GiaoDich<object>(async () => { var dn = await db.DoanhNghiep.FindAsync(id) ?? throw new LoiNghiepVu("Không tìm thấy doanh nghiệp.", 404); KiemTra(d.TrangThai is "DaDuyet" or "BiTuChoi" or "TamKhoa", "Trạng thái không hợp lệ."); if (d.TrangThai != "DaDuyet") KiemTra(!string.IsNullOrWhiteSpace(d.LyDo), "Nhập lý do."); dn.TrangThai = d.TrangThai; dn.LyDo = d.LyDo; if (d.TrangThai == "DaDuyet" && !dn.DaCapMienPhi) { phien.GhiLuot(dn, tk.Id, dn.Id, "MienPhiLanDau", 3, 0, 0); dn.DaCapMienPhi = true; } phien.Bao(dn.NguoiPhuTrachId, "Doanh nghiệp đã được cập nhật trạng thái.", "doanh-nghiep/toi"); return dn; });
    }
    [HttpGet("doanh-nghiep/thanh-vien")]
    public async Task<object> ThanhVien()
    {
        var tk = await phien.Nguoi(Request, "NhaTuyenDung");
        var dn = await phien.CongTy(tk, false);
        return await db.TaiKhoan.Where(x => x.DoanhNghiepId == dn.Id).Select(x => new { x.Id, x.HoTen, x.Email }).ToListAsync();
    }
    [HttpPost("doanh-nghiep/thanh-vien")]
    public async Task<object> SuaThanhVien(ThemThanhVien d)
    {
        var tk = await phien.Nguoi(Request, "NhaTuyenDung");
        var dn = await phien.CongTy(tk);
        KiemTra(dn.NguoiPhuTrachId == tk.Id, "Chỉ người phụ trách được quản lý thành viên.", 403);
        var tv = await db.TaiKhoan.SingleOrDefaultAsync(x => x.Email == d.Email.Trim().ToLowerInvariant()) ?? throw new LoiNghiepVu("Không tìm thấy tài khoản.", 404);
        KiemTra(tv.Id != tk.Id && tv.Loai == "NhaTuyenDung", "Thành viên không hợp lệ.");
        KiemTra(d.Xoa ? tv.DoanhNghiepId == dn.Id : tv.DoanhNghiepId == null, "Thành viên đã thuộc doanh nghiệp khác hoặc không thuộc doanh nghiệp này.");
        tv.DoanhNghiepId = d.Xoa ? null : dn.Id;
        await db.SaveChangesAsync();
        return CongKhai(tv);
    }
    [HttpGet("so-luot")]
    public async Task<object> Luot(int trang = 1)
    {
        var tk = await phien.Nguoi(Request, "NhaTuyenDung");
        var dn = await phien.CongTy(tk, false);
        return new
        {
            dn.SoLuotConLai,
            dn.SoLuotDangGiu,
            dn.SoLuotDaDung,
            lichSu = await Trang(db.SoLuot.Where(x => x.DoanhNghiepId == dn.Id).OrderByDescending(x => x.TaoLuc), trang, 30)
        };
    }
    private IQueryable<TinTuyenDung> CongKhaiTin() => db.Tin.Where(x => x.TrangThai == "DangTuyen" && x.HanNhan > DateTime.UtcNow && db.DoanhNghiep.Any(d => d.Id == x.DoanhNghiepId && d.TrangThai == "DaDuyet"));
    [HttpGet("tin-tuyen-dung")]
    public async Task<object> Tin(string? q, Guid? nganhId, string? diaDiem, string? hinhThuc, string? kinhNghiem, decimal? luongMin, int trang = 1, string sapXep = "moi", bool quanLy = false)
    {
        IQueryable<TinTuyenDung> ds = CongKhaiTin();
        if (quanLy)
        {
            var tk = await phien.Nguoi(Request);
            KiemTra(tk.VaiTro == "QuanTri" || tk.Loai == "NhaTuyenDung", "Không có quyền.", 403);
            ds = db.Tin.Where(x => tk.VaiTro == "QuanTri" || x.DoanhNghiepId == tk.DoanhNghiepId);
        }
        ds = ds.Where(x => (q == null || x.TieuDe.Contains(q) || x.MoTa.Contains(q)) && (nganhId == null || x.NganhId == nganhId) && (diaDiem == null || x.DiaDiem.Contains(diaDiem)) && (hinhThuc == null || x.HinhThuc == hinhThuc) && (kinhNghiem == null || x.KinhNghiem.Contains(kinhNghiem)) && (luongMin == null || x.LuongMax >= luongMin));
        var sapXepTin = sapXep == "luong" ? ds.OrderByDescending(x => x.LuongMax) : ds.OrderByDescending(x => x.TaoLuc);
        var danhSachHienThi =
            from tin in sapXepTin
            join doanhNghiep in db.DoanhNghiep on tin.DoanhNghiepId equals doanhNghiep.Id into dsDoanhNghiep
            from doanhNghiep in dsDoanhNghiep.DefaultIfEmpty()
            select new
            {
                tin.Id, tin.TaoLuc, tin.DoanhNghiepId, tin.NguoiTaoId, tin.NganhId,
                tin.TieuDe, tin.DiaDiem, tin.HinhThuc, tin.KinhNghiem, tin.TrinhDo,
                tin.MoTa, tin.YeuCau, tin.QuyenLoi, tin.SoNguoi, tin.LuongMin, tin.LuongMax,
                tin.HanNhan, tin.TrangThai, tin.LyDo, tin.BanSuaJson,
                tenDoanhNghiep = doanhNghiep == null ? null : doanhNghiep.Ten,
                tenNganh = db.DanhMuc.Where(x => x.Id == tin.NganhId).Select(x => x.Ten).FirstOrDefault()
            };
        return await Trang(danhSachHienThi, trang, 12);
    }
    [HttpGet("tin-tuyen-dung/{id:guid}")]
    public async Task<object> ChiTiet(Guid id)
    {
        var tin = await CongKhaiTin().SingleOrDefaultAsync(x => x.Id == id);
        if (tin == null)
        {
            var tk = await phien.Nguoi(Request);
            tin = await db.Tin.SingleOrDefaultAsync(x => x.Id == id && (tk.VaiTro == "QuanTri" || tk.Loai == "NhaTuyenDung" && x.DoanhNghiepId == tk.DoanhNghiepId));
        }
        if (tin == null)
            throw new LoiNghiepVu("Tin kh\u00f4ng c\u00f2n hi\u1ec3n th\u1ecb.", 404);
        var doanhNghiep = await db.DoanhNghiep.FindAsync(tin.DoanhNghiepId);
        return new
        {
            tin.Id, tin.TaoLuc, tin.DoanhNghiepId, tin.NguoiTaoId, tin.NganhId,
            tin.TieuDe, tin.DiaDiem, tin.HinhThuc, tin.KinhNghiem, tin.TrinhDo,
            tin.MoTa, tin.YeuCau, tin.QuyenLoi, tin.SoNguoi, tin.LuongMin, tin.LuongMax,
            tin.HanNhan, tin.TrangThai, tin.LyDo, tin.BanSuaJson,
            tenDoanhNghiep = doanhNghiep?.Ten,
            diaChiDoanhNghiep = doanhNghiep?.DiaChi,
            gioiThieuDoanhNghiep = doanhNghiep?.GioiThieu
        };
    }
    private async Task GanTin(TinTuyenDung t, SuaTin d)
    {
        KiemTra(!string.IsNullOrWhiteSpace(d.TieuDe) && !string.IsNullOrWhiteSpace(d.MoTa) && !string.IsNullOrWhiteSpace(d.DiaDiem), "Nhập tiêu đề, địa điểm và mô tả.");
        KiemTra(d.SoNguoi > 0 && d.HanNhan.ToUniversalTime() > DateTime.UtcNow, "Số người hoặc hạn nhận không hợp lệ.");
        KiemTra(d.LuongMin == null && d.LuongMax == null || d.LuongMin >= 0 && d.LuongMax >= d.LuongMin, "Khoảng lương không hợp lệ.");
        KiemTra(await db.DanhMuc.AnyAsync(x => x.Id == d.NganhId && x.Loai == "NganhNghe" && x.HoatDong), "Ngành nghề không khả dụng.");
        t.TieuDe = d.TieuDe;
        t.NganhId = d.NganhId;
        t.DiaDiem = d.DiaDiem;
        t.HinhThuc = d.HinhThuc;
        t.KinhNghiem = d.KinhNghiem;
        t.TrinhDo = d.TrinhDo;
        t.MoTa = d.MoTa;
        t.YeuCau = d.YeuCau;
        t.QuyenLoi = d.QuyenLoi;
        t.SoNguoi = d.SoNguoi;
        t.LuongMin = d.LuongMin;
        t.LuongMax = d.LuongMax;
        t.HanNhan = d.HanNhan.ToUniversalTime();
    }
    [HttpPost("tin-tuyen-dung")]
    public async Task<object> ThemTin(SuaTin d)
    {
        var tk = await phien.Nguoi(Request, "NhaTuyenDung");
        var dn = await phien.CongTy(tk, false);
        var t = new TinTuyenDung { DoanhNghiepId = dn.Id, NguoiTaoId = tk.Id };
        await GanTin(t, d);
        db.Add(t);
        await db.SaveChangesAsync();
        return t;
    }
    [HttpPut("tin-tuyen-dung/{id:guid}")]
    public async Task<object> SuaTin(Guid id, SuaTin d)
    {
        var tk = await phien.Nguoi(Request, "NhaTuyenDung");
        var dn = await phien.CongTy(tk);
        var t = await db.Tin.SingleOrDefaultAsync(x => x.Id == id && x.DoanhNghiepId == dn.Id) ?? throw new LoiNghiepVu("Không tìm thấy tin.", 404);
        KiemTra(t.TrangThai is "BanNhap" or "BiTuChoi" or "DangTuyen", "Không thể sửa ở trạng thái hiện tại.");
        if (t.TrangThai == "DangTuyen")
        {
            var kiem = new TinTuyenDung();
            await GanTin(kiem, d);
            t.BanSuaJson = JsonSerializer.Serialize(d);
        }
        else
            await GanTin(t, d);
        await db.SaveChangesAsync();
        return t;
    }
    [HttpPost("tin-tuyen-dung/{id:guid}/trang-thai")]
    public async Task<object> DoiTin(Guid id, DoiTrangThai d)
    {
        var tk = await phien.Nguoi(Request);
        return await phien.GiaoDich<object>(async () =>
        {
            var t = await db.Tin.FindAsync(id) ?? throw new LoiNghiepVu("Không tìm thấy tin.", 404);
            var dn = await db.DoanhNghiep.FindAsync(t.DoanhNghiepId) ?? throw new LoiNghiepVu("Không tìm thấy doanh nghiệp.");
            var qt = tk.VaiTro == "QuanTri";
            KiemTra(qt || tk.Loai == "NhaTuyenDung" && tk.DoanhNghiepId == dn.Id, "Không có quyền.", 403);
            if (d.TrangThai == "ChoDuyet")
            {
                KiemTra(!qt && dn.TrangThai == "DaDuyet" && t.TrangThai is "BanNhap" or "BiTuChoi", "Không thể gửi duyệt.");
                KiemTra(t.HanNhan > DateTime.UtcNow, "Hạn nhận đã qua.");
                phien.GhiLuot(dn, tk.Id, t.Id, "GiuLuot", -1, 1, 0);
            }
            else if (d.TrangThai == "DangTuyen")
            {
                KiemTra(qt && dn.TrangThai == "DaDuyet" && t.HanNhan > DateTime.UtcNow, "Không thể duyệt tin.", 403);
                if (t.TrangThai == "DangTuyen" && t.BanSuaJson != null)
                {
                    await GanTin(t, JsonSerializer.Deserialize<SuaTin>(t.BanSuaJson)!);
                    t.BanSuaJson = null;
                }
                else
                {
                    KiemTra(t.TrangThai == "ChoDuyet", "Tin không chờ duyệt.", 409);
                    phien.GhiLuot(dn, tk.Id, t.Id, "SuDungLuot", 0, -1, 1);
                }
            }
            else if (d.TrangThai == "BiTuChoi")
            {
                KiemTra(qt && !string.IsNullOrWhiteSpace(d.LyDo), "Cần quyền quản trị và lý do.", 403);
                if (t.TrangThai == "DangTuyen" && t.BanSuaJson != null)
                {
                    t.BanSuaJson = null;
                    t.LyDo = d.LyDo;
                    phien.Bao(t.NguoiTaoId, "Bản sửa tin bị từ chối: " + d.LyDo, "tin-tuyen-dung/" + id);
                    return t;
                }
                KiemTra(t.TrangThai == "ChoDuyet", "Tin không chờ duyệt.", 409);
                phien.GhiLuot(dn, tk.Id, t.Id, "TraLuotTuChoi", 1, -1, 0);
            }
            else if (d.TrangThai == "BanNhap")
            {
                KiemTra(!qt && t.TrangThai == "ChoDuyet", "Chỉ được rút tin chờ duyệt.");
                phien.GhiLuot(dn, tk.Id, t.Id, "TraLuotRut", 1, -1, 0);
            }
            else if (d.TrangThai == "DaDong")
                KiemTra(!qt && t.TrangThai == "DangTuyen", "Chỉ được đóng tin đang tuyển.");
            else if (d.TrangThai == "BiAn")
                KiemTra(qt && t.TrangThai == "DangTuyen" && !string.IsNullOrWhiteSpace(d.LyDo), "Cần tin đang tuyển và lý do ẩn.");
            else
                throw new LoiNghiepVu("Chuyển trạng thái không hợp lệ.");
            t.TrangThai = d.TrangThai;
            t.LyDo = d.LyDo;
            phien.Bao(t.NguoiTaoId, "Tin tuyển dụng đã đổi trạng thái.", "tin-tuyen-dung/" + id);
            return t;
        });
    }
    [HttpGet("viec-da-luu")]
    public async Task<object> DaLuu(int trang = 1)
    {
        var tk = await phien.Nguoi(Request, "UngVien");
        return await Trang(db.Tin.Where(t => db.ViecDaLuu.Any(x => x.TaiKhoanId == tk.Id && x.TinId == t.Id)).OrderByDescending(t => t.TaoLuc), trang, 12);
    }
    [HttpPut("viec-da-luu/{id:guid}")]
    public async Task<object> Luu(Guid id)
    {
        var tk = await phien.Nguoi(Request, "UngVien");
        KiemTra(await CongKhaiTin().AnyAsync(x => x.Id == id), "Tin không còn khả dụng.");
        if (!await db.ViecDaLuu.AnyAsync(x => x.TaiKhoanId == tk.Id && x.TinId == id))
            db.Add(new ViecDaLuu { TaiKhoanId = tk.Id, TinId = id });
        await db.SaveChangesAsync();
        return new
        {
            thongBao = "Đã lưu việc."
        };
    }
    [HttpDelete("viec-da-luu/{id:guid}")]
    public async Task<object> BoLuu(Guid id)
    {
        var tk = await phien.Nguoi(Request, "UngVien");
        db.RemoveRange(await db.ViecDaLuu.Where(x => x.TaiKhoanId == tk.Id && x.TinId == id).ToListAsync());
        await db.SaveChangesAsync();
        return new
        {
            thongBao = "Đã bỏ lưu."
        };
    }
    [HttpPost("tin-tuyen-dung/{id:guid}/ung-tuyen")]
    public async Task<object> Nop(Guid id, UngTuyen d)
    {
        var tk = await phien.Nguoi(Request, "UngVien");
        return await phien.GiaoDich<object>(async () => { var t = await CongKhaiTin().SingleOrDefaultAsync(x => x.Id == id) ?? throw new LoiNghiepVu("Tin đã dừng nhận hồ sơ.", 409); KiemTra(await db.Tep.AnyAsync(x => x.Id == d.CvId && x.ChuSoHuuId == tk.Id && x.Loai == "CV"), "CV không hợp lệ."); KiemTra(!await db.HoSo.AnyAsync(x => x.UngVienId == tk.Id && x.TinId == id), "Bạn đã ứng tuyển tin này.", 409); var hs = new HoSoUngTuyen { TinId = id, UngVienId = tk.Id, CvId = d.CvId, BanHoSoJson = JsonSerializer.Serialize(new { tk.HoTen, tk.Email, tk.HoSoJson }), ThuGioiThieu = d.ThuGioiThieu }; db.Add(hs); db.Add(new LichSuHoSo { HoSoId = hs.Id, NguoiId = tk.Id, TrangThai = "DaGui" }); foreach (var nguoi in await db.TaiKhoan.Where(x => x.DoanhNghiepId == t.DoanhNghiepId).Select(x => x.Id).ToListAsync()) phien.Bao(nguoi, "Có hồ sơ ứng tuyển mới.", "ho-so/" + hs.Id); return hs; });
    }
    private IQueryable<HoSoUngTuyen> QuyenHoSo(TaiKhoan tk) => db.HoSo.Where(h => h.UngVienId == tk.Id || tk.VaiTro == "QuanTri" || tk.Loai == "NhaTuyenDung" && db.Tin.Any(t => t.Id == h.TinId && t.DoanhNghiepId == tk.DoanhNghiepId));
    [HttpGet("ho-so")]
    public async Task<object> HoSo(Guid? tinId, string? trangThai, int trang = 1)
    {
        var tk = await phien.Nguoi(Request);
        return await Trang(QuyenHoSo(tk).Where(x => (tinId == null || x.TinId == tinId) && (trangThai == null || x.TrangThai == trangThai)).OrderByDescending(x => x.TaoLuc), trang, 20);
    }
    [HttpGet("ho-so/{id:guid}")]
    public async Task<object> ChiTietHoSo(Guid id)
    {
        var tk = await phien.Nguoi(Request);
        var hs = await QuyenHoSo(tk).SingleOrDefaultAsync(x => x.Id == id) ?? throw new LoiNghiepVu("Không tìm thấy hồ sơ.", 404);
        return new
        {
            hoSo = hs,
            lichSu = await db.LichSuHoSo.Where(x => x.HoSoId == id).OrderBy(x => x.TaoLuc).ToListAsync()
        };
    }
    [HttpPost("ho-so/{id:guid}/trang-thai")]
    public async Task<object> DoiHoSo(Guid id, XetHoSo d)
    {
        var tk = await phien.Nguoi(Request);
        return await phien.GiaoDich<object>(async () => { var hs = await QuyenHoSo(tk).SingleOrDefaultAsync(x => x.Id == id) ?? throw new LoiNghiepVu("Không tìm thấy hồ sơ.", 404); var rut = d.TrangThai == "DaRut"; KiemTra(rut ? hs.UngVienId == tk.Id : tk.Loai == "NhaTuyenDung", "Bạn không có quyền thực hiện.", 403); if (!rut) { await phien.CongTy(tk); KiemTra(await db.Tin.AnyAsync(t => t.Id == hs.TinId && t.DoanhNghiepId == tk.DoanhNghiepId), "Bạn không có quyền xử lý hồ sơ của doanh nghiệp khác.", 403); } KiemTra(QuyTacHoSo.ChoPhep(hs.TrangThai, d.TrangThai), "Chuyển trạng thái hồ sơ không hợp lệ.", 409); if (d.TrangThai == "MoiPhongVan") { KiemTra(d.GioPhongVan > DateTime.UtcNow && !string.IsNullOrWhiteSpace(d.HinhThuc) && !string.IsNullOrWhiteSpace(d.DiaDiem), "Nhập giờ tương lai, hình thức và địa điểm phỏng vấn."); hs.PhongVanJson = JsonSerializer.Serialize(new { d.GioPhongVan, d.HinhThuc, d.DiaDiem, d.GhiChu }); } hs.TrangThai = d.TrangThai; db.Add(new LichSuHoSo { HoSoId = id, NguoiId = tk.Id, TrangThai = d.TrangThai, GhiChu = d.GhiChu }); phien.Bao(hs.UngVienId, "Hồ sơ ứng tuyển đã đổi trạng thái.", "ho-so/" + id); return hs; });
    }
}

