# Merge tools/addons-manifest.txt into all WoW AddOns.txt files under WTF/Account.
# WotLK 3.3.5 format: "AddonFolderName: 0" (off) or "AddonFolderName: 1" (on)
param(
    [Parameter(Mandatory = $true)]
    [string]$WowPath,
    [string]$ManifestPath = ""
)

$ErrorActionPreference = "Stop"
$tools = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ManifestPath) { $ManifestPath = Join-Path $tools "addons-manifest.txt" }

if (-not (Test-Path $WowPath)) { throw "WoW path not found: $WowPath" }
if (-not (Test-Path "$WowPath\Wow.exe")) { throw "Wow.exe not found in: $WowPath" }
if (-not (Test-Path $ManifestPath)) { throw "Manifest not found: $ManifestPath" }

$addonsDir = Join-Path $WowPath "Interface\AddOns"
$installed = @()
if (Test-Path $addonsDir) {
    $installed = @(Get-ChildItem -Path $addonsDir -Directory | ForEach-Object { $_.Name })
}

function Read-Manifest {
    param([string]$Path, [string[]]$InstalledNames)
    $rules = [ordered]@{}

    Get-Content -Path $Path -Encoding UTF8 | ForEach-Object {
        $line = $_.Trim()
        if (-not $line -or $line.StartsWith("#")) { return }
        if ($line -notmatch '^([^:]+):\s*([01])\s*$') {
            Write-Warning "Skipping invalid manifest line: $line"
            return
        }
        $name = $Matches[1].Trim()
        $state = [int]$Matches[2]
        if ($name.EndsWith("*")) {
            $prefix = $name.TrimEnd("*")
            foreach ($folder in $InstalledNames) {
                if ($folder.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
                    $rules[$folder] = $state
                }
            }
        } else {
            $rules[$name] = $state
        }
    }
    return $rules
}

function Parse-AddonsTxt {
    param([string]$Path)
    $map = [ordered]@{}
    $order = New-Object System.Collections.Generic.List[string]
    if (-not (Test-Path $Path)) { return @{ Map = $map; Order = $order } }

    Get-Content -Path $Path -Encoding UTF8 | ForEach-Object {
        $line = $_.Trim()
        if (-not $line) { return }
        if ($line -match '^([^:]+):\s*([01])\s*$') {
            $name = $Matches[1].Trim()
            if (-not $map.Contains($name)) { [void]$order.Add($name) }
            $map[$name] = [int]$Matches[2]
        }
    }
    return @{ Map = $map; Order = $order }
}

function Write-AddonsTxt {
    param(
        [string]$Path,
        [System.Collections.Specialized.OrderedDictionary]$Map,
        [System.Collections.Generic.List[string]]$Order
    )
    $parent = Split-Path -Parent $Path
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }

    $lines = New-Object System.Collections.Generic.List[string]
    foreach ($name in $Order) {
        if ($Map.Contains($name)) {
            $lines.Add(('{0}: {1}' -f $name, $Map[$name])) | Out-Null
        }
    }
    Set-Content -Path $Path -Value $lines -Encoding ASCII
}

function Get-AddonsTxtTargets {
    param([string]$WtfAccountRoot)
    $targets = New-Object System.Collections.Generic.List[string]
    if (-not (Test-Path $WtfAccountRoot)) { return $targets }

    Get-ChildItem -Path $WtfAccountRoot -Directory | ForEach-Object {
        $accountDir = $_.FullName
        [void]$targets.Add((Join-Path $accountDir "AddOns.txt"))

        Get-ChildItem -Path $accountDir -Directory | ForEach-Object {
            $realmDir = $_.FullName
            Get-ChildItem -Path $realmDir -Directory | ForEach-Object {
                [void]$targets.Add((Join-Path $_.FullName "AddOns.txt"))
            }
        }
    }
    return $targets
}

$manifestRules = Read-Manifest -Path $ManifestPath -InstalledNames $installed

function Detect-PackGuide {
    param([string]$AddonsDir)
    $loader = Join-Path $AddonsDir "PhaseOneLoader\PhaseOneLoader.lua"
    if (Test-Path $loader) {
        $text = Get-Content -Path $loader -Raw -ErrorAction SilentlyContinue
        if ($text -match "Warlock Pack") { return "WARLOCK" }
        if ($text -match "Druid Pack") { return "DRUID" }
    }
    if (Test-Path (Join-Path $AddonsDir "P1DruidGuide")) { return "DRUID" }
    if (Test-Path (Join-Path $AddonsDir "P1WarlockHUD")) { return "WARLOCK" }
    return "DRUID"
}

$packGuide = Detect-PackGuide -AddonsDir $addonsDir
if ($packGuide -eq "WARLOCK") {
    $manifestRules["P1DruidGuide"] = 0
    $manifestRules["P1AdventureGuide"] = 1
} else {
    $manifestRules["P1DruidGuide"] = 1
    $manifestRules["P1AdventureGuide"] = 0
}
$wtfAccount = Join-Path $WowPath "WTF\Account"
if (-not (Test-Path $wtfAccount)) {
    Write-Host "No WTF/Account yet - AddOns.txt will be created on first login."
    exit 0
}

$targets = @(Get-AddonsTxtTargets -WtfAccountRoot $wtfAccount)
if ($targets.Count -eq 0) {
    Write-Host "No account folders under WTF/Account yet (log in once to create them)."
    exit 0
}

$updated = 0
$created = 0
foreach ($targetPath in $targets) {
    $isNew = -not (Test-Path $targetPath)
    $parsed = Parse-AddonsTxt -Path $targetPath
    $map = $parsed.Map
    $order = $parsed.Order

    foreach ($entry in $manifestRules.GetEnumerator()) {
        $name = [string]$entry.Key
        $state = [int]$entry.Value
        if (-not $map.Contains($name)) { [void]$order.Add($name) }
        $map[$name] = $state
    }

    Write-AddonsTxt -Path $targetPath -Map $map -Order $order
    $updated++
    if ($isNew) { $created++ }
}

if ($created -gt 0) {
    Write-Host ('Updated {0} AddOns.txt files from manifest ({1} created).' -f $updated, $created)
} else {
    Write-Host ('Updated {0} AddOns.txt files from manifest.' -f $updated)
}
