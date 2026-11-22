$ErrorActionPreference = 'Stop'
$viTriCu = Get-Location
function GitBatBuoc {
    & git @args
    if ($LASTEXITCODE -ne 0) { throw 'Git chua hoan tat. Gui lai thong bao loi; khong force push.' }
}
try {
    Set-Location -LiteralPath (Split-Path $PSScriptRoot -Parent)
    $nhanh = & git branch --show-current
    if ($nhanh -ne 'main') { throw 'Hay chuyen ve main truoc khi chay.' }
    $remote = & git remote get-url origin
    if ($remote -notin @('https://github.com/Trun26/noi-viec.git','https://github.com/Trun26/noi-viec')) { throw 'Origin khong phai repository noi-viec cua Trun26.' }
    GitBatBuoc add tai-lieu/TRANG-THAI-BAN-GIAO.md tai-lieu/TAO-CV-TRONG-APP.md tai-lieu/day-cap-nhat-cv.ps1 ung-dung/android/app/src/main/kotlin/vn/mobi/ung_dung/MainActivity.kt ung-dung/lib/giao_dien/chuc_nang.dart ung-dung/lib/giao_dien/thanh_phan.dart ung-dung/lib/giao_dien/tao_cv.dart ung-dung/test/tao_cv_test.dart
    & git diff --cached --quiet
    if ($LASTEXITCODE -eq 1) { GitBatBuoc commit -m 'Them tao CV PDF trong ung dung' }
    elseif ($LASTEXITCODE -ne 0) { throw 'Khong doc duoc cac thay doi.' }
    GitBatBuoc fetch origin
    & git merge-base --is-ancestor origin/main HEAD
    if ($LASTEXITCODE -ne 0) { throw 'GitHub co commit moi chua nam trong ban nay. Commit CV da duoc giu tren may. Gui ket qua de gop code truoc khi push.' }
    GitBatBuoc push origin main
    Write-Output 'DA DAY PHAN TAO CV: https://github.com/Trun26/noi-viec'
} finally { Set-Location -LiteralPath $viTriCu.Path }
