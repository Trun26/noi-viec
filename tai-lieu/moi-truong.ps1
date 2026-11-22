$ErrorActionPreference = 'Stop'
$gocDuAn = Split-Path $PSScriptRoot -Parent
$env:DOTNET_CLI_HOME = Join-Path $gocDuAn 'work'
$env:NUGET_PACKAGES = Join-Path $gocDuAn 'work/nuget'
$env:NUGET_HTTP_CACHE_PATH = Join-Path $gocDuAn 'work/nuget-http'
$env:PUB_CACHE = Join-Path $gocDuAn 'work/pub-cache'
$env:GRADLE_USER_HOME = Join-Path $gocDuAn 'work/gradle'
$env:APPDATA = Join-Path $gocDuAn 'work/appdata'
$env:CI = 'true'
$flutterRieng = Join-Path $gocDuAn 'work/flutter/bin'
if (Test-Path $flutterRieng) { $env:PATH = $flutterRieng + ';' + $env:PATH }
$env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'
$dotnetRieng = Join-Path $gocDuAn 'work/dotnet/dotnet.exe'
if (Test-Path $dotnetRieng) {
    $env:DOTNET_ROOT = Split-Path $dotnetRieng
    $env:PATH = $env:DOTNET_ROOT + ';' + $env:PATH
}
Set-Location -LiteralPath $gocDuAn
