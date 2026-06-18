# Symlink repo addon folders into WoW Interface/AddOns (Windows junctions).
# Advanced dev mode — SYNC_AND_PLAY.bat is the default workflow.
param(
    [Parameter(Mandatory = $true)]
    [string]$WowPath,
    [ValidateSet("DRUID", "WARLOCK", "BOTH")]
    [string]$Pack = "BOTH"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$dest = Join-Path $WowPath "Interface\AddOns"

if (-not (Test-Path "$WowPath\Wow.exe")) { throw "Wow.exe not found in: $WowPath" }
if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Path $dest -Force | Out-Null }

$packDirs = @()
switch ($Pack) {
    "DRUID" { $packDirs += Join-Path $root "PhaseOne_Druid_LevelingPack\Interface\AddOns" }
    "WARLOCK" { $packDirs += Join-Path $root "PhaseOne_LevelingPack\Interface\AddOns" }
    "BOTH" {
        $packDirs += Join-Path $root "PhaseOne_Druid_LevelingPack\Interface\AddOns"
        $packDirs += Join-Path $root "PhaseOne_LevelingPack\Interface\AddOns"
    }
}

$folderNames = New-Object System.Collections.Generic.HashSet[string]
foreach ($packDir in $packDirs) {
    if (-not (Test-Path $packDir)) { continue }
    Get-ChildItem -Path $packDir -Directory | ForEach-Object { [void]$folderNames.Add($_.Name) }
}

$linked = 0
foreach ($name in ($folderNames | Sort-Object)) {
    $source = $null
    foreach ($packDir in $packDirs) {
        $candidate = Join-Path $packDir $name
        if (Test-Path $candidate) { $source = $candidate; break }
    }
    if (-not $source) { continue }

    $target = Join-Path $dest $name
    if (Test-Path $target) {
        $item = Get-Item -LiteralPath $target -Force
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            Remove-Item -LiteralPath $target -Force -Recurse
        } else {
            Write-Warning "Skipping $name — real folder exists at $target (move/delete first)."
            continue
        }
    }

    New-Item -ItemType Junction -Path $target -Target $source -Force | Out-Null
    Write-Host "Linked: $name"
    $linked++
}

Write-Host ""
Write-Host "Created $linked junctions. Edit files in the repo; /reload in game."
Write-Host "To undo: delete the junction folders in WoW Interface/AddOns (repo files stay safe)."
