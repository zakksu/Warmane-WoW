# Automated P1 in-game tests via keyboard injection + WoWChatLog.txt parse
# CE-style HWND targeting only - no memory reads/writes (legit dev automation)
param(
    [ValidateSet("smoke", "modules", "scan", "ah_closed", "ah_open", "full")]
    [string]$Suite = "smoke",
    [switch]$NoChatLog,
    [switch]$DryRun,
    [int]$ClickX = 0,
    [int]$ClickY = 0
)

$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
. (Join-Path $here "WowInput.ps1")

$seqPath = Join-Path $here "test-sequences.json"
$seq = Get-Content $seqPath -Raw -Encoding UTF8 | ConvertFrom-Json

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " P1 WoW automation - suite: $Suite"
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Requires: WoW logged in, druid toon, P1DruidGuide ON at char select"
Write-Host ""

if ($DryRun) {
    Write-Host "[dry-run] Would run suite $Suite" -ForegroundColor Yellow
    exit 0
}

try {
    Focus-WowWindow | Out-Null
    Write-Host "Focused WoW window" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
    exit 2
}

if (-not $NoChatLog) {
    Write-Host "Enabling /chatlog ..."
    Enable-WowChatLog
}

$steps = @()
if ($Suite -eq "full") {
    foreach ($name in @("smoke", "ah_closed")) {
        $steps += $seq.suites.$name
    }
} else {
    $steps = $seq.suites.$Suite
}

if (-not $steps) { throw "Unknown suite: $Suite" }

$fail = 0
$pass = 0
$logBefore = (Get-ChatLogTail -Lines 5) -join "`n"

foreach ($step in $steps) {
    $cmd = $step.cmd
    $wait = [int]($step.waitMs | ForEach-Object { if ($_){$_} else {2000} })
    Write-Host ""
    Write-Host ">> $cmd" -ForegroundColor Cyan
    if ($step.note) { Write-Host "   $($step.note)" -ForegroundColor DarkGray }

    Send-WowSlashCommand $cmd
    Start-Sleep -Milliseconds $wait

    $tail = Get-ChatLogTail -Lines 100
    $expect = $step.expect
    $ok = $true
    if ($expect) {
        $ok = $false
        foreach ($line in $tail) {
            if ($line -match $expect) { $ok = $true; break }
        }
        if (-not $ok) {
            foreach ($line in $tail) {
                if ($line -match '\[P1TEST\]|P1 AH|P1 Guide|P1 Scan') {
                    Write-Host "   log: $line" -ForegroundColor DarkGray
                }
            }
        }
    }

    if ($ok) {
        Write-Host "   PASS" -ForegroundColor Green
        $pass++
    } else {
        Write-Host "   FAIL (expected: $expect)" -ForegroundColor Red
        $fail++
    }
}

if ($ClickX -gt 0 -and $ClickY -gt 0) {
    Write-Host ""
    Write-Host ">> click ($ClickX, $ClickY)" -ForegroundColor Cyan
    Click-WowScreen -X $ClickX -Y $ClickY
    Start-Sleep -Milliseconds 1500
    $tail = Get-ChatLogTail -Lines 30
    foreach ($line in $tail) {
        if ($line -match "SEARCHED|QUEUED|P1 Guide") {
            Write-Host "   log: $line" -ForegroundColor DarkGray
        }
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Results: $pass pass, $fail fail"
Write-Host " Chat log: $(Get-WowChatLogPath)"
Write-Host "========================================" -ForegroundColor Cyan

if ($fail -gt 0) { exit 1 }
exit 0