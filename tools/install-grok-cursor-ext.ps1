#Requires -Version 5.1
<#
.SYNOPSIS
  Install the Grok Build VS Code sidebar extension into Cursor (ACP over grok agent stdio).

.NOTES
  Extension: PawelHuryn.grok-vscode-phuryn
  Requires: grok CLI on PATH or at ~/.grok/bin/grok.exe, plus grok /login or XAI_API_KEY
#>
$ErrorActionPreference = 'Stop'
$extId = 'PawelHuryn.grok-vscode-phuryn'

function Get-EditorCli {
    if (Get-Command cursor -ErrorAction SilentlyContinue) { return 'cursor' }
    if (Get-Command code -ErrorAction SilentlyContinue) { return 'code' }
    return $null
}

$cli = Get-EditorCli
if (-not $cli) {
    Write-Error 'Neither cursor nor code CLI found on PATH. Install Cursor shell command from Command Palette.'
}

$grok = Join-Path $env:USERPROFILE '.grok\bin\grok.exe'
if (-not (Test-Path $grok)) {
    Write-Host 'Grok CLI missing. Installing...'
    irm https://x.ai/cli/install.ps1 | iex
}

Write-Host "Installing extension $extId via $cli ..."
& $cli --install-extension $extId --force

Write-Host ''
Write-Host 'Next steps:'
Write-Host '  1. Reload Cursor window'
Write-Host '  2. grok /login   (or set XAI_API_KEY)'
Write-Host '  3. Open Grok Build sidebar; it spawns grok agent stdio in this workspace'
Write-Host ''
Write-Host 'See Docs/GROK_INTEGRATION.md for Cursor + Grok dual-agent workflow.'
