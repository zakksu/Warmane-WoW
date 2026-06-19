# Static validation: P1DruidGuide <-> Auctionator search bridge
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$auction = Join-Path $root "PhaseOne_Druid_LevelingPack\Interface\AddOns\P1DruidGuide\Auction.lua"
$core = Join-Path $root "PhaseOne_Druid_LevelingPack\Interface\AddOns\P1DruidGuide\Core.lua"
$atrShop = Join-Path $root "PhaseOne_Druid_LevelingPack\Interface\AddOns\Auctionator\AuctionatorShop.lua"
$atrMain = Join-Path $root "PhaseOne_Druid_LevelingPack\Interface\AddOns\Auctionator\Auctionator.lua"

$fail = 0
function Assert-Contains {
    param([string]$Path, [string]$Pattern, [string]$Label)
    $text = Get-Content -Path $Path -Raw -Encoding UTF8
    if ($text -notmatch $Pattern) {
        Write-Host "FAIL $Label" -ForegroundColor Red
        Write-Host "  missing in $Path : $Pattern"
        $script:fail++
    } else {
        Write-Host "OK   $Label" -ForegroundColor Green
    }
}

Write-Host "P1 AH bridge static test" -ForegroundColor Cyan
Write-Host ""

Assert-Contains $auction "Atr_Search_Onclick" "Auction.lua calls Atr_Search_Onclick"
Assert-Contains $auction "Atr_SelectPane" "Auction.lua selects Auctionator pane"
Assert-Contains $auction "FlushPendingAuctionSearch" "Auction.lua flushes pending queue"
Assert-Contains $auction "PrintAhDiagnostics" "Auction.lua has diagnostics"
Assert-Contains $core "AUCTION_HOUSE_SHOW" "Core.lua listens for AH open"
Assert-Contains $core 'type = "auction"' "Core.lua wires auction click targets"
Assert-Contains $core "HandleP1Ah" "Core.lua /p1ah handler with test/debug"
Assert-Contains $atrShop "function Atr_Search_Onclick" "Auctionator exposes Atr_Search_Onclick"
Assert-Contains $atrMain "function Atr_SelectPane" "Auctionator exposes Atr_SelectPane"
Assert-Contains $atrMain "local BUY_TAB\s*=\s*3" "Auctionator BUY_TAB is 3"

Write-Host ""
if ($fail -eq 0) {
    Write-Host "All checks passed ($((Get-Item $auction).LastWriteTime))" -ForegroundColor Green
    exit 0
}
Write-Host "$fail check(s) failed" -ForegroundColor Red
exit 1