-- P1DamageText — floating combat damage numbers (Warmane 3.3.5a)

P1DamageTextDB = P1DamageTextDB or { enabled = true, position = "center" }

local VERSION = "1.2.7"
local POOL_SIZE = 24
local FONT_SIZE = 22
local DURATION = 1.4
local RISE_SPEED = 45
local STACK_OFFSET = 18

local COLORS = {
    hit = { 1, 1, 1 },
    crit = { 1, 0.92, 0.15 },
    dot = { 1, 0.55, 0.15 },
    miss = { 0.6, 0.6, 0.6 },
}

local function SyncLoader(on)
    if PhaseOneLoaderDB then PhaseOneLoaderDB.damageTextEnabled = on end
    if PhaseOneDruidLoaderDB then PhaseOneDruidLoaderDB.damageTextEnabled = on end
end

local function ReadEnabled()
    if PhaseOneLoaderDB and PhaseOneLoaderDB.damageTextEnabled ~= nil then
        return PhaseOneLoaderDB.damageTextEnabled
    end
    if PhaseOneDruidLoaderDB and PhaseOneDruidLoaderDB.damageTextEnabled ~= nil then
        return PhaseOneDruidLoaderDB.damageTextEnabled
    end
    return P1DamageTextDB.enabled ~= false
end

local enabled = ReadEnabled()
local pool = {}
local activeCount = 0
local anchorFrame

local function Trim(s)
    return (s or ""):match("^%s*(.-)%s*$") or ""
end

local function EnsureAnchor()
    if anchorFrame then return end
    anchorFrame = CreateFrame("Frame", "P1DamageTextAnchor", UIParent)
    anchorFrame:SetFrameStrata("TOOLTIP")
    anchorFrame:SetFrameLevel(300)
    anchorFrame:SetSize(200, 200)
    anchorFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 80)
end

local function RepositionAnchor()
    EnsureAnchor()
    anchorFrame:ClearAllPoints()
    if P1DamageTextDB.position == "target" and TargetFrame and TargetFrame:IsShown() then
        anchorFrame:SetPoint("TOP", TargetFrame, "BOTTOM", 0, -8)
    else
        anchorFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 80)
    end
end

local function AcquireFloater()
    for _, f in ipairs(pool) do
        if not f.active then return f end
    end
    EnsureAnchor()
    local f = CreateFrame("Frame", nil, anchorFrame)
    f:SetSize(120, 32)
    f.text = f:CreateFontString(nil, "OVERLAY")
    f.text:SetFont("Fonts\\FRIZQT__.TTF", FONT_SIZE, "OUTLINE")
    f.text:SetPoint("CENTER")
    f.active = false
    pool[#pool + 1] = f
    return f
end

local function ShowDamageNumber(amount, kind, isCrit)
    if not enabled or not amount or amount <= 0 then return end
    RepositionAnchor()
    local f = AcquireFloater()
    local color = COLORS[kind] or COLORS.hit
    if isCrit then color = COLORS.crit end

    f.text:SetText(tostring(amount))
    if isCrit then
        f.text:SetFont("Fonts\\FRIZQT__.TTF", FONT_SIZE + 4, "OUTLINE")
    else
        f.text:SetFont("Fonts\\FRIZQT__.TTF", FONT_SIZE, "OUTLINE")
    end
    f.text:SetTextColor(color[1], color[2], color[3], 1)

    local xOff = (math.random() - 0.5) * 40
    local yOff = activeCount * STACK_OFFSET
    f:ClearAllPoints()
    f:SetPoint("CENTER", anchorFrame, "CENTER", xOff, yOff)
    f:SetAlpha(1)
    f.active = true
    f.start = GetTime()
    f.rise = 0
    f:Show()
    activeCount = activeCount + 1

    f:SetScript("OnUpdate", function(self, elapsed)
        local t = GetTime() - self.start
        self.rise = self.rise + elapsed * RISE_SPEED
        self:ClearAllPoints()
        self:SetPoint("CENTER", anchorFrame, "CENTER", xOff, yOff + self.rise)
        if t > DURATION * 0.5 then
            self:SetAlpha(1 - (t - DURATION * 0.5) / (DURATION * 0.5))
        end
        if t >= DURATION then
            self.active = false
            self:Hide()
            self:SetScript("OnUpdate", nil)
            activeCount = math.max(0, activeCount - 1)
        end
    end)
end

local function PlayerGUID()
    return UnitGUID("player")
end

local function HandleCombatLog(...)
    if not enabled then return end
    local timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags = ...
    if sourceGUID ~= PlayerGUID() then return end

    local amount, overkill, critical
    if event == "SWING_DAMAGE" then
        amount = select(9, ...)
        overkill = select(10, ...)
        critical = select(11, ...)
        ShowDamageNumber(amount, "hit", critical)
    elseif event == "SPELL_DAMAGE" or event == "RANGE_DAMAGE" then
        local spellId, spellName, spellSchool = select(9, ...)
        amount = select(12, ...)
        overkill = select(13, ...)
        critical = select(14, ...)
        ShowDamageNumber(amount, "hit", critical)
    elseif event == "SPELL_PERIODIC_DAMAGE" then
        amount = select(12, ...)
        ShowDamageNumber(amount, "dot", false)
    end
end

local function ParseChatDamage(msg, kind)
    if not enabled or not msg then return end
    local amount = msg:match("(%d+) damage")
    if not amount then amount = msg:match("Your .- hits .- for (%d+)") end
    if not amount then amount = msg:match("You hit .- for (%d+)") end
    if not amount then return end
    local isCrit = msg:find("crit") or msg:find("Critical")
    ShowDamageNumber(tonumber(amount), kind or "hit", isCrit and true or false)
end

function P1DamageText_SetEnabled(on)
    enabled = on and true or false
    P1DamageTextDB.enabled = enabled
    SyncLoader(enabled)
end

local combatFrame = CreateFrame("Frame")
combatFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
combatFrame:RegisterEvent("CHAT_MSG_COMBAT")
combatFrame:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
combatFrame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE")
combatFrame:RegisterEvent("PLAYER_LOGIN")
combatFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        enabled = ReadEnabled()
        P1DamageTextDB.enabled = enabled
        return
    end
    if not enabled then return end
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        HandleCombatLog(...)
    elseif event == "CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE" then
        ParseChatDamage(..., "dot")
    elseif event == "CHAT_MSG_SPELL_SELF_DAMAGE" or event == "CHAT_MSG_COMBAT" then
        ParseChatDamage(..., "hit")
    end
end)

SLASH_P1DMG1 = "/p1dmg"
SlashCmdList["P1DMG"] = function(msg)
    msg = string.lower(Trim(msg))
    if msg == "target" or msg == "center" then
        P1DamageTextDB.position = msg
        print("|cff00ccffP1 Damage|r position: " .. msg)
        return
    end
    if msg == "on" or msg == "off" then
        P1DamageText_SetEnabled(msg == "on")
    elseif msg == "" then
        P1DamageText_SetEnabled(not enabled)
    end
    print("|cff00ccffP1 Damage|r v" .. VERSION .. " — " .. (enabled and "|cff00ff00ON|r" or "|cffaaaaaaOFF|r"))
    print("  Floating numbers · /p1dmg target|center for position")
end
