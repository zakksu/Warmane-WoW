-- P1 Adventure Guide — crafting mats only (quest pack)

P1AdventureGuideDB = P1AdventureGuideDB or {
    point = "TOPLEFT", relPoint = "TOPLEFT", x = 12, y = -120,
}

local DB = P1AdventureGuideDB
local panel, content

local function GetBagItemId(bag, slot)
    local link = GetContainerItemLink(bag, slot)
    if not link then return nil end
    return tonumber(link:match("item:(%d+)"))
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

local function ColorCount(have, goal)
    if have >= goal then return "|cff00ff00" .. have .. "/" .. goal .. "|r" end
    if have >= goal * 0.5 then return "|cffffff00" .. have .. "/" .. goal .. "|r" end
    return "|cffff4444" .. have .. "/" .. goal .. "|r"
end

local function LevelHint(needBy, playerLevel)
    if not needBy then return "" end
    if playerLevel >= needBy then
        return " |cffff8800(need by lvl " .. needBy .. " — stock up!)|r"
    end
    if playerLevel >= needBy - 3 then
        return " |cffffff00(soon — lvl " .. needBy .. ")|r"
    end
    return " |cff888888(by lvl " .. needBy .. ")|r"
end

local function BuildMatsContent()
    if not content or not content.text then return end
    local lvl = UnitLevel("player")
    local lines = { "|cff00ccffCRAFTING MATS|r |cff888888(/p1guide to hide)|r" }

    local rows = {}
    for itemId, info in pairs(P1AG.MAT_WATCH) do
        rows[#rows + 1] = { id = itemId, info = info }
    end
    table.sort(rows, function(a, b)
        local la = a.info[4] or 99
        local lb = b.info[4] or 99
        if la ~= lb then return la < lb end
        return (a.info[1] or "") < (b.info[1] or "")
    end)

    for _, row in ipairs(rows) do
        local info = row.info
        local have = CountItemInBags(row.id)
        local name, goal, hint, needBy = info[1], info[2], info[3], info[4]
        table.insert(lines, ColorCount(have, goal) .. " " .. name .. LevelHint(needBy, lvl))
        if hint and hint ~= "" then
            table.insert(lines, "  |cff666666" .. hint .. "|r")
        end
    end

    content.text:SetText(table.concat(lines, "\n"))
end

local function BuildUI()
    panel = CreateFrame("Frame", "P1AdventureGuideFrame", UIParent)
    panel:SetSize(260, 150)
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

    content = CreateFrame("Frame", nil, panel)
    content:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -8)
    content:SetSize(244, 130)

    content.text = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    content.text:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    content.text:SetWidth(240)
    content.text:SetJustifyH("LEFT")
    content.text:SetNonSpaceWrap(true)

    BuildMatsContent()
end

local init = CreateFrame("Frame")
init:RegisterEvent("PLAYER_LOGIN")
init:RegisterEvent("BAG_UPDATE")
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
