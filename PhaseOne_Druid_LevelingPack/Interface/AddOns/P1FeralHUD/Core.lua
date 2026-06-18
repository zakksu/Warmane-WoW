-- P1FeralHUD — ready on install, no import step (Warmane 3.3.5a)

P1FeralHUDB = P1FeralHUDB or { point = "CENTER", relPoint = "CENTER", x = 0, y = -100 }

local SPELL = {
    RIP = 1079,
    RAKE = 1822,
    MANGLE = 33876,
    TIGERS = 5217,
    REJUV = 774,
}

local frame
local energyBar, energyText
local cpFrames = {}
local debuffFrames = {}
local healFrame

local function HasSpell(spellId)
    local name = GetSpellInfo(spellId)
    if not name then return false end
    for i = 1, 300 do
        local n, rank = GetSpellName(i, BOOKTYPE_SPELL)
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

local function SpellOnCooldown(spellId)
    local start, duration = GetSpellCooldown(spellId)
    if not start or start == 0 then return false end
    return (start + duration - GetTime()) > 0
end

local function CreateIcon(parent, spellId, x, label)
    local btn = CreateFrame("Frame", nil, parent)
    btn:SetSize(36, 36)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -52)

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture(GetSpellTexture(spellId) or "Interface\\Icons\\INV_Misc_QuestionMark")
    btn.icon = icon

    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    border:SetBlendMode("ADD")
    border:SetSize(52, 52)
    border:SetPoint("CENTER")
    border:Hide()
    btn.glow = border

    local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    txt:SetPoint("BOTTOM", btn, "TOP", 0, 2)
    txt:SetText(label or "")
    btn.label = txt

    btn.spellId = spellId
    debuffFrames[#debuffFrames + 1] = btn
    return btn
end

local function BuildUI()
    frame = CreateFrame("Frame", "P1FeralHUDFrame", UIParent)
    frame:SetSize(220, 100)
    frame:SetPoint(P1FeralHUDB.point or "CENTER", UIParent, P1FeralHUDB.relPoint or "CENTER", P1FeralHUDB.x or 0, P1FeralHUDB.y or -100)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local p, _, rp, x, y = self:GetPoint()
        P1FeralHUDB.point, P1FeralHUDB.relPoint, P1FeralHUDB.x, P1FeralHUDB.y = p, rp, x, y
    end)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOP", frame, "TOP", 0, -2)
    title:SetText("|cff00ccffPhase One|r Feral HUD")

    energyBar = CreateFrame("StatusBar", nil, frame)
    energyBar:SetSize(180, 14)
    energyBar:SetPoint("TOP", frame, "TOP", 0, -18)
    energyBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    energyBar:SetStatusBarColor(1, 0.82, 0)
    energyBar:SetMinMaxValues(0, 100)

    local bg = energyBar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(0, 0, 0, 0.5)

    energyText = energyBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    energyText:SetPoint("CENTER")

    local cpLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    cpLabel:SetPoint("TOPLEFT", energyBar, "BOTTOMLEFT", 0, -6)
    cpLabel:SetText("CP:")

    for i = 1, 5 do
        local dot = frame:CreateTexture(nil, "ARTWORK")
        dot:SetSize(14, 14)
        dot:SetPoint("TOPLEFT", cpLabel, "TOPRIGHT", (i - 1) * 16 + 4, 2)
        dot:SetTexture("Interface\\COMMON\\Indicator-Yellow")
        dot:SetVertexColor(0.3, 0.3, 0.3)
        cpFrames[i] = dot
    end

    CreateIcon(frame, SPELL.RIP, 10, "Rip")
    CreateIcon(frame, SPELL.RAKE, 50, "Rake")
    CreateIcon(frame, SPELL.MANGLE, 90, "Mgl")
    CreateIcon(frame, SPELL.TIGERS, 130, "TF")

    healFrame = CreateFrame("Frame", nil, frame)
    healFrame:SetSize(36, 36)
    healFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 170, -52)
    local hIcon = healFrame:CreateTexture(nil, "ARTWORK")
    hIcon:SetAllPoints()
    hIcon:SetTexture(GetSpellTexture(SPELL.REJUV))
    healFrame.icon = hIcon
    local hBorder = healFrame:CreateTexture(nil, "OVERLAY")
    hBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    hBorder:SetBlendMode("ADD")
    hBorder:SetSize(52, 52)
    hBorder:SetPoint("CENTER")
    hBorder:Hide()
    healFrame.glow = hBorder
    healFrame:Hide()
end

local function Update()
    if not frame then return end

    local _, class = UnitClass("player")
    if class ~= "DRUID" then
        frame:Hide()
        return
    end
    frame:Show()

    local energy = UnitPower("player", 3)
    local maxEnergy = UnitPowerMax("player", 3) or 100
    if maxEnergy <= 0 then maxEnergy = 100 end
    energyBar:SetMinMaxValues(0, maxEnergy)
    energyBar:SetValue(energy or 0)
    energyText:SetText(string.format("%d / %d", energy or 0, maxEnergy))

    local cp = GetComboPoints("player", "target")
    if cp < 0 then cp = 0 end
    for i = 1, 5 do
        if i <= cp then
            cpFrames[i]:SetVertexColor(1, 0.85, 0.1)
        else
            cpFrames[i]:SetVertexColor(0.3, 0.3, 0.3)
        end
    end

    for _, btn in ipairs(debuffFrames) do
        if HasSpell(btn.spellId) then
            btn:Show()
            local missing = UnitExists("target") and not UnitIsDead("target") and not TargetHasDebuff(btn.spellId)
            if btn.spellId == SPELL.TIGERS then
                local ready = not SpellOnCooldown(SPELL.TIGERS)
                local lowEnergy = (UnitPower("player", 3) or 0) < 35
                btn.glow:SetShown(ready and lowEnergy)
                if ready then btn.icon:SetVertexColor(1, 1, 1) else btn.icon:SetVertexColor(0.45, 0.45, 0.45) end
            else
                btn.glow:SetShown(missing)
                btn.icon:SetVertexColor(1, 1, 1)
            end
        else
            btn:Hide()
        end
    end

    local low = UnitHealth("player") / UnitHealthMax("player") < 0.55
    local hasRejuv = false
    local rejName = GetSpellInfo(SPELL.REJUV)
    if rejName then
        for i = 1, 40 do
            local name = UnitBuff("player", i)
            if not name then break end
            if name == rejName then hasRejuv = true break end
        end
    end
    if low and not hasRejuv and HasSpell(SPELL.REJUV) then
        healFrame:Show()
        healFrame.glow:Show()
    else
        healFrame:Hide()
        healFrame.glow:Hide()
    end
end

local init = CreateFrame("Frame")
init:RegisterEvent("PLAYER_LOGIN")
init:SetScript("OnEvent", function()
    BuildUI()
    frame:SetScript("OnUpdate", function(_, elapsed)
        frame.tick = (frame.tick or 0) + elapsed
        if frame.tick > 0.1 then
            frame.tick = 0
            Update()
        end
    end)
    Update()
    print("|cff00ccffP1 Feral HUD|r loaded — drag to move. No WeakAuras import needed.")
end)

SLASH_P1HUD1 = "/p1hud"
SlashCmdList["P1HUD"] = function()
    if frame then
        if frame:IsShown() then frame:Hide() else frame:Show() end
    end
end
