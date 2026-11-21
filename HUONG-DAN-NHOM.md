# Source bài nhóm Mobi

Gói mobi-src-nhom.zip chứa toàn bộ mã nguồn của đề tài, không chỉ APK. Mỗi thành viên có thể giải nén vào thư mục bất kỳ và sửa mã. Không cần tài khoản GitHub hay thư mục cài đặt của máy trưởng nhóm.

## Thành phần

| Thư mục/tập tin | Nội dung |
|---|---|
| ung-dung | Flutter/Dart, Android, pubspec.lock và kiểm thử |
| may-chu | REST API C# .NET 10, mô hình EF Core SQL Server, Dockerfile, ảnh/dữ liệu mẫu |
| co-so-du-lieu | Thiết kế bảng, quan hệ và lưu dữ liệu |
| tai-lieu | Tập lệnh chạy/kiểm thử, đối chiếu yêu cầu môn học và kết quả kiểm tra |
| compose.docker.yaml | API .NET 10 và SQL Server 2022 Developer trong container Linux |
| .vscode | Cấu hình chạy Android và loại cache khỏi phân tích |

Không kèm SDK, cache, file tạo khi biên dịch, mật khẩu, volume/database cá nhân, CV tải lên hoặc khóa ký. Lược đồ database được tạo từ mã EF Core; dữ liệu mẫu được tạo bằng lệnh riêng, nên bạn bè không cần sao chép database của trưởng nhóm.

## Chuẩn bị

- Docker Desktop đang chạy Linux containers để chạy API và SQL Server.
- Flutter stable tương thích Dart 3.11 trở lên, Android SDK và JDK 17 để sửa/chạy ứng dụng Android. Bản đã kiểm tra dùng Flutter 3.41.6/Dart 3.11.4.
- VS Code cùng extension Dart/Flutter là lựa chọn tiện dụng, không bắt buộc.
- .NET SDK 10 trên Windows chỉ cần khi muốn biên dịch C# trực tiếp trên Windows. Khi dùng Docker, image SDK .NET 10 sẽ biên dịch máy chủ trong container.

## Chạy từ source trên máy của thành viên

Giải nén source, mở terminal tại thư mục có README.md và compose.docker.yaml. Các lệnh dưới đây dùng đường dẫn tương đối; không cần đặt dự án ở ổ H:.

Lần đầu:

```powershell
.\tai-lieu\khoi-dong-docker.ps1 -KhoiTao -DuLieuMau
```

Nhập email quản trị riêng và mật khẩu 12–128 ký tự. Sau đó nhập mật khẩu cho tài khoản mẫu. Máy thành viên có database/volume riêng; không cần biết mật khẩu của trưởng nhóm.

Những lần tiếp theo:

```powershell
.\tai-lieu\khoi-dong-docker.ps1
```

Trong terminal khác, mở Android emulator rồi chạy:

```powershell
.\tai-lieu\chay-android.ps1
```

Nếu có nhiều thiết bị, chạy flutter devices rồi truyền tham số -ThietBi với mã thiết bị. Hoặc chọn cấu hình Mobi Android trong VS Code, chọn thiết bị và nhấn F5.

Emulator gọi API qua http://10.0.2.2:5080/api/v1. APK có sẵn cũng dùng địa chỉ này: bạn bè dùng APK trên emulator cần chạy API trên máy tính của chính họ. Điện thoại thật cần cấu hình địa chỉ API/mạng riêng khi chạy từ source, không tự kết nối được vào máy trưởng nhóm.

## Tài khoản mẫu

- Nhà tuyển dụng: tuyendung@mobi.example.
- Ứng viên: ungvien@mobi.example.
- Mật khẩu: giá trị do từng thành viên nhập khi tạo dữ liệu mẫu, không có mật khẩu mặc định trong source.
- Quản trị: email/mật khẩu do từng thành viên tạo lúc khởi tạo.

Dữ liệu mẫu có 15 gói kèm ảnh, 3 danh mục dịch vụ, 3 ngành nghề, 1 doanh nghiệp và 2 tin tuyển dụng. Chức năng mua gói, đơn hàng và xác nhận thanh toán đang ở chế độ trình diễn, chưa tích hợp cổng thanh toán thật.

## Kiểm tra và phối hợp sửa

```powershell
.\tai-lieu\kiem-thu-nghiep-vu.ps1
.\tai-lieu\kiem-tra-android.ps1
.\tai-lieu\kiem-thu-api.ps1
```

Kiểm thử API hỏi quản trị của máy đang chạy và tạo bản ghi MẪU để đối chiếu. Xem tai-lieu/nghiem-thu.md để biết các tiêu chí cần trình diễn và tai-lieu/ket-qua-kiem-tra.md để phân biệt phần đã chạy với phần chưa nghiệm thu.

Nên chia công việc theo ung-dung, may-chu và tai-lieu; thống nhất trước khi nhiều người sửa cùng một tập tin. Nếu gửi source qua ZIP, ghi rõ phiên bản/ngày và người phụ trách. Database/khóa/mật khẩu không đưa vào gói trao đổi.

Đóng gói lại từ source:

```powershell
.\tai-lieu\dong-goi.ps1
```

File chính để gửi cả nhóm là outputs/mobi-src-nhom.zip; APK thử nghiệm là outputs/mobi-debug.apk nếu đã xây dựng.


## Giao diện Nối Việc

Tên hiển thị của ứng dụng là Nối Việc. Giao diện dùng tím chàm, nền trắng và điểm nhấn cam nhẹ. Đăng nhập và đăng ký nằm trong mục Tài khoản. Trang chủ có tìm kiếm, việc làm mới, danh mục và gói đăng tin phân trang. Tên thư mục, database và mã định danh Android được giữ để dùng tiếp dữ liệu hiện có.

Sau khi nhận source mới, chạy kiểm tra trong terminal: `& .\tai-lieu\kiem-tra.ps1`. APK trong outputs chỉ là bản mới khi đã biên dịch lại rồi chạy `& .\tai-lieu\dong-goi.ps1`.
