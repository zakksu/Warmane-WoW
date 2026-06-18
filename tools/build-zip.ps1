# Build PhaseOne_LevelingPack.zip for distribution
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$pack = Join-Path $root "PhaseOne_LevelingPack"
$out = Join-Path $root "PhaseOne_LevelingPack.zip"

if (Test-Path $out) { Remove-Item $out -Force }
Compress-Archive -Path $pack -DestinationPath $out -CompressionLevel Optimal
Write-Host "Created $out"
Get-Item $out | Select-Object FullName, Length
