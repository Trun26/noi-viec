param([string]$DiaChi='http://0.0.0.0:5080')
$viTriBanDau = Get-Location
try {
. "$PSScriptRoot/moi-truong.ps1"
if (-not $env:ConnectionStrings__DuLieu) {
    throw 'Chưa đặt biến ConnectionStrings__DuLieu trỏ tới SQL Server. Xem README.md.'
}
$env:ASPNETCORE_ENVIRONMENT = 'Development'
$env:TrinhDien = 'true'
dotnet run --project may-chu --no-launch-profile --urls $DiaChi
if ($LASTEXITCODE -ne 0) { throw 'Máy chủ chưa khởi động được. Kiểm tra thông báo ở trên.' }

} finally {
    Set-Location -LiteralPath $viTriBanDau.Path
}
