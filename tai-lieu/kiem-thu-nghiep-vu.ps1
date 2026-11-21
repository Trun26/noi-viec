$viTriBanDau = Get-Location
try {
. "$PSScriptRoot/moi-truong.ps1"
Set-Location -LiteralPath (Join-Path $gocDuAn 'ung-dung')
if (-not (Test-Path '.dart_tool/package_config.json')) {
    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'Chưa tải được thư viện Flutter.' }
}
dart --packages=.dart_tool/package_config.json test/kiem_thu_nghiep_vu.dart
if ($LASTEXITCODE -ne 0) { throw 'Kiểm thử nghiệp vụ không đạt.' }

} finally {
    Set-Location -LiteralPath $viTriBanDau.Path
}
