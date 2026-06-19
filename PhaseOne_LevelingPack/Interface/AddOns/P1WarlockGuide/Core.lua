-- P1 Warlock Guide — minimal PATH overlay (scaffold)

P1WarlockGuideDB = P1WarlockGuideDB or {
    point = "TOPLEFT", relPoint = "TOPLEFT", x = 12, y = -120,
    width = 260, height = 160, scale = 1.0, minimized = false,
}

local DB = P1WarlockGuideDB
local VERSION = "1.6.0"
local panel, bodyText, minimizeBtn

local function IsWarlock()
    local _, class = UnitClass("player")
    return class == "WARLOCK"
end

local function BuildBody()
    if not bodyText then return end
    local lvl = UnitLevel("player")
    local lines = { "|cff9933ffWARLOCK PATH|r |cff666666(drag title)|r", "" }
    local steps = P1WG.GetOptimalSteps and P1WG.GetOptimalSteps(lvl, 6) or {}
    if #steps == 0 then
        table.insert(lines, "  |cff888888On track — grind on|r")
    else
        for _, step in ipairs(steps) do
            table.insert(lines, string.format("  • %s", step.text or "?"))
        end
    end
    table.insert(lines, "")
    table.insert(lines, "|cff666666/p1wguide — toggle · full guide coming|r")
    bodyText:SetText(table.concat(lines, "\n"))
end

local function SetMinimized(on)
    DB.minimized = on and true or false
    if not panel then return end
    if DB.minimized then
        if bodyText then bodyText:Hide() end
        panel:SetHeight(28)
    else
        if bodyText then bodyText:Show() end
        panel:SetHeight(DB.height or 160)
        BuildBody()
    end
end

local function BuildUI()
    panel = CreateFrame("Frame", "P1WarlockGuideFrame", UIParent)
    panel:SetSize(DB.width or 260, DB.height or 160)
    panel:SetPoint(DB.point or "TOPLEFT", UIParent, DB.relPoint or "TOPLEFT", DB.x or 12, DB.y or -120)
    panel:SetScale(DB.scale or 1.0)
    panel:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 10,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    panel:SetBackdropColor(0.06, 0.02, 0.08, 0.85)
    panel:SetBackdropBorderColor(0.5, 0.2, 0.7, 0.8)
    panel:SetMovable(true)
    panel:SetClampedToScreen(true)

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

    minimizeBtn = CreateFrame("Button", nil, titleBar)
    minimizeBtn:SetSize(16, 16)
    minimizeBtn:SetPoint("TOPRIGHT", titleBar, "TOPRIGHT", -2, -1)
    minimizeBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    minimizeBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    minimizeBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    minimizeBtn:SetScript("OnClick", function() SetMinimized(not DB.minimized) end)

    bodyText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bodyText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    bodyText:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -24)
    bodyText:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -8, 8)
    bodyText:SetJustifyH("LEFT")
    bodyText:SetWordWrap(true)
end

function P1WarlockGuide_SetVisible(show)
    if not panel then BuildUI() end
    if show then panel:Show() else panel:Hide() end
    BuildBody()
end

SLASH_P1WGUIDE1 = "/p1wguide"
SlashCmdList["P1WGUIDE"] = function()
    if not panel then BuildUI() end
    if panel:IsShown() then panel:Hide() else panel:Show() end
    BuildBody()
    print("|cff9933ffP1 Warlock Guide|r v" .. VERSION)
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    if not IsWarlock() then return end
    if not panel then BuildUI() end
    panel:Show()
    if DB.minimized then SetMinimized(true) end
    BuildBody()
end)

f:SetScript("OnUpdate", function(_, elapsed)
    f.tick = (f.tick or 0) + elapsed
    if f.tick > 5 then
        f.tick = 0
        if panel and panel:IsShown() then BuildBody() end
    end
end)
