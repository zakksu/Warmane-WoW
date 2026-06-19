#Requires -Version 5.1
<#
.SYNOPSIS
  Print copy-paste prompts to spawn parallel Cursor agents per handoff lane.

.EXAMPLE
  .\tools\emit-handoff-lane.ps1 -All
  .\tools\emit-handoff-lane.ps1 -Lane druid-data
#>
param(
    [string] $Lane,
    [switch] $All
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $repoRoot 'Docs\grok-handoff\task-manifest.json'

if (-not (Test-Path $manifestPath)) {
    Write-Host 'No task-manifest.json — use single-agent CURSOR_TASKS.md'
    exit 1
}

$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json

function Emit-Lane($Task) {
    $lane = $Task.cursorLane
    $owns = ($Task.cursorPaths -join ', ')
    Write-Host ""
    Write-Host "========== LANE: $lane ($($Task.id)) ==========" -ForegroundColor Cyan
    Write-Host @"
Repo: $repoRoot
Read: AGENTS.md, Docs/grok-handoff/STATUS.md, Docs/grok-handoff/CURSOR_TASKS-$lane.md

OWN ONLY: $owns
NEVER EDIT: other lanes' paths (see task-manifest.json)

Task: Implement $($Task.title) from Grok response $($Task.response)

When done:
1. Mark Docs/grok-handoff/CURSOR_TASKS-$lane.md all [x]
2. If all lanes complete, set STATUS to CURSOR_SHIPPED
3. Do not touch files outside your lane

Other agents run in parallel on: $(($manifest.tasks | Where-Object { $_.cursorLane -ne $lane } | ForEach-Object { $_.cursorLane }) -join ', ')
"@
}

if ($All) {
    foreach ($t in $manifest.tasks) { Emit-Lane $t }
    exit 0
}

if (-not $Lane) {
    Write-Host 'Pass -Lane <name> or -All'
    exit 1
}

$match = $manifest.tasks | Where-Object { $_.cursorLane -eq $Lane -or $_.id -eq $Lane }
if (-not $match) { throw "Unknown lane: $Lane" }
foreach ($t in $match) { Emit-Lane $t }
