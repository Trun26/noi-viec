# Source chia sẻ nhóm — Nối Việc

Đây là bản đang phát triển ngày 21/11/2026, chưa phải bản nghiệm thu cuối.

Bao gồm source Flutter, API .NET 10, cấu hình Docker/SQL Server và hướng dẫn chạy trong HUONG-DAN-NHOM.md. Đã cập nhật trang chủ, màn xác thực, tài khoản và chi tiết việc làm. Mở ứng dụng sẽ vào xác thực trước; có lựa chọn xem việc công khai.

Trạng thái kiểm tra cập nhật ngày 21/11/2026: chạy lại Dart nghiệp vụ đạt 10/10 (HTTP/kho lưu thay thế); formatter 3 file đạt; parser PowerShell cho 3 script không lỗi. Pixel 7 đã cold boot và ADB nhận `emulator-5554`, đã cài và mở app debug. Flutter analyze/widget test sau sửa chưa chạy lại; API/SQL không hoạt động; đã có APK debug trong `ung-dung/build/app/outputs/flutter-apk/app-debug.apk`; chưa tạo APK phát hành cuối. Các kết quả analyze/API/APK được ghi ở phần lịch sử bên dưới là từ lần chạy trước, chưa được xác nhận cho source hiện tại.

## Cập nhật dọn dữ liệu kiểm thử

API công khai hiện ẩn danh mục theo fixture `Gói MẪU` + 10 ký tự hex, đồng thời chỉ liệt kê danh mục hoạt động/gói đang bán; đường dẫn chi tiết gói đã ẩn trả về 404. Danh sách và chi tiết quản trị truyền `quanLy=true` để vẫn xem được danh mục/gói đã ẩn; API chỉ cho quản trị dùng chế độ này.

`kiem-thu-api.ps1` ngừng bán hai gói và ẩn danh mục `Gói MẪU <mã 10 ký tự>` sau mỗi lần chạy, đồng thời giữ đơn hàng để đối chiếu. Dùng `don-dep-du-lieu-kiem-thu.ps1` để ẩn các fixture cũ theo đúng mẫu tên; script bỏ qua danh mục có gói tên không khớp và không xóa đơn hay lịch sử.

Mã lọc fixture và script dọn đã được cập nhật, nhưng chưa chạy trên DB thật: API/SQL chưa chạy, NuGet restore bị proxy từ chối (`NU1301`), Docker chưa có. PowerShell parser đã chấp nhận hai script. Chạy script dọn với API demo hoạt động và tài khoản quản trị trước khi nghiệm thu dữ liệu trên app.

Còn cần kiểm tra giao diện và toàn bộ luồng CV/ứng tuyển trên Android, dọn dữ liệu kiểm thử có mã, chạy kiểm thử API/SQL đồng thời và biên dịch APK mới. Pixel 7 đã cold boot thành công; ADB hiện nhận `emulator-5554` ở trạng thái `device`, nhưng app chưa được cài. API/SQL tại cổng 5080/14333 chưa chạy. Flutter CLI trong phiên công cụ không tạo được tiến trình con (`CreateFile failed 5`) và SDK gốc không ghi được `bin/cache/lockfile`; thử dùng bản SDK trong TEMP vẫn bị chặn khi gọi Git. Chưa tạo APK mới.

## Cập nhật giao diện

Các màn gói đăng tin có thẻ giá/lượt riêng; giỏ hàng có tóm tắt và một nút đặt đơn ở phần đầu; đơn hàng có thẻ trạng thái và màn chi tiết theo dòng hàng. Danh sách CV, hồ sơ ứng tuyển và biểu mẫu hồ sơ cá nhân có trình bày riêng. Trang quản trị gom chức năng vào các bảng tác vụ hai cột.

Đã chạy Dart formatter cho các file giao diện. `flutter pub get` hiện đã thành công. `flutter analyze` trước đó phát hiện cảnh báo dùng `BuildContext` sau await; đã thêm kiểm tra `mounted`. Widget test 360×800 phát hiện nút trong thẻ khám phá tràn ngang 75 px; đã giới hạn văn bản xuống hai dòng bằng `Flexible`, nhưng chưa chạy lại được analyze/widget test sau sửa do Flutter CLI bị chặn khởi chạy tiến trình con. Chưa nghiệm thu trực quan trên Pixel 7.

Không kèm mật khẩu, tài khoản quản trị cá nhân, cơ sở dữ liệu đang chạy, file tải lên, SDK hoặc cache. Mỗi máy cần tự cài công cụ và khởi tạo dữ liệu theo hướng dẫn. Không đưa file work/docker/mobi.env hoặc mật khẩu cá nhân vào nhóm source.

## Cập nhật kiểm thử luồng tuyển dụng

Đã thêm `kiem-thu-tuyen-dung.ps1` để tạo dữ liệu riêng theo mã chạy, thử tải/xóa CV, nộp hồ sơ, chống nộp lặp, quyền xem CV/hồ sơ giữa ứng viên và hai doanh nghiệp, xét hồ sơ, mời phỏng vấn, tuyển/từ chối, thông báo mới/đã đọc và lịch sử trạng thái. Script giữ dữ liệu và lịch sử trên DB trình diễn để đối chiếu; email dùng miền `example.invalid`.

PowerShell parser đã đọc script không có lỗi cú pháp. Chưa chạy tích hợp vì API tại `127.0.0.1:5080` và SQL Server tại `127.0.0.1:14333` không hoạt động trong môi trường này. Do đó chưa xác nhận phản hồi thực tế của API/SQL Server; cần chạy script trên DB demo trước nghiệm thu cuối.

## Cập nhật kiểm thử đồng thời

`kiem-thu-api.ps1` đã được mở rộng: tám yêu cầu cùng khóa đặt đơn chạy song song; tám yêu cầu cùng xác nhận thanh toán; bốn tin cạnh tranh ba lượt đăng; và ba lượt được hoàn lại song song. Các xung đột SQL 409 được thử lại có kiểm soát; script đối chiếu chính xác số dư, số lượt đang giữ và số đã dùng trước/sau. PowerShell parser đạt. API/SQL chưa chạy nên đây mới là kịch bản, chưa phải kết quả kiểm thử đồng thời thực tế.

## Kiểm tra Pixel 7 mới nhất

`flutter run` đã build và cài app debug trên AVD Pixel 7. Màn đăng nhập/trang khách mở được; khi API offline hiện nút tải lại sau timeout; Back từ trang khách về launcher; logcat không thấy lỗi Flutter hay tràn Flex. Đã mở Gboard và focus ô email, Back đóng bàn phím; cần kiểm tra trực quan bố cục sau bàn phím thêm. Backend chưa chạy; Docker Desktop/CLI, `sqlcmd` và `dotnet` không có trong môi trường hiện tại nên luồng dữ liệu/tài khoản và các kịch bản API chưa được nghiệm thu. APK debug và SHA-256 nằm trong `ket-qua-kiem-tra.md`.