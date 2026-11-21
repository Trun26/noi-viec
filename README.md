# Mobi — Ứng dụng hỗ trợ tuyển dụng và tìm việc

Đề tài độc lập tại `H:\mobile_ck`. Không liên kết hoặc đồng bộ với repo GitHub cũ. Căn cứ chức năng: https://ceb.net.vn/flutter/requirement.html. README cũ của repo không còn là bộ chuẩn áp dụng cho bản này.

## Công nghệ

- Flutter/Dart: giao diện Android.
- SQLite: lưu dữ liệu đã xem, giỏ và nháp trên điện thoại, tách theo tài khoản.
- C# ASP.NET Core 10: REST API `/api/v1`.
- SQL Server: dữ liệu chính; Entity Framework Core 10 truy cập dữ liệu.

## Phần đã viết

Ứng viên tìm/lưu việc, quản lý hồ sơ và CV, ứng tuyển/theo dõi/rút hồ sơ. Nhà tuyển dụng đăng ký doanh nghiệp, mua gói lượt qua giỏ hàng và đơn hàng, tạo/gửi duyệt tin, xét hồ sơ và gửi lịch phỏng vấn. Quản trị quản lý thành viên/vai trò, danh mục/ảnh, gói đăng tin/ảnh, doanh nghiệp, tin và đơn. Có thông báo và thống kê.

Trong đề tài này, sản phẩm là **gói lượt đăng tin**, danh mục sản phẩm là **danh mục dịch vụ tuyển dụng**. Đây là cách ánh xạ để giải trình với giảng viên, chưa có xác nhận cách tính điểm tương đương. Chức năng giỏ/đơn là mua gói thật, không dùng số hồ sơ ứng tuyển làm số lượng sản phẩm.

**Chưa nghiệm thu hoàn tất:** cần chạy Android → API → SQL Server. Xem `tai-lieu/nghiem-thu.md` và `tai-lieu/ket-qua-kiem-tra.md`. Không coi danh sách mã đã viết là chức năng đã chạy thành công.

## Cấu trúc

- `ung-dung/`: Flutter, kiểm thử HTTP/trạng thái/giao diện.
- `may-chu/`: API, nghiệp vụ, mô hình SQL Server.
- `co-so-du-lieu/`: thiết kế dữ liệu.
- `tai-lieu/`: đối chiếu yêu cầu, kiểm thử, tập lệnh hỗ trợ.
- `work/`: SDK/caches và bản sao lịch sử Git cũ; không cần đưa vào bài nộp.

## Môi trường đang dùng trên máy này

Người dùng đã chọn máy chủ Linux trong Docker vì Smart App Control chặn bản Windows chưa ký. Dùng hướng dẫn tai-lieu/chay-docker.md và tập lệnh tai-lieu/khoi-dong-docker.ps1. APK đã tạo không cần xây dựng lại để kết nối API này.

## Chuẩn bị chạy

Cần Flutter 3.41 trở lên (Dart 3.11), .NET SDK 10, Android SDK/JDK và một SQL Server đang hoạt động. SDK .NET 10.0.404 đã tải trong `work/dotnet`; tập lệnh `tai-lieu/moi-truong.ps1` sử dụng SDK này nếu có. Máy khác có thể cài .NET 10 bình thường.

Các lệnh dưới đây là hướng dẫn thiết lập; chưa xác minh chạy xuyên suốt trên máy hiện tại do Application Control chặn chương trình máy chủ và SQL Server chưa kết nối được.

Tại PowerShell trong thư mục dự án:

```powershell
. ./tai-lieu/moi-truong.ps1
```

Chọn SQL Server đang dùng. Với SQL Server Express xác thực Windows:

```powershell
$env:ConnectionStrings__DuLieu = 'Server=.\SQLEXPRESS;Database=mobi;Integrated Security=true;TrustServerCertificate=true'
```

Hoặc Docker Desktop, dùng mật khẩu tự đặt qua biến môi trường và không đưa mật khẩu thật vào bài nộp:

```powershell
$env:MAT_KHAU_SQL = Read-Host 'Mật khẩu SQL Server cho bản thử nghiệm'
docker compose up -d
$env:ConnectionStrings__DuLieu = "Server=localhost,14333;Database=mobi;User Id=sa;Password=$env:MAT_KHAU_SQL;TrustServerCertificate=true"
```

Đợi SQL Server sẵn sàng, sau đó khởi tạo lược đồ và tài khoản quản trị (chỉ thực hiện lần đầu):

```powershell
./tai-lieu/khoi-tao-du-lieu.ps1
./tai-lieu/chay-may-chu.ps1
```

Lệnh khởi tạo không xóa dữ liệu. Sau khi có quản trị, có thể chạy tai-lieu/tao-du-lieu-mau.ps1 để tạo dữ liệu trình diễn hoặc tự thêm danh mục/gói bằng giao diện quản trị. Doanh nghiệp được duyệt lần đầu nhận ba lượt khởi đầu.

Máy chủ trình diễn chạy cổng 5080. Kiểm tra `/api/v1/suc-khoe`; OpenAPI ở `/openapi/v1.json` trong môi trường Development. Biến `TrinhDien=true` chỉ cho phép quản trị xác nhận đơn thanh toán mô phỏng; giao diện có nhãn TRÌNH DIỄN. Chưa tích hợp cổng thanh toán thật.

Trong terminal thứ hai, chạy trên Android emulator:

```powershell
./tai-lieu/chay-android.ps1
```

Android emulator dùng `10.0.2.2` để truy cập máy tính. Điện thoại thật cần cùng mạng với máy chủ và truyền địa chỉ mạng của máy tính bằng tham số `-ApiUrl`. Bản debug cho phép HTTP phục vụ thử nghiệm cục bộ; bản phát hành cần HTTPS và khóa ký riêng. Cấu hình mẫu hiện vẫn dùng khóa debug, chưa phải bản phát hành lên cửa hàng.

## Kiểm tra

```powershell
./tai-lieu/kiem-tra.ps1
```

Kiểm thử tự động hiện tập trung vào dữ liệu cục bộ tách tài khoản, lỗi quyền không dùng cache, giỏ tính số gói, khóa đặt đơn chống lặp sau mất phản hồi và bố cục màn hình nhỏ. Chưa thay thế kiểm thử giao dịch SQL Server, tải CV, SQLite thật, bàn phím và quyền Android.

## Điểm cộng chưa triển khai

Xác thực email, quên mật khẩu, đăng nhập Google/Facebook/Zalo và thanh toán VNPayment/VietQR. Không sử dụng email hay thông tin cá nhân thật trong dữ liệu trình diễn.

Khi API và SQL Server đã chạy, dùng tập lệnh tai-lieu/kiem-thu-api.ps1 với cơ sở dữ liệu trình diễn để kiểm tra giỏ, đơn, lượt và phân quyền. Tập lệnh sẽ tạo dữ liệu mẫu có mã riêng; chưa được thực thi trong môi trường hiện tại.


## Dữ liệu mẫu và chạy trong VS Code

Đã bổ sung lệnh tạo dữ liệu mẫu (cần cơ sở dữ liệu và quản trị đã tạo):

```powershell
./tai-lieu/tao-du-lieu-mau.ps1
```

Tập lệnh hỏi mật khẩu mẫu, không có mật khẩu mặc định trong mã. Hai tài khoản mẫu là `tuyendung@mobi.example` và `ungvien@mobi.example`. Dữ liệu gồm 15 gói có ảnh, 3 danh mục dịch vụ, 3 ngành nghề, doanh nghiệp mẫu và 2 tin đã duyệt. Có nhãn mẫu; chạy lại không cộng lượt hoặc tạo lặp. Chưa xác minh chạy lệnh seed trên SQL Server trong môi trường hiện tại.

Trong VS Code, chọn thiết bị Android rồi dùng cấu hình **Mobi Android** để chạy đúng `ung-dung/lib/main.dart`. Máy chủ cần đang hoạt động ở cổng 5080; cấu hình emulator dùng địa chỉ máy tính `10.0.2.2`.

Có thể chạy riêng kiểm thử nghiệp vụ không cần listener mạng bằng `tai-lieu/kiem-thu-nghiep-vu.ps1`; chạy phần Flutter/APK bằng `tai-lieu/kiem-tra-android.ps1`. Xem kết quả mới nhất trong `tai-lieu/ket-qua-kiem-tra.md`.


