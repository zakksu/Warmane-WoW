-- Phase One Loader: welcome + first-login presets (Horde Warlock)

PhaseOneLoaderDB = PhaseOneLoaderDB or {}
local db = PhaseOneLoaderDB

local PACK_VERSION = "1.1.0"
local PACK_NAME = "Phase One Warlock Pack"

local WELCOME_LINES = {
    "|cff00ccff[" .. PACK_NAME .. "]|r Welcome, Horde Warlock!",
    "|cffaaaaaaReady to go:|r Questie + Leatrix presets applied. |cff9482c9P1 Warlock HUD|r on screen.",
    "|cffaaaaaaDoTs:|r Glow = apply |cff9482c9Corruption|r, |cff9482c9Immolate|r, |cff9482c9Curse of Agony|r.",
    "|cffaaaaaaPet:|r |cff00ff00Summon Voidwalker|r (lvl 10+) tanks for you.",
    "|cffaaaaaaQuesting:|r Ctrl+click Questie icon for TomTom arrow.",
    "|cffaaaaaaCommands:|r |cff00ff00/p1|r | |cff00ff00/p1whud|r | |cff00ff00/questie|r | |cff00ff00/ltp|r",
}

local function PrintWelcome()
    for _, line in ipairs(WELCOME_LINES) do
        DEFAULT_CHAT_FRAME:AddMessage(line)
    end
end

local function ApplyQuestiePresets()
    if not Questie or not Questie.db or not Questie.db.profile then return false end
    local p = Questie.db.profile
    p.minLevelFilter = -4
    p.maxLevelFilter = 4
    p.manualLevelOffset = 4
    p.lowLevelStyle = 2
    p.trackerSortObjectives = "byDistance"
    p.trackerShowCompleteQuests = false
    p.collapseCompletedQuests = true
    p.hideCompletedQuestObjectives = true
    p.globalScale = 0.85
    p.globalMiniMapScale = 0.75
    p.availableScale = 1.1
    p.autoTrackQuests = true
    p.trackerEnabled = true
    p.enableAvailable = true
    p.enableTurnins = true
    p.enableObjectives = true
    p.hideIconsOnContinents = false
    p.nameplateEnabled = false
    if Questie.db.char then Questie.db.char.complete = Questie.db.char.complete or {} end
    if Questie.RefreshQuestIcon then Questie:RefreshQuestIcon() end
    return true
end

local function ApplyLeatrixPresets()
    if not LeaPlusDB then return false end
    LeaPlusDB["AutoRepairGear"] = "On"
    LeaPlusDB["AutoRepairGuildFunds"] = "On"
    LeaPlusDB["AutoRepairShowSummary"] = "On"
    LeaPlusDB["AutoSellJunk"] = "On"
    LeaPlusDB["AutoSellShowSummary"] = "On"
    LeaPlusDB["FasterLooting"] = "On"
    LeaPlusDB["HideErrorMessages"] = "On"
    LeaPlusDB["NoHitIndicators"] = "On"
    LeaPlusDB["HideZoneText"] = "Off"
    LeaPlusDB["MinimapModder"] = "On"
    LeaPlusDB["EnhanceQuestLog"] = "On"
    LeaPlusDB["ShowCooldowns"] = "On"
    LeaPlusDB["DurabilityStatus"] = "On"
    if LeaPlusLC then
        for k, v in pairs(LeaPlusDB) do
            if type(v) == "string" and (v == "On" or v == "Off") then LeaPlusLC[k] = v end
        end
    end
    return true
end

local function ApplyPresets()
    if ApplyQuestiePresets() and ApplyLeatrixPresets() then
        db.presetsApplied = PACK_VERSION
        return true
    end
    return false
end

local function Delay(seconds, fn)
    local elapsed = 0
    local t = CreateFrame("Frame")
    t:SetScript("OnUpdate", function(self, e)
        elapsed = elapsed + e
        if elapsed >= seconds then self:SetScript("OnUpdate", nil) fn() end
    end)
end

local function RetryPresets(attempt)
    attempt = attempt or 1
    if db.presetsApplied == PACK_VERSION then return end
    if ApplyPresets() then return end
    if attempt < 8 then Delay(1, function() RetryPresets(attempt + 1) end) end
end

SLASH_PHASEONE1 = "/p1"
SLASH_PHASEONE2 = "/phaseone"
SlashCmdList["PHASEONE"] = function()
    PrintWelcome()
    print("|cff00ccff" .. PACK_NAME .. "|r v" .. PACK_VERSION)
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
    local _, class = UnitClass("player")
    if class ~= "WARLOCK" then
        print("|cff00ccff" .. PACK_NAME .. "|r loaded. Best on a Warlock — type /p1.")
        return
    end
    RetryPresets(1)
    if not db.welcomed or db.presetsApplied == PACK_VERSION then
        Delay(3, function() PrintWelcome() db.welcomed = true end)
    end
end)
