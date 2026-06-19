#Requires -Version 5.1
<#
.SYNOPSIS
  Optional file watcher — logs when grok-response.md updates (loop handles cycles).

.EXAMPLE
  .\tools\watch-handoff.ps1
#>
param(
    [int] $PollSeconds = 10
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'handoff-common.ps1')

$repoRoot = Get-RepoRoot
$paths = Get-HandoffPaths -RepoRoot $repoRoot
$response = $paths.Response
$lastWrite = $null

Write-HandoffLog "watch-handoff started on $response"

while ($true) {
    if (Test-Path $response) {
        $w = (Get-Item $response).LastWriteTimeUtc
        if ($lastWrite -and $w -gt $lastWrite) {
            Write-HandoffLog 'grok-response.md updated — agent-loop will pick up GROK_DONE'
        }
        $lastWrite = $w
    }
    Start-Sleep -Seconds $PollSeconds
}
