#Requires -Version 5.1
<#
.SYNOPSIS
  Cursor <-> Grok handoff runner for Warmane-WoW repo.

.EXAMPLE
  .\tools\agent-handoff.ps1 -RunGrok
  .\tools\agent-handoff.ps1 -Status
#>
param(
    [switch] $RunGrok,
    [switch] $Status,
    [switch] $NotifyCursor
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
$handoff = Join-Path $repoRoot 'Docs\grok-handoff'
$statusFile = Join-Path $handoff 'STATUS.md'
$grokTasks = Join-Path $handoff 'GROK_TASKS.md'
$responseFile = Join-Path $handoff 'grok-response.md'
$grokScript = Join-Path $PSScriptRoot 'grok-headless.ps1'

function Set-HandoffState([string] $state) {
    if (-not (Test-Path $statusFile)) { return }
    $content = Get-Content $statusFile -Raw
    $content = $content -replace '\*\*State:\*\* \w+', "**State:** $state"
    Set-Content -Path $statusFile -Value $content -NoNewline
}

if ($Status) {
    Get-Content $statusFile -ErrorAction SilentlyContinue
    if (Test-Path $responseFile) {
        Write-Host "`n--- grok-response.md (last 40 lines) ---"
        Get-Content $responseFile -Tail 40
    }
    exit 0
}

if (-not $RunGrok) {
    Write-Host 'Usage: -RunGrok | -Status'
    exit 1
}

if (-not (Test-Path $grokScript)) {
    Write-Error "Missing $grokScript"
}

Set-HandoffState 'GROK_WORKING'

$prompt = @"
You are Grok Build on the Warmane-WoW repo.
Read AGENTS.md and the file Docs/grok-handoff/GROK_TASKS.md.
Complete ALL tasks in GROK_TASKS.md.
Write your full answer ONLY to Docs/grok-handoff/grok-response.md (overwrite).
Also update Docs/grok-handoff/CURSOR_TASKS.md with a checkbox list for Cursor.
Do NOT edit any .lua files.
"@

$promptFile = Join-Path $handoff '_grok-prompt.txt'
Set-Content -Path $promptFile -Value $prompt

try {
    & $grokScript -PromptFile $promptFile -MaxTurns 12
    if ($LASTEXITCODE -ne 0) { throw "grok exited $LASTEXITCODE" }
    Set-HandoffState 'GROK_DONE'
    Write-Host "Grok done -> $responseFile"
    if ($NotifyCursor) {
        Write-Host 'Cursor: read grok-response.md and CURSOR_TASKS.md, then implement.'
    }
} catch {
    Set-HandoffState 'IDLE'
    throw
}
