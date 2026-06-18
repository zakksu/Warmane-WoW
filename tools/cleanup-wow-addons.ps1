# Disable addons marked 0 in addons-manifest.txt (move to AddOns/_disabled/)
param(
    [Parameter(Mandatory = $true)]
    [string]$WowPath,
    [string]$ManifestPath = ""
)

$ErrorActionPreference = "Stop"
$tools = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ManifestPath) { $ManifestPath = Join-Path $tools "addons-manifest.txt" }

if (-not (Test-Path "$WowPath\Wow.exe")) { throw "Wow.exe not found in: $WowPath" }
if (-not (Test-Path $ManifestPath)) { throw "Manifest not found: $ManifestPath" }

$addonsDir = Join-Path $WowPath "Interface\AddOns"
if (-not (Test-Path $addonsDir)) { exit 0 }

$disabledDir = Join-Path $addonsDir "_disabled"
if (-not (Test-Path $disabledDir)) { New-Item -ItemType Directory -Path $disabledDir -Force | Out-Null }

$installed = @(Get-ChildItem -Path $addonsDir -Directory | ForEach-Object { $_.Name })
$toDisable = New-Object System.Collections.Generic.HashSet[string] ([StringComparer]::OrdinalIgnoreCase)

Get-Content -Path $ManifestPath -Encoding UTF8 | ForEach-Object {
    $line = $_.Trim()
    if (-not $line -or $line.StartsWith("#")) { return }
    if ($line -notmatch '^([^:]+):\s*([01])\s*$') { return }
    $name = $Matches[1].Trim()
    $state = [int]$Matches[2]
    if ($state -ne 0) { return }
    if ($name.EndsWith("*")) {
        $prefix = $name.TrimEnd("*")
        foreach ($folder in $installed) {
            if ($folder.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
                [void]$toDisable.Add($folder)
            }
        }
    } else {
        [void]$toDisable.Add($name)
    }
}

$moved = @()
foreach ($folder in $installed) {
    if ($folder -eq "_disabled") { continue }
    if (-not $toDisable.Contains($folder)) { continue }
    $src = Join-Path $addonsDir $folder
    $dst = Join-Path $disabledDir $folder
    if (Test-Path $dst) {
        $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $dst = Join-Path $disabledDir ("{0}_{1}" -f $folder, $stamp)
    }
    Move-Item -Path $src -Destination $dst -Force
    $moved += $folder
}

if ($moved.Count -eq 0) {
    Write-Host "No conflicting addons to disable."
} else {
    Write-Host ("Disabled {0} addon(s) -> Interface\AddOns\_disabled\" -f $moved.Count)
    Write-Host ("  {0}" -f ($moved -join ", "))
}
