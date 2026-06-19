#Requires -Version 5.1
<#
.SYNOPSIS
  Cursor <-> Grok handoff runner for Warmane-WoW repo.

.EXAMPLE
  .\tools\agent-handoff.ps1 -RunGrok
  .\tools\agent-handoff.ps1 -RunCursor
  .\tools\agent-handoff.ps1 -Status
#>
param(
    [switch] $RunGrok,
    [switch] $RunCursor,
    [switch] $Status,
    [switch] $NotifyCursor,
    [switch] $Parallel,
    [switch] $Sequential
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'handoff-common.ps1')

$repoRoot = Get-RepoRoot
$paths = Get-HandoffPaths -RepoRoot $repoRoot
$grokScript = Join-Path $PSScriptRoot 'grok-headless.ps1'

if ($Status) {
    Get-Content $paths.Status -ErrorAction SilentlyContinue
    Write-Host "`nState: $(Get-HandoffState -RepoRoot $repoRoot)"
    if (Test-Path $paths.Response) {
        Write-Host "`n--- grok-response.md (last 40 lines) ---"
        Get-Content $paths.Response -Tail 40
    }
    exit 0
}

if ($RunCursor) {
    $manifest = Join-Path $paths.Handoff 'task-manifest.json'
    if ((Test-Path $manifest) -and -not $Sequential) {
        & (Join-Path $PSScriptRoot 'cursor-parallel.ps1')
    } else {
        & (Join-Path $PSScriptRoot 'cursor-handoff.ps1')
    }
    exit $LASTEXITCODE
}

if (-not $RunGrok) {
    Write-Host 'Usage: -RunGrok | -RunCursor | -Status'
    exit 1
}

if (-not (Test-Path $grokScript)) {
    Write-Error "Missing $grokScript"
}

Set-HandoffState -State 'GROK_WORKING' -RepoRoot $repoRoot

$manifest = Join-Path $paths.Handoff 'task-manifest.json'
$useParallel = $Parallel -or ((Test-Path $manifest) -and -not $Sequential)

if ($useParallel) {
    try {
        & (Join-Path $PSScriptRoot 'grok-parallel.ps1')
        if ($LASTEXITCODE -ne 0) { throw "grok-parallel exited $LASTEXITCODE" }
        if ($NotifyCursor) {
            & (Join-Path $PSScriptRoot 'cursor-parallel.ps1')
        }
        exit 0
    } catch {
        Set-HandoffState -State 'GROK_FAILED' -Note "Parallel Grok error: $($_.Exception.Message)" -RepoRoot $repoRoot
        throw
    }
}

$prompt = @"
You are Grok Build on the Warmane-WoW repo.
Read AGENTS.md and the file Docs/grok-handoff/GROK_TASKS.md.
Complete ALL tasks in GROK_TASKS.md.
Write your full answer ONLY to Docs/grok-handoff/grok-response.md (overwrite).
Also update Docs/grok-handoff/CURSOR_TASKS.md with a checkbox list for Cursor.
Do NOT edit any .lua files.
"@

$promptFile = Join-Path $paths.Handoff '_grok-prompt.txt'
Set-Content -Path $promptFile -Value $prompt

try {
    & $grokScript -PromptFile $promptFile -MaxTurns 30 -Yolo
    if ($LASTEXITCODE -ne 0) { throw "grok exited $LASTEXITCODE" }
    Set-HandoffState -State 'GROK_DONE' -Note 'Grok response ready for Cursor.' -RepoRoot $repoRoot
    Write-Host "Grok done -> $($paths.Response)"
    if ($NotifyCursor) {
        & (Join-Path $PSScriptRoot 'cursor-handoff.ps1')
    }
} catch {
    Set-HandoffState -State 'GROK_FAILED' -Note "Grok error: $($_.Exception.Message)" -RepoRoot $repoRoot
    throw
}
