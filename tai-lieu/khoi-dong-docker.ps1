param([switch]$KhoiTao,[switch]$DuLieuMau)
$ErrorActionPreference = 'Stop'
$viTriBanDau = Get-Location
try {
    $gocDuAn = Split-Path $PSScriptRoot -Parent
    Set-Location -LiteralPath $gocDuAn
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { throw 'Chưa tìm thấy Docker Desktop.' }
    $loaiDocker = docker info --format '{{.OSType}}' 2>$null
    if ($LASTEXITCODE -ne 0 -or $loaiDocker -ne 'linux') { throw 'Hãy mở Docker Desktop và đợi Linux engine sẵn sàng rồi chạy lại.' }
    $thuMucCauHinh = Join-Path $gocDuAn 'work/docker'
    New-Item -ItemType Directory -Force -Path $thuMucCauHinh | Out-Null
    $tepMoiTruong = Join-Path $thuMucCauHinh 'mobi.env'
    if (-not (Test-Path -LiteralPath $tepMoiTruong)) {
        $matKhauSql = 'Mobi1!' + (New-Guid).ToString('N') + (New-Guid).ToString('N')
        Set-Content -LiteralPath $tepMoiTruong -Value "MAT_KHAU_SQL=$matKhauSql" -Encoding ascii
        Remove-Variable matKhauSql
    }
    $cauHinhCompose = @('--env-file', $tepMoiTruong, '-f', (Join-Path $gocDuAn 'compose.docker.yaml'))
    docker compose @cauHinhCompose build api
    if ($LASTEXITCODE -ne 0) { throw 'Chưa xây dựng được máy chủ Linux. Xem lỗi phía trên.' }
    docker compose @cauHinhCompose up -d --wait --wait-timeout 180 sql-server
    if ($LASTEXITCODE -ne 0) { throw 'SQL Server trong Docker chưa sẵn sàng.' }
    if ($KhoiTao) {
        docker compose @cauHinhCompose run --rm --no-deps api --khoi-tao-du-lieu
        if ($LASTEXITCODE -ne 0) { throw 'Chưa khởi tạo được lược đồ.' }
        docker compose @cauHinhCompose run --rm --no-deps api --tao-quan-tri
        if ($LASTEXITCODE -ne 0) { throw 'Chưa tạo được quản trị; không tiếp tục.' }
    }
    if ($DuLieuMau) {
        docker compose @cauHinhCompose run --rm --no-deps api --tao-du-lieu-mau
        if ($LASTEXITCODE -ne 0) { throw 'Chưa tạo được dữ liệu mẫu.' }
    }
    docker compose @cauHinhCompose up -d api
    if ($LASTEXITCODE -ne 0) { throw 'Chưa khởi động được API.' }
    Write-Output 'Máy chủ: http://127.0.0.1:5080/api/v1/suc-khoe'
    Write-Output 'Android emulator vẫn dùng http://10.0.2.2:5080/api/v1; không cần xây dựng lại APK.'
} finally {
    Set-Location -LiteralPath $viTriBanDau.Path
}
