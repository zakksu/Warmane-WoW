-- P1 Druid Guide v2 — fuse AH gear ROI + quest path into one ranked NEXT list

P1DG = P1DG or {}

local function QuestEntries(maxN)
    local out = {}
    if P1QuestPath_GetTop then
        out = P1QuestPath_GetTop(maxN) or {}
    end
    if #out == 0 and P1QuestNav_GetStatus then
        local st = P1QuestNav_GetStatus()
        out = st and st.tracked or {}
    end
    return out
end

function P1DG.ScoreQuestEntry(entry)
    local xp = entry.xp or 0
    local dist = entry.dist or 500
    local travel = dist / 7
    local gearBonus = entry.gearLabel and 80 or 0
    return (xp / math.max(30, travel)) + gearBonus
end

function P1DG.ScoreAhEntry(entry)
    local ilvlGain = math.max(0, (entry.needIlvl or 0) - (entry.haveIlvl or 0))
    local afford = entry.affordable and 40 or 0
    local price = entry.price or 0
    local pricePenalty = price > 0 and math.min(30, price / 10000) or 0
    return ilvlGain * 3 + afford - pricePenalty + (100 - (entry.priority or 50))
end

function P1DG.RankNextActions(playerLevel, maxN)
    maxN = maxN or 5
    local ranked = {}

    if P1DG.BuildShopList then
        for _, shop in ipairs(P1DG.BuildShopList(playerLevel, 3)) do
            ranked[#ranked + 1] = {
                type = "auction",
                score = P1DG.ScoreAhEntry(shop),
                itemId = shop.itemId,
                itemName = shop.itemName or shop.key,
                label = shop.key,
                haveIlvl = shop.haveIlvl,
                needIlvl = shop.needIlvl,
                price = shop.price,
                affordable = shop.affordable,
                shortfall = shop.shortfall,
            }
        end
    end

    for _, quest in ipairs(QuestEntries(4)) do
        ranked[#ranked + 1] = {
            type = "quest",
            score = P1DG.ScoreQuestEntry(quest),
            entry = quest,
            questName = quest.questName,
            dirLabel = quest.dirLabel,
            xp = quest.xp,
            dist = quest.dist,
            gearLabel = quest.gearLabel,
        }
    end

    table.sort(ranked, function(a, b) return (a.score or 0) > (b.score or 0) end)

    while #ranked > maxN do table.remove(ranked) end
    return ranked
end