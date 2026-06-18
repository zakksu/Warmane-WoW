# Build both Phase One distribution zips
$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
$root = Split-Path -Parent $here

foreach ($pack in @("PhaseOne_LevelingPack", "PhaseOne_Druid_LevelingPack")) {
    $install = Join-Path (Join-Path $root $pack) "INSTALL.bat"
    if (-not (Test-Path $install)) {
        throw "Missing installer: $install - run from repo root or restore INSTALL.bat in the pack folder."
    }
}

$rootInstall = Join-Path $root "INSTALL.bat"
if (-not (Test-Path $rootInstall)) {
    throw "Missing root installer: $rootInstall"
}

& (Join-Path $here "build-zip.ps1")
& (Join-Path $here "build-druid-zip.ps1")
Write-Host "All packs built."
