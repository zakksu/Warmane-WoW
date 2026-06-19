-- Relist suggestions only — you post manually (no auto-buy, no auto-post)

P1DG = P1DG or {}

local function BagItemId(bag, slot)
    local link = GetContainerItemLink(bag, slot)
    if not link then return nil end
    return tonumber(link:match("item:(%d+)"))
end

function P1DG.BuildRelistSuggestions(maxN)
    maxN = maxN or 5
    local out = {}
    local seen = {}

    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local id = BagItemId(bag, slot)
            if id and not seen[id] then
                local market = P1DG.GetRealmPrice and P1DG.GetRealmPrice(id)
                if market and market > 0 then
                    seen[id] = true
                    local name = GetItemInfo(id)
                    local _, count = GetContainerItemInfo(bag, slot)
                    out[#out + 1] = {
                        itemId = id,
                        name = name or ("item:" .. id),
                        count = count or 1,
                        marketBuyout = market,
                        suggestPrice = math.max(1, market - 1),
                        assistOnly = true,
                    }
                end
            end
        end
    end

    table.sort(out, function(a, b)
        return (a.marketBuyout or 0) > (b.marketBuyout or 0)
    end)

    while #out > maxN do table.remove(out) end

    local db = P1DG.EnsureMarketDB()
    db.relistHints = out
    return out
end

function P1DG.PrintRelistSuggestions()
    local list = P1DG.BuildRelistSuggestions(8)
    local realm = P1DG.GetRealmKey and P1DG.GetRealmKey() or "?"
    if #list == 0 then
        print("|cff00ccffP1 Relist|r " .. realm .. " — no bag items with cached prices. Open AH, /p1ah scan")
        return
    end
    print("|cff00ccffP1 Relist|r " .. realm .. " — assist-only (you post manually)")
    for i, row in ipairs(list) do
        local mkt = P1DG.FormatAhPrice and P1DG.FormatAhPrice(row.marketBuyout) or "?"
        local sug = P1DG.FormatAhPrice and P1DG.FormatAhPrice(row.suggestPrice) or "?"
        print(string.format("  %d. %s x%d — post ~%s (market %s)",
            i, row.name or "?", row.count or 1, sug, mkt))
    end
end