# Fast addon sync for dev: custom P1 folders by default; -Full mirrors entire pack AddOns.
param(
    [Parameter(Mandatory = $true)]
    [string]$WowPath,
    [switch]$Full
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$warlockSrc = Join-Path $root "PhaseOne_LevelingPack\Interface\AddOns"
$druidSrc = Join-Path $root "PhaseOne_Druid_LevelingPack\Interface\AddOns"
$dest = Join-Path $WowPath "Interface\AddOns"

if (-not (Test-Path "$WowPath\Wow.exe")) { throw "Wow.exe not found in: $WowPath" }
if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Path $dest -Force | Out-Null }

$customFolders = @(
    "PhaseOneLoader",
    "P1AutoQuest",
    "P1AdventureGuide",
    "P1FeralHUD",
    "P1WarlockHUD"
)

function Copy-AddonFolder {
    param([string]$SourceRoot, [string]$Folder, [string]$TargetRoot)
    $src = Join-Path $SourceRoot $Folder
    if (-not (Test-Path $src)) { return $false }
    $dst = Join-Path $TargetRoot $Folder
    & robocopy $src $dst /MIR /NFL /NDL /NJH /NJS /NC /NS /NP | Out-Null
    if ($LASTEXITCODE -ge 8) { throw "robocopy failed for $Folder (exit $LASTEXITCODE)" }
    return $true
}

function Detect-PackSources {
    param([string]$TargetRoot)
    $hasDruid = Test-Path (Join-Path $TargetRoot "P1FeralHUD")
    $hasWarlock = Test-Path (Join-Path $TargetRoot "P1WarlockHUD")
    $sources = @()
    if ($hasDruid) { $sources += "DRUID" }
    if ($hasWarlock) { $sources += "WARLOCK" }
    if ($sources.Count -eq 0) {
        Write-Host "No class HUD detected — syncing custom addons from both packs."
        return @("DRUID", "WARLOCK")
    }
    if ($sources.Count -eq 2) {
        Write-Host "Both Druid and Warlock HUDs detected — syncing custom addons from both packs."
    } else {
        Write-Host "Detected pack: $($sources[0])"
    }
    return $sources
}

if ($Full) {
    $packs = Detect-PackSources -TargetRoot $dest
    foreach ($pack in $packs) {
        $srcRoot = if ($pack -eq "DRUID") { $druidSrc } else { $warlockSrc }
        if (-not (Test-Path $srcRoot)) { continue }
        Write-Host "Full sync ($pack) -> $dest"
        & robocopy $srcRoot $dest /E /NFL /NDL /NJH /NJS /NC /NS /NP | Out-Null
        if ($LASTEXITCODE -ge 8) { throw "robocopy full sync failed (exit $LASTEXITCODE)" }
    }
    Write-Host "Full addon sync complete."
    exit 0
}

Write-Host "Quick sync (P1 custom addons only) -> $dest"
$packs = Detect-PackSources -TargetRoot $dest
$copied = @()

foreach ($pack in $packs) {
    $srcRoot = if ($pack -eq "DRUID") { $druidSrc } else { $warlockSrc }
    foreach ($folder in $customFolders) {
        if ($folder -eq "P1FeralHUD" -and $pack -ne "DRUID") { continue }
        if ($folder -eq "P1WarlockHUD" -and $pack -ne "WARLOCK") { continue }
        if (Copy-AddonFolder -SourceRoot $srcRoot -Folder $folder -TargetRoot $dest) {
            if ($copied -notcontains $folder) { $copied += $folder }
        }
    }
}

if ($copied.Count -eq 0) {
    Write-Warning "No custom addon folders copied. Run with -Full for first install."
} else {
    Write-Host "Synced: $($copied -join ', ')"
    Write-Host "Tip: SYNC_AND_PLAY.bat /FULL for Questie, TomTom, Leatrix, etc."
}
