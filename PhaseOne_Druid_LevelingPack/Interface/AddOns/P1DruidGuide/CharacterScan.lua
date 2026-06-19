-- P1 Druid Guide — live character scan (gear, gold, quests, zone)

P1DG = P1DG or {}

local SLOT_NAMES = {
    [1] = "Head", [2] = "Neck", [3] = "Shoulders", [5] = "Chest", [6] = "Waist",
    [7] = "Legs", [8] = "Feet", [9] = "Wrist", [10] = "Hands",
    [13] = "Trinket", [14] = "Trinket2", [15] = "Back", [16] = "Weapon",
}

function P1DG.FormatGoldShort(copper)
    copper = copper or 0
    if copper >= 10000 then
        return string.format("%.1fg", copper / 10000)
    end
    if copper >= 100 then
        return string.format("%ds", math.floor(copper / 100))
    end
    return copper .. "c"
end

function P1DG.ScanCharacter()
    local scan = {
        name = UnitName("player"),
        level = UnitLevel("player"),
        class = select(2, UnitClass("player")),
        gold = GetMoney(),
        zone = GetRealZoneText() or "?",
        mapId = GetCurrentMapAreaID(),
        activeQuests = 0,
        slots = {},
        scannedAt = time(),
    }

    for i = 1, GetNumQuestLogEntries() do
        local _, _, _, _, _, complete, _, _ = GetQuestLogTitle(i)
        if complete == 0 or complete == -1 then
            scan.activeQuests = scan.activeQuests + 1
        end
    end

    for slot = 1, 18 do
        local link = GetInventoryItemLink("player", slot)
        if link then
            local id = tonumber(link:match("item:(%d+)"))
            local name, _, _, ilvl, _, _, _, _, equipLoc = GetItemInfo(link)
            scan.slots[slot] = {
                id = id,
                name = name,
                ilvl = ilvl or 0,
                equipLoc = equipLoc,
            }
        end
    end

    P1DruidGuideDB = P1DruidGuideDB or {}
    P1DruidGuideDB.characterScan = scan
    return scan
end

function P1DG.GetScan()
    if P1DruidGuideDB and P1DruidGuideDB.characterScan then
        return P1DruidGuideDB.characterScan
    end
    return P1DG.ScanCharacter()
end

function P1DG.GetEquippedIlvl(slot)
    local scan = P1DG.GetScan()
    local s = scan.slots and scan.slots[slot]
    return s and s.ilvl or 0
end

function P1DG.GetEquippedItemId(slot)
    local scan = P1DG.GetScan()
    local s = scan.slots and scan.slots[slot]
    return s and s.id
end

function P1DG.GetPersonalGaps(playerLevel, maxN)
    maxN = maxN or 3
    local gaps = {}
    local bracket = P1DG.GetBisBracket and P1DG.GetBisBracket(playerLevel)
    if not bracket then return gaps end

    local slots = {}
    for _, s in ipairs(bracket.slots) do slots[#slots + 1] = s end
    table.sort(slots, function(a, b) return (a.order or 99) < (b.order or 99) end)

    for _, slot in ipairs(slots) do
        if not P1DG.IsBisSlotDone(slot) then
            local eqIlvl = 0
            local eqName = "empty"
            if slot.equipSlot then
                local s = P1DG.GetScan().slots[slot.equipSlot]
                if s then
                    eqIlvl = s.ilvl or 0
                    eqName = s.name or "?"
                end
            end
            gaps[#gaps + 1] = {
                key = slot.key,
                itemId = slot.itemId,
                itemName = slot.itemName or slot.suggest,
                equipSlot = slot.equipSlot,
                needIlvl = slot.minIlvl or 0,
                haveIlvl = eqIlvl,
                haveName = eqName,
                source = slot.source,
                priceTier = slot.priceTier,
                priority = slot.order or 50,
                goldAh = true,
            }
        end
    end

    while #gaps > maxN do table.remove(gaps) end
    return gaps
end

function P1DG.PrintCharacterScan()
    local s = P1DG.ScanCharacter()
    print("|cff00ccffP1 Scan|r — " .. (s.name or "?") .. " L" .. (s.level or 0)
        .. " · " .. (s.zone or "?") .. " · " .. P1DG.FormatGoldShort(s.gold)
        .. " · " .. (s.activeQuests or 0) .. " quests")
    for slot, name in pairs(SLOT_NAMES) do
        local data = s.slots[slot]
        if data then
            print(string.format("  %s: %s (ilvl %d)", name, data.name or "?", data.ilvl or 0))
        end
    end
    local gaps = P1DG.GetPersonalGaps(s.level, 5)
    if #gaps == 0 then
        print("  |cff00ff00Gear on track for level bracket|r")
    else
        print("  |cffffcc00AH gaps:|r")
        for i, g in ipairs(gaps) do
            local price = g.itemId and P1DG.GetItemBuyout and P1DG.GetItemBuyout(g.itemId)
            local priceTag = price and (" — " .. P1DG.FormatAhPrice(price)) or ""
            print(string.format("  %d. %s (have ilvl %d, want %d+)%s",
                i, g.itemName or g.key, g.haveIlvl, g.needIlvl, priceTag))
        end
    end
end