# Watches P1 Lua/XML edits and re-runs autonomous harness (for LOOP / dev sessions)
param(
    [int]$DebounceSec = 8,
    [string]$Suite = "smoke"
)

$ErrorActionPreference = "Stop"
$repo = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$auto = Join-Path $PSScriptRoot "run-autonomous.ps1"
$watchRoots = @(
    (Join-Path $repo "PhaseOne_Druid_LevelingPack\Interface\AddOns"),
    (Join-Path $repo "PhaseOne_LevelingPack\Interface\AddOns")
)

Write-Host "Watching P1 addons under repo (debounce ${DebounceSec}s) ..."
Write-Host "Ctrl+C to stop."

$pending = $false
$timer = $null

function Queue-AutoTest {
    if ($script:pending) { return }
    $script:pending = $true
    if ($script:timer) { $script:timer.Dispose() }
    $script:timer = New-Object System.Timers.Timer ($DebounceSec * 1000)
    $script:timer.AutoReset = $false
    Register-ObjectEvent -InputObject $script:timer -EventName Elapsed -Action {
        $script:pending = $false
        Write-Host ""
        Write-Host "Change detected - running autonomous harness ..." -ForegroundColor Cyan
        & $using:auto -Suite $using:Suite -MaxCycles 2 -SkipRelog:$false
    } | Out-Null
    $script:timer.Start()
}

$watchers = @()
foreach ($root in $watchRoots) {
    if (-not (Test-Path $root)) { continue }
    $w = New-Object System.IO.FileSystemWatcher $root, "*.lua"
    $w.IncludeSubdirectories = $true
    $w.EnableRaisingEvents = $true
    Register-ObjectEvent $w Changed -Action { Queue-AutoTest } | Out-Null
    Register-ObjectEvent $w Created -Action { Queue-AutoTest } | Out-Null
    Register-ObjectEvent $w Renamed -Action { Queue-AutoTest } | Out-Null
    $watchers += $w
    $wx = New-Object System.IO.FileSystemWatcher $root, "*.xml"
    $wx.IncludeSubdirectories = $true
    $wx.EnableRaisingEvents = $true
    Register-ObjectEvent $wx Changed -Action { Queue-AutoTest } | Out-Null
    $watchers += $wx
}

& $auto -Suite $Suite -MaxCycles 1
while ($true) { Start-Sleep -Seconds 60 }