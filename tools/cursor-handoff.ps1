#Requires -Version 5.1
<#
.SYNOPSIS
  Wake Cursor to implement CURSOR_TASKS after Grok handoff.

.DESCRIPTION
  Tries headless Cursor (CLI or SDK). Falls back to CURSOR_WAKE.md for hooks / IDE.
#>
param(
    [switch] $DryRun
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'handoff-common.ps1')
$repoRoot = Get-RepoRoot
$paths = Get-HandoffPaths -RepoRoot $repoRoot

function Find-CursorCli {
    if (Get-Command cursor -ErrorAction SilentlyContinue) {
        return (Get-Command cursor).Source
    }
    $candidates = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\cursor\resources\app\bin\cursor.cmd'),
        (Join-Path $env:LOCALAPPDATA 'Programs\cursor\Cursor.exe')
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { return $c }
    }
    return $null
}

function Write-CursorWakeFile {
    $prompt = @"
# Cursor wake  - implement handoff

**Triggered:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

Read in order:
1. `Docs/grok-handoff/STATUS.md`  - set **State:** CURSOR_WORKING when you start
2. `Docs/grok-handoff/grok-response.md`  - Grok research output
3. `Docs/grok-handoff/CURSOR_TASKS.md`  - check off each item as you complete it

## Autonomous rules (AGENTS.md + Docs/AUTONOMOUS_LOOP.md)

- Implement all unchecked CURSOR_TASKS into Lua/Data.lua as appropriate
- Questie `wotlkItemDB.lua` wins for item IDs
- Run sync via `tools/sync-addons.ps1` (wow-path.cfg) after Lua edits
- Commit locally when done; push/tag only if gh auth works
- Set STATUS to **CURSOR_SHIPPED** when all tasks are [x]
- Queue next `GROK_TASKS.md` items for the following Grok cycle

Delete or rename this file after starting work (optional).
"@
    Set-Content -Path $paths.Wake -Value $prompt -Encoding UTF8
    Write-HandoffLog "Wrote CURSOR_WAKE.md (hook / IDE pickup)"
}

function Invoke-CursorCliAgent {
    param([string] $CursorExe, [string] $Prompt)
    # Cursor CLI agent surface varies by version; try known patterns.
    $argsList = @(
        @('agent', '--print', '--workspace', $repoRoot, $Prompt),
        @('--new-window', $repoRoot)
    )
    foreach ($a in $argsList) {
        try {
            Write-HandoffLog "Trying: $CursorExe $($a -join ' ')"
            if ($DryRun) { return $true }
            & $CursorExe @a 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-HandoffLog 'Cursor CLI invoked'
                return $true
            }
        } catch {
            Write-HandoffLog "Cursor CLI pattern failed: $($_.Exception.Message)"
        }
    }
    return $false
}

function Invoke-CursorSdk {
    param([string] $Prompt)
    if (-not $env:CURSOR_API_KEY) { return $false }
    $py = Get-Command python -ErrorAction SilentlyContinue
    if (-not $py) { return $false }

    $script = @"
import os, sys
try:
    from cursor_sdk import Agent, AgentOptions, LocalAgentOptions
except ImportError:
    sys.exit(2)
prompt = sys.argv[1]
cwd = sys.argv[2]
result = Agent.prompt(
    prompt,
    AgentOptions(
        api_key=os.environ['CURSOR_API_KEY'],
        model='composer-2.5',
        local=LocalAgentOptions(cwd=cwd),
    ),
)
print(result.status)
sys.exit(0 if result.status == 'completed' else 1)
"@
    $tmp = Join-Path $env:TEMP "cursor-handoff-$([guid]::NewGuid().ToString('N')).py"
    Set-Content -Path $tmp -Value $script -Encoding UTF8
    try {
        if ($DryRun) { return $true }
        & $py.Source $tmp $Prompt $repoRoot
        return ($LASTEXITCODE -eq 0)
    } finally {
        Remove-Item $tmp -Force -ErrorAction SilentlyContinue
    }
}

$cursorPrompt = @"
You are the Cursor agent on Warmane-WoW. Autonomous handoff cycle.

Read Docs/grok-handoff/STATUS.md, grok-response.md, and CURSOR_TASKS.md.
Set STATUS State to CURSOR_WORKING, implement every unchecked CURSOR_TASKS item,
sync addons (tools/sync-addons.ps1 + tools/wow-path.cfg), commit when done,
mark all CURSOR_TASKS [x], set STATUS to CURSOR_SHIPPED, queue next GROK_TASKS.md.
Follow AGENTS.md and Docs/AUTONOMOUS_LOOP.md. Do not ask the user.
"@

Set-HandoffState -State 'CURSOR_PENDING' -Note 'Cursor handoff triggered by agent-loop.' -RepoRoot $repoRoot
Write-CursorWakeFile

$cursorExe = Find-CursorCli
if ($cursorExe -and (Invoke-CursorCliAgent -CursorExe $cursorExe -Prompt $cursorPrompt)) {
    Set-HandoffState -State 'CURSOR_WORKING' -RepoRoot $repoRoot
    exit 0
}

if (Invoke-CursorSdk -Prompt $cursorPrompt) {
    Set-HandoffState -State 'CURSOR_WORKING' -RepoRoot $repoRoot
    exit 0
}

Write-HandoffLog 'No headless Cursor runtime  - waiting for IDE/hooks via CURSOR_WAKE.md'
exit 0
