#Requires -Version 5.1
# On agent stop: mark handoff complete or chain follow-up for unfinished CURSOR_TASKS.
$ErrorActionPreference = 'SilentlyContinue'

$repoRoot = $PWD.Path
if (-not $repoRoot) { exit 0 }

$common = Join-Path $repoRoot 'tools\handoff-common.ps1'
if (-not (Test-Path $common)) { exit 0 }
. $common

$paths = Get-HandoffPaths -RepoRoot $repoRoot
$state = Get-HandoffState -RepoRoot $repoRoot

if (Test-CursorTasksComplete -RepoRoot $repoRoot) {
    if ($state -in @('CURSOR_WORKING', 'CURSOR_PENDING')) {
        Set-HandoffState -State 'CURSOR_SHIPPED' -Note 'Cursor hook detected all tasks complete.' -RepoRoot $repoRoot
    }
    exit 0
}

$shouldChain = $state -in @('GROK_DONE', 'CURSOR_PENDING', 'CURSOR_WORKING') -or (Test-Path $paths.Wake)
if (-not $shouldChain) { exit 0 }

$followup = @"
Handoff cycle incomplete. Read Docs/grok-handoff/CURSOR_TASKS.md and implement remaining unchecked items.
Set STATUS to CURSOR_WORKING, then CURSOR_SHIPPED when all [x]. See Docs/AUTONOMOUS_LOOP.md.
"@

@{ followup_message = $followup } | ConvertTo-Json -Compress
exit 0
