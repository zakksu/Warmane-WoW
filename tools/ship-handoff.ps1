#Requires -Version 5.1
<#
.SYNOPSIS
  Ship cycle after Cursor completes handoff: sync WoW, commit, optional release.
#>
param(
    [switch] $SkipPush,
    [switch] $DryRun
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'handoff-common.ps1')
$repoRoot = Get-RepoRoot
$paths = Get-HandoffPaths -RepoRoot $repoRoot

function Test-LuaDataChanged {
    Push-Location $repoRoot
    try {
        $changed = git status --porcelain | ForEach-Object {
            if ($_ -match '^\S+\s+(.+)$') { $Matches[1] }
        }
        return ($changed | Where-Object { $_ -match 'Data\.lua$|PhaseOneLoader\.lua$' }).Count -gt 0
    } finally {
        Pop-Location
    }
}

Write-HandoffLog 'Ship cycle starting'

$wowPath = Get-WowPathFromConfig -RepoRoot $repoRoot
if ($wowPath) {
    Write-HandoffLog "Syncing addons to $wowPath"
    if (-not $DryRun) {
        & (Join-Path $PSScriptRoot 'sync-addons.ps1') -WowPath $wowPath -Pack DRUID
        & (Join-Path $PSScriptRoot 'cleanup-wow-addons.ps1') -WowPath $wowPath
        & (Join-Path $PSScriptRoot 'write-addons-txt.ps1') -WowPath $wowPath
    }
} else {
    Write-HandoffLog 'WARN: tools/wow-path.cfg missing — skipped addon sync'
}

Push-Location $repoRoot
try {
    $luaChanged = Test-LuaDataChanged
    if ($luaChanged -and -not $DryRun) {
        Write-HandoffLog 'Data.lua changed — running quick-release (version bump + push + tag)'
        try {
            & (Join-Path $PSScriptRoot 'quick-release.ps1') -Notes 'Autonomous handoff ship'
        } catch {
            Write-HandoffLog "WARN: quick-release failed: $($_.Exception.Message)"
        }
    } else {
        $dirty = git status --porcelain
        if ($dirty -and -not $DryRun) {
            git add -A
            $msg = "handoff: ship cursor implementation`n`nAutonomous agent-loop cycle."
            git commit -m $msg
            if ($LASTEXITCODE -ne 0) {
                Write-HandoffLog 'WARN: git commit failed or nothing to commit'
            } else {
                Write-HandoffLog 'Committed handoff changes'
            }
        }

        if (-not $SkipPush -and -not $DryRun) {
            if (Get-Command gh -ErrorAction SilentlyContinue) {
                $null = gh auth status 2>&1
                if ($LASTEXITCODE -eq 0) {
                    git push origin HEAD 2>&1 | Out-Null
                    Write-HandoffLog 'Pushed to remote'
                } else {
                    Write-HandoffLog 'WARN: gh not authenticated — skipped push'
                }
            }
        }
    }
} finally {
    Pop-Location
}

if (Test-Path $paths.Wake) {
    Remove-Item $paths.Wake -Force -ErrorAction SilentlyContinue
}

$version = 'unknown'
$loader = Join-Path $repoRoot 'PhaseOne_LevelingPack\Interface\AddOns\PhaseOneLoader\PhaseOneLoader.lua'
if (Test-Path $loader) {
    $t = Get-Content $loader -Raw
    if ($t -match 'PACK_VERSION = "([^"]+)"') { $version = $Matches[1] }
}

Set-HandoffState -State 'SHIPPED' -Note @"
Handoff shipped (v$version). Synced to WoW client when path configured.

**You:** ``/reload`` in game.

**Next:** agent-loop queues Grok when GROK_TASKS.md has items.
"@ -RepoRoot $repoRoot

Write-HandoffLog 'Ship cycle complete'
exit 0
