# Sync core addons from Warlock pack into Druid pack (no re-download)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$src = Join-Path $root "PhaseOne_LevelingPack\Interface\AddOns"
$dst = Join-Path $root "PhaseOne_Druid_LevelingPack\Interface\AddOns"

if (-not (Test-Path $src)) {
    Write-Error "Run Warlock pack setup first or use download-addons.ps1"
}

New-Item -ItemType Directory -Force -Path $dst | Out-Null
$skip = @("PhaseOneLoader", "P1FeralHUD", "P1DruidGuide")

Get-ChildItem -LiteralPath $src -Directory | Where-Object { $skip -notcontains $_.Name } | ForEach-Object {
    $target = Join-Path $dst $_.Name
    if (Test-Path $target) { Remove-Item $target -Recurse -Force }
    Copy-Item $_.FullName $target -Recurse -Force
    Write-Host "Synced $($_.Name)"
}

Write-Host "Done. PhaseOneLoader (Druid) was not overwritten."
