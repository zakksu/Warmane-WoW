# Update lane status in lanes.json (for orchestrator + agents).
param(
    [Parameter(Mandatory = $true)]
    [string]$Lane,
    [Parameter(Mandatory = $true)]
    [ValidateSet("pending", "in_progress", "done", "blocked")]
    [string]$Status
)

$ErrorActionPreference = "Stop"
$lanesFile = Join-Path $PSScriptRoot "lanes.json"
$json = Get-Content $lanesFile -Raw | ConvertFrom-Json
$found = $false
foreach ($entry in $json.lanes) {
    if ($entry.id -eq $Lane) {
        $entry.status = $Status
        $found = $true
        break
    }
}
if (-not $found) { throw "Lane not found: $Lane" }
$json | ConvertTo-Json -Depth 6 | Set-Content $lanesFile -Encoding UTF8
Write-Host "Lane $Lane -> $Status"