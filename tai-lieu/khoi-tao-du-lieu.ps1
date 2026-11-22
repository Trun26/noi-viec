$viTriBanDau = Get-Location
try {
. "$PSScriptRoot/moi-truong.ps1"
if (-not $env:ConnectionStrings__DuLieu) { throw 'Chưa đặt ConnectionStrings__DuLieu.' }
dotnet run --project may-chu --no-launch-profile -- --khoi-tao-du-lieu
if ($LASTEXITCODE -ne 0) { throw 'Không khởi tạo được dữ liệu. Không tiếp tục tạo quản trị.' }
$env:EMAIL_QUAN_TRI = Read-Host 'Email quản trị'
$matKhauNhap = Read-Host 'Mật khẩu quản trị (ít nhất 12 ký tự)' -AsSecureString
try {
    $env:MAT_KHAU_QUAN_TRI = [System.Net.NetworkCredential]::new('', $matKhauNhap).Password
    dotnet run --project may-chu --no-launch-profile -- --tao-quan-tri
    if ($LASTEXITCODE -ne 0) { throw 'Chưa tạo được quản trị. Xem lỗi ở trên.' }
} finally {
    Remove-Item Env:MAT_KHAU_QUAN_TRI -ErrorAction SilentlyContinue
    Remove-Item Env:EMAIL_QUAN_TRI -ErrorAction SilentlyContinue
}

} finally {
    Set-Location -LiteralPath $viTriBanDau.Path
}
