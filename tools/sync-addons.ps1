# Quest pack sync: default = 6 core addons; -Full mirrors entire pack AddOns (dev only).
param(
    [Parameter(Mandatory = $true)]
    [string]$WowPath,
    [switch]$Full,
    [ValidateSet("", "DRUID", "WARLOCK")]
    [string]$Pack = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$warlockSrc = Join-Path $root "PhaseOne_LevelingPack\Interface\AddOns"
$druidSrc = Join-Path $root "PhaseOne_Druid_LevelingPack\Interface\AddOns"
$dest = Join-Path $WowPath "Interface\AddOns"

if (-not (Test-Path "$WowPath\Wow.exe")) { throw "Wow.exe not found in: $WowPath" }
if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Path $dest -Force | Out-Null }

$minimalFolders = @(
    "PhaseOneLoader",
    "P1AutoQuest",
    "P1QuestNav",
    "P1RangeDisplay",
    "P1DamageText",
    "P1AdventureGuide",
    "Questie-335",
    "TomTom",
    "!Astrolabe"
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

function Detect-Pack {
    param([string]$TargetRoot, [string]$ForcedPack)
    if ($ForcedPack) { return $ForcedPack }

    $loader = Join-Path $TargetRoot "PhaseOneLoader\PhaseOneLoader.lua"
    if (Test-Path $loader) {
        $text = Get-Content -Path $loader -Raw -ErrorAction SilentlyContinue
        if ($text -match "Warlock Pack") { return "WARLOCK" }
        if ($text -match "Druid Pack") { return "DRUID" }
    }

    if (Test-Path (Join-Path $TargetRoot "P1WarlockHUD")) { return "WARLOCK" }
    if (Test-Path (Join-Path $TargetRoot "P1FeralHUD")) { return "DRUID" }

    Write-Host "No pack detected - defaulting to DRUID quest pack."
    return "DRUID"
}

$packName = Detect-Pack -TargetRoot $dest -ForcedPack $Pack
$srcRoot = if ($packName -eq "DRUID") { $druidSrc } else { $warlockSrc }

if (-not (Test-Path $srcRoot)) { throw "Pack source not found: $srcRoot" }

if ($Full) {
    Write-Host "Full sync ($packName) -> $dest"
    & robocopy $srcRoot $dest /E /NFL /NDL /NJH /NJS /NC /NS /NP | Out-Null
    if ($LASTEXITCODE -ge 8) { throw "robocopy full sync failed (exit $LASTEXITCODE)" }
    Write-Host "Full addon sync complete (dev only)."
    exit 0
}

Write-Host "Quest pack sync ($packName) -> $dest"
$copied = @()
foreach ($folder in $minimalFolders) {
    if (Copy-AddonFolder -SourceRoot $srcRoot -Folder $folder -TargetRoot $dest) {
        $copied += $folder
    }
}

if ($copied.Count -eq 0) {
    Write-Warning "No addon folders copied. Check pack source at $srcRoot"
} else {
    Write-Host ("Synced: {0}" -f ($copied -join ", "))
}
