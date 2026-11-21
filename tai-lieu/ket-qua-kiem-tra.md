# Kết quả kiểm tra ngày 21/11/2026

Bản làm việc tại `C:\Users\letri\Downloads\noi-viec-main\noi-viec-main` là thư mục source không có metadata Git. Chưa push GitHub; phần source đã sửa nằm trong workspace để nhóm tiếp tục đồng bộ sau.

| Hạng mục | Trạng thái hiện tại | Bằng chứng/giới hạn |
|---|---|---|
| Dart nghiệp vụ | Đạt 10/10 | Chạy lại bằng Dart VM ngày 21/11. HTTP và kho lưu được thay thế; không xác nhận SQLite, API hay Android thật. |
| Định dạng Dart | Đạt | Ba file giao diện/test đã kiểm tra, 0 file cần format. |
| Flutter analyze và widget test sau sửa | Chưa xác minh | Widget test trước đó tìm thấy tràn ngang 75 px; đã sửa bằng `Flexible`, nhưng chưa chạy lại. Flutter analyze qua phiên công cụ vẫn bị `CreateFile failed 5` khi gọi Git. |
| Kịch bản PowerShell | Đạt cú pháp | Parser AST không báo lỗi ở kiểm thử API, tuyển dụng và dọn dữ liệu. Chưa chạy tích hợp. |
| Pixel 7 | Đã cài và mở app debug | Cold boot xong; `emulator-5554` ở trạng thái `device`. Đã mở màn đăng nhập và trang khách; xem ghi chú nghiệm thu Android bên dưới. |
| API và SQL Server | Chưa chạy | `127.0.0.1:5080` và `127.0.0.1:14333` không lắng nghe. Có .NET SDK nhưng NuGet restore thất bại (`NU1301`, proxy `127.0.0.1:9` từ chối kết nối); Docker CLI/Desktop và `sqlcmd` không có nên chưa thể build API hay chạy kiểm thử tích hợp/dọn fixture. |
| Kiểm thử tuyển dụng và đồng thời | Có kịch bản, chưa nghiệm thu | Script bao phủ CV, ứng tuyển, phân quyền, thông báo, đơn hàng/lượt song song; cần API + SQL Server để lấy kết quả thật. |
| APK debug | Đã build/cài trên Pixel 7 | `ung-dung/build/app/outputs/flutter-apk/app-debug.apk`, 74.036.143 byte, SHA-256 `610F9922E7A357A065588B2F07DB9AEE43114216501F590029792A80D1C2EC86`. Chưa tạo APK phát hành cuối. |

Các kết quả cũ trong những phần bên dưới là bằng chứng của lần chạy trước, không thay cho kiểm tra lại sau thay đổi hiện tại. Các mục còn “chưa xác minh/chưa chạy” không được tính là nghiệm thu.

## Bổ sung ngày 21/11/2026 — dọn danh mục kiểm thử

| Hạng mục | Kết quả | Bằng chứng/giới hạn |
|---|---|---|
| Chặn fixture có mã khỏi API công khai | Đã sửa mã, chưa build API | API lọc chính xác mẫu tên `Gói MẪU` + 10 ký tự hex ở danh mục, danh sách gói và chi tiết; quản trị vẫn xem qua `quanLy=true`. Danh mục/gói không hoạt động cũng được ẩn. |
| Ngăn dữ liệu kiểm thử mới làm bẩn app | Đã thêm bước dọn sau kiểm thử | `kiem-thu-api.ps1` ngừng bán hai gói, ẩn danh mục và giữ đơn hàng; có bước dọn dự phòng trong `finally` |
| Dọn dữ liệu mã cũ | Có script, chưa chạy trên DB | `don-dep-du-lieu-kiem-thu.ps1` chỉ xử lý danh mục khớp chính xác `Gói MẪU <10 ký tự hex>` và gói có tên khớp cùng mã; cần API + SQL Server demo đang chạy |
| Cú pháp PowerShell | Đạt | Parser không báo lỗi cho hai script vừa sửa/thêm |
| Kiểm thử tích hợp API sau thay đổi | Chưa chạy | Cổng API `5080` và SQL Server `14333` không hoạt động trong môi trường hiện tại; cần chạy script trên DB demo để xác minh phản hồi thật |
| Flutter analyze/test sau thay đổi | Chưa xác minh | Không có `.dart_tool/package_config.json`; `flutter pub get --offline` thiếu `url_launcher 6.3.3`, còn lượt chạy online không trả output do môi trường mạng |

Không xóa đơn hàng hoặc lịch sử mua lượt do chúng giữ ảnh chụp giao dịch. Dữ liệu demo có tên cố định như `Đăng tin cơ bản` không thuộc mẫu có mã và không bị script đụng tới.

## Bổ sung ngày 21/11/2026 — giao diện thương mại, hồ sơ và quản trị

Đã thay thẻ chung bằng bố cục riêng cho gói đăng tin, dòng giỏ hàng, đơn mua lượt, CV cá nhân và hồ sơ ứng tuyển. Giỏ hàng đưa tóm tắt và hành động đặt đơn lên phần đầu; chi tiết đơn có danh sách dòng hàng và tổng tiền. Biểu mẫu hồ sơ có phần giới thiệu cùng nhóm liên hệ/năng lực. Trang quản trị có các bảng tác vụ hai cột.

Đã chạy Dart formatter cho `chuc_nang.dart`, `thanh_phan.dart`, `trang_chu.dart` và `bieu_mau.dart`. Đây mới là kiểm tra cú pháp/định dạng, không phải kiểm tra kiểu hay render. Flutter analyze/widget tests và kiểm tra tràn trên Android còn chờ khôi phục package `url_launcher 6.3.3` cùng thiết bị/emulator; `adb devices` hiện không có thiết bị.

10 ca nghiệp vụ kiểm tra cache tách tài khoản, lỗi quyền không dùng cache, badge đếm gói, giữ khóa đặt đơn khi mất phản hồi hoặc mở lại ứng dụng, không gửi lại thao tác quan trọng, phản hồi tài khoản cũ không lọt sang tài khoản mới, đăng xuất mất mạng, ngăn đặt đơn đồng thời và khôi phục phiên nhất quán.

Các kiểm thử dùng HTTP/kho lưu thay thế không chứng minh SQLite hoặc API/SQL Server thật đã hoạt động. Các ca cần nghiệm thu thêm nằm trong nghiem-thu.md, đặc biệt giao dịch đồng thời, cộng lượt một lần, CV, quyền sở hữu và giá đơn bất biến.

Môi trường công cụ từng bị Application Control chặn chương trình máy chủ và chặn localhost của Flutter/Gradle. Kiểm thử Flutter đã qua khi người dùng chạy trong terminal thường. Chưa kết luận nguyên nhân kết nối SQL Server Express thất bại trong sandbox là dịch vụ hay quyền môi trường; không tắt hoặc thay đổi bảo vệ Windows để chạy.

Thư viện máy chủ đang dùng phiên bản 10.0.15. Chưa kết luận kiểm toán lỗ hổng đạt vì dữ liệu NuGet hiện không truy cập được. Mô hình hiện dùng EnsureCreated cho cơ sở dữ liệu mới, chưa có migration nâng cấp.

## Bổ sung ngày 21/11/2026 — kịch bản kiểm thử tuyển dụng

| Hạng mục | Kết quả | Bằng chứng/giới hạn |
|---|---|---|
| Kịch bản CV → ứng tuyển → xét → phỏng vấn → tuyển/từ chối | Đã thêm, chưa chạy tích hợp | `kiem-thu-tuyen-dung.ps1` tạo 2 doanh nghiệp và 2 ứng viên mẫu, đi qua cả nhánh tuyển và từ chối; có kiểm tra nộp trùng, xóa CV đang tham chiếu và lịch sử trạng thái |
| Phân quyền hồ sơ/CV | Có ca kiểm tra, chưa chạy tích hợp | Kiểm tra ứng viên khác và nhà tuyển dụng ngoài doanh nghiệp không đọc/xét hồ sơ hoặc tải CV; ứng viên không tự đặt trạng thái tuyển dụng |
| Thông báo | Có ca kiểm tra, chưa chạy tích hợp | Kiểm tra thông báo khi nộp/đổi trạng thái, đánh dấu đã đọc và tài khoản khác không thể đánh dấu thông báo của người nhận |
| Cú pháp PowerShell | Đạt | PowerShell AST parser đọc `kiem-thu-tuyen-dung.ps1` không có lỗi |
| API/SQL Server thật | Chưa xác minh | API `127.0.0.1:5080` không lắng nghe; SQL Server `127.0.0.1:14333` cũng chưa có. Cần chạy script với DB demo và tài khoản quản trị để kết luận luồng nghiệp vụ |

Script giữ hồ sơ/lịch sử kiểm thử trên DB demo để lưu bằng chứng; mỗi lần chạy dùng email mới ở miền `example.invalid`, không gửi email thật. Không dùng script trên dữ liệu production.

## Cập nhật ngày 21/11/2026 — kiểm tra lại Android và đồng thời

| Hạng mục | Kết quả mới nhất | Bằng chứng/giới hạn |
|---|---|---|
| Kết nối Pixel 7 | ADB nhận emulator-5554 và `sys.boot_completed=1` | Emulator đã boot; `pm list packages vn.mobi.ung_dung` không thấy app, nên chưa có bản mới cài trên máy ảo |
| Giao diện điện thoại 360×800 | Lỗi phát hiện và đã sửa mã; chưa xác minh lại | Test tìm thấy RenderFlex tràn 75 px ở hàng lời gọi khám phá trong thẻ trang chủ. Văn bản chuyển sang `Flexible`, tối đa hai dòng và ellipsis. Cần chạy lại widget test trên Flutter test runner |
| Flutter package | Đạt | `flutter pub get` hoàn tất và tạo package config |
| Flutter analyze/test và APK | Chưa xác minh/chưa tạo | Flutter SDK cài đặt yêu cầu ghi `bin/cache/lockfile` ngoài vùng ghi được; bản sao SDK trong TEMP vẫn không khởi chạy được tiến trình Git từ Flutter (`CreateFile failed 5`). Analyze, test và `flutter build apk` không trả kết quả; không có APK mới |
| Chạy từ VS Code | Cấu hình sẵn | `.vscode/launch.json` có `Mobi Android` trỏ `ung-dung/lib/main.dart`, thiết bị cần chọn Pixel 7; công cụ UI bị auto-review từ chối thao tác vào VS Code trong phiên này |
| API/SQL Server | Chưa chạy | Cổng 5080 và 14333 không lắng nghe; chưa kiểm thử app Android gọi backend |
| Đặt đơn đồng thời | Đã thêm kịch bản, chưa chạy tích hợp | `kiem-thu-api.ps1` gửi 8 yêu cầu cùng khóa và xác nhận thanh toán song song; đối chiếu một đơn, một lần cộng lượt |
| Cạnh tranh và hoàn lượt đăng tin | Đã thêm kịch bản, chưa chạy tích hợp | 4 yêu cầu giữ lượt đồng thời với 3 lượt ban đầu, sau đó 3 lần hoàn lượt song song; kiểm tra số dư/đang giữ/đã dùng |
| Cú pháp kịch bản API | Đạt | PowerShell AST parser đọc `kiem-thu-api.ps1` không báo lỗi |

Không đánh dấu các kịch bản đồng thời là đạt cho tới khi chạy với API/SQL Server trình diễn. Bản APK trước đó (nếu có trong máy khác) không chứng minh đã đóng gói thay đổi giao diện hiện tại.


## Kiểm tra thực tế Pixel 7 — 21/11/2026

- `flutter run -d emulator-5554` đã hoàn tất build `assembleDebug`, cài package `vn.mobi.ung_dung` và mở được màn đăng nhập.
- Đã vào “Khám phá việc làm trước”; trang chủ khách render trên màn 1080×2400, CTA và thanh điều hướng hiển thị. Khi API không hoạt động, sau timeout trang hiện nút tải lại việc làm/danh mục thay cho spinner vô hạn. Logcat không ghi `FATAL EXCEPTION`, `FlutterError` hoặc `RenderFlex overflow`. Dữ liệu việc/gói chưa xác nhận vì API/SQL chưa bật.
- Đã mở Gboard và xác nhận email field nhận focus. Emulator ban đầu ẩn bàn phím mềm (`show_ime_with_hard_keyboard=0`); bật tùy chọn thành `1` để thử. Back đóng bàn phím và giữ form. Ảnh `screencap` khi IME mở không thể hiện rõ control phía sau dù hierarchy Android còn thấy các field; bố cục trực quan dưới bàn phím chưa kết luận đạt.
- Nhấn Back từ trang khách đưa ứng dụng về launcher, không crash. Khôi phục phiên, đăng xuất có phiên, mất mạng có dữ liệu đã đăng nhập và các thao tác cần tài khoản chưa kiểm tra vì backend không chạy.
- APK ở trên là bản debug do `flutter run` tạo, không phải bản release/nghiệm thu cuối.