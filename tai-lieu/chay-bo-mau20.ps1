$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
$env:ConnectionStrings__DuLieu = 'Server=(localdb)\Mobi;Database=mobi_mau20;Integrated Security=true;Connect Timeout=60'
$env:ASPNETCORE_ENVIRONMENT = 'Development'
$env:TrinhDien = 'true'
SqlLocalDB start Mobi
if ($LASTEXITCODE -ne 0) { throw 'Không khởi động được LocalDB Mobi.' }
dotnet run --project .\may-chu\may-chu.csproj --no-launch-profile -- --tao-bo-mau-20
if ($LASTEXITCODE -ne 0) { throw 'Chưa tạo được bộ mẫu. Giữ nguyên dữ liệu cũ; xem lỗi phía trên.' }
Write-Host 'Đang chạy máy chủ với cơ sở dữ liệu mobi_mau20. Đăng nhập quantri@mau20.example và mật khẩu vừa nhập.'
dotnet run --project .\may-chu\may-chu.csproj --no-launch-profile --urls http://0.0.0.0:5080
