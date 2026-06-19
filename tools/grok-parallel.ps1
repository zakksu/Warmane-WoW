#Requires -Version 5.1
<#
.SYNOPSIS
  Run Grok tasks in parallel (one agent per lane) to avoid max-turn timeouts.

.EXAMPLE
  .\tools\grok-parallel.ps1
  .\tools\grok-parallel.ps1 -MaxParallel 2 -MaxTurnsPerTask 20
#>
param(
    [int] $MaxParallel = 3,
    [int] $MaxTurnsPerTask = 18,
    [switch] $DryRun
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'handoff-common.ps1')

$repoRoot = Get-RepoRoot
$paths = Get-HandoffPaths -RepoRoot $repoRoot
$manifestPath = Join-Path $paths.Handoff 'task-manifest.json'
$grokScript = Join-Path $PSScriptRoot 'grok-headless.ps1'
$responsesDir = Join-Path $paths.Handoff 'responses'

if (-not (Test-Path $manifestPath)) {
    Write-HandoffLog 'WARN: task-manifest.json missing - falling back to single Grok'
    & (Join-Path $PSScriptRoot 'agent-handoff.ps1') -RunGrok
    exit $LASTEXITCODE
}

$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
if ($manifest.maxTurnsPerTask) { $MaxTurnsPerTask = [int]$manifest.maxTurnsPerTask }
if ($manifest.maxParallel) { $MaxParallel = [int]$manifest.maxParallel }

$tasks = @($manifest.tasks)
if ($tasks.Count -eq 0) {
    Write-HandoffLog 'No tasks in manifest'
    exit 0
}

New-Item -ItemType Directory -Force -Path $responsesDir | Out-Null

function New-GrokTaskPrompt {
    param($Task, [string] $HandoffDir)
    $specRel = $Task.spec -replace '\\', '/'
    $respRel = $Task.response -replace '\\', '/'
    @"
You are Grok Build on the Warmane-WoW repo.
Read AGENTS.md.

Complete ONLY this task spec (read the file):
  Docs/grok-handoff/$specRel

Write your FULL answer ONLY to (overwrite):
  Docs/grok-handoff/$respRel

Rules:
- Tables and research only. Do NOT edit any .lua or .xml files.
- Cross-check item IDs in Questie wotlkItemDB.lua.
- Include wowhead wotlk links where helpful.
- End with a short "Cursor lane: $($Task.cursorLane)" checklist (markdown bullets).
"@
}

function Invoke-GrokTask {
    param($Task, [int] $MaxTurns)
    $taskId = $Task.id
    $responsePath = Join-Path $paths.Handoff ($Task.response -replace '/', '\')
    $promptText = New-GrokTaskPrompt -Task $Task -HandoffDir $paths.Handoff
    $promptFile = Join-Path $paths.Handoff "_grok-prompt-$taskId.txt"
    Set-Content -Path $promptFile -Value $promptText -Encoding UTF8

    Write-HandoffLog "Grok lane $taskId starting (maxTurns=$MaxTurns)"
    if ($DryRun) {
        Set-Content -Path $responsePath -Value "# $taskId dry-run`n" -Encoding UTF8
        return $true
    }

    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & $grokScript -PromptFile $promptFile -MaxTurns $MaxTurns -Yolo
        $ok = ($LASTEXITCODE -eq 0) -and (Test-Path $responsePath) -and ((Get-Item $responsePath).Length -gt 80)
        if (-not $ok) {
            Write-HandoffLog "WARN: Grok lane $taskId failed (exit=$LASTEXITCODE, response missing/short)"
        }
        return $ok
    } finally {
        $ErrorActionPreference = $prev
    }
}

function Merge-GrokResponses {
    param($Tasks)
    $merged = @"
# Grok parallel handoff - $(Get-Date -Format 'yyyy-MM-dd HH:mm')

Merged from $($Tasks.Count) parallel Grok lanes. Implement per lane CURSOR_TASKS files.

"@
    foreach ($t in $Tasks) {
        $resp = Join-Path $paths.Handoff ($t.response -replace '/', '\')
        $merged += "`n---`n`n## $($t.id) - $($t.title)`n`n"
        if (Test-Path $resp) {
            $merged += (Get-Content $resp -Raw)
        } else {
            $merged += "_No response file (lane failed)._`n"
        }
    }
    Set-Content -Path $paths.Response -Value $merged.TrimEnd() -Encoding UTF8
    Write-HandoffLog "Merged -> $($paths.Response)"
}

function Write-ParallelCursorTasks {
    param($Tasks)
    $main = "# Cursor follow-up - parallel lanes ($(Get-Date -Format 'yyyy-MM-dd'))`n`n"
    $main += "Grok ran **$($Tasks.Count) parallel agents**. Each lane has its own task file.`n`n"
    $main += "| Lane | File | Owns |`n|------|------|------|`n"
    foreach ($t in $Tasks) {
        $lane = $t.cursorLane
        $laneFile = "CURSOR_TASKS-$lane.md"
        $pathsList = ($t.cursorPaths -join ', ')
        $main += "| $lane | $laneFile | $pathsList |`n"

        $resp = Join-Path $paths.Handoff ($t.response -replace '/', '\')
        $body = @"
# Cursor lane: $lane ($($t.id))

**Own only:** $pathsList  
**Read:** Docs/grok-handoff/$($t.response -replace '\\','/')

- [ ] Read Grok response for $($t.id)
- [ ] Implement into allowed paths only (Data.lua per AGENTS.md)
- [ ] Mark this file all [x] when done

## Grok output

"@
        if (Test-Path $resp) {
            $body += (Get-Content $resp -Raw)
        }
        $lanePath = Join-Path $paths.Handoff $laneFile
        Set-Content -Path $lanePath -Value $body.TrimEnd() -Encoding UTF8
    }

    $main += "`n## All lanes complete`n`n"
    $main += "- [ ] All lane files above marked [x]`n"
    $main += "- [ ] Run PLAY.bat + remind user /reload`n"
    $main += "- [ ] Set STATUS to CURSOR_SHIPPED`n`n"
    $main += "Spawn more Cursor agents: .\tools\emit-handoff-lane.ps1 -All`n"
    Set-Content -Path $paths.CursorTasks -Value $main.TrimEnd() -Encoding UTF8
}

Write-HandoffLog "Parallel Grok: $($tasks.Count) tasks, maxParallel=$MaxParallel"
Set-HandoffState -State 'GROK_WORKING' -Note "Parallel Grok ($($tasks.Count) lanes)" -RepoRoot $repoRoot

$pending = @($tasks)
$attempt = 0
$maxRounds = 2

while ($pending.Count -gt 0 -and $attempt -lt $maxRounds) {
    $attempt++
    $batch = $pending | Select-Object -First $MaxParallel
    $jobs = @()

    foreach ($t in $batch) {
        $jobs += Start-Job -Name "grok-$($t.id)" -ScriptBlock {
            param($Root, $GrokScript, $TaskJson, $MaxTurns, $Dry)
            Set-Location $Root
            $task = $TaskJson | ConvertFrom-Json
            $handoff = Join-Path $Root 'Docs\grok-handoff'
            $specRel = $task.spec -replace '\\', '/'
            $respRel = $task.response -replace '\\', '/'
            $prompt = @"
You are Grok Build on the Warmane-WoW repo.
Read AGENTS.md.
Complete ONLY: Docs/grok-handoff/$specRel
Write FULL answer ONLY to: Docs/grok-handoff/$respRel
No .lua edits. Questie wotlkItemDB wins for item IDs.
"@
            $pf = Join-Path $handoff "_grok-prompt-$($task.id).txt"
            Set-Content -Path $pf -Value $prompt -Encoding UTF8
            if ($Dry) {
                $rp = Join-Path $Root (Join-Path 'Docs\grok-handoff' ($task.response -replace '/', '\'))
                Set-Content -Path $rp -Value "# $($task.id) dry-run" -Encoding UTF8
                return $true
            }
            $args = @('--cwd', $Root, '--prompt-file', $pf, '-m', 'grok-build', '--output-format', 'plain', '--yolo', '--max-turns', "$MaxTurns")
            $grok = Join-Path $env:USERPROFILE '.grok\bin\grok.exe'
            & $grok @args | Out-Null
            $rp = Join-Path $Root (Join-Path 'Docs\grok-handoff' ($task.response -replace '/', '\'))
            return (Test-Path $rp) -and ((Get-Item $rp).Length -gt 80)
        } -ArgumentList $repoRoot, $grokScript, ($t | ConvertTo-Json -Compress), $MaxTurnsPerTask, ($DryRun.IsPresent)
    }

    $jobs | Wait-Job | Out-Null
    $stillPending = @()
    for ($i = 0; $i -lt $batch.Count; $i++) {
        $ok = Receive-Job -Job $jobs[$i]
        Remove-Job -Job $jobs[$i] -Force
        if ($ok) {
            Write-HandoffLog "Grok lane $($batch[$i].id) OK"
        } else {
            Write-HandoffLog "WARN: Grok lane $($batch[$i].id) failed round $attempt"
            $stillPending += $batch[$i]
        }
    }
    $pending = $stillPending
    if ($pending.Count -gt 0 -and $attempt -lt $maxRounds) {
        Write-HandoffLog "Retrying $($pending.Count) failed lane(s) after 45s"
        Start-Sleep -Seconds 45
    }
}

$succeeded = @($tasks | Where-Object {
    $rp = Join-Path $paths.Handoff ($_.response -replace '/', '\')
    (Test-Path $rp) -and ((Get-Item $rp).Length -gt 80)
})

if ($succeeded.Count -eq 0) {
    Write-HandoffLog 'WARN: All parallel Grok lanes failed - exit 1 for Cursor fallback'
    Set-HandoffState -State 'GROK_FAILED' -Note 'All parallel Grok lanes failed. Cursor uses task specs.' -RepoRoot $repoRoot
    exit 1
}

Merge-GrokResponses -Tasks $tasks
Write-ParallelCursorTasks -Tasks $tasks

$note = "Parallel Grok: $($succeeded.Count)/$($tasks.Count) lanes OK."
if ($succeeded.Count -lt $tasks.Count) { $note += ' Partial merge - retry failed lanes next cycle.' }
Set-HandoffState -State 'GROK_DONE' -Note $note -RepoRoot $repoRoot
Write-HandoffLog $note
exit 0
