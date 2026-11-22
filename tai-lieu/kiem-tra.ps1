$viTriBanDau = Get-Location
try {
. "$PSScriptRoot/moi-truong.ps1"
dotnet build may-chu --nologo
if ($LASTEXITCODE -ne 0) { throw 'Xây dựng máy chủ thất bại.' }
Set-Location -LiteralPath (Join-Path $gocDuAn 'ung-dung')
flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'Chưa tải được thư viện Flutter.' }
dart --packages=.dart_tool/package_config.json test/kiem_thu_nghiep_vu.dart
if ($LASTEXITCODE -ne 0) { throw 'Kiểm thử nghiệp vụ thất bại.' }
dart format --output=none --set-exit-if-changed lib test
if ($LASTEXITCODE -ne 0) { throw 'Mã Dart chưa đúng định dạng.' }
flutter analyze
if ($LASTEXITCODE -ne 0) { throw 'Phân tích Flutter thất bại.' }
flutter test
if ($LASTEXITCODE -ne 0) { throw 'Kiểm thử Flutter thất bại.' }
flutter build apk --debug
if ($LASTEXITCODE -ne 0) { throw 'Xây dựng APK thất bại.' }

} finally {
    Set-Location -LiteralPath $viTriBanDau.Path
}
