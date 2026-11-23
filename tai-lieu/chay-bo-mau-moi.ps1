$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
if (Get-NetTCPConnection -LocalPort 5080 -State Listen -ErrorAction SilentlyContinue) {
    throw 'Cổng 5080 đang được dùng. Nhấn Ctrl+C tại cửa sổ máy chủ cũ rồi chạy lại.'
}
$env:ConnectionStrings__DuLieu = 'Server=(localdb)\Mobi;Database=mobi_mau_moi;Integrated Security=true;Connect Timeout=60'
$env:ASPNETCORE_ENVIRONMENT = 'Development'
$env:TrinhDien = 'true'
SqlLocalDB start Mobi
if ($LASTEXITCODE -ne 0) { throw 'Không khởi động được LocalDB Mobi.' }
dotnet run --project .\may-chu\may-chu.csproj --no-launch-profile -- --tao-bo-mau-moi
if ($LASTEXITCODE -ne 0) { throw 'Chưa tạo được bộ mẫu mới. Chưa xóa cơ sở dữ liệu cũ.' }
dotnet run --project .\may-chu\may-chu.csproj --no-launch-profile -- --xoa-co-so-du-lieu-mau20
if ($LASTEXITCODE -ne 0) { throw 'Bộ mới đã tạo, nhưng chưa xóa được mobi_mau20. Xem lỗi phía trên.' }
Write-Host 'Đang chạy mobi_mau_moi. Đăng nhập quantri@maumoi.example, mật khẩu vừa nhập.'
dotnet run --project .\may-chu\may-chu.csproj --no-launch-profile --urls http://0.0.0.0:5080
