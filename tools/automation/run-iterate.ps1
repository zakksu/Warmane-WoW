# Iterate harness until all required scope features pass (or max iterations).
param(
    [int]$MaxIterations = 50,
    [int]$PauseSec = 4,
    [switch]$SkipSync,
    [switch]$IgnorePause
)

$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
. (Join-Path $here "harness-control.ps1")
. (Join-Path $here "harness-common.ps1")

$auto = Join-Path $here "run-autonomous.ps1"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " P1 Scope Iterate - until all required pass"
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Max iterations: $MaxIterations | Killswitch: STOP_AUTO.bat"
Write-Host ""

$manifest = Get-FeatureScopeManifest
if ($manifest) {
    $req = @($manifest.features | Where-Object { $_.required }).Count
    Write-Host "Scope v$($manifest.version): $req required features (+ slash smoke)" -ForegroundColor DarkGray
}

for ($i = 1; $i -le $MaxIterations; $i++) {
    if ((Test-HarnessControlPaused) -and -not $IgnorePause) {
        Write-Host "[$i] PAUSED - waiting for RESUME_AUTO.bat ..." -ForegroundColor Yellow
        Start-Sleep -Seconds 8
        continue
    }

    Write-Host ""
    Write-Host "=== Iteration $i / $MaxIterations ===" -ForegroundColor Cyan
    $args = @{
        Suite = "scope"
        MaxCycles = 1
        SkipRelog = $true
        UntilScopeComplete = $true
    }
    if ($SkipSync) { $args.SkipSync = $true }
    if ($IgnorePause) { $args.IgnorePause = $true }

    & $auto @args
    $exit = $LASTEXITCODE

    $statusPath = Join-Path (Get-HarnessReportDir) "scope-status.json"
    if (Test-Path $statusPath) {
        $status = Get-Content $statusPath -Raw -Encoding UTF8 | ConvertFrom-Json
        Write-Host "Scope: $($status.requiredPass)/$($status.requiredTotal) required | complete=$($status.allRequiredPass)" -ForegroundColor $(if ($status.allRequiredPass) { "Green" } else { "Yellow" })
        if (-not $status.allRequiredPass) {
            foreach ($f in @($status.features | Where-Object { $_.required -and -not $_.pass } | Select-Object -First 6)) {
                Write-Host "  GAP [$($f.id)] $($f.failedChecks -join ', ')" -ForegroundColor DarkRed
            }
        }
    }

    if ($exit -eq 0) {
        Write-Host ""
        Write-Host "SCOPE COMPLETE after $i iteration(s)." -ForegroundColor Green
        Write-Host "Reports: scope-status.json, scope-gaps.txt, harness-latest.json"
        Update-HarnessControlRunResult -Success $true -Message "scope complete iter $i"
        exit 0
    }

    if ($i -lt $MaxIterations) {
        Write-Host "Retry in ${PauseSec}s (sync+recover) ..." -ForegroundColor DarkGray
        Start-Sleep -Seconds $PauseSec
    }
}

Write-Host ""
Write-Host "Stopped after $MaxIterations iterations - scope still incomplete." -ForegroundColor Red
Write-Host "Read: tools/automation/reports/scope-gaps.txt"
Update-HarnessControlRunResult -Success $false -Message "scope incomplete after $MaxIterations iter"
exit 1