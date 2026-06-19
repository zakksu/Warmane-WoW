# Emit a copy-paste Cursor Cloud Agent prompt for a v2.0 lane.
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("brain", "ah", "rank", "integrate", "release", "orchestrator")]
    [string]$Lane,
    [switch]$All
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$lanesFile = Join-Path $PSScriptRoot "lanes.json"
$lanes = Get-Content $lanesFile -Raw | ConvertFrom-Json

function Emit-Lane($entry) {
    $paths = ($entry.paths -join ", ")
    $forbidden = ($entry.forbidden -join ", ")
    Write-Host ""
    Write-Host "========== LANE: $($entry.id) ==========" -ForegroundColor Cyan
    Write-Host @"
Repo: $root
Read: AGENTS.md, Docs/CURSOR_ORCHESTRATION.md, tools/orchestrator/lanes.json
Lane ID: $($entry.id) | Owner: $($entry.owner)

OWN ONLY: $paths
NEVER EDIT: $forbidden

Task: $($entry.task)

When done:
1. Mark lane done: .\tools\orchestrator\set-status.ps1 -Lane $($entry.id) -Status done
2. Do not touch other lanes' files.

User tests: PLAY.bat + /reload on druid toon.
"@
}

if ($All) {
    foreach ($entry in $lanes.lanes) {
        if ($entry.id -ne "orchestrator" -and $entry.id -ne "integrate") {
            Emit-Lane $entry
        }
    }
    exit 0
}

$match = $lanes.lanes | Where-Object { $_.id -eq $Lane }
if (-not $match) { throw "Unknown lane: $Lane" }
Emit-Lane $match