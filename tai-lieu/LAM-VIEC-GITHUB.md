# Làm việc nhóm trên GitHub

Source hiện là bản đang phát triển. Xem TRANG-THAI-BAN-GIAO.md và HUONG-DAN-NHOM.md trước khi chạy.

## Tham gia repository riêng tư

Chủ repository vào Settings → Collaborators → Add people, nhập username GitHub của thành viên. Người được mời chấp nhận lời mời rồi mới clone được. Chỉ gửi link repository không tự cấp quyền sửa.

## Quy trình mỗi thành viên

1. Clone repository về máy; mở thư mục trong VS Code.
2. Cài Flutter, Android SDK và Docker theo HUONG-DAN-NHOM.md. Mỗi máy tự khởi tạo database và tài khoản quản trị, không dùng chung mật khẩu.
3. Trước khi làm: `git switch main` và `git pull`.
4. Tạo nhánh riêng, ví dụ `git switch -c feature/ho-so`.
5. Sửa và kiểm tra; `git add` các file đã sửa, `git commit -m "Hoan thien ho so"`, `git push -u origin feature/ho-so`.
6. Mở Pull Request để nhóm xem và hợp nhất. Không ghi đè nhánh của người khác.

Không commit work/, outputs/, file .env, mật khẩu, database, ảnh/CV thật hoặc khóa ký APK. APK được gửi riêng sau khi kiểm thử, không đưa vào lịch sử Git.
