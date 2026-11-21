# Kết quả kiểm tra ngày 21/11/2026

Bản đề tài độc lập tại H:\mobile_ck, không có Git repository ở gốc và không đẩy mã lên GitHub.

| Hạng mục | Kết quả mới nhất | Bằng chứng/giới hạn |
|---|---|---|
| Máy chủ .NET 10 | Biên dịch thành công, 0 lỗi | Cả công cụ và terminal người dùng đã xây dựng được. Có cảnh báo NU1900 vì không truy cập được dữ liệu kiểm toán NuGet |
| Flutter analyze | No issues found | Đã chạy lại bằng Flutter SDK đầy đủ sau sửa thư mục dev/examples |
| Dart nghiệp vụ độc lập | 10/10 đạt | Chạy bằng Dart VM, không cần listener mạng; HTTP và kho lưu được thay thế |
| Flutter test | 7/7 đạt | Đã quan sát terminal VS Code ghi 00:13 +7: All tests passed!; gồm 6 ca HTTP/trạng thái và 1 ca bố cục 360×800 |
| Định dạng | Đã chạy Dart/C# formatter | 15 file Dart lib/test; C# dùng dotnet format whitespace |
| PowerShell 5.1 | Parser không báo lỗi cú pháp | File .ps1 dùng UTF-8 BOM; các script khôi phục thư mục ban đầu. Kiểm thử API chưa được thực thi |
| VS Code | Đã quan sát 0 lỗi/0 cảnh báo | Loại work/outputs khỏi phân tích và theo dõi file; không tắt kiểm tra mã của ung-dung |
| APK | Xây dựng thành công | Đã quan sát Built build/app/outputs/flutter-apk/app-debug.apk sau 287,9 giây. Bản sao outputs/mobi-debug.apk có 155.113.503 byte, SHA-256 C0C2038445B167BDE500D9D786CEA956DD24487EDDF9EEFDB86B651D50474E8D |
| Android thực tế | Chưa nghiệm thu | Cần xác minh SQLite, chọn ảnh/PDF, bàn phím, quyền và luồng nghiệp vụ trên thiết bị |
| API + SQL Server | Chưa nghiệm thu | Cần chạy máy chủ và dữ liệu rồi thực thi kiem-thu-api.ps1 |
| Dữ liệu mẫu | Có mã và ảnh mẫu | 15 gói, 3 danh mục dịch vụ, 3 ngành, 1 doanh nghiệp, 2 tin; chưa thực thi seed trên SQL Server |

10 ca nghiệp vụ kiểm tra cache tách tài khoản, lỗi quyền không dùng cache, badge đếm gói, giữ khóa đặt đơn khi mất phản hồi hoặc mở lại ứng dụng, không gửi lại thao tác quan trọng, phản hồi tài khoản cũ không lọt sang tài khoản mới, đăng xuất mất mạng, ngăn đặt đơn đồng thời và khôi phục phiên nhất quán.

Các kiểm thử dùng HTTP/kho lưu thay thế không chứng minh SQLite hoặc API/SQL Server thật đã hoạt động. Các ca cần nghiệm thu thêm nằm trong nghiem-thu.md, đặc biệt giao dịch đồng thời, cộng lượt một lần, CV, quyền sở hữu và giá đơn bất biến.

Môi trường công cụ từng bị Application Control chặn chương trình máy chủ và chặn localhost của Flutter/Gradle. Kiểm thử Flutter đã qua khi người dùng chạy trong terminal thường. Chưa kết luận nguyên nhân kết nối SQL Server Express thất bại trong sandbox là dịch vụ hay quyền môi trường; không tắt hoặc thay đổi bảo vệ Windows để chạy.

Thư viện máy chủ đang dùng phiên bản 10.0.15. Chưa kết luận kiểm toán lỗ hổng đạt vì dữ liệu NuGet hiện không truy cập được. Mô hình hiện dùng EnsureCreated cho cơ sở dữ liệu mới, chưa có migration nâng cấp.

