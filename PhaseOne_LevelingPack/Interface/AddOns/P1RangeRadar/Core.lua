-- P1RangeRadar — 2D HUD range arc at screen bottom (Warmane 3.3.5a)

P1RangeRadarDB = P1RangeRadarDB or { enabled = true }

local UPDATE_INTERVAL = 0.08
local SEGMENTS = 19
local ARC_RADIUS = 58
local ARC_WIDTH = 120
local DOT_SIZE = 11
local BOTTOM_OFFSET = 118

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
local lastDebug = {}

local function Trim(s)
    return (s or ""):match("^%s*(.-)%s*$") or ""
end

local function GetRangeSpell()
    local _, class = UnitClass("player")
    local spells = SPELL_BY_CLASS[class] or SPELL_BY_CLASS.DRUID
    local form = GetShapeshiftForm and GetShapeshiftForm() or 0
    if form == 3 or form == 1 then
        return spells.melee, "melee"
    end
    return spells.caster, "caster"
end

local function GetRangeState(spellId, mode)
    if UnitExists("target") and not UnitIsDead("target") and UnitCanAttack("player", "target") then
        local inRange = IsSpellInRange(spellId, "target")
        if inRange == 1 then return "in", inRange end
        if mode == "melee" then return "out", inRange end
        if inRange == 0 then return "partial", inRange end
        return "unknown", inRange
    end
    return "idle", nil
end

local function GetArcColor(state)
    if state == "in" then return 0.1, 0.95, 0.15, 0.92 end
    if state == "partial" then return 0.98, 0.82, 0.05, 0.9 end
    if state == "out" then return 0.95, 0.12, 0.12, 0.9 end
    return 0.45, 0.75, 0.95, 0.65
end

local function EnsureFrame()
    if frame then return end
    frame = CreateFrame("Frame", "P1RangeRadarFrame", UIParent)
    frame:SetFrameStrata("TOOLTIP")
    frame:SetFrameLevel(90)
    frame:SetSize(ARC_WIDTH + 20, ARC_RADIUS + DOT_SIZE + 8)
    frame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, BOTTOM_OFFSET)
    frame:Show()

    for i = 1, SEGMENTS do
        local seg = frame:CreateTexture(nil, "OVERLAY")
        seg:SetTexture("Interface\\Buttons\\WHITE8X8")
        seg:SetSize(DOT_SIZE, DOT_SIZE)
        seg:Hide()
        segments[i] = seg
    end
end

local function UpdateArc()
    if not enabled then
        for _, seg in ipairs(segments) do seg:Hide() end
        if frame then frame:Hide() end
        return
    end
    EnsureFrame()
    frame:Show()

    local spellId, mode = GetRangeSpell()
    local state = GetRangeState(spellId, mode)
    local r, g, b, a = GetArcColor(state)
    lastDebug = {
        enabled = enabled,
        spellId = spellId,
        mode = mode,
        state = state,
        target = UnitExists("target") and UnitName("target") or nil,
    }

    local spread = math.pi
    local base = math.pi / 2
    for i, seg in ipairs(segments) do
        local t = (i - 1) / (SEGMENTS - 1)
        local angle = base + spread * t
        local x = math.cos(angle) * ARC_RADIUS + (ARC_WIDTH + 20) / 2
        local y = math.sin(angle) * ARC_RADIUS + DOT_SIZE / 2
        seg:SetVertexColor(r, g, b, a)
        seg:ClearAllPoints()
        seg:SetPoint("CENTER", frame, "BOTTOMLEFT", x, y)
        seg:Show()
    end
end

function P1RangeRadar_SetEnabled(on)
    enabled = on and true or false
    P1RangeRadarDB.enabled = enabled
    EnsureFrame()
    UpdateArc()
end

function P1RangeRadar_DebugPrint()
    local spellId, mode = GetRangeSpell()
    local state, raw = GetRangeState(spellId, mode)
    local spellName = GetSpellInfo and GetSpellInfo(spellId) or tostring(spellId)
    print("|cff00ccffP1 Range|r v1.2.4 debug")
    print("  enabled: " .. (enabled and "|cff00ff00yes|r" or "|cffff4444no|r"))
    print("  mode: " .. mode .. "  spell: " .. (spellName or "?") .. " (" .. spellId .. ")")
    print("  target: " .. (UnitExists("target") and (UnitName("target") or "?") or "|cff888888none|r"))
    print("  range: " .. state .. (raw ~= nil and ("  IsSpellInRange=" .. tostring(raw)) or "  (no hostile target)"))
    print("  frame: " .. (frame and frame:IsShown() and "|cff00ff00visible|r" or "|cffff4444hidden|r")
        .. "  segments: " .. SEGMENTS .. "  offset: " .. BOTTOM_OFFSET .. "px")
end

local tick = CreateFrame("Frame")
tick:SetScript("OnUpdate", function(_, elapsed)
    lastUpdate = lastUpdate + elapsed
    if lastUpdate < UPDATE_INTERVAL then return end
    lastUpdate = 0
    if not enabled then return end
    UpdateArc()
end)

local login = CreateFrame("Frame")
login:RegisterEvent("PLAYER_LOGIN")
login:SetScript("OnEvent", function()
    enabled = P1RangeRadarDB.enabled ~= false
    EnsureFrame()
    UpdateArc()
end)

SLASH_P1RANGE1 = "/p1range"
SlashCmdList["P1RANGE"] = function(msg)
    msg = string.lower(Trim(msg))
    if msg == "debug" then
        P1RangeRadar_DebugPrint()
        return
    end
    if msg == "on" or msg == "off" then
        P1RangeRadar_SetEnabled(msg == "on")
    elseif msg == "" then
        P1RangeRadar_SetEnabled(not enabled)
    end
    print("|cff00ccffP1 Range|r v1.2.4 — " .. (enabled and "|cff00ff00ON|r" or "|cffaaaaaaOFF|r"))
    print("  /p1range debug — spell, target, range state")
    print("  Arc: |cff00ff00green|r in · |cffffee00yellow|r spell out · |cffff3333red|r melee out · |cff66bbffblue|r idle")
end
