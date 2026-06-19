#Requires -Version 5.1
<#
.SYNOPSIS
  Continuous Grok <-> Cursor handoff loop for Warmane-WoW.

.EXAMPLE
  .\tools\agent-loop.ps1
  .\tools\agent-loop.ps1 -PollSeconds 60 -Once
  .\tools\start-agent-loop.ps1
#>
param(
    [int] $PollSeconds = 45,
    [int] $MaxRetries = 3,
    [int] $CursorWaitMinutes = 120,
    [switch] $Once,
    [switch] $DryRun
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'handoff-common.ps1')

$repoRoot = Get-RepoRoot
$paths = Get-HandoffPaths -RepoRoot $repoRoot
$handoffScript = Join-Path $PSScriptRoot 'agent-handoff.ps1'
$cursorScript = Join-Path $PSScriptRoot 'cursor-handoff.ps1'
$shipScript = Join-Path $PSScriptRoot 'ship-handoff.ps1'
$cursorWaitStart = $null

function Invoke-GrokCycle {
    Write-HandoffLog 'Starting Grok cycle'
    Set-HandoffState -State 'GROK_WORKING' -RepoRoot $repoRoot
    if ($DryRun) {
        Set-HandoffState -State 'GROK_DONE' -Note 'Dry run  - Grok skipped.' -RepoRoot $repoRoot
        return
    }
    Invoke-WithBackoff -Label 'Grok' -MaxAttempts $MaxRetries -BaseDelaySeconds 60 -Action {
        & (Join-Path $PSScriptRoot 'grok-parallel.ps1')
        if ($LASTEXITCODE -ne 0) {
            & $handoffScript -RunGrok -Sequential
            if ($LASTEXITCODE -ne 0) { throw "grok exited $LASTEXITCODE" }
        }
    }
    Set-HandoffState -State 'GROK_DONE' -Note 'Grok response ready for Cursor.' -RepoRoot $repoRoot
}

function Invoke-CursorCycle {
    Write-HandoffLog 'Starting Cursor cycle'
    if ($DryRun) {
        Set-HandoffState -State 'CURSOR_SHIPPED' -Note 'Dry run  - Cursor skipped.' -RepoRoot $repoRoot
        return
    }
    if (Test-Path (Join-Path $paths.Handoff 'task-manifest.json')) {
        & (Join-Path $PSScriptRoot 'cursor-parallel.ps1')
    } else {
        & $cursorScript
    }
    $script:cursorWaitStart = Get-Date
}

function Invoke-ShipCycle {
    Write-HandoffLog 'Starting ship cycle'
    if ($DryRun) {
        Set-HandoffState -State 'SHIPPED' -Note 'Dry run  - ship skipped.' -RepoRoot $repoRoot
        return
    }
    try {
        & $shipScript
    } catch {
        Write-HandoffLog "WARN: ship cycle error: $($_.Exception.Message)"
    }
}

function Step-HandoffLoop {
    $state = Get-HandoffState -RepoRoot $repoRoot

    switch ($state) {
        'IDLE' {
            if (Test-GrokTasksPending -RepoRoot $repoRoot) {
                Set-HandoffState -State 'GROK_PENDING' -RepoRoot $repoRoot
            }
        }
        'GROK_PENDING' {
            try {
                Invoke-GrokCycle
            } catch {
                Set-HandoffState -State 'GROK_FAILED' -Note "Grok failed: $($_.Exception.Message)" -RepoRoot $repoRoot
            }
        }
        'GROK_FAILED' {
            # Retry after backoff window (loop sleep handles delay)
            Set-HandoffState -State 'GROK_PENDING' -Note 'Retrying Grok after failure.' -RepoRoot $repoRoot
        }
        'GROK_DONE' {
            Invoke-CursorCycle
        }
        'CURSOR_PENDING' {
            if (Test-CursorTasksComplete -RepoRoot $repoRoot) {
                Set-HandoffState -State 'CURSOR_SHIPPED' -RepoRoot $repoRoot
            } elseif ($cursorWaitStart -and ((Get-Date) - $cursorWaitStart).TotalMinutes -gt $CursorWaitMinutes) {
                Write-HandoffLog 'Cursor wait timeout  - re-triggering wake'
                Invoke-CursorCycle
            }
        }
        'CURSOR_WORKING' {
            if (Test-CursorTasksComplete -RepoRoot $repoRoot) {
                Set-HandoffState -State 'CURSOR_SHIPPED' -RepoRoot $repoRoot
            }
        }
        'CURSOR_SHIPPED' {
            Invoke-ShipCycle
            if (Test-GrokTasksPending -RepoRoot $repoRoot) {
                Set-HandoffState -State 'GROK_PENDING' -RepoRoot $repoRoot
            } else {
                Set-HandoffState -State 'IDLE' -Note 'Cycle complete  - waiting for next GROK_TASKS queue.' -RepoRoot $repoRoot
            }
        }
        'SHIPPED' {
            if (Test-GrokTasksPending -RepoRoot $repoRoot) {
                Set-HandoffState -State 'GROK_PENDING' -RepoRoot $repoRoot
            }
        }
        default {
            Write-HandoffLog "WARN: unknown state '$state'  - resetting to IDLE"
            Set-HandoffState -State 'IDLE' -RepoRoot $repoRoot
        }
    }
}

Write-HandoffLog "Agent loop started (poll=${PollSeconds}s, once=$Once, dryRun=$DryRun)"
Write-HandoffLog "Repo: $repoRoot"

do {
    try {
        Step-HandoffLoop
    } catch {
        Write-HandoffLog "ERROR loop step: $($_.Exception.Message)"
    }

    if ($Once) { break }

    $state = Get-HandoffState -RepoRoot $repoRoot
    $sleep = $PollSeconds
    if ($state -in @('GROK_WORKING', 'CURSOR_WORKING')) { $sleep = [math]::Min($PollSeconds, 15) }
    if ($state -eq 'GROK_FAILED') { $sleep = $PollSeconds * 2 }

    Start-Sleep -Seconds $sleep
} while ($true)

Write-HandoffLog 'Agent loop exited'
