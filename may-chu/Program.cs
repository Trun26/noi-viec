using MayChu.DuLieu;
using MayChu.NghiepVu;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Identity;
using System.Text.Json;
using Microsoft.Data.SqlClient;
using System.Threading.RateLimiting;
using Microsoft.AspNetCore.RateLimiting;
var builder = WebApplication.CreateBuilder(args);
builder.Services.AddDbContext<KhoDuLieu>(o => o.UseSqlServer(builder.Configuration.GetConnectionString("DuLieu") ?? "Server=localhost,14333;Database=mobi;Integrated Security=true;TrustServerCertificate=true"));
builder.Services.AddScoped<PhienLamViec>();
builder.Services.AddScoped<PasswordHasher<TaiKhoan>>();
builder.Services.AddControllers().AddJsonOptions(o => o.JsonSerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.CamelCase);
builder.Services.AddOpenApi();
builder.Services.AddRateLimiter(o =>
{
    o.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(c => RateLimitPartition.GetFixedWindowLimiter(
        (c.Connection.RemoteIpAddress?.ToString() ?? "noi-bo") + (c.Request.Path.StartsWithSegments("/api/v1/tai-khoan/dang-nhap") || c.Request.Path.StartsWithSegments("/api/v1/tai-khoan/dang-ky") ? "/xac-thuc" : "/chung"),
        _ => new FixedWindowRateLimiterOptions { PermitLimit = c.Request.Path.StartsWithSegments("/api/v1/tai-khoan/dang-nhap") || c.Request.Path.StartsWithSegments("/api/v1/tai-khoan/dang-ky") ? 20 : 200, Window = TimeSpan.FromMinutes(1), QueueLimit = 0 }));
    o.OnRejected = async (c, ct) => { c.HttpContext.Response.StatusCode = 429; await c.HttpContext.Response.WriteAsJsonAsync(new { thongBao = "Bạn thao tác quá nhanh. Vui lòng thử lại sau một phút." }, ct); };
});
var app = builder.Build();
app.Use(async (ctx, next) =>
{
    try
    {
        await next();
    }
    catch (LoiNghiepVu e) { ctx.Response.StatusCode = e.Ma; await ctx.Response.WriteAsJsonAsync(new { thongBao = e.Message }); }
    catch (DbUpdateConcurrencyException) { ctx.Response.StatusCode = 409; await ctx.Response.WriteAsJsonAsync(new { thongBao = "Dữ liệu đã đổi, vui lòng tải lại." }); }
    catch (SqlException e) when (e.Number is 1205 or 1222 or 3960) { ctx.Response.StatusCode = 409; await ctx.Response.WriteAsJsonAsync(new { thongBao = "Có thao tác đồng thời. Vui lòng tải lại và thử lại." }); }
    catch (DbUpdateException e) { app.Logger.LogWarning("Lỗi cập nhật: {Loai}", e.GetType().Name); ctx.Response.StatusCode = 409; await ctx.Response.WriteAsJsonAsync(new { thongBao = "Dữ liệu trùng hoặc đang được sử dụng. Vui lòng tải lại." }); }
    catch (Exception e) { app.Logger.LogError("Lỗi xử lý {DuongDan}: {Loai}", ctx.Request.Path, e.GetType().Name); ctx.Response.StatusCode = 500; await ctx.Response.WriteAsJsonAsync(new { thongBao = "Máy chủ chưa xử lý được yêu cầu. Vui lòng thử lại." }); }
});
app.UseRateLimiter();
app.MapControllers();
if (app.Environment.IsDevelopment()) app.MapOpenApi();
app.MapGet("/api/v1/suc-khoe", async (KhoDuLieu db) => Results.Ok(new { mayChu = "Hoạt động", coSoDuLieu = await db.Database.CanConnectAsync() }));
if (args.Contains("--khoi-tao-du-lieu")) { using var scope = app.Services.CreateScope(); await scope.ServiceProvider.GetRequiredService<KhoDuLieu>().Database.EnsureCreatedAsync(); return; }
if (args.Contains("--tao-quan-tri"))
{
    using var scope = app.Services.CreateScope();
    var db = scope.ServiceProvider.GetRequiredService<KhoDuLieu>();
    var email = DocNhap.GiaTri("EMAIL_QUAN_TRI", "Email quản trị").Trim().ToLowerInvariant();
    PhienLamViec.KiemTra(System.Net.Mail.MailAddress.TryCreate(email, out var emailHopLe) && emailHopLe.Address.Equals(email, StringComparison.OrdinalIgnoreCase), "Email không hợp lệ.");
    var daCo = await db.TaiKhoan.SingleOrDefaultAsync(x => x.Email == email);
    if (daCo != null)
    {
        PhienLamViec.KiemTra(daCo.VaiTro == "QuanTri" && !daCo.BiKhoa, "Email đã thuộc tài khoản khác hoặc quản trị đang bị khóa.");
        Console.WriteLine("Quản trị đã tồn tại. Giữ nguyên mật khẩu và dữ liệu đã có.");
        return;
    }
    var mk = DocNhap.MatKhau("MAT_KHAU_QUAN_TRI", "Mật khẩu quản trị (12–128 ký tự)");
    var tk = new TaiKhoan { Email = email, HoTen = "Quản trị trình diễn", VaiTro = "QuanTri", Loai = "QuanTri" };
    tk.MatKhauBam = scope.ServiceProvider.GetRequiredService<PasswordHasher<TaiKhoan>>().HashPassword(tk, mk);
    db.Add(tk);
    await db.SaveChangesAsync();
    return;
}
if (args.Contains("--tao-du-lieu-mau"))
{
    using var scope = app.Services.CreateScope();
    await MayChu.DuLieuMau.TaoDuLieuMau.Tao(
        scope.ServiceProvider.GetRequiredService<KhoDuLieu>(),
        scope.ServiceProvider.GetRequiredService<PasswordHasher<TaiKhoan>>(),
        scope.ServiceProvider.GetRequiredService<PhienLamViec>(),
        app.Environment.ContentRootPath,
        DocNhap.MatKhau("MAT_KHAU_MAU", "Mật khẩu hai tài khoản mẫu (ít nhất 12 ký tự)"));
    return;
}
app.Run();
public partial class Program;
