-- Phase One Druid Loader: welcome + first-login presets (Icecrown / Horde Feral)

PhaseOneDruidLoaderDB = PhaseOneDruidLoaderDB or {}
local db = PhaseOneDruidLoaderDB

local PACK_VERSION = "1.1.3-druid"
local PACK_NAME = "Phase One Druid Pack"

local WELCOME_LINES = {
    "|cff00ccff[" .. PACK_NAME .. "]|r Welcome, Horde Feral Druid!",
    "|cffaaaaaaReady to go:|r Questie + Leatrix presets applied. |cff00ff00P1 Feral HUD|r is on screen (drag to move).",
    "|cffaaaaaaCat (20+):|r |cff00ff00Mangle|r → |cff00ff00Rip|r (5 CP) → |cff00ff00Rake|r → |cff00ff00Shred|r",
    "|cffaaaaaaGlow icons|r = debuff missing or Tiger's Fury ready. Low HP = Rejuvenation reminder.",
    "|cffaaaaaaQuesting:|r Ctrl+click Questie icon for TomTom arrow.",
    "|cffaaaaaaAdventure:|r |cff00ff00/p1guide|r — next action, profs, mats, rare mobs (click + to expand).",
    "|cffaaaaaaAuto quests:|r |cff00ff00/p1auto|r or |cff00ff00Auto Q|r on HUD — toggle accept/turn-in.",
}

_G.P1AutoQuestButtons = _G.P1AutoQuestButtons or {}

local function IsAutoQuestEnabled()
    if db.autoQuestEnabled ~= nil then return db.autoQuestEnabled end
    return true
end

local function ApplyAutoQuestToQuestie(enabled)
    if not Questie or not Questie.db or not Questie.db.profile then return false end
    local p = Questie.db.profile
    p.autoaccept = enabled
    p.autocomplete = enabled
    if enabled then p.autoModifier = "disabled" end
    return true
end

function P1_AutoQuest_RefreshButtons()
    local on = IsAutoQuestEnabled()
    for _, btn in ipairs(P1AutoQuestButtons) do
        if btn.text then
            if on then btn.text:SetTextColor(0.2, 1, 0.2)
            else btn.text:SetTextColor(0.45, 0.45, 0.45) end
        end
    end
end

local function SetAutoQuestEnabled(enabled)
    db.autoQuestEnabled = enabled
    ApplyAutoQuestToQuestie(enabled)
    P1_AutoQuest_RefreshButtons()
    if enabled then
        print("|cff00ccffP1 Auto Q:|r |cff00ff00ON|r — Questie auto-accept and auto-complete.")
    else
        print("|cff00ccffP1 Auto Q:|r |cffaaaaaaOFF|r — accept and turn in quests manually.")
    end
end

function P1_AutoQuest_Toggle()
    SetAutoQuestEnabled(not IsAutoQuestEnabled())
end

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
    p.autoaccept = IsAutoQuestEnabled()
    p.autocomplete = IsAutoQuestEnabled()
    p.autoModifier = "disabled"

    if Questie.db.char then
        Questie.db.char.complete = Questie.db.char.complete or {}
    end

    if Questie.RefreshQuestIcon then
        Questie:RefreshQuestIcon()
    end
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
            if type(v) == "string" and (v == "On" or v == "Off") then
                LeaPlusLC[k] = v
            end
        end
    end
    return true
end

local function ApplyPresets()
    local q = ApplyQuestiePresets()
    local l = ApplyLeatrixPresets()
    if q and l then
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
        if elapsed >= seconds then
            self:SetScript("OnUpdate", nil)
            fn()
        end
    end)
end

local function EnsureSlash()
    SLASH_PHASEONEDRUID1 = "/p1d"
    SLASH_PHASEONEDRUID2 = "/phaseonedruid"
    SlashCmdList["PHASEONEDRUID"] = function()
        PrintWelcome()
        print("|cff00ccff" .. PACK_NAME .. "|r v" .. PACK_VERSION)
    end

    SLASH_P1AUTO1 = "/p1auto"
    SLASH_P1AUTO2 = "/p1qauto"
    SlashCmdList["P1AUTO"] = function()
        P1_AutoQuest_Toggle()
    end

    SLASH_P1FIX1 = "/p1fix"
    SlashCmdList["P1FIX"] = function()
        if TomTom and TomTom.activeWaypoint then
            TomTom.activeWaypoint = nil
            if TomTom.arrow then TomTom.arrow:Hide() end
        end
        if WeakAuras and WeakAuras.Toggle and not WeakAuras.IsPaused() then
            WeakAuras.Toggle()
            print("|cff00ccffP1 Fix:|r WeakAuras paused (stuck glows hidden). /p1fix again to un-pause.")
        elseif WeakAuras and WeakAuras.Toggle then
            WeakAuras.Toggle()
            print("|cff00ccffP1 Fix:|r WeakAuras un-paused.")
        end
        if _G.P1FeralHUDFrame then _G.P1FeralHUDFrame:Show() end
        print("|cff00ccffP1 Fix:|r To delete stuck aura forever: |cff00ff00/wa|r → find it → Delete.")
        print("|cffaaaaaaTip:|r You don't need WeakAuras — P1 Feral HUD handles combat alerts.")
    end
end

local function RetryPresets(attempt)
    attempt = attempt or 1
    if db.presetsApplied == PACK_VERSION then return end
    if ApplyPresets() then return end
    if attempt < 8 then
        Delay(1, function() RetryPresets(attempt + 1) end)
    end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
    EnsureSlash()

    local _, class = UnitClass("player")
    if class ~= "DRUID" then
        print("|cff00ccff" .. PACK_NAME .. "|r loaded. Best on a Druid — type /p1d.")
        return
    end

    RetryPresets(1)
    Delay(2, function()
        ApplyAutoQuestToQuestie(IsAutoQuestEnabled())
        P1_AutoQuest_RefreshButtons()
    end)

    if not db.welcomed or db.presetsApplied == PACK_VERSION then
        Delay(3, function()
            PrintWelcome()
            db.welcomed = true
        end)
    end
end)
