# Build PhaseOne_Druid_LevelingPack.zip
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$pack = Join-Path $root "PhaseOne_Druid_LevelingPack"
$out = Join-Path $root "PhaseOne_Druid_LevelingPack.zip"

if (-not (Test-Path $pack)) {
    Write-Error "PhaseOne_Druid_LevelingPack folder not found"
}

if (Test-Path $out) { Remove-Item $out -Force }
Compress-Archive -Path $pack -DestinationPath $out -CompressionLevel Optimal
Write-Host "Created $out"
Get-Item $out | Select-Object FullName, @{n='SizeMB';e={[math]::Round($_.Length/1MB,2)}}
