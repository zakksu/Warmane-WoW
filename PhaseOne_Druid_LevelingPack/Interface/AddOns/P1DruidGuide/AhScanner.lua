-- AH browse scanner — records prices to realm DB (assist-only, no auto-buy)

P1DG = P1DG or {}

local scanFrame = CreateFrame("Frame")
scanFrame:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
scanFrame:RegisterEvent("AUCTION_HOUSE_SHOW")

local function ScanBrowseList()
    if not P1DG.IsAuctionHouseOpen or not P1DG.IsAuctionHouseOpen() then return 0 end
    if not GetNumAuctionItems then return 0 end
    local total = GetNumAuctionItems("list") or 0
    local recorded = 0
    for i = 1, total do
        local _, _, count, _, _, _, _, _, buyout = GetAuctionItemInfo("list", i)
        local link = GetAuctionItemLink and GetAuctionItemLink("list", i)
        local itemId = link and tonumber(link:match("item:(%d+)"))
        if itemId and buyout and buyout > 0 then
            P1DG.RecordItemPrice(itemId, buyout, count)
            recorded = recorded + 1
        end
    end
    local db = P1DG.EnsureMarketDB()
    db.lastScanAt = GetTime()
    db.lastScanCount = recorded
    return recorded
end

function P1DG.ScanBrowseList()
    return ScanBrowseList()
end

function P1DG.ScanShopWatchlist(maxN)
    maxN = maxN or 5
    if not P1DG.BuildShopList then return 0 end
    local shop = P1DG.BuildShopList(UnitLevel("player"), maxN)
    local queued = 0
    for _, item in ipairs(shop) do
        if item.itemId and P1DG.SearchAuctionItem then
            P1DG.SearchAuctionItem(item.itemId, true)
            queued = queued + 1
        end
    end
    return queued
end

scanFrame:SetScript("OnEvent", function(_, event)
    if event == "AUCTION_HOUSE_SHOW" then
        P1DG._ahOpenAt = GetTime()
    elseif event == "AUCTION_ITEM_LIST_UPDATE" then
        if P1DG._scanOnUpdate ~= false then
            ScanBrowseList()
        end
    end
end)