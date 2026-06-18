-- P1WarlockHUD — ready on install (Warmane 3.3.5a)

P1WarlockHUDB = P1WarlockHUDB or { point = "CENTER", relPoint = "CENTER", x = 0, y = -90 }

local SPELL = {
    CORRUPTION = 172,
    IMMOLATE = 348,
    CURSE_AGONY = 980,
    HEALTHSTONE = 47875,
}

local frame
local debuffFrames = {}
local healthFrame

local function HasSpell(spellId)
    local name = GetSpellInfo(spellId)
    if not name then return false end
    for i = 1, 300 do
        local n = GetSpellName(i, BOOKTYPE_SPELL)
        if not n then break end
        if n == name then return true end
    end
    return false
end

local function TargetHasDebuff(spellId)
    if not UnitExists("target") or UnitIsDead("target") then return false end
    local want = GetSpellInfo(spellId)
    if not want then return false end
    for i = 1, 40 do
        local name = UnitDebuff("target", i)
        if not name then break end
        if name == want then return true end
    end
    return false
end

local function CreateIcon(parent, spellId, x, label)
    local btn = CreateFrame("Frame", nil, parent)
    btn:SetSize(40, 40)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -28)
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture(GetSpellTexture(spellId) or "Interface\\Icons\\INV_Misc_QuestionMark")
    btn.icon = icon
    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    border:SetBlendMode("ADD")
    border:SetSize(56, 56)
    border:SetPoint("CENTER")
    border:Hide()
    btn.glow = border
    local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    txt:SetPoint("BOTTOM", btn, "TOP", 0, 2)
    txt:SetText(label or "")
    btn.spellId = spellId
    debuffFrames[#debuffFrames + 1] = btn
    return btn
end

local function BuildUI()
    frame = CreateFrame("Frame", "P1WarlockHUDFrame", UIParent)
    frame:SetSize(200, 80)
    frame:SetPoint(P1WarlockHUDB.point or "CENTER", UIParent, P1WarlockHUDB.relPoint or "CENTER", P1WarlockHUDB.x or 0, P1WarlockHUDB.y or -90)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local p, _, rp, x, y = self:GetPoint()
        P1WarlockHUDB.point, P1WarlockHUDB.relPoint, P1WarlockHUDB.x, P1WarlockHUDB.y = p, rp, x, y
    end)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOP", frame, "TOP", 0, -2)
    title:SetText("|cff9482c9Phase One|r Warlock DoTs")

    CreateIcon(frame, SPELL.CORRUPTION, 10, "Corr")
    CreateIcon(frame, SPELL.IMMOLATE, 55, "Imm")
    CreateIcon(frame, SPELL.CURSE_AGONY, 100, "CoA")

    healthFrame = CreateFrame("Frame", nil, frame)
    healthFrame:SetSize(36, 36)
    healthFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 145, -28)
    local hIcon = healthFrame:CreateTexture(nil, "ARTWORK")
    hIcon:SetAllPoints()
    hIcon:SetTexture("Interface\\Icons\\INV_Stone_04")
    local hBorder = healthFrame:CreateTexture(nil, "OVERLAY")
    hBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    hBorder:SetBlendMode("ADD")
    hBorder:SetSize(52, 52)
    hBorder:SetPoint("CENTER")
    healthFrame.glow = hBorder
    healthFrame:Hide()
end

local function Update()
    if not frame then return end
    local _, class = UnitClass("player")
    if class ~= "WARLOCK" then
        frame:Hide()
        return
    end
    frame:Show()

    for _, btn in ipairs(debuffFrames) do
        if HasSpell(btn.spellId) then
            btn:Show()
            local missing = UnitExists("target") and not UnitIsDead("target") and not TargetHasDebuff(btn.spellId)
            btn.glow:SetShown(missing)
            btn.icon:SetVertexColor(1, 1, 1)
        else
            btn:Hide()
        end
    end

    local pct = UnitHealth("player") / UnitHealthMax("player")
    if pct < 0.45 then
        healthFrame:Show()
        healthFrame.glow:Show()
    else
        healthFrame:Hide()
        healthFrame.glow:Hide()
    end
end

local init = CreateFrame("Frame")
init:RegisterEvent("PLAYER_LOGIN")
init:SetScript("OnEvent", function()
    BuildUI()
    frame:SetScript("OnUpdate", function(_, elapsed)
        frame.tick = (frame.tick or 0) + elapsed
        if frame.tick > 0.12 then
            frame.tick = 0
            Update()
        end
    end)
    Update()
    print("|cff9482c9P1 Warlock HUD|r loaded — drag to move. Glow = apply DoT.")
end)

SLASH_P1WLOCKHUD1 = "/p1whud"
SlashCmdList["P1WLOCKHUD"] = function()
    if frame then
        if frame:IsShown() then frame:Hide() else frame:Show() end
    end
end
