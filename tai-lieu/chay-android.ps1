param([string]$ApiUrl='http://10.0.2.2:5080/api/v1',[string]$ThietBi='')
$viTriBanDau = Get-Location
try {
. "$PSScriptRoot/moi-truong.ps1"
Set-Location -LiteralPath (Join-Path $gocDuAn 'ung-dung')
if ($ThietBi) { flutter run -d $ThietBi "--dart-define=API_URL=$ApiUrl" }
else { flutter run "--dart-define=API_URL=$ApiUrl" }

} finally {
    Set-Location -LiteralPath $viTriBanDau.Path
}
