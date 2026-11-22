$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$gocDuAn = Split-Path $PSScriptRoot -Parent
$banGiao = Join-Path $gocDuAn ('work/ban-giao-' + [guid]::NewGuid().ToString('N'))
$dauRa = Join-Path $gocDuAn 'outputs'
New-Item -ItemType Directory -Force -Path $banGiao, $dauRa | Out-Null
foreach ($thuMuc in @('may-chu', 'ung-dung', 'tai-lieu', 'co-so-du-lieu', '.vscode')) {
    robocopy (Join-Path $gocDuAn $thuMuc) (Join-Path $banGiao $thuMuc) /E /XD bin obj build .dart_tool .gradle .kotlin .idea .git kho-tep /XF .flutter-plugins-dependencies .flutter-plugins .packages pubspec_overrides.yaml key.properties '*.iml' local.properties appsettings.Development.json '*.user' '*.pfx' '*.jks' '*.keystore' '*.db' '.env' /R:0 /W:0 /NFL /NDL /NJH /NJS /NP
    if ($LASTEXITCODE -gt 7) { throw "Không đóng gói đủ thư mục $thuMuc" }
}
foreach ($ten in @('README.md', 'HUONG-DAN-NHOM.md', 'compose.yaml', 'compose.docker.yaml', 'global.json', '.gitignore', '.editorconfig', 'analysis_options.yaml')) {
    Copy-Item -LiteralPath (Join-Path $gocDuAn $ten) -Destination (Join-Path $banGiao $ten)
}
$tepZip = Join-Path $dauRa 'mobi-src-nhom.zip'
Compress-Archive -LiteralPath (Get-ChildItem -LiteralPath $banGiao -Force).FullName -DestinationPath $tepZip -Force
$zip = [IO.Compression.ZipFile]::OpenRead($tepZip)
try {
    $cam = @($zip.Entries.FullName -match '(^|/|\\)(\.git|work|kho-tep|bin|obj|build|\.dart_tool|\.gradle)(/|\\)')
    if ($cam.Count) { throw 'Gói mã nguồn chứa dữ liệu không được đưa vào bài nộp.' }
} finally { $zip.Dispose() }
Copy-Item -LiteralPath $tepZip -Destination (Join-Path $dauRa 'mobi-ma-nguon-doc-lap.zip') -Force
$apk = Join-Path $gocDuAn 'ung-dung/build/app/outputs/flutter-apk/app-debug.apk'
if (Test-Path -LiteralPath $apk) {
    $dichApk = Join-Path $dauRa 'mobi-debug.apk'
    Copy-Item -LiteralPath $apk -Destination $dichApk -Force
    if ((Get-FileHash -LiteralPath $apk).Hash -ne (Get-FileHash -LiteralPath $dichApk).Hash) {
        throw 'APK sao chép không trùng bản đã xây dựng.'
    }
}
Write-Output "Mã nguồn: $tepZip"
Write-Output 'Đã loại Git, cache, dữ liệu tải lên và khóa ký khỏi gói mã nguồn.'
