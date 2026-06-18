-- P1RangeDisplay — target distance number HUD (Warmane 3.3.5a)

P1RangeDisplayDB = P1RangeDisplayDB or { enabled = true }

local VERSION = "1.2.7"
local UPDATE_INTERVAL = 0.1
local BOTTOM_Y = 140

local SPELL_BY_CLASS = {
    DRUID = { caster = 5176, melee = 33876, casterRange = 30, meleeRange = 5 },
    WARLOCK = { caster = 686, melee = 686, casterRange = 30, meleeRange = 5 },
    WARRIOR = { caster = 100, melee = 772, casterRange = 25, meleeRange = 5 },
    PALADIN = { caster = 635, melee = 35395, casterRange = 40, meleeRange = 5 },
    HUNTER = { caster = 75, melee = 75, casterRange = 35, meleeRange = 5 },
    MAGE = { caster = 133, melee = 133, casterRange = 30, meleeRange = 5 },
    PRIEST = { caster = 585, melee = 585, casterRange = 30, meleeRange = 5 },
    ROGUE = { caster = 1752, melee = 1752, casterRange = 5, meleeRange = 5 },
    SHAMAN = { caster = 403, melee = 403, casterRange = 30, meleeRange = 5 },
    DEATHKNIGHT = { caster = 47541, melee = 45477, casterRange = 30, meleeRange = 5 },
}

local function SyncLoaderRange(on)
    if PhaseOneLoaderDB then PhaseOneLoaderDB.rangeEnabled = on end
    if PhaseOneDruidLoaderDB then PhaseOneDruidLoaderDB.rangeEnabled = on end
end

local function ReadRangeEnabled()
    if PhaseOneLoaderDB and PhaseOneLoaderDB.rangeEnabled ~= nil then
        return PhaseOneLoaderDB.rangeEnabled
    end
    if PhaseOneDruidLoaderDB and PhaseOneDruidLoaderDB.rangeEnabled ~= nil then
        return PhaseOneDruidLoaderDB.rangeEnabled
    end
    if P1RangeRadarDB and P1RangeRadarDB.enabled ~= nil then
        return P1RangeRadarDB.enabled
    end
    return P1RangeDisplayDB.enabled ~= false
end

local enabled = ReadRangeEnabled()
local frame, distText
local lastUpdate = 0

local function Trim(s)
    return (s or ""):match("^%s*(.-)%s*$") or ""
end

local function GetRangeSpell()
    local _, class = UnitClass("player")
    local spells = SPELL_BY_CLASS[class] or SPELL_BY_CLASS.DRUID
    local form = GetShapeshiftForm and GetShapeshiftForm() or 0
    if form == 3 or form == 1 then
        return spells.melee, "melee", spells.meleeRange
    end
    return spells.caster, "caster", spells.casterRange
end

local function EstimateYards()
    if not UnitExists("target") or UnitIsDead("target") then return nil end
    if CheckInteractDistance("target", 3) then return 5 end
    if CheckInteractDistance("target", 2) then return 10 end
    if CheckInteractDistance("target", 4) then return 28 end
    return 38
end

local function GetDisplayState()
    if not UnitExists("target") then
        return "idle", nil, nil, nil
    end
    if UnitIsDead("target") then
        return "dead", nil, "—", 0.5, 0.5, 0.5
    end
    if not UnitCanAttack("player", "target") and not UnitIsFriend("player", "target") then
        return "neutral", EstimateYards(), nil, 0.7, 0.85, 1.0
    end

    local spellId, mode, maxRange = GetRangeSpell()
    local yards = EstimateYards()
    local inRange = IsSpellInRange(spellId, "target")

    if inRange == 1 then
        return "in", maxRange, string.format("%d yd ✓", maxRange), 0.1, 0.95, 0.15
    end
    if inRange == 0 then
        local yd = yards or 38
        return "out", yd, string.format("%d yd", yd), 0.95, 0.12, 0.12
    end
    if mode == "melee" and yards and yards <= 5 then
        return "in", 5, "5 yd ✓", 0.1, 0.95, 0.15
    end
    if yards then
        local r, g, b = 0.98, 0.82, 0.05
        if yards >= maxRange then r, g, b = 0.95, 0.12, 0.12 end
        return "partial", yards, string.format("%d yd", yards), r, g, b
    end
    return "unknown", nil, "?", 0.45, 0.75, 0.95
end

local function EnsureFrame()
    if frame then return end

    frame = CreateFrame("Frame", "P1RangeDisplayFrame", UIParent)
    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel(120)
    frame:SetSize(120, 28)
    frame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, BOTTOM_Y)
    frame:EnableMouse(false)

    distText = frame:CreateFontString(nil, "OVERLAY")
    distText:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
    distText:SetPoint("CENTER", frame, "CENTER", 0, 0)
    distText:SetText("[ — ]")
end

local function UpdateDisplay()
    EnsureFrame()
    if not enabled then
        frame:Hide()
        return
    end
    frame:Show()

    local state, _, label, r, g, b = GetDisplayState()
    if state == "idle" then
        distText:SetText("[ — ]")
        distText:SetTextColor(0.45, 0.75, 0.95, 0.85)
    elseif state == "dead" then
        distText:SetText("[ dead ]")
        distText:SetTextColor(0.5, 0.5, 0.5, 0.85)
    else
        distText:SetText("[ " .. (label or "?") .. " ]")
        distText:SetTextColor(r or 1, g or 1, b or 1, 1)
    end
end

function P1RangeDisplay_SetEnabled(on)
    enabled = on and true or false
    P1RangeDisplayDB.enabled = enabled
    SyncLoaderRange(enabled)
    EnsureFrame()
    UpdateDisplay()
end

P1RangeRadar_SetEnabled = P1RangeDisplay_SetEnabled

function P1RangeDisplay_DebugPrint()
    local spellId, mode, maxRange = GetRangeSpell()
    local state, yards, label = GetDisplayState()
    local raw = UnitExists("target") and IsSpellInRange(spellId, "target") or nil
    local spellName = GetSpellInfo and GetSpellInfo(spellId) or tostring(spellId)
    print("|cff00ccffP1 Range|r v" .. VERSION .. " debug")
    print("  enabled: " .. (enabled and "|cff00ff00yes|r" or "|cffff4444no|r"))
    print("  mode: " .. mode .. "  spell: " .. (spellName or "?") .. " (" .. spellId .. ") max " .. maxRange .. "yd")
    print("  target: " .. (UnitExists("target") and (UnitName("target") or "?") or "|cff888888none|r"))
    print("  state: " .. state .. "  display: " .. (label or "—") .. (raw ~= nil and ("  IsSpellInRange=" .. tostring(raw)) or ""))
    print("  interact: d3=" .. tostring(CheckInteractDistance("target", 3))
        .. " d2=" .. tostring(CheckInteractDistance("target", 2))
        .. " d4=" .. tostring(CheckInteractDistance("target", 4)))
    print("  frame: " .. (frame and frame:IsShown() and "|cff00ff00visible|r" or "|cffff4444hidden|r")
        .. "  offsetY: " .. BOTTOM_Y)
end

local tick = CreateFrame("Frame")
tick:SetScript("OnUpdate", function(_, elapsed)
    lastUpdate = lastUpdate + elapsed
    if lastUpdate < UPDATE_INTERVAL then return end
    lastUpdate = 0
    if enabled then UpdateDisplay() end
end)

local login = CreateFrame("Frame")
login:RegisterEvent("PLAYER_LOGIN")
login:RegisterEvent("PLAYER_TARGET_CHANGED")
login:SetScript("OnEvent", function()
    if P1RangeRadarDB and P1RangeDisplayDB.enabled == nil then
        P1RangeDisplayDB.enabled = P1RangeRadarDB.enabled
    end
    enabled = ReadRangeEnabled()
    P1RangeDisplayDB.enabled = enabled
    UpdateDisplay()
end)

SLASH_P1RANGE1 = "/p1range"
SlashCmdList["P1RANGE"] = function(msg)
    msg = string.lower(Trim(msg))
    if msg == "debug" then
        P1RangeDisplay_DebugPrint()
        return
    end
    if msg == "on" or msg == "off" then
        P1RangeDisplay_SetEnabled(msg == "on")
    elseif msg == "" then
        P1RangeDisplay_SetEnabled(not enabled)
    end
    print("|cff00ccffP1 Range|r v" .. VERSION .. " — " .. (enabled and "|cff00ff00ON|r" or "|cffaaaaaaOFF|r"))
    print("  Distance number above action bars · /p1range debug")
    print("  |cff00ff00green|r in range · |cffff3333red|r out · |cffffee00yellow|r partial")
end
