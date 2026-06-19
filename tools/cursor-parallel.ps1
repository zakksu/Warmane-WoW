#Requires -Version 5.1
<#
.SYNOPSIS
  Wake multiple Cursor agents (one per handoff lane).

.EXAMPLE
  .\tools\cursor-parallel.ps1
  .\tools\emit-handoff-lane.ps1 -Lane druid-data
#>
param(
    [switch] $DryRun
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'handoff-common.ps1')

$repoRoot = Get-RepoRoot
$paths = Get-HandoffPaths -RepoRoot $repoRoot
$manifestPath = Join-Path $paths.Handoff 'task-manifest.json'

if (-not (Test-Path $manifestPath)) {
    & (Join-Path $PSScriptRoot 'cursor-handoff.ps1')
    exit $LASTEXITCODE
}

$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
$lanes = @($manifest.tasks | ForEach-Object { $_.cursorLane } | Select-Object -Unique)

Set-HandoffState -State 'CURSOR_PENDING' -Note "Parallel Cursor ($($lanes.Count) lanes)" -RepoRoot $repoRoot

foreach ($lane in $lanes) {
    $laneFile = "CURSOR_TASKS-$lane.md"
    $lanePath = Join-Path $paths.Handoff $laneFile
    if (-not (Test-Path $lanePath)) { continue }

    $wakePath = Join-Path $paths.Handoff "CURSOR_WAKE-$lane.md"
    $task = $manifest.tasks | Where-Object { $_.cursorLane -eq $lane } | Select-Object -First 1
    $owns = ($task.cursorPaths -join ', ')

    $body = @"
# Cursor wake - lane **$lane**

**Triggered:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

You are one of **$($lanes.Count) parallel Cursor agents**. Own only your lane files.

1. Read ``Docs/grok-handoff/STATUS.md`` — set **CURSOR_WORKING** when you start (first agent only)
2. Read ``Docs/grok-handoff/$laneFile``
3. Read ``Docs/grok-handoff/grok-response.md`` section for your lane

## Rules

- **OWN ONLY:** $owns
- Do NOT edit other lanes' files
- Mark ``$laneFile`` items [x] when done
- When ALL lane files are [x], set STATUS to **CURSOR_SHIPPED**

Spawn siblings: ``.\tools\emit-handoff-lane.ps1 -All``
"@
    if (-not $DryRun) {
        Set-Content -Path $wakePath -Value $body -Encoding UTF8
    }
    Write-HandoffLog "Wrote CURSOR_WAKE-$lane.md"
}

# Also write master wake for hook compatibility
$masterWake = @"
# Cursor wake - parallel orchestrator

**Lanes:** $($lanes -join ', ')
**Triggered:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

Open **$($lanes.Count) Cursor agents** (one per lane):
``````powershell
.\tools\emit-handoff-lane.ps1 -All
``````

Or read each ``CURSOR_WAKE-<lane>.md`` and ``CURSOR_TASKS-<lane>.md``.
Set STATUS to **CURSOR_WORKING**, then **CURSOR_SHIPPED** when all lanes [x].
"@
if (-not $DryRun) {
    Set-Content -Path $paths.Wake -Value $masterWake -Encoding UTF8
}
Write-HandoffLog "Parallel wake: $($lanes.Count) lane files + master CURSOR_WAKE.md"
exit 0
