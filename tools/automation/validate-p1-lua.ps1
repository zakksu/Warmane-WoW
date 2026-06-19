# Static checks for common WoW 3.3.5 Lua 5.1 breakages in P1 addons
param([string]$RepoRoot = "")

$ErrorActionPreference = "Stop"
if (-not $RepoRoot) {
    $RepoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
}

$roots = @(
    Join-Path $RepoRoot "PhaseOne_Druid_LevelingPack\Interface\AddOns"
    Join-Path $RepoRoot "PhaseOne_LevelingPack\Interface\AddOns"
)

$badPatterns = @(
    @{ Name = "method-ref-before-and"; Regex = ':\w+\s+and\s+[^:]+:' }
)

$fail = 0
foreach ($root in $roots) {
    if (-not (Test-Path $root)) { continue }
    Get-ChildItem $root -Recurse -Include "*.lua" | Where-Object {
        $_.FullName -match '\\P1[^\\]+\\' -and $_.FullName -notmatch 'Questie-335'
    } | ForEach-Object {
        $text = Get-Content $_.FullName -Raw -Encoding UTF8
        foreach ($pat in $badPatterns) {
            if ($text -match $pat.Regex) {
                Write-Host "FAIL $($_.FullName) - $($pat.Name)" -ForegroundColor Red
                $fail++
            }
        }
    }
}

if ($fail -eq 0) {
    Write-Host "P1 Lua static validation OK" -ForegroundColor Green
    exit 0
}
exit 1