# Ứng dụng Flutter Mobi

Mã Android của đề tài độc lập tuyển dụng và tìm việc. Xem README.md ở thư mục gốc để thiết lập máy chủ .NET 10 và SQL Server trước khi chạy.

- `lib/du_lieu`: REST API, lưu SQLite, lưu token an toàn.
- `lib/nghiep_vu`: trạng thái tài khoản, giỏ và chống đặt đơn lặp.
- `lib/giao_dien`: trang chủ, biểu mẫu, danh sách và các chức năng theo vai trò.
- `test`: các ca kiểm thử HTTP/trạng thái và bố cục điện thoại.

Chạy từ thư mục gốc bằng `tai-lieu/chay-android.ps1`. Máy chủ mặc định của emulator là `http://10.0.2.2:5080/api/v1`; có thể thay qua `--dart-define=API_URL=...`.

Đã tạo APK debug tại outputs/mobi-debug.apk ở thư mục gốc; chưa nghiệm thu luồng Android → API → SQL Server. Xem `tai-lieu/ket-qua-kiem-tra.md` ở gốc để biết kết quả và giới hạn môi trường.

