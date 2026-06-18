-- P1RangeRadar — melee/spell range arc HUD (Warmane 3.3.5a)

P1RangeRadarDB = P1RangeRadarDB or { enabled = true }

local UPDATE_INTERVAL = 0.1
local SEGMENTS = 13
local ARC_RADIUS = 70
local ARC_Y = -72

local SPELL_BY_CLASS = {
    DRUID = { caster = 5176, melee = 33876 },
    WARLOCK = { caster = 686, melee = 686 },
    WARRIOR = { caster = 100, melee = 772 },
    PALADIN = { caster = 635, melee = 35395 },
    HUNTER = { caster = 75, melee = 75 },
    MAGE = { caster = 133, melee = 133 },
    PRIEST = { caster = 585, melee = 585 },
    ROGUE = { caster = 1752, melee = 1752 },
    SHAMAN = { caster = 403, melee = 403 },
    DEATHKNIGHT = { caster = 47541, melee = 45477 },
}

local enabled = P1RangeRadarDB.enabled ~= false
local segments = {}
local frame
local lastUpdate = 0

local function GetRangeSpell()
    local _, class = UnitClass("player")
    local spells = SPELL_BY_CLASS[class] or SPELL_BY_CLASS.DRUID
    local form = GetShapeshiftForm and GetShapeshiftForm() or 0
    if form == 3 or form == 1 then
        return spells.melee, "melee"
    end
    return spells.caster, "caster"
end

local function GetArcColor(spellId, mode)
    if not UnitExists("target") or UnitIsDead("target") or not UnitCanAttack("player", "target") then
        return 0.55, 0.55, 0.55, 0.35
    end
    if mode == "melee" then
        local inRange = IsSpellInRange(spellId, "target")
        if inRange == 1 then return 0.15, 0.95, 0.2, 0.75 end
        return 0.95, 0.15, 0.15, 0.7
    end
    local inRange = IsSpellInRange(spellId, "target")
    if inRange == 1 then return 0.15, 0.95, 0.2, 0.75 end
    if inRange == 0 then return 0.95, 0.85, 0.1, 0.7 end
    return 0.55, 0.55, 0.55, 0.35
end

local function EnsureFrame()
    if frame then return end
    frame = CreateFrame("Frame", "P1RangeRadarFrame", UIParent)
    frame:SetFrameStrata("LOW")
    frame:SetAllPoints()
    for i = 1, SEGMENTS do
        local seg = frame:CreateTexture(nil, "ARTWORK")
        seg:SetTexture("Interface\\Buttons\\WHITE8X8")
        seg:SetSize(5, 22)
        seg:Hide()
        segments[i] = seg
    end
end

local function UpdateArc()
    if not enabled then
        for _, seg in ipairs(segments) do seg:Hide() end
        return
    end
    local spellId, mode = GetRangeSpell()
    local r, g, b, a = GetArcColor(spellId, mode)
    local spread = math.pi
    local base = -math.pi / 2
    for i, seg in ipairs(segments) do
        local t = (i - 1) / (SEGMENTS - 1)
        local angle = base - spread / 2 + spread * t
        local x = math.cos(angle) * ARC_RADIUS
        local y = math.sin(angle) * ARC_RADIUS + ARC_Y
        seg:SetVertexColor(r, g, b, a)
        seg:ClearAllPoints()
        seg:SetPoint("CENTER", UIParent, "CENTER", x, y)
        if seg.SetRotation then
            seg:SetRotation(angle + math.pi / 2)
        end
        seg:Show()
    end
end

function P1RangeRadar_SetEnabled(on)
    enabled = on and true or false
    P1RangeRadarDB.enabled = enabled
    EnsureFrame()
    if not enabled then
        for _, seg in ipairs(segments) do seg:Hide() end
    else
        UpdateArc()
    end
end

local tick = CreateFrame("Frame")
tick:SetScript("OnUpdate", function(_, elapsed)
    lastUpdate = lastUpdate + elapsed
    if lastUpdate < UPDATE_INTERVAL then return end
    lastUpdate = 0
    if not enabled then return end
    EnsureFrame()
    UpdateArc()
end)

local login = CreateFrame("Frame")
login:RegisterEvent("PLAYER_LOGIN")
login:SetScript("OnEvent", function()
    enabled = P1RangeRadarDB.enabled ~= false
    EnsureFrame()
end)

SLASH_P1RANGE1 = "/p1range"
SlashCmdList["P1RANGE"] = function(msg)
    msg = string.lower(strtrim and strtrim(msg) or (msg or ""):match("^%s*(.-)%s*$") or "")
    if msg == "on" or msg == "off" then
        P1RangeRadar_SetEnabled(msg == "on")
    else
        P1RangeRadar_SetEnabled(not enabled)
    end
    print("|cff00ccffP1 Range|r v1.2.3 — " .. (enabled and "|cff00ff00ON|r" or "|cffaaaaaaOFF|r"))
    print("  Arc: |cff00ff00green|r in range · |cffffee00yellow|r spell out · |cffff3333red|r melee out")
end
