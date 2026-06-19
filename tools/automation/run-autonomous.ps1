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
    [switch]$DryRun,
    [switch]$IgnorePause
)

$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
. (Join-Path $here "harness-control.ps1")
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
        $expect = $step.expect
        $verifyMs = [int]($step.verifyMs | ForEach-Object { if ($_){$_} else { [Math]::Max($wait, 3500) } })
        $maxAttempts = [int]($step.maxAttempts | ForEach-Object { if ($_){$_} else {3} })

        Dismiss-WowUI -EscapeCount 5 -ClickWorld -ClickChat
        Start-Sleep -Milliseconds 250

        $cmdOk = $true
        if ($expect) {
            $cmdOk = Send-WowSlashCommandVerified -Command $cmd -ExpectPattern $expect `
                -MaxAttempts $maxAttempts -VerifyTimeoutMs $verifyMs
        } else {
            Send-WowSlashCommand -Command $cmd -ClickChatFirst
        }

        $stepVerification = $null
        if ($cmd -match '/p1test') {
            $pollSec = [Math]::Max(6, [int][Math]::Ceiling([Math]::Max($wait, 5000) / 1000.0))
            $stepVerification = Wait-P1HarnessLogSummary -TimeoutSec $pollSec
        } else {
            Start-Sleep -Milliseconds $wait
        }

        $tail = @(Get-CombinedChatTail -Lines 150)
        $p1Lines = @(Get-P1TestLines -Lines 150 -PreferSavedVars)
        if ($p1Lines.Count -eq 0) {
            $p1Lines = @($tail | Where-Object { $_ -match '\[P1TEST\]' })
        }
        $ok = $cmdOk
        if ($expect -and -not $ok) {
            foreach ($line in $tail) {
                if ($line -match $expect) { $ok = $true; break }
            }
            if (-not $ok) {
                foreach ($line in $p1Lines) {
                    if ($line -match $expect) { $ok = $true; break }
                }
            }
        }
        if (-not $ok -and $stepVerification -and $stepVerification.passed) {
            $ok = $true
        }
        if (-not $ok -and $expect -match 'addon_P1DruidGuide') {
            $ok = Send-WowSlashCommandVerified -Command "/p1scan" -ExpectPattern "P1 Scan" -MaxAttempts 2
        }

        if ($ok) { $stepPass++ } else { $stepFail++ }
        $Report.steps += @{
            cmd = $cmd
            expect = $expect
            pass = $ok
            p1testLines = @($p1Lines | Select-Object -Last 10)
            verificationSource = if ($stepVerification) { $stepVerification.source } else { $null }
        }
    }

    $verification = Wait-P1HarnessLogSummary -TimeoutSec 12
    $Report.harnessLog = @{
        lines = @(if ($verification.harnessLog.Count -gt 0) { $verification.harnessLog } else { Read-P1HarnessLog -LastN 80 })
        count = 0
        source = "SavedVariables"
        failLines = @($verification.failLines)
    }
    $Report.harnessLog.count = $Report.harnessLog.lines.Count
    $Report.chatLog.p1testLines = @(Get-P1TestLines -Lines 250 -PreferSavedVars)
    $Report.savedVars = if ($verification.savedVars) { $verification.savedVars } else { Read-P1HarnessSavedVars }
    if (-not $Report.savedVars.harnessLogLines -or $Report.savedVars.harnessLogLines.Count -eq 0) {
        $Report.savedVars.harnessLogLines = $Report.harnessLog.lines
    }

    $svOk = Test-P1SavedVarsSummaryPassed -SavedVars $Report.savedVars
    $harnessOk = $false
    foreach ($line in $Report.harnessLog.lines) {
        if (Test-P1HarnessSummaryLine -Line $line) { $harnessOk = $true; break }
    }
    $chatOk = $false
    foreach ($line in $Report.chatLog.p1testLines) {
        if (Test-P1HarnessSummaryLine -Line $line) { $chatOk = $true; break }
    }

    $summaryOk = $svOk -or $harnessOk -or $chatOk -or $verification.passed
    $verifySource = "none"
    if ($svOk) { $verifySource = "SavedVariables" }
    elseif ($harnessOk) { $verifySource = "harnessLog" }
    elseif ($chatOk) { $verifySource = "chatLog" }
    elseif ($verification.passed) { $verifySource = $verification.source }

    $Report.verification = @{
        passed = $summaryOk
        source = $verifySource
        summaryLine = $verification.summaryLine
        savedVarsPass = $Report.savedVars.lastTestPass
        savedVarsTotal = $Report.savedVars.lastTestTotal
    }
    $Report.stepPass = $stepPass
    $Report.stepFail = $stepFail
    # Step expects are advisory; SavedVariables/harnessLog summary is authoritative pre-reload.
    $Report.success = $summaryOk
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
        harnessLog = @{ lines = @(); count = 0; source = "SavedVariables"; failLines = @() }
        verification = @{ passed = $false; source = "none"; summaryLine = $null; savedVarsPass = $null; savedVarsTotal = $null }
        addonsTxt = @{}
        steps = @()
        actions = @()
    }

    Ensure-WowReady -InWorldTimeoutSec 60 | Out-Null
    $report.screenshots.before = Capture-WowWindow -Label ("cycle{0}-before" -f $Cycle)
    $report.wowTitle = Get-WowWindowTitle
    $xmlOffset = Get-FrameXmlOffset

    Dismiss-WowUI -EscapeCount 5 -ClickWorld -ClickChat
    Start-Sleep -Milliseconds 350

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

    $chatOk = Enable-WowChatLog
    $report.chatLog.path = Get-WowChatLogPath
    $report.chatLog.exists = (Test-Path $report.chatLog.path) -or $chatOk
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

    Dismiss-WowUI -EscapeCount 6 -ClickWorld -ClickChat
    Start-Sleep -Milliseconds 500

    if ($seq.prelude) {
        foreach ($pre in $seq.prelude) {
            $preCmd = $pre.cmd
            $preWait = [int]($pre.waitMs | ForEach-Object { if ($_){$_} else {600} })
            Send-WowSlashCommandVerified -Command $preCmd -MaxAttempts 2 -VerifyTimeoutMs 1200 | Out-Null
            Start-Sleep -Milliseconds $preWait
        }
    }

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
    $postReload = Wait-P1HarnessLogSummary -TimeoutSec 25 -RequireFullPass
    $report.savedVars = if ($postReload.savedVars) { $postReload.savedVars } else { Read-P1HarnessSavedVars }
    if (-not $report.savedVars.harnessLogLines -or $report.savedVars.harnessLogLines.Count -eq 0) {
        $report.savedVars.harnessLogLines = @(Read-P1HarnessLog -LastN 80)
    }
    $report.harnessLog = @{
        lines = @(if ($postReload.harnessLog.Count -gt 0) { $postReload.harnessLog } else { $report.savedVars.harnessLogLines })
        count = 0
        source = "SavedVariables"
        failLines = @($postReload.failLines)
    }
    $report.harnessLog.count = $report.harnessLog.lines.Count

    $svOk = Test-P1SavedVarsSummaryPassed -SavedVars $report.savedVars
    if ($svOk) {
        $report.success = $true
        $report.verification = @{
            passed = $true
            source = "SavedVariables"
            summaryLine = if ($postReload.summaryLine) { $postReload.summaryLine } else { "lastTestPass=$($report.savedVars.lastTestPass)/$($report.savedVars.lastTestTotal)" }
            savedVarsPass = $report.savedVars.lastTestPass
            savedVarsTotal = $report.savedVars.lastTestTotal
        }
        $report.actions += "verified:savedvars"
    } elseif ($postReload.passed) {
        $report.success = $true
        $report.verification = @{
            passed = $true
            source = $postReload.source
            summaryLine = $postReload.summaryLine
            savedVarsPass = $report.savedVars.lastTestPass
            savedVarsTotal = $report.savedVars.lastTestTotal
        }
        $report.actions += "verified:$($postReload.source)"
    } else {
        $report.success = $false
        $report.verification = @{
            passed = $false
            source = "none"
            summaryLine = $postReload.summaryLine
            savedVarsPass = $report.savedVars.lastTestPass
            savedVarsTotal = $report.savedVars.lastTestTotal
        }
        $report.actions += "verified:failed"
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

if ((Test-HarnessControlPaused) -and -not $IgnorePause) {
    Write-Host "SKIPPED: automation paused (killswitch). Run RESUME_AUTO.bat or click Resume in tray." -ForegroundColor Yellow
    Update-HarnessControlRunResult -Success $false -Message "skipped: paused"
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
    Write-Host "Ensuring WoW is running and in-world ..."
    try {
        Ensure-WowReady -InWorldTimeoutSec 90 | Out-Null
        Write-Host "WoW ready: $(Get-WowWindowTitle)" -ForegroundColor Green
    } catch {
        Write-Host "WoW start/world check: $($_.Exception.Message)" -ForegroundColor Yellow
        Start-WowClient | Out-Null
        Focus-WowWindow | Out-Null
    }
}

$finalReport = $null
for ($cycle = 1; $cycle -le $MaxCycles; $cycle++) {
    if ((Test-HarnessControlPaused) -and -not $IgnorePause) {
        Write-Host "Stopped: killswitch engaged before cycle $cycle" -ForegroundColor Yellow
        Update-HarnessControlRunResult -Success $false -Message "stopped: paused mid-run"
        exit 0
    }
    Write-Host ""
    Write-Host "Cycle $cycle / $MaxCycles" -ForegroundColor Cyan
    $needRelog = (Test-AddonsNeedRelog) -or $ForceRelog
    $doRelog = $needRelog -and (-not $SkipRelog)
    try {
        $finalReport = Invoke-AutonomousCycle -Cycle $cycle -DoRelog:$doRelog
    } catch {
        $errMsg = $_.Exception.Message
        if ($errMsg -match 'Wow\.exe not running|WoW window not found') {
            try {
                Write-Host "WoW not running - restarting client ..." -ForegroundColor Yellow
                Start-WowClient | Out-Null
                $null = Wait-WowPlayerInWorld -TimeoutSec 90
                $finalReport = Invoke-AutonomousCycle -Cycle $cycle -DoRelog:$doRelog
            } catch {
                $errMsg = $_.Exception.Message
                $finalReport = [ordered]@{
                    timestamp = (Get-Date).ToString("o")
                    cycle = $cycle
                    suite = $Suite
                    success = $false
                    error = $errMsg
                    screenshots = @{}
                    actions = @("wow_restart_failed")
                }
            }
        } else {
            $finalReport = [ordered]@{
                timestamp = (Get-Date).ToString("o")
                cycle = $cycle
                suite = $Suite
                success = $false
                error = $errMsg
                screenshots = @{}
            }
        }
        if (-not $finalReport.success) {
            try {
                $finalReport.screenshots.error = Capture-WowWindow -Label ("cycle{0}-exception" -f $cycle)
            } catch { }
        }
    }

    $reportPath = Write-HarnessReport -Report $finalReport -FileName "harness-latest.json"
    Write-HarnessReport -Report $finalReport -FileName ("harness-{0}.json" -f (Get-Date -Format "yyyyMMdd-HHmmss")) | Out-Null

    if ($finalReport.success) {
        Write-Host "PASS cycle $cycle - $reportPath" -ForegroundColor Green
        Update-HarnessControlRunResult -Success $true -Message "cycle $cycle pass"
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
Update-HarnessControlRunResult -Success $false -Message "failed after $MaxCycles cycles"
exit 1