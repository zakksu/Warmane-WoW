-- P1RangeRadar — bulletproof HUD range bar (Warmane 3.3.5a)

P1RangeRadarDB = P1RangeRadarDB or { enabled = true }

local VERSION = "1.2.6"

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
    return P1RangeRadarDB.enabled ~= false
end

local enabled = ReadRangeEnabled()
local BAR_W, BAR_H = 200, 40
local BOTTOM_Y = 120
local UPDATE_INTERVAL = 0.08
local SEGMENTS = 11
local ARC_CHARS = 11

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

local TEX_BAR = "Interface\\TargetingFrame\\UI-StatusBar"
local TEX_BORDER = "Interface\\Buttons\\UI-ActionButton-Border"
local TEX_DOT = "Interface\\Icons\\Ability_Druid_Mangle2"

local testMode = false
local testStart = 0
local splashUntil = 0

local frame, bgBar, borderTex, splashText, arcText
local segTextures = {}
local lastUpdate = 0

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
    if state == "in" then return 0.1, 0.95, 0.15 end
    if state == "partial" then return 0.98, 0.82, 0.05 end
    if state == "out" then return 0.95, 0.12, 0.12 end
    return 0.45, 0.75, 0.95
end

local function GetTestState(elapsed)
    local phase = math.floor(elapsed) % 3
    if phase == 0 then return "out" end
    if phase == 1 then return "in" end
    return "partial"
end

local function BuildArcString()
    local mid = math.floor(ARC_CHARS / 2) + 1
    local parts = { "[" }
    for i = 1, ARC_CHARS do
        if i > 1 then parts[#parts + 1] = "" end
        parts[#parts + 1] = (i == mid) and "●" or "="
    end
    parts[#parts + 1] = "]"
    return table.concat(parts)
end

local function EnsureFrame()
    if frame then return end

    frame = CreateFrame("Frame", "P1RangeRadarFrame", UIParent)
    frame:SetFrameStrata("TOOLTIP")
    frame:SetFrameLevel(200)
    frame:SetSize(BAR_W, BAR_H)
    frame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, BOTTOM_Y)
    frame:EnableMouse(false)
    frame:Show()

    bgBar = frame:CreateTexture(nil, "BACKGROUND")
    bgBar:SetTexture(TEX_BAR)
    bgBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 4, 6)
    bgBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 6)
    bgBar:SetHeight(14)
    bgBar:SetVertexColor(0.08, 0.08, 0.12, 0.95)

    borderTex = frame:CreateTexture(nil, "BORDER")
    borderTex:SetTexture(TEX_BORDER)
    borderTex:SetPoint("TOPLEFT", frame, "TOPLEFT", -2, 2)
    borderTex:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 2, -2)
    borderTex:SetVertexColor(0.35, 0.65, 0.9, 0.85)

    for i = 1, SEGMENTS do
        local seg = frame:CreateTexture(nil, "ARTWORK")
        seg:SetTexture(TEX_DOT)
        seg:SetSize(10, 10)
        seg:Hide()
        segTextures[i] = seg
    end

    arcText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    arcText:SetPoint("CENTER", frame, "CENTER", 0, 2)
    arcText:SetText(BuildArcString())

    splashText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    splashText:SetPoint("CENTER", frame, "CENTER", 0, 0)
    splashText:Hide()
end

local function UpdateArc()
    EnsureFrame()

    if not enabled then
        frame:Hide()
        return
    end

    frame:Show()

    local now = GetTime()
    if splashUntil > now then
        splashText:SetText("|cff00ff00P1 Range loaded|r")
        splashText:Show()
        arcText:Hide()
        for _, seg in ipairs(segTextures) do seg:Hide() end
        bgBar:SetVertexColor(0.1, 0.45, 0.15, 0.95)
        return
    end
    splashText:Hide()
    arcText:Show()

    local state
    if testMode then
        local elapsed = now - testStart
        if elapsed >= 3 then
            testMode = false
            local spellId, mode = GetRangeSpell()
            state = GetRangeState(spellId, mode)
        else
            state = GetTestState(elapsed)
        end
    else
        local spellId, mode = GetRangeSpell()
        state = GetRangeState(spellId, mode)
    end

    local r, g, b = GetArcColor(state)
    arcText:SetTextColor(r, g, b, 1)
    arcText:SetText(BuildArcString())
    bgBar:SetVertexColor(r * 0.25, g * 0.25, b * 0.25, 0.92)
    borderTex:SetVertexColor(r, g, b, 0.9)

    local spread = math.pi * 0.85
    local base = math.pi / 2
    local cx = BAR_W / 2
    local cy = 10
    local radius = 52
    for i, seg in ipairs(segTextures) do
        local t = (i - 1) / (SEGMENTS - 1)
        local angle = base + spread * (t - 0.5)
        local x = cx + math.cos(angle) * radius
        local y = cy + math.sin(angle) * radius * 0.55
        seg:ClearAllPoints()
        seg:SetPoint("CENTER", frame, "BOTTOMLEFT", x, y)
        seg:SetVertexColor(r, g, b, 0.95)
        seg:Show()
    end
end

function P1RangeRadar_SetEnabled(on)
    enabled = on and true or false
    P1RangeRadarDB.enabled = enabled
    SyncLoaderRange(enabled)
    EnsureFrame()
    if enabled then frame:Show() end
    UpdateArc()
end

function P1RangeRadar_DebugPrint()
    local spellId, mode = GetRangeSpell()
    local state, raw = GetRangeState(spellId, mode)
    local spellName = GetSpellInfo and GetSpellInfo(spellId) or tostring(spellId)
    print("|cff00ccffP1 Range|r v" .. VERSION .. " debug")
    print("  enabled: " .. (enabled and "|cff00ff00yes|r" or "|cffff4444no|r"))
    print("  mode: " .. mode .. "  spell: " .. (spellName or "?") .. " (" .. spellId .. ")")
    print("  target: " .. (UnitExists("target") and (UnitName("target") or "?") or "|cff888888none|r"))
    print("  range: " .. state .. (raw ~= nil and ("  IsSpellInRange=" .. tostring(raw)) or "  (no hostile target)"))
    print("  frame: " .. (frame and frame:IsShown() and "|cff00ff00visible|r" or "|cffff4444hidden|r")
        .. "  bar: " .. BAR_W .. "x" .. BAR_H .. "  offsetY: " .. BOTTOM_Y)
    print("  textures: StatusBar + ActionButton-Border + arc FontString")
end

function P1RangeRadar_RunTest()
    testMode = true
    testStart = GetTime()
    EnsureFrame()
    frame:Show()
    UpdateArc()
    print("|cff00ccffP1 Range|r test — flashing |cffff3333red|r / |cff00ff00green|r / |cffffee00yellow|r for 3s")
end

local tick = CreateFrame("Frame")
tick:SetScript("OnUpdate", function(_, elapsed)
    lastUpdate = lastUpdate + elapsed
    if lastUpdate < UPDATE_INTERVAL then return end
    lastUpdate = 0
    if not enabled and not testMode and splashUntil <= GetTime() then return end
    UpdateArc()
end)

local login = CreateFrame("Frame")
login:RegisterEvent("PLAYER_LOGIN")
login:SetScript("OnEvent", function()
    enabled = ReadRangeEnabled()
    P1RangeRadarDB.enabled = enabled
    splashUntil = GetTime() + 2
    EnsureFrame()
    if enabled then frame:Show() end
    UpdateArc()
end)

SLASH_P1RANGE1 = "/p1range"
SlashCmdList["P1RANGE"] = function(msg)
    msg = string.lower(Trim(msg))
    if msg == "debug" then
        P1RangeRadar_DebugPrint()
        return
    end
    if msg == "test" then
        P1RangeRadar_RunTest()
        return
    end
    if msg == "on" or msg == "off" then
        P1RangeRadar_SetEnabled(msg == "on")
    elseif msg == "" then
        P1RangeRadar_SetEnabled(not enabled)
    end
    print("|cff00ccffP1 Range|r v" .. VERSION .. " — " .. (enabled and "|cff00ff00ON|r" or "|cffaaaaaaOFF|r"))
    print("  /p1range test — flash arc red/green/yellow for 3s")
    print("  /p1range debug — spell, target, range state")
    print("  Arc: |cff00ff00green|r in · |cffffee00yellow|r spell out · |cffff3333red|r melee out · |cff66bbffblue|r idle")
end
