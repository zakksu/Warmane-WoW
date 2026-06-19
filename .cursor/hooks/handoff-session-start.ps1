#Requires -Version 5.1
# Injects handoff context when a Cursor session starts and work is queued.
$ErrorActionPreference = 'SilentlyContinue'

$repoRoot = $PWD.Path
if (-not $repoRoot) { exit 0 }

. (Join-Path $repoRoot 'tools\handoff-common.ps1')

$state = Get-HandoffState -RepoRoot $repoRoot
$wake = (Get-HandoffPaths -RepoRoot $repoRoot).Wake

$active = $state -in @('GROK_DONE', 'CURSOR_PENDING', 'CURSOR_WORKING') -or (Test-Path $wake)
if (-not $active) { exit 0 }

$msg = @"
AGENT HANDOFF ACTIVE (state=$state).

Before any other work:
1. Read Docs/grok-handoff/STATUS.md, grok-response.md, CURSOR_TASKS.md
2. Set STATUS State to CURSOR_WORKING
3. Implement every unchecked CURSOR_TASKS item (Lua/Data.lua per AGENTS.md)
4. Sync: tools/sync-addons.ps1 with tools/wow-path.cfg
5. Mark all CURSOR_TASKS [x], set STATUS to CURSOR_SHIPPED
6. Follow Docs/AUTONOMOUS_LOOP.md — no user prompts unless gh/WoW path blocked
"@

@{ additional_context = $msg } | ConvertTo-Json -Compress
exit 0
