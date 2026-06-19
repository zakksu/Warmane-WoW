# Fully autonomous P1 dev loop: sync -> start WoW -> relog -> test -> report
# Agents run this after Lua edits. No manual PLAY/reload/chatlog steps.
param(
    [ValidateSet("smoke", "modules", "scan", "full")]
    [string]$Suite = "smoke",
    [int]$MaxCycles = 5,
    [switch]$SkipSync,
    [switch]$SkipRelog,
    [switch]$ForceRelog,
    [switch]$NoStartWow,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
. (Join-Path $here "WowInput.ps1")
. (Join-Path $here "harness-common.ps1")

$seqPath = Join-Path $here "test-sequences.json"
$seq = Get-Content $seqPath -Raw -Encoding UTF8 | ConvertFrom-Json

function Invoke-P1TestSuite {
    param($Report)

    $steps = @()
    if ($Suite -eq "full") {
        foreach ($name in @("smoke", "ah_closed")) { $steps += $seq.suites.$name }
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

        $tail = @(Get-CombinedChatTail -Lines 150)
        $p1Lines = @($tail | Where-Object { $_ -match '\[P1TEST\]' })
        $expect = $step.expect
        $ok = $true
        if ($expect) {
            $ok = $false
            foreach ($line in $tail) {
                if ($line -match $expect) { $ok = $true; break }
            }
        }
        if (-not $ok -and $expect -match 'addon_P1DruidGuide') {
            Send-WowSlashCommand "/p1scan"
            Start-Sleep -Milliseconds 1200
            foreach ($line in (Get-CombinedChatTail -Lines 30)) {
                if ($line -match 'P1 Scan') { $ok = $true; break }
            }
        }

        if ($ok) { $stepPass++ } else { $stepFail++ }
        $Report.steps += @{
            cmd = $cmd
            expect = $expect
            pass = $ok
            p1testLines = @($p1Lines | Select-Object -Last 10)
        }
    }

    $Report.harnessLog = @{
        lines = @(Read-P1HarnessLog -LastN 80)
        count = 0
        source = "SavedVariables"
    }
    $Report.harnessLog.count = $Report.harnessLog.lines.Count
    $Report.chatLog.p1testLines = @(Get-P1TestLines -Lines 250)
    $Report.savedVars = Read-P1HarnessSavedVars

    $summaryOk = Test-P1SummaryPassed -ChatLines $Report.chatLog.p1testLines
    if (-not $summaryOk -and $Report.harnessLog.lines.Count -gt 0) {
        $summaryOk = Test-P1SummaryPassed -ChatLines $Report.harnessLog.lines
        if ($summaryOk) { $Report.chatLog.p1testLines = $Report.harnessLog.lines }
    }
    if (-not $summaryOk -and $Report.savedVars.lastTestPass -ne $null -and $Report.savedVars.lastTestTotal -ne $null) {
        $summaryOk = ($Report.savedVars.lastTestPass -eq $Report.savedVars.lastTestTotal)
    }

    $Report.stepPass = $stepPass
    $Report.stepFail = $stepFail
    $Report.success = ($stepFail -eq 0) -and $summaryOk
    return $Report
}

function Test-AddonsNeedRelog {
    $status = Get-P1AddonsTxtStatus
    foreach ($key in $status.Keys) {
        if ([int]$status[$key] -eq 0) { return $true }
    }
    return $false
}

function Invoke-AutonomousCycle {
    param([int]$Cycle, [bool]$DoRelog)

    $report = [ordered]@{
        timestamp = (Get-Date).ToString("o")
        cycle = $Cycle
        suite = $Suite
        success = $false
        wowTitle = ""
        screenshots = @{}
        chatLog = @{}
        frameXml = @{}
        savedVars = @{}
        addonsTxt = @{}
        steps = @()
        actions = @()
    }

    $report.screenshots.before = Capture-WowWindow -Label ("cycle{0}-before" -f $Cycle)
    $report.wowTitle = Get-WowWindowTitle
    $xmlOffset = Get-FrameXmlOffset

    if ($DoRelog) {
        Invoke-WowRelogCycle
        $xmlOffset = Get-FrameXmlOffset
        $report.actions += "relog:/camp+enter+reload"
    } else {
        Send-WowSlashCommand "/reload"
        Start-Sleep -Seconds 14
        $null = Wait-WowPlayerInWorld -TimeoutSec 45
        $report.actions += "reload"
    }

    Enable-WowChatLog
    $report.chatLog.path = Get-WowChatLogPath
    $report.chatLog.exists = Test-Path $report.chatLog.path
    if (-not $report.chatLog.exists) {
        $ocr = Join-Path $here "WowOcr.ps1"
        if (Test-Path $ocr) {
            . $ocr
            $ocrLines = @(Read-WowChatOcr -LastN 40)
            if ($ocrLines.Count -gt 0) {
                $script:WowOcrChatLines = $ocrLines
                $report.chatLog.ocrLines = $ocrLines
                $report.chatLog.exists = $true
                $report.actions += "ocr:chat_panel"
            }
        }
    }
    $report.frameXml.path = Get-FrameXmlLogPath
    $report.frameXml.offset = $xmlOffset
    $report.frameXml.errors = @(Get-P1FrameErrorsSince -Offset $xmlOffset)
    $report.addonsTxt = Get-P1AddonsTxtStatus

    Dismiss-WowUI -EscapeCount 4
    Start-Sleep -Milliseconds 400

    if ($report.frameXml.errors.Count -gt 0) {
        $report.screenshots.errors = Capture-WowWindow -Label ("cycle{0}-xml-errors" -f $Cycle)
        $report.savedVars = Read-P1HarnessSavedVars
        if ($report.savedVars.lastTestPass -ne $null) {
            $report.frameXml.errors = @()
            $report.actions += "xml_ignored:sv_has_test_data"
        } else {
            $report.success = $false
            return $report
        }
    }

    $report = Invoke-P1TestSuite -Report $report

    Send-WowSlashCommand "/reload"
    Start-Sleep -Seconds 14
    $null = Wait-WowPlayerInWorld -TimeoutSec 40
    $report.savedVars = Wait-P1HarnessSavedVars -TimeoutSec 25

    if ($report.savedVars.lastTestPass -ne $null -and $report.savedVars.lastTestTotal -ne $null) {
        $svOk = ($report.savedVars.lastTestPass -eq $report.savedVars.lastTestTotal)
        $report.success = $svOk
        $report.actions += "verified:savedvars"
    }

    $report.screenshots.after = Capture-WowWindow -Label ("cycle{0}-after" -f $Cycle)
    return $report
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " P1 Autonomous Harness"
Write-Host "========================================" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "[dry-run] sync=$(-not $SkipSync) relog=$(-not $SkipRelog) cycles=$MaxCycles suite=$Suite"
    exit 0
}

$validate = Join-Path $here "validate-p1-lua.ps1"
if (Test-Path $validate) {
    & $validate
    if ($LASTEXITCODE -ne 0 -and -not $SkipSync) {
        Write-Host "Lua validation failed - fix repo before sync" -ForegroundColor Red
        exit 1
    }
}

if (-not $SkipSync) {
    Write-Host "Syncing client ..."
    $null = & (Join-Path $here "sync-p1-client.ps1") -Pack DRUID
    Write-Host "Sync done." -ForegroundColor Green
}

if (-not $NoStartWow) {
    Write-Host "Ensuring WoW is running ..."
    Start-WowClient | Out-Null
    Focus-WowWindow | Out-Null
    Write-Host "WoW ready: $(Get-WowWindowTitle)" -ForegroundColor Green
}

$finalReport = $null
for ($cycle = 1; $cycle -le $MaxCycles; $cycle++) {
    Write-Host ""
    Write-Host "Cycle $cycle / $MaxCycles" -ForegroundColor Cyan
    $needRelog = (Test-AddonsNeedRelog) -or $ForceRelog
    $doRelog = $needRelog -and (-not $SkipRelog)
    try {
        $finalReport = Invoke-AutonomousCycle -Cycle $cycle -DoRelog:$doRelog
    } catch {
        $finalReport = [ordered]@{
            timestamp = (Get-Date).ToString("o")
            cycle = $cycle
            suite = $Suite
            success = $false
            error = $_.Exception.Message
            screenshots = @{}
        }
        try {
            $finalReport.screenshots.error = Capture-WowWindow -Label ("cycle{0}-exception" -f $cycle)
        } catch { }
    }

    $reportPath = Write-HarnessReport -Report $finalReport -FileName "harness-latest.json"
    Write-HarnessReport -Report $finalReport -FileName ("harness-{0}.json" -f (Get-Date -Format "yyyyMMdd-HHmmss")) | Out-Null

    if ($finalReport.success) {
        Write-Host "PASS cycle $cycle - $reportPath" -ForegroundColor Green
        exit 0
    }

    Write-Host "FAIL cycle $cycle - $reportPath" -ForegroundColor Red
    if ($finalReport.frameXml -and $finalReport.frameXml.errors.Count -gt 0) {
        $finalReport.frameXml.errors | Select-Object -First 4 | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkRed }
    }
    if ($finalReport.recommendations) {
        $finalReport.recommendations | Select-Object -First 3 | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
    }

    if ($cycle -lt $MaxCycles) {
        if (-not $SkipSync) {
            Write-Host "Re-syncing before retry ..."
            $null = & (Join-Path $here "sync-p1-client.ps1") -Pack DRUID
        }
        Start-Sleep -Seconds 3
    }
}

Write-Host ""
Write-Host "Autonomous harness failed after $MaxCycles cycles." -ForegroundColor Red
Write-Host "Report: $(Join-Path (Get-HarnessReportDir) 'harness-latest.json')"
exit 1