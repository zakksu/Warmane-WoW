# Headless PLAY.bat — sync addons + cleanup + AddOns.txt (no prompts)
param(
    [string]$WowPath = "",
    [ValidateSet("", "DRUID", "WARLOCK")]
    [string]$Pack = "DRUID"
)

$ErrorActionPreference = "Stop"
$tools = Split-Path $PSScriptRoot -Parent
if (-not $WowPath) {
    $cfg = Join-Path $tools "wow-path.cfg"
    if (-not (Test-Path $cfg)) { throw "Missing tools/wow-path.cfg" }
    $WowPath = (Get-Content $cfg -Raw).Trim()
}

$sync = Join-Path $tools "sync-addons.ps1"
$cleanup = Join-Path $tools "cleanup-wow-addons.ps1"
$addonsTxt = Join-Path $tools "write-addons-txt.ps1"

if (-not (Test-Path "$WowPath\Wow.exe")) { throw "Wow.exe not found: $WowPath" }

$packArg = @{}
if ($Pack) { $packArg["Pack"] = $Pack }

& $sync -WowPath $WowPath @packArg
& $cleanup -WowPath $WowPath
& $addonsTxt -WowPath $WowPath

$wowInput = Join-Path $PSScriptRoot "WowInput.ps1"
if (Test-Path $wowInput) {
    . $wowInput
    Enable-WowChatLogConfig
}

return @{
    wowPath = $WowPath
    syncedAt = (Get-Date).ToString("o")
}