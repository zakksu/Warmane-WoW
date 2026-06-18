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

$manifestRules = Read-Manifest -Path $ManifestPath -InstalledNames $installed
$wtfAccount = Join-Path $WowPath "WTF\Account"
if (-not (Test-Path $wtfAccount)) {
    Write-Host "No WTF/Account yet - AddOns.txt will be created on first login."
    exit 0
}

$files = @(Get-ChildItem -Path $wtfAccount -Filter "AddOns.txt" -Recurse -File -ErrorAction SilentlyContinue)
if ($files.Count -eq 0) {
    Write-Host "No AddOns.txt files found under WTF/Account (normal before first character login)."
    exit 0
}

$updated = 0
foreach ($file in $files) {
    $parsed = Parse-AddonsTxt -Path $file.FullName
    $map = $parsed.Map
    $order = $parsed.Order

    foreach ($entry in $manifestRules.GetEnumerator()) {
        $name = [string]$entry.Key
        $state = [int]$entry.Value
        if (-not $map.Contains($name)) { [void]$order.Add($name) }
        $map[$name] = $state
    }

    Write-AddonsTxt -Path $file.FullName -Map $map -Order $order
    $updated++
}

Write-Host ('Updated {0} AddOns.txt files from manifest.' -f $updated)
