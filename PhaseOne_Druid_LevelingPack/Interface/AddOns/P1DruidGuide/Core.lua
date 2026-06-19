-- P1 Druid Guide — unified druid leveling overlay (Warmane 3.3.5a)

P1DruidGuideDB = P1DruidGuideDB or {
    point = "TOPLEFT", relPoint = "TOPLEFT", x = 12, y = -80,
    width = 280, height = 220, scale = 1.0,
    collapsed = { path = false, next = false, shop = false, tips = false, mats = false, gather = false, bis = false },
    minimized = false,
    tipsVisible = true,
    autoWaypoint = true,
}

local DB = P1DruidGuideDB
local VERSION = "2.1.0"
local panel, headerText, headerBtn, bodyText, resizeGrip, iconBar, minimizeBtn, clickCatcher
local iconFrames = {}
local guideVisible = true
local tipsVisible = true
local clickTargets = {}
local lastAutoQuestKey = nil
local lastRanked = {}

local SECTIONS = { "path", "next", "shop", "tips", "mats", "gather", "bis" }
local SECTION_LABELS = {
    path = "PATH",
    next = "NEXT",
    shop = "SHOP",
    tips = "TIPS",
    mats = "MATS",
    gather = "GATHER",
    bis = "BIS / BUILD",
}

local PRICE_TAGS = {
    free = "|cff00ff00[free]|r",
    cheap = "|cffffff00[~5g]|r",
    splurge = "|cffff8800[splurge]|r",
}

local function MigrateLegacyDB()
    if P1AdventureGuideDB and not DB.migrated then
        DB.point = DB.point or P1AdventureGuideDB.point
        DB.relPoint = DB.relPoint or P1AdventureGuideDB.relPoint
        DB.x = DB.x or P1AdventureGuideDB.x
        DB.y = DB.y or P1AdventureGuideDB.y
        DB.migrated = true
    end
    if DB.autoWaypoint == nil then DB.autoWaypoint = true end
end

local function SyncLoaderGuide(on)
    if PhaseOneLoaderDB then PhaseOneLoaderDB.guideVisible = on end
    if PhaseOneDruidLoaderDB then PhaseOneDruidLoaderDB.guideVisible = on end
end

local function ReadGuideVisible()
    if PhaseOneLoaderDB and PhaseOneLoaderDB.guideVisible ~= nil then
        return PhaseOneLoaderDB.guideVisible
    end
    if PhaseOneDruidLoaderDB and PhaseOneDruidLoaderDB.guideVisible ~= nil then
        return PhaseOneDruidLoaderDB.guideVisible
    end
    return true
end

local function ReadTipsVisible()
    if PhaseOneLoaderDB and PhaseOneLoaderDB.tipsVisible ~= nil then
        return PhaseOneLoaderDB.tipsVisible
    end
    if PhaseOneDruidLoaderDB and PhaseOneDruidLoaderDB.tipsVisible ~= nil then
        return PhaseOneDruidLoaderDB.tipsVisible
    end
    if DB.tipsVisible ~= nil then return DB.tipsVisible end
    return true
end

local function SyncLoaderTips(on)
    DB.tipsVisible = on
    if PhaseOneLoaderDB then PhaseOneLoaderDB.tipsVisible = on end
    if PhaseOneDruidLoaderDB then PhaseOneDruidLoaderDB.tipsVisible = on end
end

local function ReadAhPriority()
    if PhaseOneDruidLoaderDB and PhaseOneDruidLoaderDB.guideAhPriority ~= nil then
        return PhaseOneDruidLoaderDB.guideAhPriority
    end
    if PhaseOneLoaderDB and PhaseOneLoaderDB.guideAhPriority ~= nil then
        return PhaseOneLoaderDB.guideAhPriority
    end
    return true
end

local function ReadAutoWaypoint()
    if PhaseOneLoaderDB and PhaseOneLoaderDB.guideAutoWaypoint ~= nil then
        return PhaseOneLoaderDB.guideAutoWaypoint
    end
    if PhaseOneDruidLoaderDB and PhaseOneDruidLoaderDB.guideAutoWaypoint ~= nil then
        return PhaseOneDruidLoaderDB.guideAutoWaypoint
    end
    if DB.autoWaypoint ~= nil then return DB.autoWaypoint end
    return true
end

local function SyncLoaderAutoWaypoint(on)
    DB.autoWaypoint = on
    if PhaseOneLoaderDB then PhaseOneLoaderDB.guideAutoWaypoint = on end
    if PhaseOneDruidLoaderDB then PhaseOneDruidLoaderDB.guideAutoWaypoint = on end
end

local function IsDruidPlayer()
    local _, class = UnitClass("player")
    return class == "DRUID"
end

local function GetBagItemId(bag, slot)
    local link = GetContainerItemLink(bag, slot)
    if not link then return nil end
    return tonumber(link:match("item:(%d+)"))
end

local function CountItemInBags(itemId)
    if not itemId then return 0 end
    local total = 0
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            if GetBagItemId(bag, slot) == itemId then
                local _, count = GetContainerItemInfo(bag, slot)
                total = total + (count or 1)
            end
        end
    end
    return total
end

local function CountBandageCredit(bandageIds)
    local total = 0
    for itemId, weight in pairs(bandageIds) do
        total = total + CountItemInBags(itemId) * weight
    end
    return total
end

local function GetFirstAidSkill()
    for i = 1, GetNumSkillLines() do
        local name, _, _, rank = GetSkillLineInfo(i)
        if name == "First Aid" then return rank or 0 end
    end
    return nil
end

local function PickFaTier(playerLevel, faRank)
    local tiers = P1DG.FIRST_AID.tiers
    if faRank then
        for _, tier in ipairs(tiers) do
            if faRank < tier.skillMax then return tier end
        end
        return tiers[#tiers]
    end
    for _, tier in ipairs(tiers) do
        if playerLevel <= tier.levelMax then return tier end
    end
    return tiers[#tiers]
end

local function PickHerbMilestone(playerLevel)
    for _, band in ipairs(P1DG.HERB_MILESTONES) do
        if playerLevel >= band.levelMin and playerLevel <= band.levelMax then
            return band
        end
    end
    return P1DG.HERB_MILESTONES[#P1DG.HERB_MILESTONES]
end

local function PickOreMilestone(playerLevel)
    for _, band in ipairs(P1DG.ORE_MILESTONES) do
        if playerLevel >= band.levelMin and playerLevel <= band.levelMax then
            return band
        end
    end
    return P1DG.ORE_MILESTONES[#P1DG.ORE_MILESTONES]
end

local function PickBisBracket(playerLevel)
    return P1DG.GetBisBracket and P1DG.GetBisBracket(playerLevel)
        or (function()
            for _, bracket in ipairs(P1DG.BIS_BRACKETS) do
                if playerLevel >= bracket.levelMin and playerLevel <= bracket.levelMax then
                    return bracket
                end
            end
            return P1DG.BIS_BRACKETS[#P1DG.BIS_BRACKETS]
        end)()
end

local function PickTipsBracket(playerLevel)
    if not P1DG.TIPS_BRACKETS then return nil, nil end
    local current, nextBracket
    for i, bracket in ipairs(P1DG.TIPS_BRACKETS) do
        if playerLevel >= bracket.levelMin and playerLevel <= bracket.levelMax then
            current = bracket
            nextBracket = P1DG.TIPS_BRACKETS[i + 1]
            break
        end
        if playerLevel < bracket.levelMin then
            nextBracket = bracket
            break
        end
    end
    if not current and playerLevel >= P1DG.TIPS_BRACKETS[#P1DG.TIPS_BRACKETS].levelMax then
        current = P1DG.TIPS_BRACKETS[#P1DG.TIPS_BRACKETS]
    end
    return current, nextBracket
end

local function AddLine(lines, text, click)
    table.insert(lines, text)
    if click then clickTargets[#lines] = click end
end

local function SlotLineClick(slot, done)
    if done or not slot then return nil end
    if slot.itemId then
        return { type = "auction", itemId = slot.itemId }
    end
    if slot.waypoint then
        return { type = "waypoint", waypoint = slot.waypoint, label = slot.itemName or slot.key }
    end
    return nil
end

local function StepLineClick(step, playerLevel)
    if not step then return nil end
    if step.itemId and (step.goldAh or (step.text and step.text:find("AH", 1, true))) then
        return { type = "auction", itemId = step.itemId }
    end
    if step.waypoint then
        return { type = "waypoint", waypoint = step.waypoint, label = step.text }
    end
    local bisSlot = P1DG.FindBisSlotForStep and P1DG.FindBisSlotForStep(step)
    if bisSlot and P1DG.IsStepDone then
        return SlotLineClick(bisSlot, P1DG.IsStepDone(step, playerLevel))
    end
    return nil
end

local function AppendTipsBlock(lines, bracket, gray)
    if not bracket then return end
    local prefix = gray and "|cff666666" or "|cffffffff"
    local close = "|r"
    AddLine(lines, string.format("  %s[%d-%d] %s%s",
        prefix, bracket.levelMin, bracket.levelMax, bracket.zone or "", close))
    if bracket.flavor and not gray then
        AddLine(lines, "  |cffccaa00" .. bracket.flavor .. "|r")
    end
    if bracket.rotation then
        for rotLine in bracket.rotation:gmatch("[^\n]+") do
            AddLine(lines, "  " .. prefix .. rotLine .. close)
        end
    end
    if bracket.talents then
        AddLine(lines, "  " .. prefix .. "Talents: " .. bracket.talents .. close)
    end
    if bracket.survival then
        AddLine(lines, "  " .. prefix .. "Survive: " .. bracket.survival .. close)
    end
    if bracket.quests then
        AddLine(lines, "  " .. prefix .. "Quests: " .. bracket.quests .. close)
    end
    if bracket.gather then
        AddLine(lines, "  " .. prefix .. "Gather: " .. bracket.gather .. close)
    end
end

local function BuildTipsLines(playerLevel, lines)
    if not tipsVisible then
        AddLine(lines, "  |cff888888Tips hidden — /p1tips to show|r")
        return
    end
    local current, nextBracket = PickTipsBracket(playerLevel)
    if current then
        AppendTipsBlock(lines, current, false)
        local talentTip = P1DG.GetTalentTip and P1DG.GetTalentTip(playerLevel)
        if talentTip then
            AddLine(lines, "  |cffffcc00@lvl " .. playerLevel .. ":|r " .. talentTip)
        end
    elseif playerLevel < 10 then
        AddLine(lines, "  |cff888888Reach lvl 10 for cat form tips|r")
    end
    if nextBracket then
        AddLine(lines, "  |cff666666--- next (" .. nextBracket.levelMin .. "-" .. nextBracket.levelMax .. ") ---|r")
        AppendTipsBlock(lines, nextBracket, true)
    end
    AddLine(lines, "  |cff666666Nav: TomTom arrow + minimap dots · mobs glow|r")
end

local function ColorRatio(have, goal)
    if goal <= 0 then return "|cff888888", "|r" end
    if have >= goal then return "|cff00ff00", "|r" end
    if have >= goal * 0.5 then return "|cffffff00", "|r" end
    return "|cffff4444", "|r"
end

local function FormatRatio(have, goal)
    local open, close = ColorRatio(have, goal)
    return open .. have .. "/" .. goal .. close
end

local function LevelMilestoneTag(levelMin, levelMax, playerLevel)
    if playerLevel >= levelMax then
        return " |cffff8800(by lvl " .. levelMax .. ")|r"
    end
    if playerLevel >= levelMin then
        return " |cffffff00(lvl " .. levelMax .. ")|r"
    end
    return " |cff888888(lvl " .. levelMin .. "-" .. levelMax .. ")|r"
end

local function Truncate(s, n)
    if not s then return "?" end
    if #s <= n then return s end
    return string.sub(s, 1, n - 1) .. "…"
end

local function GetEquippedIlvl(slot)
    if not slot then return 0 end
    local link = GetInventoryItemLink("player", slot)
    if not link then return 0 end
    local _, _, _, level = GetItemInfo(link)
    return level or 0
end

local function GetEquippedItemId(slot)
    if not slot then return nil end
    local link = GetInventoryItemLink("player", slot)
    if not link then return nil end
    return tonumber(link:match("item:(%d+)"))
end

local function BisStatusColor(equipped, minIlvl, slotDef)
    if slotDef and slotDef.itemId and slotDef.equipSlot then
        if GetEquippedItemId(slotDef.equipSlot) == slotDef.itemId then
            return "|cff00ff00"
        end
    end
    if not minIlvl or minIlvl <= 0 then return "|cff888888" end
    if equipped >= minIlvl then return "|cff00ff00" end
    if equipped >= minIlvl - 2 then return "|cffffff00" end
    return "|cffff4444"
end

local function IsBisSlotDone(slot)
    if P1DG.IsBisSlotDone then return P1DG.IsBisSlotDone(slot) end
    if slot.itemId and slot.equipSlot and GetEquippedItemId(slot.equipSlot) == slot.itemId then
        return true
    end
    if slot.equipSlot and slot.minIlvl and slot.minIlvl > 0 then
        return GetEquippedIlvl(slot.equipSlot) >= slot.minIlvl
    end
    return false
end

local function PriceTierTag(tier)
    if not tier then return "" end
    return PRICE_TAGS[tier] or ""
end

local function BuildWaypointTarget(waypoint, label)
    if not waypoint or not waypoint.zone then return nil end
    return {
        zone = waypoint.zone,
        spawn = { (waypoint.x or 0) * 100, (waypoint.y or 0) * 100 },
        title = waypoint.title or label or "Guide waypoint",
        questName = label or waypoint.title,
    }
end

local function SetGuideWaypoint(waypoint, label)
    local target = BuildWaypointTarget(waypoint, label)
    if not target then return false end
    if P1QuestNav_API and P1QuestNav_API.SetWaypoint then
        P1QuestNav_API.SetWaypoint(target)
        print("|cff00ccffP1 Guide|r TomTom → " .. (label or target.title or "?"))
        return true
    end
    return false
end

local function GetPrimaryQuestEntry()
    if P1QuestPath_GetTop then
        local top = P1QuestPath_GetTop(1)
        if top and top[1] then return top[1] end
    end
    if P1QuestNav_GetPrimary then return P1QuestNav_GetPrimary() end
    return nil
end

local function NavigateToPrimary()
    local lvl = UnitLevel("player")
    local ahTop = P1DG.GetNextAhPriority and P1DG.GetNextAhPriority(lvl)
    if ahTop and P1DG.SearchAuctionItem then
        if P1DG.SearchAuctionItem(ahTop.itemId) then
            return true
        end
    end
    local primary = GetPrimaryQuestEntry()
    if not primary then
        if ahTop then
            print("|cff00ccffP1 Guide|r — open AH to search |cffffcc00" .. (ahTop.itemName or ahTop.label or "?") .. "|r")
        else
            print("|cff00ccffP1 Guide|r — accept a quest (Questie ON) or check BIS slots")
        end
        return false
    end
    if P1QuestNav_API and P1QuestNav_API.SetWaypoint then
        P1QuestNav_API.SetWaypoint(primary)
        print("|cff00ccffP1 Guide|r TomTom → " .. (primary.questName or "?"))
        return true
    end
    return false
end

local function MaybeAutoWaypoint()
    if not DB.autoWaypoint then return end
    local primary = GetPrimaryQuestEntry()
    if not primary then return end
    local key = (primary.questId or primary.questName or "?") .. ":" .. (primary.zone or 0)
    if key == lastAutoQuestKey then return end
    lastAutoQuestKey = key
    if P1QuestNav_API and P1QuestNav_API.SetWaypoint then
        P1QuestNav_API.SetWaypoint(primary)
    end
end

local function BuildPathLines(playerLevel, lines)
    local steps = P1DG.GetOptimalSteps and P1DG.GetOptimalSteps(playerLevel, 5) or {}
    if #steps == 0 then
        AddLine(lines, "  |cff888888On track — check NEXT quests|r")
        return
    end
    local hasWp = false
    for _, step in ipairs(steps) do
        if step.waypoint or (P1DG.FindBisSlotForStep and P1DG.FindBisSlotForStep(step) and P1DG.FindBisSlotForStep(step).waypoint) then
            hasWp = true
            break
        end
    end
    if hasWp then
        AddLine(lines, "  |cff666666(click • line → TomTom)|r")
    end
    local hasAh = false
    for _, step in ipairs(steps) do
        if step.itemId and (step.goldAh or (step.text and step.text:find("AH", 1, true))) then
            hasAh = true
            break
        end
    end
    if hasAh then
        AddLine(lines, "  |cff666666(click [AH] line → Auctionator — open AH first)|r")
    end
    for _, step in ipairs(steps) do
        local tag = (step.goldAh or (step.text and step.text:find("AH", 1, true))) and " |cffffcc00[AH]|r" or ""
        local cat = step.type == "gear" and "|cff44ff44" or (step.type == "spell" and "|cff88ccff" or "|cffffffff")
        AddLine(lines, string.format("  %s•|r %s%s", cat, step.text or "?", tag),
            StepLineClick(step, playerLevel))
        if step.flavor then
            AddLine(lines, "    |cffccaa00" .. step.flavor .. "|r")
        end
    end
end

local function RefreshIconBar()
    if not iconBar then return end
    local lvl = UnitLevel("player")
    local icons = P1DG.GetPendingBisIcons and P1DG.GetPendingBisIcons(lvl, 4) or {}
    for i = 1, 4 do
        local f = iconFrames[i]
        if f then
            local data = icons[i]
            f.iconData = data
            if data and data.itemId then
                f.tex:SetTexture(P1DG.GetItemIcon(data.itemId))
                f.tex:SetVertexColor(1, 0.85, 0.2)
                f.border:Show()
                f.label:SetText(data.label or "")
                f:Show()
                if not GetItemInfo(data.itemId) then
                    GameTooltip:SetHyperlink("item:" .. data.itemId .. ":0:0:0:0:0:0:0")
                    GameTooltip:Hide()
                end
            else
                f.iconData = nil
                f:Hide()
            end
        end
    end
    if #icons > 0 then iconBar:Show() else iconBar:Hide() end
end

local function SetMinimized(on)
    DB.minimized = on and true or false
    if not panel then return end
    if DB.minimized then
        if bodyText then bodyText:Hide() end
        if iconBar then iconBar:Hide() end
        if resizeGrip then resizeGrip:Hide() end
        if clickCatcher then clickCatcher:Hide() end
        if headerBtn then headerBtn:Hide() end
        panel:SetHeight(44)
    else
        if bodyText then bodyText:Show() end
        if resizeGrip then resizeGrip:Show() end
        if clickCatcher then clickCatcher:Show() end
        if headerBtn then headerBtn:Show() end
        panel:SetHeight(DB.height or 220)
        RefreshIconBar()
        P1DruidGuide_Refresh()
    end
end

local function BuildHeaderLine()
    local lvl = UnitLevel("player")
    if P1DG.ScanCharacter then P1DG.ScanCharacter() end
    local scan = P1DG.GetScan and P1DG.GetScan()
    local ahTop = ReadAhPriority() and P1DG.GetNextAhPriority and P1DG.GetNextAhPriority(lvl)
    local primary = GetPrimaryQuestEntry()
    local scanTag = ""
    if scan then
        scanTag = string.format("|cff555555%s L%d · %s · %dq|r ",
            Truncate(scan.name or "?", 10), scan.level or lvl,
            P1DG.FormatGoldShort and P1DG.FormatGoldShort(scan.gold) or "?",
            scan.activeQuests or 0)
    end
    if ahTop and ReadAhPriority() then
        local priceTag = ""
        if ahTop.itemId and P1DG.GetItemBuyout and P1DG.FormatAhPrice then
            local price = P1DG.GetItemBuyout(ahTop.itemId)
            if price then priceTag = " — " .. P1DG.FormatAhPrice(price) end
        end
        local ilvlTag = ""
        if ahTop.haveIlvl and ahTop.needIlvl then
            ilvlTag = string.format(" |cff888888(eq %d→%d)|r", ahTop.haveIlvl, ahTop.needIlvl)
        end
        local questHint = ""
        if primary then
            questHint = string.format(" |cff666666· then %s|r", Truncate(primary.questName, 14))
        end
        return scanTag .. string.format("|cffffcc00[AH]|r %s%s%s%s",
            Truncate(ahTop.itemName or ahTop.label or "upgrade", 18), ilvlTag, priceTag, questHint)
    end
    if not primary then
        return scanTag .. "|cff888888No quest — check BIS/AH|r |cff666666· /p1scan|r"
    end
    local dir = primary.dirLabel or ""
    if dir == "" and P1QuestNav_API and P1QuestNav_API.GetDirectionLabel then
        dir = P1QuestNav_API.GetDirectionLabel(primary) or ""
    end
    if dir == "" and primary.dist then dir = string.format("%dy", primary.dist) end
    local xpTag = primary.xp and primary.xp > 0 and string.format(" [%dxp]", primary.xp) or ""
    local gearTag = primary.gearLabel and " |cff44ff44↑gear|r" or ""
    return scanTag .. string.format("|cff00ff00[GO]|r %s — %s%s%s",
        Truncate(primary.questName, 22), dir, xpTag, gearTag)
end

local function BuildShopLines(playerLevel, lines)
    if not P1DG.BuildShopList then
        AddLine(lines, "  |cff888888SHOP module loading…|r")
        return
    end
    local shop = P1DG.BuildShopList(playerLevel, 5)
    if #shop == 0 then
        AddLine(lines, "  |cff00ff00Gear on track — no AH buys needed|r")
        return
    end
    AddLine(lines, string.format("  |cff666666Gold %s · click line → Auctionator|r",
        P1DG.FormatGoldShort and P1DG.FormatGoldShort(GetMoney()) or "?"))
    for i, item in ipairs(shop) do
        local priceTag = "?"
        if item.price and P1DG.FormatAhPrice then
            priceTag = P1DG.FormatAhPrice(item.price)
        end
        local affordTag = item.affordable and "|cff00ff00buy|r"
            or ("|cffff4444+" .. (P1DG.FormatGoldShort and P1DG.FormatGoldShort(item.shortfall) or "?") .. "|r")
        local ilvlTag = ""
        if item.haveIlvl and item.needIlvl then
            ilvlTag = string.format(" %d→%d", item.haveIlvl, item.needIlvl)
        end
        AddLine(lines, string.format("  %d. %s%s — %s %s",
            i, Truncate(item.itemName or item.key or "?", 16), ilvlTag, priceTag, affordTag),
            item.itemId and { type = "auction", itemId = item.itemId } or nil)
    end
    if P1DG.BuildRelistSuggestions then
        local relist = P1DG.BuildRelistSuggestions(3)
        if #relist > 0 then
            AddLine(lines, "  |cff666666Relist hints (assist)|r")
            for j, row in ipairs(relist) do
                local sug = P1DG.FormatAhPrice and P1DG.FormatAhPrice(row.suggestPrice) or "?"
                AddLine(lines, string.format("  R%d. %s — post ~%s",
                    j, Truncate(row.name or "?", 14), sug))
            end
        end
    end
end

local function BuildNextLines(playerLevel, lines)
    lastRanked = {}
    if P1DG.RankNextActions then
        lastRanked = P1DG.RankNextActions(playerLevel, 5) or {}
    end
    if #lastRanked == 0 then
        AddLine(lines, "  |cff888888No ranked actions — /p1scan|r")
        AddLine(lines, "  |cff666666Accept quests or check SHOP for AH buys|r")
        return
    end
    AddLine(lines, "  |cff666666Fused rank: gear ROI + quest xp/min|r")
    for i, action in ipairs(lastRanked) do
        if action.type == "auction" then
            local priceTag = action.price and P1DG.FormatAhPrice and P1DG.FormatAhPrice(action.price) or "?"
            local tag = action.affordable and "|cffffcc00AH|r" or "|cffff8800SAVE|r"
            AddLine(lines, string.format("  %d. %s %s — %s",
                i, tag, Truncate(action.itemName or "?", 16), priceTag),
                action.itemId and { type = "ranked", index = i } or nil)
        else
            local e = action.entry or {}
            local dir = e.dirLabel or (e.dist and (e.dist .. "y") or "")
            local xpTag = e.xp and e.xp > 0 and string.format("[%dxp]", e.xp) or ""
            AddLine(lines, string.format("  %d. |cff00ff00Q|r %s %s — %s",
                i, Truncate(action.questName or "?", 16), xpTag, dir),
                { type = "ranked", index = i })
        end
    end
end

local function BuildMatsLines(playerLevel, lines)
    local tier = PickFaTier(playerLevel, GetFirstAidSkill())
    if tier then
        local cloth = CountItemInBags(tier.clothId)
        local total = cloth + CountBandageCredit(tier.bandageIds)
        AddLine(lines, "  FA " .. tier.clothName .. " " .. FormatRatio(total, tier.goalTotal)
            .. LevelMilestoneTag(tier.levelMin, tier.levelMax, playerLevel))
    end
    for _, item in ipairs(PickHerbMilestone(playerLevel).items) do
        AddLine(lines, "  " .. FormatRatio(CountItemInBags(item.id), item.goal) .. " " .. item.name)
    end
    for _, item in ipairs(PickOreMilestone(playerLevel).items) do
        AddLine(lines, "  " .. FormatRatio(CountItemInBags(item.id), item.goal) .. " " .. item.name)
    end
    for _, mat in ipairs(P1DG.MAT_WATCH) do
        if playerLevel <= mat.levelMax + 5 then
            AddLine(lines, "  " .. FormatRatio(CountItemInBags(mat.id), mat.goal) .. " " .. mat.name)
        end
    end
end

local function BuildGatherLines(playerLevel, lines)
    local shown = 0
    local matsLow = false
    local tier = PickFaTier(playerLevel, GetFirstAidSkill())
    if tier and CountItemInBags(tier.clothId) + CountBandageCredit(tier.bandageIds) < tier.goalTotal * 0.5 then
        matsLow = true
    end
    for _, item in ipairs(PickHerbMilestone(playerLevel).items) do
        if CountItemInBags(item.id) < item.goal * 0.5 then
            matsLow = true
            local farm = P1DG.GATHER_FARM[item.id]
            if farm and farm.farms then
                for _, f in ipairs(farm.farms) do
                    if playerLevel >= f.levelMin and playerLevel <= f.levelMax + 5 then
                        AddLine(lines, string.format("  Farm: %s — %s %s", farm.name, f.zone, f.dir))
                        shown = shown + 1
                        break
                    end
                end
            end
        end
    end
    for _, item in ipairs(PickOreMilestone(playerLevel).items) do
        if CountItemInBags(item.id) < item.goal * 0.5 then
            matsLow = true
            local farm = P1DG.GATHER_FARM[item.id]
            if farm and farm.farms then
                for _, f in ipairs(farm.farms) do
                    if playerLevel >= f.levelMin and playerLevel <= f.levelMax + 5 then
                        AddLine(lines, string.format("  Mine: %s — %s %s", farm.name, f.zone, f.dir))
                        shown = shown + 1
                        break
                    end
                end
            end
        end
    end
    if playerLevel >= 11 and (matsLow or shown == 0) then
        for _, tip in ipairs(P1DG.AH_TIPS) do
            if shown >= 4 then break end
            if playerLevel >= tip.levelMin and playerLevel <= tip.levelMax + 5 and not tip.skipOnly then
                local skip = false
                if tip.itemId and tip.goal and CountItemInBags(tip.itemId) >= tip.goal then skip = true end
                if tip.itemId and matsLow and CountItemInBags(tip.itemId) >= (tip.goal or 999) * 0.5 then skip = true end
                if not skip then
                    AddLine(lines, "  |cff666666AH: " .. tip.tip .. "|r",
                        tip.itemId and { type = "auction", itemId = tip.itemId } or nil)
                    shown = shown + 1
                end
            end
        end
    end
    if shown == 0 then
        AddLine(lines, "  |cff888888Mats stocked — Questie node icons on map|r")
    end
end

local function BuildBisLines(playerLevel, lines)
    local bracket = PickBisBracket(playerLevel)
    if not bracket then return end

    local slots = {}
    for _, slot in ipairs(bracket.slots) do slots[#slots + 1] = slot end
    table.sort(slots, function(a, b) return (a.order or 99) < (b.order or 99) end)

    local green, total = 0, 0
    for _, slot in ipairs(slots) do
        total = total + 1
        if IsBisSlotDone(slot) then green = green + 1 end
    end

    local nextUp = P1DG.GetNextBisUpgrade and P1DG.GetNextBisUpgrade(playerLevel)
    if nextUp then
        local name = nextUp.itemName or nextUp.suggest or nextUp.key
        local click = SlotLineClick(nextUp, false)
        AddLine(lines, string.format("  |cffffcc00NEXT UPGRADE|r → %s (%s)",
            name, nextUp.key), click)
        if click and click.type == "auction" then
            AddLine(lines, "  |cff666666(click line → Auctionator)|r")
        elseif click and click.type == "waypoint" then
            AddLine(lines, "  |cff666666(click line → TomTom)|r")
        end
    end
    AddLine(lines, string.format("  |cff666666Lvl %d-%d — %d/%d slots|r",
        bracket.levelMin, bracket.levelMax, green, total))

    for _, slot in ipairs(slots) do
        local done = IsBisSlotDone(slot)
        local mark = done and "|cff00ff00✓|r" or "|cffff4444✗|r"
        local equipped = GetEquippedIlvl(slot.equipSlot)
        local color = BisStatusColor(equipped, slot.minIlvl, slot)
        local ilvlTag = slot.equipSlot and string.format(" (eq %d)", equipped) or ""
        local priceTag = PriceTierTag(slot.priceTier)
        local nameTag = slot.itemName and (" — " .. slot.itemName) or ""
        AddLine(lines, string.format("  %s %s%s:|r %s%s%s %s",
            mark, color, slot.key, slot.suggest, nameTag, ilvlTag, priceTag),
            SlotLineClick(slot, done))
        if slot.why then
            AddLine(lines, "    |cff888888" .. slot.why .. "|r")
        end
        if slot.flavor then
            AddLine(lines, "    |cffccaa00" .. slot.flavor .. "|r")
        end
        if slot.alt and not done then
            AddLine(lines, "    |cff666666Alt: " .. slot.alt .. "|r")
        end
    end
end

local function BuildBody()
    if not bodyText then return end
    local lvl = UnitLevel("player")
    DB.collapsed = DB.collapsed or {}
    clickTargets = {}
    local lines = {}
    for _, key in ipairs(SECTIONS) do
        if key == "tips" and not tipsVisible then
            -- skip section header when tips toggled off via /p1tips
        else
            local collapsed = DB.collapsed[key]
            AddLine(lines, (collapsed and "[+]" or "[-]") .. " |cff00ccff" .. SECTION_LABELS[key] .. "|r")
            if not collapsed then
                if key == "path" then BuildPathLines(lvl, lines)
                elseif key == "next" then BuildNextLines(lvl, lines)
                elseif key == "shop" then BuildShopLines(lvl, lines)
                elseif key == "tips" then BuildTipsLines(lvl, lines)
                elseif key == "mats" then BuildMatsLines(lvl, lines)
                elseif key == "gather" then BuildGatherLines(lvl, lines)
                elseif key == "bis" then BuildBisLines(lvl, lines) end
                AddLine(lines, "")
            end
        end
    end
    bodyText:SetText(table.concat(lines, "\n"))
end

local function ToggleSection(key)
    DB.collapsed = DB.collapsed or {}
    DB.collapsed[key] = not DB.collapsed[key]
    BuildBody()
end

local function ActivateRanked(index)
    local action = lastRanked[index]
    if not action then return end
    if action.type == "auction" and action.itemId and P1DG.SearchAuctionItem then
        P1DG.SearchAuctionItem(action.itemId)
    elseif action.type == "quest" and action.entry and P1QuestNav_API and P1QuestNav_API.SetWaypoint then
        P1QuestNav_API.SetWaypoint(action.entry)
        print("|cff00ccffP1 Guide|r TomTom → " .. (action.questName or "?"))
    end
end

local function HandleBodyClick(key, idx)
    if key == "next" and idx then
        ActivateRanked(idx)
        return
    end
    if key then ToggleSection(key) end
end

local function HandleClickTarget(target)
    if not target then return end
    if target.type == "ranked" and target.index then
        ActivateRanked(target.index)
    elseif target.type == "auction" and target.itemId and P1DG.SearchAuctionItem then
        P1DG.SearchAuctionItem(target.itemId)
    elseif target.type == "quest" then
        HandleBodyClick("next", target.index)
    elseif target.type == "waypoint" then
        SetGuideWaypoint(target.waypoint, target.label)
    end
end

local function SectionAtLine(text, lineNum)
    local current = 0
    local section = nil
    for line in text:gmatch("[^\n]+") do
        current = current + 1
        for _, key in ipairs(SECTIONS) do
            if line:find(SECTION_LABELS[key], 1, true) then
                section = key
                break
            end
        end
        if current == lineNum then return section end
    end
    return section
end

local function ClickTargetFromBody(y)
    if not bodyText then return nil, nil end
    local text = bodyText:GetText() or ""
    local _, size = bodyText:GetFont()
    local lineH = (size or 10) + 1
    local top = bodyText:GetTop()
    local lineNum = math.floor((top - y) / lineH) + 1
    if clickTargets[lineNum] then
        return "click", clickTargets[lineNum]
    end
    local current = 0
    for line in text:gmatch("[^\n]+") do
        current = current + 1
        if current == lineNum then
            for _, key in ipairs(SECTIONS) do
                if line:find(SECTION_LABELS[key], 1, true) then return key, nil end
            end
            local idx = line:match("^%s*(%d+)%.")
            if idx then
                local section = SectionAtLine(text, lineNum)
                if section == "shop" or section == "gather" or section == "bis" then
                    return "click", nil
                end
                return section or "next", tonumber(idx)
            end
            break
        end
    end
    return nil, nil
end

local function SetupDragRegion(frame)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function() panel:StartMoving() end)
    frame:SetScript("OnDragStop", function()
        panel:StopMovingOrSizing()
        local p, _, rp, x, y = panel:GetPoint()
        DB.point, DB.relPoint, DB.x, DB.y = p, rp, x, y
    end)
end

local function BuildUI()
    panel = CreateFrame("Frame", "P1DruidGuideFrame", UIParent)
    panel:SetSize(DB.width or 280, DB.height or 220)
    panel:SetPoint(DB.point or "TOPLEFT", UIParent, DB.relPoint or "TOPLEFT", DB.x or 12, DB.y or -80)
    panel:SetScale(DB.scale or 1.0)
    panel:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 10,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    panel:SetBackdropColor(0.04, 0.04, 0.06, 0.82)
    panel:SetBackdropBorderColor(0.25, 0.5, 0.7, 0.75)
    panel:SetClampedToScreen(true)
    panel:SetMovable(true)
    panel:SetResizable(true)
    panel:SetMinResize(220, 140)
    panel:SetMaxResize(420, 480)

    local titleBar = CreateFrame("Frame", nil, panel)
    titleBar:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -4)
    titleBar:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -4, -4)
    titleBar:SetHeight(18)
    titleBar:SetFrameLevel(panel:GetFrameLevel() + 5)
    SetupDragRegion(titleBar)

    local titleLabel = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    titleLabel:SetPoint("LEFT", titleBar, "LEFT", 4, 0)
    titleLabel:SetText("|cff00ccffDRUID GUIDE|r |cff666666(drag title)|r")

    minimizeBtn = CreateFrame("Button", nil, titleBar)
    minimizeBtn:SetSize(16, 16)
    minimizeBtn:SetPoint("TOPRIGHT", titleBar, "TOPRIGHT", -2, -1)
    minimizeBtn:SetFrameLevel(titleBar:GetFrameLevel() + 2)
    minimizeBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    minimizeBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    minimizeBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    minimizeBtn:SetScript("OnClick", function()
        SetMinimized(not DB.minimized)
    end)

    iconBar = CreateFrame("Frame", nil, panel)
    iconBar:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -38)
    iconBar:SetSize(200, 36)
    for i = 1, 4 do
        local f = CreateFrame("Button", nil, iconBar)
        f:SetSize(32, 32)
        f:SetPoint("LEFT", iconBar, "LEFT", (i - 1) * 36, 0)
        f.border = f:CreateTexture(nil, "OVERLAY")
        f.border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        f.border:SetBlendMode("ADD")
        f.border:SetPoint("CENTER", f, "CENTER", 0, 0)
        f.border:SetSize(42, 42)
        f.border:SetAlpha(0.5)
        f.tex = f:CreateTexture(nil, "ARTWORK")
        f.tex:SetPoint("TOPLEFT", f, "TOPLEFT", 2, -2)
        f.tex:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2, 2)
        f.label = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        f.label:SetPoint("BOTTOM", f, "BOTTOM", 0, -2)
        f.label:SetTextColor(1, 0.85, 0.3)
        f:SetScript("OnEnter", function(self)
            local data = self.iconData
            if not data or not data.itemId then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink("item:" .. data.itemId .. ":0:0:0:0:0:0:0")
            if data.why then GameTooltip:AddLine(data.why, 0.7, 0.7, 0.7, true) end
            if data.flavor then GameTooltip:AddLine(data.flavor, 0.8, 0.67, 0.0, true) end
            if data.source then GameTooltip:AddLine(data.source, 0.5, 0.8, 0.5) end
            if data.goldAh and data.itemId then
                GameTooltip:AddLine("Click: search Auctionator", 1, 0.82, 0)
            elseif data.waypoint then
                GameTooltip:AddLine("Click: TomTom waypoint", 0.5, 1, 0.5)
            end
            GameTooltip:Show()
        end)
        f:SetScript("OnLeave", function() GameTooltip:Hide() end)
        f:SetScript("OnClick", function(self)
            local data = self.iconData
            if not data then return end
            if data.goldAh and data.itemId and P1DG.SearchAuctionItem then
                local ok = P1DG.SearchAuctionItem(data.itemId)
                if not ok and P1DG.IsAuctionHouseOpen and not P1DG.IsAuctionHouseOpen() then
                    print("|cff666666(icon click queued — open AH)|r")
                end
            elseif data.waypoint then
                SetGuideWaypoint(data.waypoint, data.label)
            end
        end)
        iconFrames[i] = f
        f:Hide()
    end

    headerText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    headerText:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -22)
    headerText:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -28, -22)
    headerText:SetJustifyH("LEFT")
    headerText:SetWordWrap(true)

    headerBtn = CreateFrame("Button", nil, panel)
    headerBtn:SetPoint("TOPLEFT", headerText, "TOPLEFT", -2, 2)
    headerBtn:SetPoint("BOTTOMRIGHT", headerText, "BOTTOMRIGHT", 2, -2)
    headerBtn:SetFrameLevel(panel:GetFrameLevel() + 4)
    headerBtn:SetScript("OnClick", function() NavigateToPrimary() end)
    headerBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Click [AH] — search top upgrade in Auctionator", 1, 0.82, 0)
        GameTooltip:AddLine("Click [GO] — TomTom arrow to top quest", 1, 1, 1)
        GameTooltip:AddLine("AH lines in NEXT — click to search (open AH first)", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    headerBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local headerDrag = CreateFrame("Frame", nil, panel)
    headerDrag:SetPoint("TOPLEFT", headerText, "TOPLEFT", 0, 0)
    headerDrag:SetPoint("BOTTOMRIGHT", headerText, "BOTTOMRIGHT", 0, 0)
    headerDrag:SetFrameLevel(panel:GetFrameLevel() + 3)
    headerDrag:EnableMouse(true)
    headerDrag:RegisterForDrag("RightButton")
    headerDrag:SetScript("OnDragStart", function() panel:StartMoving() end)
    headerDrag:SetScript("OnDragStop", function()
        panel:StopMovingOrSizing()
        local p, _, rp, x, y = panel:GetPoint()
        DB.point, DB.relPoint, DB.x, DB.y = p, rp, x, y
    end)

    bodyText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bodyText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    bodyText:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -76)
    bodyText:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -10, 10)
    bodyText:SetJustifyH("LEFT")
    bodyText:SetWordWrap(false)

    clickCatcher = CreateFrame("Button", nil, panel)
    clickCatcher:SetPoint("TOPLEFT", bodyText, "TOPLEFT", 0, 0)
    clickCatcher:SetPoint("BOTTOMRIGHT", bodyText, "BOTTOMRIGHT", 0, 0)
    clickCatcher:SetFrameLevel(panel:GetFrameLevel() + 2)
    clickCatcher:SetScript("OnClick", function(_, button)
        if button ~= "LeftButton" then return end
        local _, cy = GetCursorPosition()
        local scale = panel:GetEffectiveScale()
        local key, idx = ClickTargetFromBody(cy / scale)
        if key == "click" then
            HandleClickTarget(idx)
            return
        end
        HandleBodyClick(key, idx)
    end)

    resizeGrip = CreateFrame("Frame", nil, panel)
    resizeGrip:SetSize(14, 14)
    resizeGrip:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -2, 2)
    resizeGrip:EnableMouse(true)
    resizeGrip:SetScript("OnMouseDown", function() panel:StartSizing("BOTTOMRIGHT") end)
    resizeGrip:SetScript("OnMouseUp", function()
        panel:StopMovingOrSizing()
        DB.width = panel:GetWidth()
        DB.height = panel:GetHeight()
    end)
    local gripTex = resizeGrip:CreateTexture(nil, "ARTWORK")
    gripTex:SetAllPoints()
    gripTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
end

function P1DruidGuide_Refresh()
    if not panel or not guideVisible then return end
    if headerText then headerText:SetText(BuildHeaderLine()) end
    if not DB.minimized then
        BuildBody()
        RefreshIconBar()
        MaybeAutoWaypoint()
    end
end

function P1DruidGuide_SetTipsVisible(show)
    tipsVisible = show and true or false
    SyncLoaderTips(tipsVisible)
    P1DruidGuide_Refresh()
end

function P1DruidGuide_SetPathCollapsed(collapsed)
    DB.collapsed = DB.collapsed or {}
    DB.collapsed.path = not not collapsed
    P1DruidGuide_Refresh()
end

function P1DruidGuide_SetVisible(show)
    if not panel then BuildUI() end
    guideVisible = show and true or false
    SyncLoaderGuide(guideVisible)
    if guideVisible then panel:Show() else panel:Hide() end
    P1DruidGuide_Refresh()
    if P1QuestNav_Refresh then P1QuestNav_Refresh(true) end
end

function P1DruidGuide_SetAutoWaypoint(on)
    on = on and true or false
    SyncLoaderAutoWaypoint(on)
    if on then
        lastAutoQuestKey = nil
        MaybeAutoWaypoint()
    end
end

function P1DruidGuide_ResetLayout()
    DB.point, DB.relPoint, DB.x, DB.y = "TOPLEFT", "TOPLEFT", 12, -80
    DB.width, DB.height, DB.scale = 280, 220, 1.0
    if panel then
        panel:ClearAllPoints()
        panel:SetPoint(DB.point, UIParent, DB.relPoint, DB.x, DB.y)
        panel:SetSize(DB.width, DB.height)
        panel:SetScale(DB.scale)
    end
    print("|cff00ccffP1 Druid Guide|r — position reset")
end

function P1DruidGuide_SetScale(s)
    DB.scale = math.max(0.6, math.min(1.4, s))
    if panel then panel:SetScale(DB.scale) end
end

P1AdventureGuide_SetVisible = P1DruidGuide_SetVisible
P1AdventureGuide_SetPathCollapsed = P1DruidGuide_SetPathCollapsed

local function HandleGuideSlash(msg)
    msg = string.lower((msg or ""):match("^%s*(.-)%s*$") or "")
    if msg == "on" then P1DruidGuide_SetVisible(true)
    elseif msg == "off" then P1DruidGuide_SetVisible(false)
    elseif msg == "reset" then P1DruidGuide_ResetLayout()
    elseif msg == "min" or msg == "minimize" then SetMinimized(true)
    elseif msg == "max" or msg == "restore" then SetMinimized(false)
    elseif msg == "go" then NavigateToPrimary()
    elseif msg == "autogo on" then
        P1DruidGuide_SetAutoWaypoint(true)
        print("|cff00ccffP1 Guide|r autogo |cff00ff00ON|r — top quest auto-sets TomTom")
    elseif msg == "autogo off" then
        P1DruidGuide_SetAutoWaypoint(false)
        print("|cff00ccffP1 Guide|r autogo |cffaaaaaaOFF|r")
    elseif msg:match("^scale ") then
        local s = tonumber(msg:match("^scale%s+(.+)$"))
        if s then P1DruidGuide_SetScale(s) end
    else
        if not panel then BuildUI() end
        P1DruidGuide_SetVisible(not panel:IsShown())
    end
    print("|cff00ccffP1 Druid Guide|r v" .. VERSION .. " — "
        .. (guideVisible and "|cff00ff00ON|r" or "|cffaaaaaaOFF|r"))
end

SLASH_P1GUIDE1 = "/p1guide"
SlashCmdList["P1GUIDE"] = HandleGuideSlash
SLASH_P1DRUID1 = "/p1"
SlashCmdList["P1DRUID"] = HandleGuideSlash

local function HandleP1Ah(msg)
    msg = string.lower((msg or ""):match("^%s*(.-)%s*$") or "")
    if msg == "debug" or msg == "status" then
        if P1DG.PrintAhDiagnostics then P1DG.PrintAhDiagnostics() end
        if P1DG.PrintMarketSummary then P1DG.PrintMarketSummary() end
        return
    end
    if msg == "scan" then
        local n = P1DG.ScanBrowseList and P1DG.ScanBrowseList() or 0
        print(string.format("|cff00ccffP1 AH scan|r — %d listings on %s (assist-only)",
            n, P1DG.GetRealmKey and P1DG.GetRealmKey() or "?"))
        if P1DG.PrintMarketSummary then P1DG.PrintMarketSummary() end
        return
    end
    if msg == "relist" then
        if P1DG.PrintRelistSuggestions then P1DG.PrintRelistSuggestions() end
        return
    end
    if msg == "watch" then
        local q = P1DG.ScanShopWatchlist and P1DG.ScanShopWatchlist(5) or 0
        print("|cff00ccffP1 AH watch|r — queued " .. q .. " SHOP searches (open AH)")
        return
    end
    local testId = tonumber(msg:match("^test%s+(%d+)$"))
    if msg == "test" or testId then
        local itemId = testId
        if not itemId then
            local top = P1DG.GetNextAhPriority and P1DG.GetNextAhPriority(UnitLevel("player"))
            itemId = top and top.itemId
        end
        if not itemId then
            print("|cff00ccffP1 Guide|r — /p1ah test 10410 (Leggings of the Fang)")
            return
        end
        print("|cff00ccffP1 AH test|r — firing SearchAuctionItem(" .. itemId .. ")")
        if P1DG.SearchAuctionItem then P1DG.SearchAuctionItem(itemId) end
        if P1DG.PrintAhDiagnostics then P1DG.PrintAhDiagnostics() end
        return
    end
    local ahTop = P1DG.GetNextAhPriority and P1DG.GetNextAhPriority(UnitLevel("player"))
    if not ahTop or not ahTop.itemId then
        print("|cff00ccffP1 Guide|r — no pending AH upgrades (gear looks good)")
        return
    end
    if P1DG.SearchAuctionItem then
        P1DG.SearchAuctionItem(ahTop.itemId)
    end
end

SLASH_P1AH1 = "/p1ah"
SlashCmdList["P1AH"] = HandleP1Ah

local function HandleP1Scan()
    local _, class = UnitClass("player")
    if class ~= "DRUID" then
        print("|cff00ccffP1 Scan|r — druid characters only")
        return
    end
    if not P1DG or not P1DG.PrintCharacterScan then
        print("|cff00ccffP1 Scan|r — enable |cff00ff00P1DruidGuide|r at character select, then /reload")
        return
    end
    local ok, err = pcall(function()
        P1DG.PrintCharacterScan()
        if P1DruidGuide_Refresh then P1DruidGuide_Refresh() end
    end)
    if not ok then
        print("|cffff0000P1 Scan error:|r " .. tostring(err))
    end
end

SLASH_P1SCAN1 = "/p1scan"
SlashCmdList["P1SCAN"] = HandleP1Scan

SLASH_P1TIPS1 = "/p1tips"
SlashCmdList["P1TIPS"] = function(msg)
    msg = string.lower((msg or ""):match("^%s*(.-)%s*$") or "")
    if msg == "on" then P1DruidGuide_SetTipsVisible(true)
    elseif msg == "off" then P1DruidGuide_SetTipsVisible(false)
    else P1DruidGuide_SetTipsVisible(not tipsVisible) end
    print("|cff00ccffP1 Tips|r — level bracket advice "
        .. (tipsVisible and "|cff00ff00ON|r" or "|cffaaaaaaOFF|r"))
end

local init = CreateFrame("Frame")
init:RegisterEvent("PLAYER_LOGIN")
init:RegisterEvent("BAG_UPDATE")
init:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
init:RegisterEvent("SKILL_LINES_CHANGED")
init:RegisterEvent("QUEST_LOG_UPDATE")
init:RegisterEvent("AUCTION_HOUSE_SHOW")
init:RegisterEvent("AUCTION_HOUSE_CLOSED")
init:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
init:RegisterEvent("PLAYER_MONEY")
init:SetScript("OnEvent", function(_, event)
    MigrateLegacyDB()
    if not panel then BuildUI() end
    if event == "PLAYER_LOGIN" then
        if not IsDruidPlayer() then
            guideVisible = false
            if panel then panel:Hide() end
            return
        end
        guideVisible = ReadGuideVisible()
        tipsVisible = ReadTipsVisible()
        SyncLoaderTips(tipsVisible)
        P1DruidGuide_SetAutoWaypoint(ReadAutoWaypoint())
        P1DruidGuide_SetVisible(guideVisible)
        if DB.minimized then SetMinimized(true) end
        if P1DG.ResetSessionBaseline then P1DG.ResetSessionBaseline() end
        if P1DG.ScanCharacter then P1DG.ScanCharacter() end
    else
        if event == "AUCTION_HOUSE_SHOW" then
            init.ahFlushDelay = 0.4
            init.ahFlushPending = true
        elseif event == "AUCTION_HOUSE_CLOSED" then
            init.ahFlushPending = false
        elseif event == "PLAYER_EQUIPMENT_CHANGED" or event == "BAG_UPDATE"
            or event == "PLAYER_MONEY" or event == "QUEST_LOG_UPDATE" then
            if P1DG.ScanCharacter then P1DG.ScanCharacter() end
        end
        P1DruidGuide_Refresh()
    end
end)

init:SetScript("OnUpdate", function(_, elapsed)
    if init.ahFlushPending then
        init.ahFlushDelay = (init.ahFlushDelay or 0) - elapsed
        if init.ahFlushDelay <= 0 then
            init.ahFlushPending = false
            if P1DG.FlushPendingAuctionSearch then P1DG.FlushPendingAuctionSearch() end
        end
    end
    init.tick = (init.tick or 0) + elapsed
    if init.tick > 4 then
        init.tick = 0
        P1DruidGuide_Refresh()
    end
end)