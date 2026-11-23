using MayChu.DuLieu;
using Microsoft.EntityFrameworkCore;
namespace MayChu.DuLieuMau;

public static class BoSungDanhMuc
{
    public static async Task Tao(KhoDuLieu db)
    {
        var dichVu = new[] {
            ("Đăng tin cơ bản", "Nhóm gói ít lượt cho nhu cầu tuyển dụng thông thường."),
            ("Tuyển dụng số lượng lớn", "Nhóm gói nhiều lượt cho nhiều vị trí tuyển dụng."),
            ("Tuyển dụng theo đợt", "Nhóm gói lượt cho các đợt tuyển dụng."),
            ("Tuyển dụng thực tập", "Nhóm gói lượt dành cho vị trí thực tập."),
            ("Tuyển dụng bán thời gian", "Nhóm gói lượt dành cho việc làm bán thời gian."),
            ("Tuyển dụng từ xa", "Nhóm gói lượt dành cho vị trí làm việc từ xa.")
        };
        var nganh = new[] { "Công nghệ thông tin", "Kinh doanh", "Kế toán - Kiểm toán", "Tài chính - Ngân hàng",
            "Nhân sự", "Hành chính - Văn phòng", "Tiếp thị - Truyền thông", "Thiết kế",
            "Chăm sóc khách hàng", "Giáo dục - Đào tạo", "Y tế - Dược", "Xây dựng",
            "Cơ khí - Chế tạo", "Điện - Điện tử", "Vận tải - Kho vận", "Du lịch - Khách sạn",
            "Nhà hàng - Thực phẩm", "Bất động sản", "Pháp lý", "Nông nghiệp" };
        var daCo = await db.DanhMuc.Select(x => new { x.Loai, x.TenChuan }).ToListAsync();
        var khoa = daCo.Select(x => x.Loai + "|" + x.TenChuan).ToHashSet(StringComparer.OrdinalIgnoreCase);
        var them = 0;
        void Gan(string ten, string loai, string moTa) {
            var chuan = string.Join(' ', ten.Split(' ', StringSplitOptions.RemoveEmptyEntries)).ToUpperInvariant();
            if (!khoa.Add(loai + "|" + chuan)) return;
            db.Add(new DanhMuc { Ten = ten, TenChuan = chuan, Loai = loai, MoTa = moTa, HoatDong = true }); them++;
        }
        foreach (var d in dichVu) Gan(d.Item1, "DichVu", d.Item2);
        foreach (var n in nganh) Gan(n, "NganhNghe", "Phân loại vị trí tuyển dụng thuộc ngành " + n.ToLowerInvariant() + ".");
        await db.SaveChangesAsync();
        Console.WriteLine($"Đã thêm {them} danh mục mới; giữ nguyên các danh mục đã có. Dịch vụ là nhóm gói lượt, không tự bổ sung tính năng trả phí mới.");
    }
}
