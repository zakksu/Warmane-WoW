-- Realm-specific AH price cache (assist-only; no auto-buy)

P1DG = P1DG or {}

function P1DG.GetRealmKey()
    if GetRealmName then return GetRealmName() or "Unknown" end
    return "Unknown"
end

function P1DG.EnsureMarketDB()
    P1DruidGuideDB = P1DruidGuideDB or {}
    P1DruidGuideDB.market = P1DruidGuideDB.market or {}
    local realm = P1DG.GetRealmKey()
    if not P1DruidGuideDB.market[realm] then
        P1DruidGuideDB.market[realm] = {
            items = {},
            lastScanAt = 0,
            lastScanCount = 0,
        }
    end
    return P1DruidGuideDB.market[realm], realm
end

function P1DG.RecordItemPrice(itemId, buyout, count)
    if not itemId or not buyout or buyout <= 0 then return end
    local db = P1DG.EnsureMarketDB()
    local slot = db.items[itemId]
    if not slot then
        slot = { history = {}, lastBuyout = nil, lastAt = 0, lastCount = 0 }
        db.items[itemId] = slot
    end
    slot.lastBuyout = buyout
    slot.lastAt = GetTime()
    slot.lastCount = count or 1
    slot.history[#slot.history + 1] = { buyout = buyout, count = count or 1, at = GetTime() }
    while #slot.history > 20 do table.remove(slot.history, 1) end
end

function P1DG.GetRealmPrice(itemId)
    if not itemId then return nil end
    local db = P1DG.EnsureMarketDB()
    local slot = db.items[itemId]
    if slot and slot.lastBuyout and slot.lastBuyout > 0 then
        return slot.lastBuyout
    end
    return nil
end

function P1DG.GetMarketScanMeta()
    local db, realm = P1DG.EnsureMarketDB()
    local itemCount = 0
    for _ in pairs(db.items) do itemCount = itemCount + 1 end
    return {
        realm = realm,
        itemCount = itemCount,
        lastScanAt = db.lastScanAt or 0,
        lastScanCount = db.lastScanCount or 0,
    }
end

function P1DG.PrintMarketSummary()
    local meta = P1DG.GetMarketScanMeta()
    local ago = meta.lastScanAt > 0 and string.format("%.0fs ago", GetTime() - meta.lastScanAt) or "never"
    print(string.format("|cff00ccffP1 Market|r %s — %d items cached, last scan %s (%d rows)",
        meta.realm, meta.itemCount, ago, meta.lastScanCount or 0))
end