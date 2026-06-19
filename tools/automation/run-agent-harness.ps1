# Back-compat wrapper — use run-autonomous.ps1
param(
    [ValidateSet("smoke", "modules", "scan", "full")]
    [string]$Suite = "smoke",
    [switch]$UntilPass,
    [int]$MaxAttempts = 5,
    [switch]$Reload,
    [switch]$Sync,
    [switch]$DryRun,
    [int]$ClickX = 0,
    [int]$ClickY = 0
)

$autoArgs = @{
    Suite = $Suite
    MaxCycles = $MaxAttempts
    DryRun = $DryRun
}
if (-not $Sync) { $autoArgs["SkipSync"] = $true }
if ($Reload) { $autoArgs["SkipRelog"] = $false } else { $autoArgs["SkipRelog"] = $true }

& (Join-Path $PSScriptRoot "run-autonomous.ps1") @autoArgs
exit $LASTEXITCODE