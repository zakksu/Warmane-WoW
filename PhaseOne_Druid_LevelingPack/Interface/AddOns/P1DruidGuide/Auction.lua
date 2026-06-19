-- P1 Druid Guide — Auctionator bridge (AH search + price hints)

P1DG = P1DG or {}

local BUY_TAB = 3

local function CacheItem(itemId)
    if not itemId then return nil end
    local name = GetItemInfo(itemId)
    if name then return name end
    GameTooltip:SetHyperlink("item:" .. itemId .. ":0:0:0:0:0:0:0")
    GameTooltip:Hide()
    return GetItemInfo(itemId)
end

function P1DG.EnsureAuctionator()
    if IsAddOnLoaded("Auctionator") then return true end
    if not LoadAddOn then return false end
    LoadAddOn("Auctionator")
    return IsAddOnLoaded("Auctionator")
end

function P1DG.IsAuctionatorLoaded()
    if not P1DG.EnsureAuctionator() then return false end
    return Atr_Search_Onclick and Atr_Search_Box and Atr_SelectPane
end

function P1DG.IsAuctionHouseOpen()
    return AuctionFrame and AuctionFrame:IsShown()
end

function P1DG.QueueAuctionSearch(itemId)
    if not itemId then return end
    P1DG._pendingAhItemId = itemId
end

function P1DG.ClearPendingAuctionSearch()
    P1DG._pendingAhItemId = nil
end

function P1DG.FlushPendingAuctionSearch()
    local itemId = P1DG._pendingAhItemId
    if not itemId then return false end
    if not P1DG.IsAuctionHouseOpen() then return false end
    if P1DG.SearchAuctionItem(itemId, true) then
        P1DG._pendingAhItemId = nil
        return true
    end
    return false
end

function P1DG.FormatAhPrice(copper)
    if not copper or copper <= 0 then return "?" end
    if copper >= 10000 then
        return string.format("%.1fg", copper / 10000)
    end
    if copper >= 100 then
        return string.format("%ds", math.floor(copper / 100))
    end
    return copper .. "c"
end

function P1DG.GetItemBuyout(itemId)
    if not itemId then return nil end
    if not P1DG.IsAuctionatorLoaded() then return nil end
    if Atr_GetAuctionBuyout then
        local price = Atr_GetAuctionBuyout(itemId)
        if price and price > 0 then return price end
    end
    if Atr_GetAuctionPrice then
        local name = CacheItem(itemId)
        if name then
            local price = Atr_GetAuctionPrice(name)
            if price and price > 0 then return price end
        end
    end
    return nil
end

function P1DG.GetPendingAhUpgrades(playerLevel, maxN)
    maxN = maxN or 3
    local out = {}
    local seen = {}

    local function add(entry)
        if not entry or not entry.itemId or seen[entry.itemId] then return end
        seen[entry.itemId] = true
        out[#out + 1] = entry
    end

    local bracket = P1DG.GetBisBracket and P1DG.GetBisBracket(playerLevel)
    if bracket then
        local slots = {}
        for _, s in ipairs(bracket.slots) do slots[#slots + 1] = s end
        table.sort(slots, function(a, b) return (a.order or 99) < (b.order or 99) end)
        for _, slot in ipairs(slots) do
            if slot.itemId and not P1DG.IsBisSlotDone(slot) then
                add({
                    itemId = slot.itemId,
                    label = slot.key,
                    itemName = slot.itemName or slot.suggest,
                    source = slot.source,
                    priority = slot.order or 50,
                    goldAh = true,
                })
            end
        end
    end

    for _, ah in ipairs(P1DG.GOLD_AH_BIS or {}) do
        if playerLevel >= ah.levelMin then
            if ah.itemId and ah.equipSlot then
                local eqId = nil
                local link = GetInventoryItemLink("player", ah.equipSlot)
                if link then eqId = tonumber(link:match("item:(%d+)")) end
                local ilvl = 0
                if link then
                    local _, _, _, lvl = GetItemInfo(link)
                    ilvl = lvl or 0
                end
                if eqId ~= ah.itemId and ilvl < (ah.minIlvl or 0) then
                    add({
                        itemId = ah.itemId,
                        label = ah.label,
                        itemName = CacheItem(ah.itemId) or ah.label,
                        source = "AH",
                        priority = 40 - (ah.levelMin or 0) / 10,
                        goldAh = true,
                    })
                end
            end
        end
    end

    for _, step in ipairs(P1DG.PATH_STEPS or {}) do
        if playerLevel >= (step.level or 1) and not P1DG.IsStepDone(step, playerLevel) then
            if step.itemId and (step.goldAh or (step.text and step.text:find("AH", 1, true))) then
                add({
                    itemId = step.itemId,
                    label = step.type,
                    itemName = CacheItem(step.itemId) or step.text,
                    source = "AH path",
                    priority = step.impact or 30,
                    goldAh = true,
                })
            end
        end
    end

    if #out < maxN then
        for _, tip in ipairs(P1DG.AH_TIPS or {}) do
            if #out >= maxN then break end
            if playerLevel >= tip.levelMin and playerLevel <= (tip.levelMax or 80) + 5 then
                if tip.itemId then
                    local have = 0
                    for bag = 0, 4 do
                        for slot = 1, GetContainerNumSlots(bag) do
                            local link = GetContainerItemLink(bag, slot)
                            if link and tonumber(link:match("item:(%d+)")) == tip.itemId then
                                local _, c = GetContainerItemInfo(bag, slot)
                                have = have + (c or 1)
                            end
                        end
                    end
                    local need = tip.goal or tip.skipIfHave or 0
                    if need > 0 and have < need then
                        add({
                            itemId = tip.itemId,
                            label = "Consumable",
                            itemName = tip.itemName or CacheItem(tip.itemId),
                            source = "AH consumable",
                            priority = 60,
                            goldAh = true,
                        })
                    end
                end
            end
        end
    end

    table.sort(out, function(a, b)
        if a.priority ~= b.priority then return (a.priority or 99) < (b.priority or 99) end
        return (a.label or "") < (b.label or "")
    end)

    while #out > maxN do table.remove(out) end
    return out
end

function P1DG.GetNextAhPriority(playerLevel)
    if P1DG.GetPersonalGaps then
        local gaps = P1DG.GetPersonalGaps(playerLevel, 1)
        if gaps[1] then
            local g = gaps[1]
            return {
                itemId = g.itemId,
                label = g.key,
                itemName = g.itemName,
                source = g.source,
                goldAh = true,
                haveIlvl = g.haveIlvl,
                needIlvl = g.needIlvl,
            }
        end
    end
    local list = P1DG.GetPendingAhUpgrades(playerLevel, 1)
    return list[1]
end

function P1DG.GetAhSearchStatus()
    local itemId = P1DG._pendingAhItemId
    local pendingName = itemId and CacheItem(itemId) or nil
    return {
        auctionatorLoaded = IsAddOnLoaded("Auctionator"),
        bridgeReady = P1DG.IsAuctionatorLoaded(),
        ahOpen = P1DG.IsAuctionHouseOpen(),
        hasSearchBox = Atr_Search_Box ~= nil,
        hasSearchFn = Atr_Search_Onclick ~= nil,
        hasSelectPane = Atr_SelectPane ~= nil,
        buyTabActive = (Atr_IsTabSelected and Atr_IsModeBuy and Atr_IsModeBuy()) or false,
        searchBoxText = Atr_Search_Box and Atr_Search_Box:GetText() or "",
        pendingItemId = itemId,
        pendingName = pendingName,
        lastItemId = P1DG._lastAhItemId,
        lastName = P1DG._lastAhName,
        lastResult = P1DG._lastAhResult,
        lastAt = P1DG._lastAhAt,
    }
end

function P1DG.PrintAhDiagnostics()
    print("|cff00ccffP1 AH debug|r — Auctionator bridge status")
    local st = P1DG.GetAhSearchStatus()
    local function yn(v) return v and "|cff00ff00yes|r" or "|cffff4444no|r" end
    print("  Auctionator loaded: " .. yn(st.auctionatorLoaded))
    print("  Bridge ready: " .. yn(st.bridgeReady))
    print("  AH frame open: " .. yn(st.ahOpen))
    print("  Atr_Search_Box: " .. yn(st.hasSearchBox))
    print("  Atr_Search_Onclick: " .. yn(st.hasSearchFn))
    print("  Buy tab active: " .. yn(st.buyTabActive))
    if st.searchBoxText ~= "" then
        print("  Search box: |cffffcc00" .. st.searchBoxText .. "|r")
    end
    if st.pendingItemId then
        print("  Queued: " .. (st.pendingName or "?") .. " (id " .. st.pendingItemId .. ")")
    else
        print("  Queued: |cff888888(none)|r")
    end
    if st.lastItemId then
        local ago = st.lastAt and string.format("%.1fs ago", GetTime() - st.lastAt) or "?"
        print("  Last search: " .. (st.lastName or "?") .. " → " .. (st.lastResult or "?") .. " (" .. ago .. ")")
    end
    local top = P1DG.GetNextAhPriority and P1DG.GetNextAhPriority(UnitLevel("player"))
    if top and top.itemId then
        local price = P1DG.GetItemBuyout(top.itemId)
        local priceTag = price and P1DG.FormatAhPrice(price) or "no scan data"
        print("  Top priority: " .. (top.itemName or top.label or "?") .. " (id " .. top.itemId .. ") — " .. priceTag)
    else
        print("  Top priority: |cff888888(none)|r")
    end
    print("  |cff666666Tests: /p1ah test · /p1ah test 10410 · open AH then retry|r")
end

function P1DG.RecordAhSearchAttempt(itemId, name, result)
    P1DG._lastAhItemId = itemId
    P1DG._lastAhName = name
    P1DG._lastAhResult = result
    P1DG._lastAhAt = GetTime()
end

function P1DG.SearchAuctionItem(itemId, fromQueue)
    if not itemId then return false end
    local name = CacheItem(itemId)
    if not name then
        P1DG.RecordAhSearchAttempt(itemId, nil, "uncached")
        print("|cff00ccffP1 Guide|r — item not cached. Mouse over it once, then retry.")
        return false
    end
    if not P1DG.IsAuctionatorLoaded() then
        P1DG.RecordAhSearchAttempt(itemId, name, "no_addon")
        print("|cff00ccffP1 Guide|r — Auctionator not loaded. Run PLAY.bat and /reload.")
        return false
    end
    if not P1DG.IsAuctionHouseOpen() then
        P1DG.QueueAuctionSearch(itemId)
        P1DG.RecordAhSearchAttempt(itemId, name, "queued")
        if not fromQueue then
            print("|cff00ccffP1 Guide|r — |cffff8800QUEUED|r (open AH to search)")
            print("  Item: |cffffcc00" .. name .. "|r — will auto-search on AH open")
        end
        return false
    end
    Atr_SelectPane(BUY_TAB)
    Atr_Search_Box:SetText(name)
    Atr_Search_Onclick()
    P1DG.RecordAhSearchAttempt(itemId, name, "searched")
    print("|cff00ccffP1 Guide|r — |cff00ff00SEARCHED|r Auctionator Buy tab → |cffffcc00" .. name .. "|r")
    return true
end