$viTriBanDau = Get-Location
try {
. "$PSScriptRoot/moi-truong.ps1"
if (-not $env:ConnectionStrings__DuLieu) { throw 'Chưa đặt ConnectionStrings__DuLieu.' }
$matKhauNhap = Read-Host 'Mật khẩu hai tài khoản mẫu (ít nhất 12 ký tự)' -AsSecureString
try {
    $env:MAT_KHAU_MAU = [System.Net.NetworkCredential]::new('', $matKhauNhap).Password
    dotnet run --project may-chu --no-launch-profile -- --tao-du-lieu-mau
    if ($LASTEXITCODE -ne 0) { throw 'Chưa tạo được dữ liệu mẫu.' }
    Write-Output 'Tài khoản: tuyendung@mobi.example và ungvien@mobi.example. Dùng mật khẩu vừa nhập.'
} finally { Remove-Item Env:MAT_KHAU_MAU -ErrorAction SilentlyContinue }

} finally {
    Set-Location -LiteralPath $viTriBanDau.Path
}
