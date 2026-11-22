# Đối chiếu yêu cầu môn học

Nguồn: https://ceb.net.vn/flutter/requirement.html, đọc ngày 21/11/2026. Chủ đề: tuyển dụng/tìm việc; sản phẩm thương mại là gói lượt đăng tin. Việc chấm chức năng tương đương cần giải trình với giảng viên.

Các dòng “có mã” bên dưới **chưa đồng nghĩa đã nghiệm thu trên Android với SQL Server**. Cần đánh dấu kết quả thực tế sau khi chạy được toàn bộ hệ thống. Điểm chép theo từng dòng của đề, không tự suy ra điểm cuối cùng từ tổng cộng.

## Công nghệ bắt buộc

| Yêu cầu | Triển khai | Cần xác minh |
|---|---|---|
| Flutter/Dart | ung-dung | Chạy Android |
| SQLite điện thoại | KhoCucBo, bảng bo_nho theo tài khoản | Thật trên thiết bị, mất mạng và đăng xuất |
| REST API C# .NET Core 10 | may-chu, net10.0 | Khởi động, gọi từ điện thoại |
| SQL Server | KhoDuLieu, EF Core SQL Server | Khởi tạo, lưu/đọc và giao dịch đồng thời |

## Chức năng bắt buộc

| Tiêu chí | Điểm dòng đề | Vị trí/luồng có mã |
|---|---:|---|
| Đăng ký | 0,25 | Tài khoản → Tạo tài khoản |
| Đăng nhập | 0,25 | Tài khoản → Đăng nhập |
| Đổi mật khẩu | 0,25 | Tài khoản → Đổi mật khẩu, kiểm tra mật khẩu cũ |
| Quản lý member | 0,25 | Quản trị → Thành viên, tìm kiếm, khóa/mở |
| Quản lý role | 0,5 | Quản trị → Quyền & khóa |
| Logout | 0,25 | Tài khoản → Đăng xuất, thu hồi phiên và xóa cache riêng |
| Phân quyền Member/Admin | 0,5 | Kiểm tra quyền máy chủ từng API; thành viên có loại ứng viên/nhà tuyển dụng |
| Hiển thị danh mục | 0,25 | Quản trị → Danh mục dịch vụ |
| Thêm danh mục | 0,25 | Nút Thêm mới |
| Xóa danh mục | 0,25 | Nút Xóa, có xác nhận |
| Kiểm tra có sản phẩm trước xóa danh mục | 0,25 | API chặn nếu còn gói/tin, khóa ngoại hỗ trợ |
| Sửa danh mục | 0,25 | Chỉnh sửa danh mục |
| Hiển thị sản phẩm có phân trang | 0,5 | Quản trị → Quản lý gói đăng tin |
| Thêm sản phẩm kèm ảnh | 0,5 | Thêm gói, chọn ảnh PNG/JPEG |
| Xóa sản phẩm kèm ảnh | 0,5 | Xóa gói chưa có đơn, dọn ảnh không còn tham chiếu |
| Sửa sản phẩm, thay ảnh phải xóa ảnh cũ | 0,5 | Chỉnh sửa gói, dọn ảnh cũ sau lưu thành công |
| Hiển thị danh mục trên trang chủ | 0,25 | Trang chủ → Danh mục gói đăng tin |
| Sản phẩm mới nhất có phân trang trên trang chủ | 0,5 | Trang chủ → Gói mới nhất, thứ tự tạo giảm dần |
| Hiển thị sản phẩm theo danh mục | 0,25 | Chọn danh mục dịch vụ → danh sách gói |
| Tìm kiếm sản phẩm | 0,25 | Ô tìm kiếm ở danh sách gói |
| Chi tiết sản phẩm | 0,25 | Chạm thẻ gói → mô tả, giá, số lượt |
| Nút thêm giỏ hàng | 0,25 | Nút Thêm vào giỏ của nhà tuyển dụng |
| Thêm sản phẩm vào giỏ | 0,25 | API kiểm tra gói, quyền doanh nghiệp và giá |
| Số lượng trên icon giỏ | 0,25 | Badge giỏ trên danh sách gói; tổng số gói |
| Hiển thị giỏ | 0,25 | Trang chủ nhà tuyển dụng / icon giỏ |
| Cập nhật số lượng giỏ | 0,5 | Số lượng 1–99, gộp cùng gói |
| Xóa sản phẩm khỏi giỏ | 0,25 | Xóa dòng giỏ |
| Checkout | 0,5 | Xem tổng & đặt đơn; máy chủ kiểm tra giá và giữ bản chụp đơn |
| Chi tiết đơn hàng | 0,25 | Danh sách đơn → chi tiết giá/số lượng lúc mua |
| Danh sách đơn cho admin | 0,25 | Quản trị → Đơn mua lượt |
| Cập nhật trạng thái đơn | 0,5 | Chờ thanh toán → đã thanh toán / đã hủy, chế độ trình diễn |

Phần API đề ghi điểm riêng theo nhóm: xác thực 0,75; danh mục 0,5; sản phẩm 0,75; trang chủ 0,5; giỏ hàng 1; quản lý đơn 0,25. Cần trình diễn gọi REST API và dữ liệu SQL Server thực tế, không chỉ giao diện.

## Điểm cộng

| Tiêu chí | Điểm đề | Tình trạng mã |
|---|---:|---|
| Xác thực email | 0,5 | Chưa triển khai |
| Quên mật khẩu | 0,5 | Chưa triển khai |
| Đăng nhập Gmail/Facebook/Zalo | Mỗi loại 0,5 | Chưa triển khai |
| Ảnh danh mục: thêm/xóa/sửa | 0,75 | Có mã, cần thử tệp và dọn ảnh |
| Kiểm tra sản phẩm có trong đơn trước xóa | 0,5 | Có mã chặn và khóa ngoại |
| Phân trang theo danh mục | 0,25 | Có mã, cần thử hơn một trang |
| Phân trang tìm kiếm | 0,25 | Có mã, cần thử hơn một trang |
| Sản phẩm liên quan | 0,25; phân trang thêm 0,25 | Có danh sách gói cùng danh mục |
| Người mua tìm đơn | 0,25 | Có tìm theo mã |
| VNPayment/VietQR | Mỗi loại 0,5 | Chưa triển khai, không tính xác nhận trình diễn là thanh toán thật |
| Admin tìm đơn | 0,25 | Có mã |
| Admin lọc đơn theo ngày | 0,25 | Có API và biểu mẫu lọc |

## Kịch bản phải chạy trước khi nộp

1. Tạo quản trị, thêm/sửa/xóa danh mục và ảnh. Danh mục có gói phải bị chặn xóa.
2. Tạo đủ hơn 12 gói để thử trang sau, tìm kiếm, lọc danh mục, trang chủ và chi tiết.
3. Thêm gói có ảnh; thay ảnh và xác minh ảnh cũ được dọn; xóa gói chưa có đơn và xác minh ảnh đi kèm.
4. Đăng ký nhà tuyển dụng, tạo doanh nghiệp, duyệt. Kiểm tra cấp ba lượt một lần.
5. Thêm 3 gói 1 lượt giá 20.000đ và 2 gói 5 lượt giá 90.000đ: badge 5 gói, tổng 13 lượt, 240.000đ. Thử nhập 0/100, xóa dòng và thêm trùng gói.
6. Đổi giá gói khi đang có trong giỏ: đặt đơn phải yêu cầu xác nhận lại. Đặt lại sau mất phản hồi phải giữ cùng khóa chống lặp.
7. Quản trị xác nhận đơn hai lần: chỉ cộng lượt một lần. Sửa giá/tên gói sau đặt không đổi đơn cũ. Gói đã có đơn không được xóa.
8. Thử Member gọi API quản trị, nhà tuyển dụng xem đơn/CV doanh nghiệp khác, token hết hạn và tài khoản khóa.
9. Tạo/duyệt tin và ứng tuyển với CV PDF. Thử hồ sơ trùng, rút rồi nộp lại, chuyển trạng thái sai, thay hồ sơ cá nhân sau nộp.
10. Trên Android thử chọn ảnh/PDF, tải CV, bàn phím, nút quay lại, ngắt mạng, nháp SQLite, đăng xuất và đổi tài khoản. Không báo thao tác thành công trước xác nhận API.

Ghi kết quả, phiên bản và bằng chứng thực tế vào `ket-qua-kiem-tra.md`; các kịch bản chưa chạy phải giữ trạng thái chưa nghiệm thu.
