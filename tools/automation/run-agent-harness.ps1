# P1 agent dev harness: HWND input + chat log + screenshots + JSON report for Cursor
# Legit dev automation only (no memory reads). Not a gameplay bot.
param(
    [ValidateSet("smoke", "modules", "scan", "full")]
    [string]$Suite = "smoke",
    [switch]$UntilPass,
    [int]$MaxAttempts = 3,
    [switch]$Reload,
    [switch]$Sync,
    [switch]$DryRun,
    [int]$ClickX = 0,
    [int]$ClickY = 0
)

$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
. (Join-Path $here "WowInput.ps1")
. (Join-Path $here "harness-common.ps1")

$repoRoot = Split-Path (Split-Path $here -Parent) -Parent
$seqPath = Join-Path $here "test-sequences.json"
$seq = Get-Content $seqPath -Raw -Encoding UTF8 | ConvertFrom-Json

function Invoke-HarnessAttempt {
    param([int]$Attempt)

    $report = [ordered]@{
        timestamp = (Get-Date).ToString("o")
        attempt = $Attempt
        suite = $Suite
        success = $false
        screenshots = @{}
        chatLog = @{}
        frameXml = @{}
        savedVars = @{}
        addonsTxt = @{}
        steps = @()
    }

    $report.screenshots.before = Capture-WowWindow -Label ("attempt{0}-before" -f $Attempt)

    if ($Reload) {
        Send-WowSlashCommand "/reload"
        Start-Sleep -Seconds 10
        $report.steps += @{ cmd = "/reload"; result = "sent" }
    }

    Enable-WowChatLog
    $chatPath = Get-WowChatLogPath
    $report.chatLog.path = $chatPath
    $report.chatLog.exists = Test-Path $chatPath

    $report.frameXml.path = Get-FrameXmlLogPath
    $report.frameXml.errors = @(Get-P1FrameErrors)
    $report.addonsTxt = Get-P1AddonsTxtStatus

    if ($report.frameXml.errors.Count -gt 0) {
        $report.screenshots.afterErrors = Capture-WowWindow -Label ("attempt{0}-xml-errors" -f $Attempt)
        $report.success = $false
        $report.savedVars = Read-P1HarnessSavedVars
        return $report
    }

    Send-WowSlashCommand "/p1test state"
    Start-Sleep -Milliseconds 1500

    $steps = @()
    if ($Suite -eq "full") {
        foreach ($name in @("smoke", "ah_closed")) {
            $steps += $seq.suites.$name
        }
    } else {
        $steps = $seq.suites.$Suite
    }
    if (-not $steps) { throw "Unknown suite: $Suite" }

    $stepPass = 0
    $stepFail = 0
    foreach ($step in $steps) {
        $cmd = $step.cmd
        $wait = [int]($step.waitMs | ForEach-Object { if ($_){$_} else {2000} })
        Send-WowSlashCommand $cmd
        Start-Sleep -Milliseconds $wait

        $tail = @(Get-ChatLogTail -Lines 120)
        $p1Lines = @($tail | Where-Object { $_ -match '\[P1TEST\]' })
        $expect = $step.expect
        $ok = $true
        if ($expect) {
            $ok = $false
            foreach ($line in $tail) {
                if ($line -match $expect) { $ok = $true; break }
            }
        }

        if ($ok) { $stepPass++ } else { $stepFail++ }
        $report.steps += @{
            cmd = $cmd
            expect = $expect
            pass = $ok
            p1testLines = @($p1Lines | Select-Object -Last 8)
        }
    }

    if ($ClickX -gt 0 -and $ClickY -gt 0) {
        Click-WowScreen -X $ClickX -Y $ClickY
        Start-Sleep -Milliseconds 1500
        $report.steps += @{ cmd = "click"; x = $ClickX; y = $ClickY }
    }

    Start-Sleep -Milliseconds 800
    $report.chatLog.p1testLines = @(Get-P1TestLinesFromChat -Lines 200)
    $report.savedVars = Read-P1HarnessSavedVars
    $report.screenshots.after = Capture-WowWindow -Label ("attempt{0}-after" -f $Attempt)

    $summaryOk = Test-P1SummaryPassed -ChatLines $report.chatLog.p1testLines
    if (-not $summaryOk -and $report.savedVars.lastTestPass -ne $null -and $report.savedVars.lastTestTotal -ne $null) {
        $summaryOk = ($report.savedVars.lastTestPass -eq $report.savedVars.lastTestTotal)
    }

    $report.success = ($stepFail -eq 0) -and $summaryOk
    $report.stepPass = $stepPass
    $report.stepFail = $stepFail
    return $report
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " P1 Agent Harness - suite: $Suite"
Write-Host "========================================" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "[dry-run] Would run up to $MaxAttempts attempt(s), UntilPass=$UntilPass"
    exit 0
}

if ($Sync) {
    $play = Join-Path $repoRoot "PLAY.bat"
    if (-not (Test-Path $play)) { throw "PLAY.bat not found" }
    Write-Host "Syncing addons via PLAY.bat ..."
    cmd /c "`"$play`""
}

try {
    Focus-WowWindow | Out-Null
}
catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
    exit 2
}

$finalReport = $null
$attempt = 0
while ($attempt -lt $MaxAttempts) {
    $attempt++
    Write-Host ""
    Write-Host "Attempt $attempt / $MaxAttempts" -ForegroundColor Cyan
    $finalReport = Invoke-HarnessAttempt -Attempt $attempt
    $reportPath = Write-HarnessReport -Report $finalReport -FileName "harness-latest.json"
    Write-HarnessReport -Report $finalReport -FileName ("harness-{0}.json" -f (Get-Date -Format "yyyyMMdd-HHmmss")) | Out-Null

    if ($finalReport.success) {
        Write-Host "PASS - report: $reportPath" -ForegroundColor Green
        if ($finalReport.screenshots.after) {
            Write-Host "Screenshot: $($finalReport.screenshots.after)"
        }
        exit 0
    }

    Write-Host "FAIL - report: $reportPath" -ForegroundColor Red
    foreach ($tip in $finalReport.recommendations) {
        Write-Host "  -> $tip" -ForegroundColor Yellow
    }
    if ($finalReport.frameXml.errors.Count -gt 0) {
        Write-Host "FrameXML errors:" -ForegroundColor Red
        $finalReport.frameXml.errors | Select-Object -First 5 | ForEach-Object { Write-Host "  $_" }
    }

    if (-not $UntilPass -or $attempt -ge $MaxAttempts) { break }
    Write-Host "Retrying in 5s ..."
    Start-Sleep -Seconds 5
}

exit 1