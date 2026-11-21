# Chạy môi trường Docker của đề tài

Máy chủ dùng Linux container .NET 10 và SQL Server 2022 Developer. Đây là môi trường phát triển riêng đã được người dùng chọn; không chạy file Windows MayChu.exe. Docker Desktop cần đang chạy Linux engine.

Tại terminal PowerShell, khởi tạo lần đầu:

```powershell
& 'H:\mobile_ck\tai-lieu\khoi-dong-docker.ps1' -KhoiTao -DuLieuMau
```

Tập lệnh thực hiện:

1. Tạo mật khẩu SQL ngẫu nhiên trong work/docker/mobi.env nếu chưa có. File chỉ dành cho cấu hình máy này, không được đóng gói vào bài nộp.
2. Biên dịch máy chủ từ mã nguồn trong image SDK .NET 10, xuất bản vào image ASP.NET Core.
3. Chạy SQL Server và đợi trạng thái Healthy.
4. Khởi tạo database mobi và các bảng nếu chưa có; giữ nguyên dữ liệu cũ.
5. Hỏi email quản trị và mật khẩu 12–128 ký tự. Mật khẩu nhập được che. Nếu quá ngắn, hỏi lại; nếu quản trị đã tồn tại, giữ nguyên mật khẩu cũ.
6. Hỏi mật khẩu mẫu cho hai tài khoản tuyendung@mobi.example và ungvien@mobi.example; tạo dữ liệu trình diễn có nhãn mẫu nếu chưa có.
7. Chạy API ở http://127.0.0.1:5080; endpoint kiểm tra là /api/v1/suc-khoe.

Chạy những lần sau, không cần tạo lại tài khoản:

```powershell
& 'H:\mobile_ck\tai-lieu\khoi-dong-docker.ps1'
```

Nếu quản trị đã tạo thành công nhưng bước dữ liệu mẫu bị gián đoạn, chạy lại với -DuLieuMau, không cần -KhoiTao. Không xóa volume hoặc file cấu hình để thử lại, vì chúng giữ cơ sở dữ liệu và mật khẩu đang dùng.

API và SQL Server chỉ mở cổng trên máy tính hiện tại (5080 và 14333). Android emulator truy cập API qua http://10.0.2.2:5080/api/v1, đúng cấu hình APK đã tạo. Điện thoại thật cần cấu hình mạng riêng và địa chỉ API của máy chủ trước khi xây dựng/chạy.

Sau khi API hoạt động, chạy kiểm thử tích hợp trong terminal:

```powershell
& 'H:\mobile_ck\tai-lieu\kiem-thu-api.ps1'
```

Tập lệnh hỏi tài khoản quản trị và tạo dữ liệu kiểm thử có mã riêng. Không gửi mật khẩu trong log. Kiểm thử này khác với các kiểm thử HTTP dùng dữ liệu thay thế trong Flutter.
