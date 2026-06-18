-- P1 Druid Guide — unified druid leveling overlay (Warmane 3.3.5a)

P1DruidGuideDB = P1DruidGuideDB or {
    point = "TOPLEFT", relPoint = "TOPLEFT", x = 12, y = -80,
    width = 280, height = 220, scale = 1.0,
    collapsed = { next = false, mats = false, gather = false, bis = true },
}

local DB = P1DruidGuideDB
local VERSION = "1.3.0"
local panel, headerText, bodyText, resizeGrip
local guideVisible = true

local SECTIONS = { "next", "mats", "gather", "bis" }
local SECTION_LABELS = {
    next = "NEXT",
    mats = "MATS",
    gather = "GATHER",
    bis = "BIS / BUILD",
}

local function MigrateLegacyDB()
    if P1AdventureGuideDB and not DB.migrated then
        DB.point = DB.point or P1AdventureGuideDB.point
        DB.relPoint = DB.relPoint or P1AdventureGuideDB.relPoint
        DB.x = DB.x or P1AdventureGuideDB.x
        DB.y = DB.y or P1AdventureGuideDB.y
        DB.migrated = true
    end
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
    for _, bracket in ipairs(P1DG.BIS_BRACKETS) do
        if playerLevel >= bracket.levelMin and playerLevel <= bracket.levelMax then
            return bracket
        end
    end
    return P1DG.BIS_BRACKETS[#P1DG.BIS_BRACKETS]
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

local function BisStatusColor(equipped, minIlvl)
    if not minIlvl or minIlvl <= 0 then return "|cff888888" end
    if equipped >= minIlvl then return "|cff00ff00" end
    if equipped >= minIlvl - 2 then return "|cffffff00" end
    return "|cffff4444"
end

local function BuildHeaderLine()
    local primary
    if P1QuestPath_GetTop then
        local top = P1QuestPath_GetTop(1)
        primary = top and top[1]
    end
    if not primary and P1QuestNav_GetPrimary then
        primary = P1QuestNav_GetPrimary()
    end
    if not primary then
        return "|cff00ccffP1 Druid Guide|r |cff666666— no active quest|r"
    end
    local dir = primary.dirLabel or ""
    if dir == "" and primary.dist then dir = string.format("%dy", primary.dist) end
    local xpTag = primary.xp and primary.xp > 0 and string.format(" [%dxp]", primary.xp) or ""
    local gearTag = primary.gearLabel and " |cff44ff44↑gear|r" or ""
    return string.format("|cff00ccffNEXT:|r %s — %s%s%s",
        Truncate(primary.questName, 22), dir, xpTag, gearTag)
end

local function BuildNextLines(lines)
    local entries = P1QuestPath_GetTop and (P1QuestPath_GetTop(3) or {}) or {}
    if #entries == 0 then
        table.insert(lines, "  |cff888888Accept a quest — Questie icons ON|r")
        return
    end
    for i, e in ipairs(entries) do
        local dir = e.dirLabel or (e.dist and (e.dist .. "y") or "")
        local xpTag = e.xp and e.xp > 0 and string.format("[%dxp", e.xp) or "[?"
        local gearTag = e.gearLabel and (", " .. e.gearLabel .. "]") or "]"
        local gearFlag = e.gearLabel and " |cff44ff44↑|r" or ""
        table.insert(lines, string.format("  %d. %s%s%s — %s%s",
            i, Truncate(e.questName, 18), xpTag, gearTag, dir, gearFlag))
    end
end

local function BuildMatsLines(playerLevel, lines)
    local tier = PickFaTier(playerLevel, GetFirstAidSkill())
    if tier then
        local cloth = CountItemInBags(tier.clothId)
        local total = cloth + CountBandageCredit(tier.bandageIds)
        table.insert(lines, "  FA " .. tier.clothName .. " " .. FormatRatio(total, tier.goalTotal)
            .. LevelMilestoneTag(tier.levelMin, tier.levelMax, playerLevel))
    end
    for _, item in ipairs(PickHerbMilestone(playerLevel).items) do
        table.insert(lines, "  " .. FormatRatio(CountItemInBags(item.id), item.goal) .. " " .. item.name)
    end
    for _, item in ipairs(PickOreMilestone(playerLevel).items) do
        table.insert(lines, "  " .. FormatRatio(CountItemInBags(item.id), item.goal) .. " " .. item.name)
    end
    for _, mat in ipairs(P1DG.MAT_WATCH) do
        if playerLevel <= mat.levelMax + 5 then
            table.insert(lines, "  " .. FormatRatio(CountItemInBags(mat.id), mat.goal) .. " " .. mat.name)
        end
    end
end

local function BuildGatherLines(playerLevel, lines)
    local shown = 0
    for _, item in ipairs(PickHerbMilestone(playerLevel).items) do
        if CountItemInBags(item.id) < item.goal * 0.5 then
            local farm = P1DG.GATHER_FARM[item.id]
            if farm and farm.farms then
                for _, f in ipairs(farm.farms) do
                    if playerLevel >= f.levelMin and playerLevel <= f.levelMax + 5 then
                        table.insert(lines, string.format("  Farm: %s — %s %s", farm.name, f.zone, f.dir))
                        shown = shown + 1
                        break
                    end
                end
            end
        end
    end
    for _, item in ipairs(PickOreMilestone(playerLevel).items) do
        if CountItemInBags(item.id) < item.goal * 0.5 then
            local farm = P1DG.GATHER_FARM[item.id]
            if farm and farm.farms then
                for _, f in ipairs(farm.farms) do
                    if playerLevel >= f.levelMin and playerLevel <= f.levelMax + 5 then
                        table.insert(lines, string.format("  Mine: %s — %s %s", farm.name, f.zone, f.dir))
                        shown = shown + 1
                        break
                    end
                end
            end
        end
    end
    if playerLevel >= 11 then
        for _, tip in ipairs(P1DG.AH_TIPS) do
            if shown >= 4 then break end
            if playerLevel >= tip.levelMin and playerLevel <= tip.levelMax + 5 and not tip.skipOnly then
                if not (tip.itemId and tip.goal and CountItemInBags(tip.itemId) >= tip.goal) then
                    table.insert(lines, "  |cff666666AH: " .. tip.tip .. "|r")
                    shown = shown + 1
                end
            end
        end
    end
    if shown == 0 then
        table.insert(lines, "  |cff888888Mats stocked — Questie node icons on map|r")
    end
end

local function BuildBisLines(playerLevel, lines)
    local bracket = PickBisBracket(playerLevel)
    if not bracket then return end
    table.insert(lines, string.format("  |cff666666Lvl %d-%d — impact order|r",
        bracket.levelMin, bracket.levelMax))
    local slots = {}
    for _, slot in ipairs(bracket.slots) do slots[#slots + 1] = slot end
    table.sort(slots, function(a, b) return (a.order or 99) < (b.order or 99) end)
    for _, slot in ipairs(slots) do
        local equipped = GetEquippedIlvl(slot.equipSlot)
        local color = BisStatusColor(equipped, slot.minIlvl)
        local ilvlTag = slot.equipSlot and string.format(" (eq %d)", equipped) or ""
        table.insert(lines, string.format("  %s%s:|r %s%s |cff666666[%s]|r",
            color, slot.key, slot.suggest, ilvlTag, slot.source or ""))
    end
end

local function BuildBody()
    if not bodyText then return end
    local lvl = UnitLevel("player")
    DB.collapsed = DB.collapsed or {}
    local lines = {}
    for _, key in ipairs(SECTIONS) do
        local collapsed = DB.collapsed[key]
        table.insert(lines, (collapsed and "[+]" or "[-]") .. " |cff00ccff" .. SECTION_LABELS[key] .. "|r")
        if not collapsed then
            if key == "next" then BuildNextLines(lines)
            elseif key == "mats" then BuildMatsLines(lvl, lines)
            elseif key == "gather" then BuildGatherLines(lvl, lines)
            elseif key == "bis" then BuildBisLines(lvl, lines) end
            table.insert(lines, "")
        end
    end
    bodyText:SetText(table.concat(lines, "\n"))
end

local function ToggleSection(key)
    DB.collapsed = DB.collapsed or {}
    DB.collapsed[key] = not DB.collapsed[key]
    BuildBody()
end

local function SectionFromClick(y)
    if not bodyText then return nil end
    local text = bodyText:GetText() or ""
    local lineH = 11
    local top = bodyText:GetTop()
    local lineNum = math.floor((top - y) / lineH) + 1
    local current = 0
    for line in text:gmatch("[^\n]+") do
        current = current + 1
        if current == lineNum then
            for _, key in ipairs(SECTIONS) do
                if line:find(SECTION_LABELS[key], 1, true) then return key end
            end
            break
        end
    end
    return nil
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
    panel:SetResizable(true)
    panel:SetMinResize(220, 140)
    panel:SetMaxResize(420, 480)

    local titleBar = CreateFrame("Frame", nil, panel)
    titleBar:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -4)
    titleBar:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -4, -4)
    titleBar:SetHeight(18)
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function() panel:StartMoving() end)
    titleBar:SetScript("OnDragStop", function()
        panel:StopMovingOrSizing()
        local p, _, rp, x, y = panel:GetPoint()
        DB.point, DB.relPoint, DB.x, DB.y = p, rp, x, y
    end)

    headerText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    headerText:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -22)
    headerText:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -8, -22)
    headerText:SetJustifyH("LEFT")
    headerText:SetWordWrap(true)

    bodyText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bodyText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    bodyText:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -40)
    bodyText:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -10, 10)
    bodyText:SetJustifyH("LEFT")
    bodyText:SetWordWrap(true)

    local clickCatcher = CreateFrame("Button", nil, panel)
    clickCatcher:SetPoint("TOPLEFT", bodyText, "TOPLEFT", 0, 0)
    clickCatcher:SetPoint("BOTTOMRIGHT", bodyText, "BOTTOMRIGHT", 0, 0)
    clickCatcher:SetScript("OnClick", function(_, button)
        if button ~= "LeftButton" then return end
        local _, cy = GetCursorPosition()
        local scale = panel:GetEffectiveScale()
        local key = SectionFromClick(cy / scale)
        if key then ToggleSection(key) end
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
    BuildBody()
end

function P1DruidGuide_SetVisible(show)
    if not panel then BuildUI() end
    guideVisible = show and true or false
    SyncLoaderGuide(guideVisible)
    if guideVisible then panel:Show() else panel:Hide() end
    P1DruidGuide_Refresh()
    if P1QuestNav_Refresh then P1QuestNav_Refresh(true) end
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

local function HandleGuideSlash(msg)
    msg = string.lower((msg or ""):match("^%s*(.-)%s*$") or "")
    if msg == "on" then P1DruidGuide_SetVisible(true)
    elseif msg == "off" then P1DruidGuide_SetVisible(false)
    elseif msg == "reset" then P1DruidGuide_ResetLayout()
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

local init = CreateFrame("Frame")
init:RegisterEvent("PLAYER_LOGIN")
init:RegisterEvent("BAG_UPDATE")
init:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
init:RegisterEvent("SKILL_LINES_CHANGED")
init:RegisterEvent("QUEST_LOG_UPDATE")
init:SetScript("OnEvent", function(_, event)
    MigrateLegacyDB()
    if not panel then BuildUI() end
    if event == "PLAYER_LOGIN" then
        guideVisible = ReadGuideVisible()
        P1DruidGuide_SetVisible(guideVisible)
    else
        P1DruidGuide_Refresh()
    end
end)

init:SetScript("OnUpdate", function(_, elapsed)
    init.tick = (init.tick or 0) + elapsed
    if init.tick > 4 then
        init.tick = 0
        P1DruidGuide_Refresh()
    end
end)
