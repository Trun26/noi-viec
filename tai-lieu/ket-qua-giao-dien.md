# Cập nhật giao diện Nối Việc

- Thương hiệu hiển thị Nối Việc; tím chàm, trắng và cam nhẹ.
- Trang chủ ưu tiên tìm kiếm và việc làm thật từ API; bỏ các hàng đăng nhập/đăng ký khỏi trang chủ.
- Màn xác thực riêng có kiểm tra dữ liệu, ẩn/hiện mật khẩu và trạng thái đang gửi.
- Gói mới nhất có phân trang và mở đúng chi tiết; đổi nhãn Giỏ hàng, Đơn hàng, Gói đăng tin.
- Dart analyze: không có vấn đề.
- Đã bổ sung kiểm thử bố cục 360x800 và điều hướng đến màn đăng nhập.
- Khi chạy widget test 360×800, phát hiện thẻ trang chủ tràn ngang 75 px ở nút “Khám phá việc làm”; đã sửa bằng `Flexible`, tối đa hai dòng và ellipsis.
- Chưa xác minh lại test sau sửa. Pixel 7 đã boot, nhưng app chưa cài; API/SQL cũng chưa hoạt động. Flutter CLI hiện bị chặn khi khởi chạy tiến trình con và không ghi được SDK lockfile, nên APK mới chưa tạo.

Cập nhật tiếp: chi tiết việc làm có bố cục riêng và thanh ứng tuyển; bộ lọc chỉ xuất hiện một lần trên thanh công cụ, kể cả khi danh sách rỗng; tài khoản ứng viên có CV, việc đã lưu và theo dõi ứng tuyển. Bổ sung kiểm thử nút ứng tuyển cho khách và tin hết hạn, chưa thực thi được trong sandbox.
