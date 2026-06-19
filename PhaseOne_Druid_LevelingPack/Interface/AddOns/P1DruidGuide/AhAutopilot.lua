-- P1 Druid Guide v2 — AH shopping list + afford check

P1DG = P1DG or {}

function P1DG.CanAfford(priceCopper, goldCopper)
    if not priceCopper or priceCopper <= 0 then return true end
    goldCopper = goldCopper or (GetMoney and GetMoney() or 0)
    return goldCopper >= priceCopper
end

function P1DG.GetShortfall(priceCopper, goldCopper)
    goldCopper = goldCopper or (GetMoney and GetMoney() or 0)
    if not priceCopper then return 0 end
    return math.max(0, priceCopper - goldCopper)
end

function P1DG.BuildShopList(playerLevel, maxN)
    maxN = maxN or 5
    local gold = GetMoney()
    local out = {}
    local seen = {}

    local function add(entry)
        if not entry or seen[entry.key or entry.itemName] then return end
        seen[entry.key or entry.itemName] = true
        local price = entry.itemId and P1DG.GetItemBuyout and P1DG.GetItemBuyout(entry.itemId)
        entry.price = price
        entry.affordable = P1DG.CanAfford(price, gold)
        entry.shortfall = P1DG.GetShortfall(price, gold)
        out[#out + 1] = entry
    end

    if P1DG.GetPersonalGaps then
        for _, g in ipairs(P1DG.GetPersonalGaps(playerLevel, maxN)) do
            add({
                key = g.key,
                itemId = g.itemId,
                itemName = g.itemName,
                haveIlvl = g.haveIlvl,
                needIlvl = g.needIlvl,
                priority = g.priority or 50,
            })
        end
    end

    if #out < maxN and P1DG.GetPendingAhUpgrades then
        for _, ah in ipairs(P1DG.GetPendingAhUpgrades(playerLevel, maxN - #out)) do
            add({
                key = ah.label,
                itemId = ah.itemId,
                itemName = ah.itemName or ah.label,
                priority = 60,
            })
        end
    end

    table.sort(out, function(a, b)
        if a.affordable ~= b.affordable then return a.affordable end
        return (a.priority or 99) < (b.priority or 99)
    end)

    while #out > maxN do table.remove(out) end
    return out
end