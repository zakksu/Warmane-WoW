# Export P1DruidGuideDB.market realm prices from SavedVariables to JSON/SQLite-friendly CSV.
param(
    [string]$Realm = "",
    [string]$OutDir = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
. (Join-Path $root "tools\automation\WowInput.ps1")

$svPath = Get-P1DruidGuideSavedVarsPath
if (-not $svPath -or -not (Test-Path $svPath)) {
    Write-Host "P1DruidGuide SavedVariables not found. Log in on a druid and /reload first." -ForegroundColor Yellow
    exit 1
}

$text = Get-Content -Path $svPath -Raw -Encoding UTF8
if ($text -notmatch '\["market"\]') {
    Write-Host "No market data in SavedVariables. Open AH and run /p1ah scan in game." -ForegroundColor Yellow
    exit 1
}

if (-not $OutDir) {
    $OutDir = Join-Path $PSScriptRoot "exports"
}
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }

$realms = @()
foreach ($m in [regex]::Matches($text, '\["([^"]+)"\]\s*=\s*\{[^}]*\["items"\]')) {
    $realms += $m.Groups[1].Value
}
$realms = @($realms | Select-Object -Unique)
if ($Realm) { $realms = @($Realm) }

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
foreach ($r in $realms) {
    $safeRealm = ($r -replace '[^\w\-]', '_')
    $csvPath = Join-Path $OutDir ("prices-{0}-{1}.csv" -f $safeRealm, $stamp)
    $rows = New-Object System.Collections.Generic.List[string]
    $rows.Add("realm,itemId,lastBuyout,lastAt,lastCount") | Out-Null

    $realmBlock = ""
    if ($text -match ('\["' + [regex]::Escape($r) + '"\]\s*=\s*\{([\s\S]*?)\n\t\},')) {
        $realmBlock = $Matches[1]
    }
    foreach ($im in [regex]::Matches($realmBlock, '\[(\d+)\]\s*=\s*\{([\s\S]*?)\n\t\t\},')) {
        $itemId = $im.Groups[1].Value
        $block = $im.Groups[2].Value
        $buyout = 0
        $at = 0
        $count = 1
        if ($block -match '\["lastBuyout"\]\s*=\s*(\d+)') { $buyout = $Matches[1] }
        if ($block -match '\["lastAt"\]\s*=\s*([\d.]+)') { $at = $Matches[1] }
        if ($block -match '\["lastCount"\]\s*=\s*(\d+)') { $count = $Matches[1] }
        if ([int]$buyout -gt 0) {
            $rows.Add("$r,$itemId,$buyout,$at,$count") | Out-Null
        }
    }

    Set-Content -Path $csvPath -Value $rows -Encoding UTF8
    Write-Host "Exported $($rows.Count - 1) items -> $csvPath" -ForegroundColor Green
}

Write-Host ""
Write-Host "SQLite import hint:"
Write-Host "  CREATE TABLE prices (realm TEXT, item_id INT, buyout INT, scanned_at REAL, stack INT);"
Write-Host "  .mode csv"
Write-Host "  .import prices-Icecrown-*.csv prices"