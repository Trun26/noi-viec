# Tạo CV trong Nối Việc

## Cách dùng

1. Đăng nhập bằng tài khoản ứng viên, vào Tài khoản → CV của tôi.
2. Chọn Tạo CV mới. Họ tên, email và nội dung hồ sơ cá nhân được điền sẵn; bản nháp đã lưu được ưu tiên nếu có.
3. Chọn mẫu Tím chàm hoặc Tối giản. Nhập tên, vị trí ứng tuyển, email và các nội dung khác. Các mục nội dung để trống không xuất hiện trên CV.
4. Lưu nháp để sửa tiếp trên thiết bị. Mỗi tài khoản có bản nháp riêng.
5. Chọn Xem trước CV. Ứng dụng tạo PDF A4 nhiều trang trên Android và hiển thị chính các trang của PDF đó, không phải ảnh dựng từ form.
6. Nút tải xuống ở thanh trên cho phép lưu PDF vào vị trí được chọn. Hủy chọn vị trí sẽ không báo lưu thành công.
7. Chọn Lưu vào CV của tôi để tải PDF lên API, sau đó chọn CV đó khi ứng tuyển như CV tải lên từ máy. CV đã nộp được giữ theo quy tắc hồ sơ hiện có.

Không thay đổi hồ sơ cá nhân trên máy chủ khi sửa bản nháp CV. Có thể tiếp tục tải CV PDF có sẵn. Tạo, xem trước và lưu nháp không yêu cầu API; lưu CV vào tài khoản cần mạng và phiên đăng nhập hợp lệ. Nếu API lỗi, bản xem trước vẫn giữ để thử lại hoặc tải PDF về máy. Không tự gửi lại yêu cầu upload.

## Phạm vi và giới hạn

- Hiện dành cho Android; dùng PdfDocument và PdfRenderer của Android qua MethodChannel, không thêm thư viện hay tải font từ mạng.
- Hai mẫu là biến thể màu/đường nhấn trên cùng bố cục một cột để dễ đọc, không phải trình kéo thả.
- Tối đa 24.000 ký tự và 12 trang. Hỗ trợ tiếng Việt bằng font hệ thống Android. PDF chỉ chứa các trường người dùng nhập, không thêm thông tin bịa hoặc logo công ty.
- Bản PDF lưu trên máy chủ là một tệp mới; muốn sửa tiếp thì mở Tạo CV mới (bản nháp được khôi phục), xuất và lưu lại. Không ghi đè CV đã nộp.
- Không cần đổi lược đồ SQL: dùng endpoint tải tệp loại CV và quyền sở hữu sẵn có.

## Kiểm tra ngày 22/11/2026

- MainActivity.kt biên dịch riêng bằng Kotlin compiler 2.2.20 với Android SDK và Flutter embedding: đạt. Đây không thay thế build APK.
- Có ba widget test với MethodChannel/HTTP/kho lưu thay thế: điền sẵn và lưu đúng loại CV; lỗi upload rồi thử lại; chặn thiếu tên và tách bản nháp tài khoản. Người dùng đã chạy trong terminal thường: 3/3 đạt (`All tests passed!`). Bộ test dùng renderer và upload thay thế nên chưa chứng minh PDF thật/SQL Server.
- Build APK trong sandbox bị chặn kết nối Gradle daemon. Chưa xác minh PDF thực tế, phông tiếng Việt, phân trang và luồng upload trên thiết bị.

## Chạy kiểm tra

Từ thư mục gốc trong PowerShell:

```powershell
. .\tai-lieu\moi-truong.ps1
cd ung-dung
flutter test test/tao_cv_test.dart --no-pub
```

Dừng phiên flutter run cũ bằng q rồi chạy lại tai-lieu/chay-android.ps1. Hot reload hoặc hot restart không đăng ký được mã Android mới.

Trên Pixel 7, thử tên có dấu, nội dung dài hơn một trang, cả hai mẫu, cuộn xem trang cuối, tải PDF và mở bằng trình đọc PDF để kiểm tra. Sau đó lưu lên API, kiểm tra CV xuất hiện trong danh sách, chọn khi ứng tuyển. Thử mất mạng lúc lưu, hủy hộp thoại tải PDF và đăng xuất/đăng nhập tài khoản khác để xác minh bản nháp tách biệt.

- Phân tích Dart cho tao_cv.dart, chuc_nang.dart, thanh_phan.dart và tao_cv_test.dart: không có vấn đề.
- Lần chạy đầu test chọn nhầm vùng cuộn EditableText; đã gắn key cho danh sách biểu mẫu và chạy lại đạt 3/3. Kiểm tra dữ liệu bắt buộc thực hiện trên controller để không bỏ sót ô đang ngoài màn hình.
