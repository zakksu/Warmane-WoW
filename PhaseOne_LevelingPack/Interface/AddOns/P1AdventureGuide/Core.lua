-- P1 Adventure Guide — crafting mats with consumable credit (quest pack)

P1AdventureGuideDB = P1AdventureGuideDB or {
    point = "TOPLEFT", relPoint = "TOPLEFT", x = 12, y = -120,
}

local DB = P1AdventureGuideDB
local panel, scroll, content, contentText
local MAX_VISIBLE_LINES = 8

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
        local name, _, _, rank, _, _, skillMax = GetSkillLineInfo(i)
        if name == "First Aid" then
            return rank or 0, skillMax or 0
        end
    end
    return nil, nil
end

local function PickFaTier(playerLevel, faRank)
    local tiers = P1AG.FIRST_AID.tiers
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
    for _, band in ipairs(P1AG.HERB_MILESTONES) do
        if playerLevel >= band.levelMin and playerLevel <= band.levelMax then
            return band
        end
    end
    return P1AG.HERB_MILESTONES[#P1AG.HERB_MILESTONES]
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
        return " |cffff8800(by lvl " .. levelMax .. " — catch up!)|r"
    end
    if playerLevel >= levelMin then
        return " |cffffff00(next — lvl " .. levelMax .. ")|r"
    end
    return " |cff888888(lvl " .. levelMin .. "-" .. levelMax .. ")|r"
end

local function BuildFirstAidLines(playerLevel, lines)
    local faRank, faMax = GetFirstAidSkill()
    local tier = PickFaTier(playerLevel, faRank)
    if not tier then return end

    local cloth = CountItemInBags(tier.clothId)
    local bandageCredit = CountBandageCredit(tier.bandageIds)
    local altCloth = tier.altClothId and CountItemInBags(tier.altClothId) or 0
    local total = cloth + bandageCredit + altCloth
    local goal = tier.goalTotal

    table.insert(lines, "|cff00ccffFIRST AID|r" .. LevelMilestoneTag(tier.levelMin, tier.levelMax, playerLevel))

    if faRank then
        local need = math.max(0, tier.skillMax - faRank)
        local estMats = math.ceil(need * 0.6)
        local open, close = ColorRatio(faRank, tier.skillMax)
        table.insert(lines, string.format("  FA %s%d/%d%s — need ~%d more %s for next tier",
            open, faRank, tier.skillMax, close, estMats, tier.clothName:lower()))
    end

    local bandageCount = 0
    for itemId in pairs(tier.bandageIds) do
        bandageCount = bandageCount + CountItemInBags(itemId)
    end

    local summary = string.format("  %s: %d cloth + %d bandages = %s toward %s",
        tier.clothName, cloth, bandageCount, FormatRatio(total, goal), tier.label)
    table.insert(lines, summary)

    if tier.altClothName then
        table.insert(lines, string.format("  + %d %s (expert tier)", altCloth, tier.altClothName))
    end

    local finalGoal = 0
    for _, t in ipairs(P1AG.FIRST_AID.tiers) do finalGoal = finalGoal + t.goalTotal end
    table.insert(lines, string.format("  Have: %d cloth, %d bandages | Need by lvl %d: ~%d total healing supplies",
        cloth, bandageCount, P1AG.FIRST_AID.finalLevel, finalGoal))
end

local function BuildHerbLines(playerLevel, lines)
    local band = PickHerbMilestone(playerLevel)
    table.insert(lines, "|cff00ccffHERBS|r" .. LevelMilestoneTag(band.levelMin, band.levelMax, playerLevel))
    for _, item in ipairs(band.items) do
        local have = CountItemInBags(item.id)
        table.insert(lines, "  " .. FormatRatio(have, item.goal) .. " " .. item.name)
    end
end

local function BuildMatWatchLines(playerLevel, lines)
    local shown = 0
    for _, mat in ipairs(P1AG.MAT_WATCH) do
        if playerLevel <= mat.levelMax + 5 then
            local have = CountItemInBags(mat.id)
            table.insert(lines, "  " .. FormatRatio(have, mat.goal) .. " " .. mat.name
                .. LevelMilestoneTag(mat.levelMin, mat.levelMax, playerLevel))
            if mat.hint then
                table.insert(lines, "    |cff666666" .. mat.hint .. "|r")
            end
            shown = shown + 1
        end
    end
    if shown == 0 then
        table.insert(lines, "  |cff888888Leather/thread goals met for this level band|r")
    end
end

local function GetEquippedIlvl(slot)
    local link = GetInventoryItemLink("player", slot)
    if not link then return 0 end
    local _, _, _, level = GetItemInfo(link)
    return level or 0
end

local function BuildAHTipsLines(playerLevel, lines)
    local bandMin = math.max(11, playerLevel)
    local bandMax = playerLevel + 10
    table.insert(lines, "|cff00ccffAH TIPS|r (lvl " .. bandMin .. "-" .. bandMax .. ")")

    local shown = 0
    for _, tip in ipairs(P1AG.AH_TIPS) do
        if playerLevel >= tip.levelMin and playerLevel <= tip.levelMax + 5 then
            if tip.levelMax >= bandMin and tip.levelMin <= bandMax then
                local gray = false
                if tip.itemId and tip.equipSlot then
                    gray = GetEquippedIlvl(tip.equipSlot) >= (tip.maxIlvl or 99)
                elseif tip.itemId and tip.goal then
                    gray = CountItemInBags(tip.itemId) >= tip.goal
                elseif tip.checkBandages then
                    local tier = PickFaTier(playerLevel, GetFirstAidSkill())
                    if tier then
                        local total = CountItemInBags(tier.clothId) + CountBandageCredit(tier.bandageIds)
                        gray = total >= (tip.skipIfHave or 20)
                    end
                elseif tip.isGeneric and tip.equipSlot then
                    gray = GetEquippedIlvl(tip.equipSlot) >= (tip.maxIlvl or 22)
                end

                local prefix = tip.skipOnly and "  |cff888888" or (gray and "  |cff666666" or "  |cffffffff")
                local suffix = gray and " (have better)|r" or "|r"
                table.insert(lines, prefix .. "• " .. tip.tip .. suffix)
                shown = shown + 1
            end
        end
    end
    if shown == 0 then
        table.insert(lines, "  |cff888888No AH tips for this level yet|r")
    end
end

local function BuildMatsContent()
    if not contentText then return end
    local lvl = UnitLevel("player")
    local lines = { "|cff00ccffCRAFTING MATS|r |cff888888(/p1guide to hide)|r", "" }

    BuildFirstAidLines(lvl, lines)
    table.insert(lines, "")
    BuildHerbLines(lvl, lines)
    table.insert(lines, "")
    table.insert(lines, "|cff00ccffOTHER MATS|r")
    BuildMatWatchLines(lvl, lines)
    if lvl >= 11 then
        table.insert(lines, "")
        BuildAHTipsLines(lvl, lines)
    end

    contentText:SetText(table.concat(lines, "\n"))
    if content then
        local h = contentText:GetStringHeight() + 12
        content:SetHeight(math.max(h, 80))
    end
end

local function BuildUI()
    panel = CreateFrame("Frame", "P1AdventureGuideFrame", UIParent)
    panel:SetSize(300, 200)
    panel:SetPoint(DB.point or "TOPLEFT", UIParent, DB.relPoint or "TOPLEFT", DB.x or 12, DB.y or -120)
    panel:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    panel:SetBackdropColor(0.05, 0.05, 0.08, 0.88)
    panel:SetBackdropBorderColor(0.3, 0.6, 0.85, 0.9)
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("RightButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local p, _, rp, x, y = self:GetPoint()
        DB.point, DB.relPoint, DB.x, DB.y = p, rp, x, y
    end)

    scroll = CreateFrame("ScrollFrame", "P1AdventureGuideScroll", panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -28)
    scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -28, 8)

    content = CreateFrame("Frame", nil, scroll)
    content:SetSize(260, 80)
    scroll:SetScrollChild(content)

    contentText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    contentText:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    contentText:SetWidth(256)
    contentText:SetJustifyH("LEFT")
    contentText:SetNonSpaceWrap(true)

    BuildMatsContent()
end

local init = CreateFrame("Frame")
init:RegisterEvent("PLAYER_LOGIN")
init:RegisterEvent("BAG_UPDATE")
init:RegisterEvent("SKILL_LINES_CHANGED")
init:SetScript("OnEvent", function()
    if not panel then BuildUI() end
    BuildMatsContent()
end)

init:SetScript("OnUpdate", function(_, elapsed)
    init.tick = (init.tick or 0) + elapsed
    if init.tick > 3 then
        init.tick = 0
        BuildMatsContent()
    end
end)

SLASH_P1GUIDE1 = "/p1guide"
SlashCmdList["P1GUIDE"] = function()
    if panel then
        if panel:IsShown() then panel:Hide() else panel:Show() end
    end
end
