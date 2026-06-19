# Shared killswitch + status for P1 automation (harness, file watch, agent-loop).
param(
    [ValidateSet("pause", "resume", "status")]
    [string]$Action = "status"
)

$ErrorActionPreference = "Stop"

$script:HarnessControlDir = Join-Path $PSScriptRoot "control"
$script:HarnessPauseFlag = Join-Path $script:HarnessControlDir "PAUSED"
$script:HarnessStatePath = Join-Path $script:HarnessControlDir "state.json"
$script:HarnessDaemonPid = Join-Path $script:HarnessControlDir "daemon.pid"

function Initialize-HarnessControl {
    if (-not (Test-Path $script:HarnessControlDir)) {
        New-Item -ItemType Directory -Path $script:HarnessControlDir -Force | Out-Null
    }
}

function Get-HarnessControlState {
    Initialize-HarnessControl
    if (-not (Test-Path $script:HarnessStatePath)) {
        return @{
            paused = (Test-Path $script:HarnessPauseFlag)
            watchEnabled = $true
            daemonRunning = $false
            lastRun = $null
            lastResult = $null
            lastMessage = ""
            pid = $null
        }
    }
    try {
        $obj = Get-Content $script:HarnessStatePath -Raw -Encoding UTF8 | ConvertFrom-Json
        $paused = (Test-Path $script:HarnessPauseFlag) -or [bool]$obj.paused
        return @{
            paused = $paused
            watchEnabled = if ($null -ne $obj.watchEnabled) { [bool]$obj.watchEnabled } else { $true }
            daemonRunning = [bool]$obj.daemonRunning
            lastRun = $obj.lastRun
            lastResult = $obj.lastResult
            lastMessage = [string]$obj.lastMessage
            pid = $obj.pid
        }
    } catch {
        return @{
            paused = (Test-Path $script:HarnessPauseFlag)
            watchEnabled = $true
            daemonRunning = $false
            lastRun = $null
            lastResult = $null
            lastMessage = "state read error"
            pid = $null
        }
    }
}

function Set-HarnessControlState {
    param([hashtable]$Patch)
    Initialize-HarnessControl
    $cur = Get-HarnessControlState
    foreach ($key in $Patch.Keys) { $cur[$key] = $Patch[$key] }
    $cur.paused = Test-Path $script:HarnessPauseFlag
    $cur | ConvertTo-Json -Depth 4 | Set-Content -Path $script:HarnessStatePath -Encoding UTF8
}

function Test-HarnessControlPaused {
    Initialize-HarnessControl
    if (Test-Path $script:HarnessPauseFlag) { return $true }
    $state = Get-HarnessControlState
    return [bool]$state.paused
}

function Set-HarnessControlPaused {
    param([string]$Reason = "user pause")
    Initialize-HarnessControl
    Set-Content -Path $script:HarnessPauseFlag -Value (Get-Date).ToString("o") -Encoding ASCII -NoNewline
    Set-HarnessControlState @{
        paused = $true
        lastMessage = $Reason
    }
}

function Clear-HarnessControlPaused {
    Initialize-HarnessControl
    if (Test-Path $script:HarnessPauseFlag) { Remove-Item $script:HarnessPauseFlag -Force }
    Set-HarnessControlState @{
        paused = $false
        lastMessage = "resumed"
    }
}

function Assert-HarnessControlAllowed {
    param(
        [switch]$IgnorePause,
        [string]$Context = "automation"
    )
    if ($IgnorePause) { return }
    if (Test-HarnessControlPaused) {
        throw "P1 automation paused (killswitch). Run RESUME_AUTO.bat before $Context."
    }
}

function Update-HarnessControlRunResult {
    param(
        [bool]$Success,
        [string]$Message = ""
    )
    Set-HarnessControlState @{
        lastRun = (Get-Date).ToString("o")
        lastResult = if ($Success) { "pass" } else { "fail" }
        lastMessage = $Message
    }
}

function Get-HarnessLatestSummary {
    $reportPath = Join-Path $PSScriptRoot "reports\harness-latest.json"
    if (-not (Test-Path $reportPath)) { return $null }
    try {
        $r = Get-Content $reportPath -Raw -Encoding UTF8 | ConvertFrom-Json
        return @{
            success = [bool]$r.success
            timestamp = [string]$r.timestamp
            suite = [string]$r.suite
            message = if ($r.verification.summaryLine) { $r.verification.summaryLine } elseif ($r.error) { $r.error } else { "" }
        }
    } catch {
        return $null
    }
}

$invoked = $MyInvocation.InvocationName
$dotSourced = ($invoked -eq '.') -or ($MyInvocation.Line -match '^\s*\.\s+')
if (-not $dotSourced) {
    switch ($Action) {
        "pause" {
            Set-HarnessControlPaused -Reason "CLI pause"
            Write-Host "Automation PAUSED (killswitch ON)." -ForegroundColor Yellow
        }
        "resume" {
            Clear-HarnessControlPaused
            Write-Host "Automation RESUMED." -ForegroundColor Green
        }
        "status" {
            $s = Get-HarnessControlState
            $latest = Get-HarnessLatestSummary
            Write-Host "paused: $($s.paused)"
            Write-Host "watch: $($s.watchEnabled)"
            Write-Host "daemon: $($s.daemonRunning)"
            if ($latest) {
                Write-Host "last harness: $($latest.success) $($latest.timestamp)"
            }
        }
    }
}