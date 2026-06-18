# Build both Phase One distribution zips
$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
& (Join-Path $here "build-zip.ps1")
& (Join-Path $here "build-druid-zip.ps1")
Write-Host "All packs built."
