#Requires -Version 5.1
<#
.SYNOPSIS
  Run Grok Build headless against this repo (single prompt, stdout, exit).

.EXAMPLE
  .\tools\grok-headless.ps1 -Prompt "Summarize P1AutoQuest.lua event flow"
  .\tools\grok-headless.ps1 -PromptFile .\prompt.txt -Yolo
#>
param(
    [Parameter(ParameterSetName = 'Prompt')]
    [string] $Prompt,

    [Parameter(ParameterSetName = 'File')]
    [string] $PromptFile,

    [string] $Model = 'grok-build',
    [ValidateSet('plain', 'json', 'streaming-json')]
    [string] $OutputFormat = 'plain',
    [switch] $Yolo,
    [string] $Rules,
    [int] $MaxTurns = 0
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
$grok = Join-Path $env:USERPROFILE '.grok\bin\grok.exe'

if (-not (Test-Path $grok)) {
    Write-Error "Grok CLI not found at $grok. Install: irm https://x.ai/cli/install.ps1 | iex"
}

$args = @('--cwd', $repoRoot)

if ($PromptFile) {
    $args += @('--prompt-file', (Resolve-Path $PromptFile))
} elseif ($Prompt) {
    $args += @('-p', $Prompt)
} else {
    Write-Error 'Pass -Prompt or -PromptFile'
}

$args += @('-m', $Model, '--output-format', $OutputFormat)

if ($Yolo) { $args += '--yolo' }
if ($Rules) { $args += @('--rules', $Rules) }
if ($MaxTurns -gt 0) { $args += @('--max-turns', "$MaxTurns") }

Push-Location $repoRoot
try {
    & $grok @args
    exit $LASTEXITCODE
} finally {
    Pop-Location
}
