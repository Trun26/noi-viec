$ErrorActionPreference = 'Stop'
$viTriCu = Get-Location
function GitBatBuoc {
    & git @args
    if ($LASTEXITCODE -ne 0) { throw 'Git chua hoan tat. Giu nguyen du lieu; gui lai thong bao loi de xu ly.' }
}
try {
    Set-Location -LiteralPath (Split-Path $PSScriptRoot -Parent)
    if (-not (Test-Path -LiteralPath '.git')) { GitBatBuoc init -b main }
    $cacRemote = @(& git remote)
    if ($cacRemote -contains 'origin') {
        $remote = & git remote get-url origin
        if ($remote -notin @('https://github.com/Trun26/noi-viec.git','https://github.com/Trun26/noi-viec','git@github.com:Trun26/noi-viec.git')) { throw 'Origin dang noi repository khac. Khong tu y thay doi.' }
    } else { GitBatBuoc remote add origin https://github.com/Trun26/noi-viec.git }
    $ten = & git config user.name
    if (-not $ten) { GitBatBuoc config user.name Trun26 }
    $email = & git config user.email
    if (-not $email) {
        $email = Read-Host 'Nhap email commit GitHub (co the dung email noreply trong GitHub Settings > Emails)'
        if ([string]::IsNullOrWhiteSpace($email)) { throw 'Can email de tao commit.' }
        GitBatBuoc config user.email $email
    }
    GitBatBuoc fetch origin
    GitBatBuoc add .gitignore .editorconfig .vscode README.md HUONG-DAN-NHOM.md analysis_options.yaml compose.yaml compose.docker.yaml global.json co-so-du-lieu may-chu tai-lieu ung-dung
    & git diff --cached --quiet
    if ($LASTEXITCODE -eq 1) { GitBatBuoc commit -m 'Cap nhat source ung dung Noi Viec' }
    elseif ($LASTEXITCODE -ne 0) { throw 'Khong doc duoc cac file cho commit.' }
    & git show-ref --verify --quiet refs/remotes/origin/main
    if ($LASTEXITCODE -eq 0) {
        & git merge origin/main --allow-unrelated-histories --no-edit
        if ($LASTEXITCODE -ne 0) { throw 'Can giai quyet xung dot truoc khi day code. Khong force push. Gui lai thong bao de xu ly.' }
    }
    GitBatBuoc push -u origin main
    Write-Host 'DA DONG BO: https://github.com/Trun26/noi-viec'
} finally { Set-Location -LiteralPath $viTriCu.Path }
