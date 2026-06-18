-- P1 Adventure Guide — next action, profs, mats, rares

P1AdventureGuideDB = P1AdventureGuideDB or {
    expanded = false,
    tab = 1,
    point = "TOP", relPoint = "BOTTOM", x = 0, y = -8,
}

local DB = P1AdventureGuideDB
local panel, content, nextText, tabButtons = {}, {}
local TAB_NAMES = { "Next", "Profs", "Mats", "Rare" }

local function GetBagItemId(bag, slot)
    local link = GetContainerItemLink(bag, slot)
    if not link then return nil end
    local id = tonumber(link:match("item:(%d+)"))
    return id
end

local function CountItemInBags(itemId)
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

local function GetProfessions()
    local list = {}
    for i = 1, GetNumSkillLines() do
        local name, isHeader, _, rank, _, _, maxRank = GetSkillLineInfo(i)
        if name and not isHeader and maxRank and maxRank > 0 and name ~= "Weapon Skills" and name ~= "Armor Skills" then
            if not name:find("Languages") and name ~= "Riding" then
                list[#list + 1] = { name = name, rank = rank or 0, max = maxRank or 0 }
            end
        end
    end
    return list
end

local function GetNextAction()
    local lvl = UnitLevel("player")
    local best, bestLvl = "Quest nearby objectives (Questie) — biggest XP gain.", 0
    for _, row in ipairs(P1AG.LEVEL_ACTIONS) do
        if lvl >= row.lvl and row.lvl >= bestLvl then
            best, bestLvl = row.text, row.lvl
        end
    end

    local zone = GetRealZoneText()
    if zone and P1AG.ZONE_RARES[zone] then
        best = best .. " |cffaaaaaa(See Rare tab for " .. zone .. ")|r"
    end

    local profs = GetProfessions()
    if #profs == 0 and lvl >= 8 then
        best = "|cffffcc00Pick up a gathering profession|r — " .. best
    elseif #profs > 0 then
        for _, p in ipairs(profs) do
            if p.rank < 75 and lvl >= 12 then
                best = "Train " .. p.name .. " Journeyman soon (" .. p.rank .. "/75) — " .. best
                break
            end
        end
    end
    return best
end

local function ColorCount(have, goal)
    if have >= goal then return "|cff00ff00" .. have .. "/" .. goal .. "|r" end
    if have >= goal * 0.5 then return "|cffffff00" .. have .. "/" .. goal .. "|r" end
    return "|cffff4444" .. have .. "/" .. goal .. "|r"
end

local function BuildTabContent()
    if not content.text then return end
    local tab = DB.tab
    local lines = {}

    if tab == 1 then
        content.text:SetText("|cff00ccffNEXT ACTION|r\n" .. GetNextAction())
        return
    end

    if tab == 2 then
        table.insert(lines, "|cff00ccffPROFESSIONS|r")
        local profs = GetProfessions()
        if #profs == 0 then
            table.insert(lines, "None yet — visit a trainer in your starter zone.")
            table.insert(lines, "|cffaaaaaaRecommended: Skinning + Herbalism|r")
        else
            for _, p in ipairs(profs) do
                local tip = P1AG.PROF_TIPS[p.name] or ""
                table.insert(lines, p.name .. ": " .. p.rank .. "/" .. p.max .. (tip ~= "" and " — " .. tip or ""))
            end
        end
        content.text:SetText(table.concat(lines, "\n"))
        return
    end

    if tab == 3 then
        table.insert(lines, "|cff00ccffCRAFTING MATS|r (bags)")
        for itemId, info in pairs(P1AG.MAT_WATCH) do
            local have = CountItemInBags(itemId)
            local name, goal, hint = info[1], info[2], info[3]
            table.insert(lines, ColorCount(have, goal) .. " " .. name .. " |cff888888(" .. hint .. ")|r")
        end
        content.text:SetText(table.concat(lines, "\n"))
        return
    end

    if tab == 4 then
        table.insert(lines, "|cff00ccffRARE MOBS|r — zone tips")
        local zone = GetRealZoneText() or "Unknown"
        table.insert(lines, "|cffffff00" .. zone .. "|r")
        table.insert(lines, P1AG.ZONE_RARES[zone] or "No rares cataloged — check wowhead for this zone.")
        table.insert(lines, "")
        table.insert(lines, "|cffaaaaaaOther zones:|r")
        local n = 0
        for z, tip in pairs(P1AG.ZONE_RARES) do
            if z ~= zone and n < 3 then
                table.insert(lines, z .. ": " .. tip:sub(1, 50) .. "...")
                n = n + 1
            end
        end
        content.text:SetText(table.concat(lines, "\n"))
    end
end

local function SetTab(idx)
    DB.tab = idx
    for i, btn in ipairs(tabButtons) do
        if i == idx then
            btn.text:SetText("|cff00ccff" .. TAB_NAMES[i] .. "|r")
        else
            btn.text:SetText("|cff888888" .. TAB_NAMES[i] .. "|r")
        end
    end
    BuildTabContent()
end

local function ToggleExpand()
    DB.expanded = not DB.expanded
    if DB.expanded then
        panel:SetHeight(200)
        content:Show()
        panel.expandBtn:SetText("-")
    else
        panel:SetHeight(52)
        content:Hide()
        panel.expandBtn:SetText("+")
        nextText:SetText("|cff00ccffNEXT:|r " .. GetNextAction():sub(1, 55) .. "...")
    end
end

local function AnchorToCombatHUD()
    local hud = _G.P1FeralHUDFrame or _G.P1WarlockHUDFrame
    if hud then
        panel:ClearAllPoints()
        panel:SetPoint("TOP", hud, "BOTTOM", DB.x or 0, DB.y or -8)
    end
end

local function BuildUI()
    panel = CreateFrame("Frame", "P1AdventureGuideFrame", UIParent)
    panel:SetSize(280, DB.expanded and 200 or 52)
    panel:SetPoint(DB.point or "CENTER", UIParent, DB.relPoint or "CENTER", 0, -200)
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

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -8)
    title:SetText("|cff00ccffAdventure Guide|r")

    panel.expandBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    panel.expandBtn:SetSize(22, 18)
    panel.expandBtn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -8, -6)
    panel.expandBtn:SetText(DB.expanded and "-" or "+")
    panel.expandBtn:SetScript("OnClick", ToggleExpand)

    nextText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    nextText:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    nextText:SetWidth(250)
    nextText:SetJustifyH("LEFT")
    nextText:SetText("|cff00ccffNEXT:|r loading...")

    content = CreateFrame("Frame", nil, panel)
    content:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -48)
    content:SetSize(264, 140)

    local tabRow = CreateFrame("Frame", nil, content)
    tabRow:SetSize(264, 20)
    tabRow:SetPoint("TOP", content, "TOP", 0, 0)
    for i, name in ipairs(TAB_NAMES) do
        local btn = CreateFrame("Button", nil, tabRow)
        btn:SetSize(60, 18)
        btn:SetPoint("LEFT", tabRow, "LEFT", (i - 1) * 62, 0)
        local t = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        t:SetAllPoints()
        t:SetText(name)
        btn.text = t
        btn:SetScript("OnClick", function() SetTab(i) end)
        tabButtons[i] = btn
    end

    content.text = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    content.text:SetPoint("TOPLEFT", tabRow, "BOTTOMLEFT", 0, -6)
    content.text:SetWidth(250)
    content.text:SetJustifyH("LEFT")
    content.text:SetNonSpaceWrap(true)

    if not DB.expanded then content:Hide() end
    SetTab(DB.tab or 1)
    AnchorToCombatHUD()
end

local function Update()
    if not panel then return end
    if DB.expanded then
        BuildTabContent()
    else
        local action = GetNextAction()
        if #action > 58 then action = action:sub(1, 55) .. "..." end
        nextText:SetText("|cff00ccffNEXT:|r " .. action)
    end
    AnchorToCombatHUD()
end

local init = CreateFrame("Frame")
init:RegisterEvent("PLAYER_LOGIN")
init:RegisterEvent("ZONE_CHANGED_NEW_AREA")
init:SetScript("OnEvent", function()
    if not panel then BuildUI() end
    Update()
end)

init:SetScript("OnUpdate", function(_, elapsed)
    init.tick = (init.tick or 0) + elapsed
    if init.tick > 2 then
        init.tick = 0
        Update()
    end
end)

SLASH_P1GUIDE1 = "/p1guide"
SlashCmdList["P1GUIDE"] = function()
    if panel then
        if panel:IsShown() then panel:Hide() else panel:Show() end
    end
end
