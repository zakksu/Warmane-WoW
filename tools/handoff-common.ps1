#Requires -Version 5.1
# Shared helpers for Cursor <-> Grok handoff scripts.

$script:HandoffStates = @(
    'IDLE', 'GROK_PENDING', 'GROK_WORKING', 'GROK_DONE', 'GROK_FAILED',
    'CURSOR_PENDING', 'CURSOR_WORKING', 'CURSOR_SHIPPED', 'SHIPPED'
)

function Get-RepoRoot {
    if ($PSScriptRoot) {
        return (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    }
    throw 'PSScriptRoot not set'
}

function Get-HandoffDir {
    param([string] $RepoRoot = (Get-RepoRoot))
    Join-Path $RepoRoot 'Docs\grok-handoff'
}

function Get-HandoffPaths {
    param([string] $RepoRoot = (Get-RepoRoot))
    $handoff = Get-HandoffDir -RepoRoot $RepoRoot
    @{
        Handoff   = $handoff
        Status    = Join-Path $handoff 'STATUS.md'
        GrokTasks = Join-Path $handoff 'GROK_TASKS.md'
        Response  = Join-Path $handoff 'grok-response.md'
        CursorTasks = Join-Path $handoff 'CURSOR_TASKS.md'
        Wake      = Join-Path $handoff 'CURSOR_WAKE.md'
        Log       = Join-Path $handoff 'loop.log'
    }
}

function Get-HandoffState {
    param([string] $RepoRoot = (Get-RepoRoot))
    $statusFile = (Get-HandoffPaths -RepoRoot $RepoRoot).Status
    if (-not (Test-Path $statusFile)) { return 'IDLE' }
    $line = Get-Content $statusFile -ErrorAction SilentlyContinue |
        Where-Object { $_ -match '^\*\*State:\*\*' } |
        Select-Object -First 1
    if (-not $line) { return 'IDLE' }
    if ($line -match '\*\*State:\*\*\s*([A-Z_]+)') { return $Matches[1] }
    return 'IDLE'
}

function Set-HandoffState {
    param(
        [Parameter(Mandatory)]
        [string] $State,
        [string] $Note = '',
        [string] $RepoRoot = (Get-RepoRoot)
    )
    if ($script:HandoffStates -notcontains $State) {
        throw "Unknown handoff state: $State"
    }
    $paths = Get-HandoffPaths -RepoRoot $RepoRoot
    $statusFile = $paths.Status
    $date = Get-Date -Format 'yyyy-MM-dd HH:mm'
    $body = @"
# Agent handoff status

**State:** $State
**Updated:** $date

"@
    if ($Note) { $body += "$Note`n" }
    if (Test-Path $statusFile) {
        $existing = Get-Content $statusFile -Raw
        if ($existing -match '(?s)\n\*\*You:\*\*.*$') {
            $body += "`n" + ($existing -replace '(?s)^.*?(?=\n\*\*You:\*\*|\z)', '').TrimStart()
        }
    }
    Set-Content -Path $statusFile -Value $body.TrimEnd() -NoNewline
    Write-HandoffLog "STATE -> $State" -RepoRoot $RepoRoot
}

function Write-HandoffLog {
    param(
        [Parameter(Mandatory)]
        [string] $Message,
        [string] $RepoRoot = (Get-RepoRoot)
    )
    $logFile = (Get-HandoffPaths -RepoRoot $RepoRoot).Log
    $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "[$stamp] $Message"
    Add-Content -Path $logFile -Value $line -Encoding UTF8
    Write-Host $line
}

function Test-GrokTasksPending {
    param([string] $RepoRoot = (Get-RepoRoot))
    $file = (Get-HandoffPaths -RepoRoot $RepoRoot).GrokTasks
    if (-not (Test-Path $file)) { return $false }
    $text = Get-Content $file -Raw
    if ($text -match '\|\s*G\d+\s*\|') { return $true }
    if ($text -match '## Grok owns') { return $true }
    return $false
}

function Test-CursorTasksComplete {
    param([string] $RepoRoot = (Get-RepoRoot))
    $file = (Get-HandoffPaths -RepoRoot $RepoRoot).CursorTasks
    if (-not (Test-Path $file)) { return $false }
    $lines = Get-Content $file | Where-Object { $_ -match '^\s*-\s*\[[ xX]\]' }
    if ($lines.Count -eq 0) { return $false }
    return (($lines | Where-Object { $_ -notmatch '\[x\]' -and $_ -notmatch '\[X\]' }).Count -eq 0)
}

function Get-WowPathFromConfig {
    param([string] $RepoRoot = (Get-RepoRoot))
    $cfg = Join-Path $RepoRoot 'tools\wow-path.cfg'
    if (-not (Test-Path $cfg)) { return $null }
    $path = (Get-Content $cfg -TotalCount 1).Trim()
    if ($path -and (Test-Path (Join-Path $path 'Wow.exe'))) { return $path }
    return $null
}

function Test-GhAuthenticated {
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { return $false }
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    try {
        & gh auth status *> $null
        return ($LASTEXITCODE -eq 0)
    } finally {
        $ErrorActionPreference = $prev
    }
}

function Invoke-GitPush {
    param(
        [string] $Remote = 'origin',
        [string] $Ref = 'HEAD',
        [switch] $Force
    )
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    try {
        if ($Force) {
            & git push $Remote $Ref --force *> $null
        } else {
            & git push $Remote $Ref *> $null
        }
        return ($LASTEXITCODE -eq 0)
    } finally {
        $ErrorActionPreference = $prev
    }
}

function Invoke-WithBackoff {
    param(
        [Parameter(Mandatory)]
        [scriptblock] $Action,
        [int] $MaxAttempts = 3,
        [int] $BaseDelaySeconds = 30,
        [string] $Label = 'operation'
    )
    for ($i = 1; $i -le $MaxAttempts; $i++) {
        try {
            & $Action
            return
        } catch {
            $msg = $_.Exception.Message
            Write-HandoffLog "WARN $Label attempt $i/$MaxAttempts failed: $msg"
            if ($i -eq $MaxAttempts) { throw }
            $delay = $BaseDelaySeconds * [math]::Pow(2, $i - 1)
            Write-HandoffLog "Backoff ${delay}s before retry..."
            Start-Sleep -Seconds $delay
        }
    }
}
