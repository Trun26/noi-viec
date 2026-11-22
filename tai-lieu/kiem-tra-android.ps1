$viTriBanDau = Get-Location
try {
    . "$PSScriptRoot/moi-truong.ps1"
    Set-Location -LiteralPath (Join-Path $gocDuAn 'ung-dung')
    if (-not (Test-Path '.dart_tool/package_config.json')) {
        flutter pub get
        if ($LASTEXITCODE -ne 0) { throw 'Chưa tải được thư viện Flutter.' }
    }
    flutter test --no-pub
    if ($LASTEXITCODE -ne 0) { throw 'Kiểm thử giao diện/Flutter chưa đạt.' }
    flutter build apk --debug --no-pub
    if ($LASTEXITCODE -ne 0) { throw 'Chưa tạo được APK Android.' }
    Write-Output ('APK: ' + (Join-Path $gocDuAn 'ung-dung/build/app/outputs/flutter-apk/app-debug.apk'))
} finally {
    Set-Location -LiteralPath $viTriBanDau.Path
}
