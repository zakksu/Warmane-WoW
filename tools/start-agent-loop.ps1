#Requires -Version 5.1
# Entry wrapper for agent-loop.ps1 (same flags).
param(
    [int] $PollSeconds = 45,
    [int] $MaxRetries = 3,
    [switch] $Once,
    [switch] $DryRun
)

& (Join-Path $PSScriptRoot 'agent-loop.ps1') @PSBoundParameters
