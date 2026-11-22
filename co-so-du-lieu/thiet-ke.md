# Dữ liệu của đề tài độc lập

SQL Server lưu dữ liệu chính qua Entity Framework Core 10. Mô hình nằm trong `may-chu/DuLieu/MoHinh.cs`. Lệnh `--khoi-tao-du-lieu` chỉ tạo cơ sở dữ liệu/lược đồ ban đầu khi chưa có; không xóa hay nâng cấp lược đồ cũ. Cần bổ sung migration trước khi thay đổi lược đồ đã đưa vào sử dụng.

Các nhóm bảng:

| Nhóm | Bảng |
|---|---|
| Tài khoản | tai_khoan, phien |
| Doanh nghiệp | doanh_nghiep |
| Danh mục/sản phẩm | danh_muc, goi_luot, tep |
| Giỏ/đơn | dong_gio, don_hang, chi_tiet_don |
| Lượt | so_luot |
| Tuyển dụng | tin_tuyen_dung, ho_so_ung_tuyen, lich_su_ho_so, viec_da_luu |
| Thông báo | thong_bao |

Khóa chính dùng UUID. Giá dùng decimal(18,2). Các ràng buộc duy nhất chống trùng email, dòng giỏ, khóa đặt hàng, hồ sơ ứng tuyển và việc đã lưu. Khóa ngoại ngăn xóa dữ liệu đang được tham chiếu. Sổ lượt có ràng buộc số dư không âm; các thao tác đơn/lượt dùng giao dịch Serializable. Trường hợp đồng thời có thể phải tải lại/thử lại khi SQL Server hủy một giao dịch do tranh chấp.

SQLite trên Android lưu phản hồi đã xem và nháp theo cặp tài khoản/khóa, kèm thời gian cập nhật. Đăng xuất xóa bộ nhớ riêng của tài khoản. Token lưu trong Flutter Secure Storage, không lưu trong SQLite. Chỉ lỗi kết nối mới dùng bản lưu; lỗi xác thực/phân quyền không được thay bằng dữ liệu cũ. Các kiểm thử dùng bộ nhớ thay thế không chứng minh hoạt động SQLite trên thiết bị.
