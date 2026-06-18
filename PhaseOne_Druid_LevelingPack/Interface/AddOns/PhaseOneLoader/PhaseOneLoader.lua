-- Phase One Druid Loader: quest pack welcome + Questie presets

PhaseOneDruidLoaderDB = PhaseOneDruidLoaderDB or {}
local db = PhaseOneDruidLoaderDB

local PACK_VERSION = "1.2.1-druid"
local PACK_NAME = "Phase One Quest Pack (Druid)"

local WELCOME_LINES = {
    "|cff00ccff[" .. PACK_NAME .. "]|r Welcome!",
    "|cffaaaaaaQuest pack:|r Questie tracking + auto accept/turn-in + TomTom arrow + idle walk.",
    "|cffaaaaaaToggle:|r |cff00ff00/p1auto|r or top-right |cff00ff00Auto Q|r button (green=on).",
    "|cffaaaaaaMats:|r |cff00ff00/p1guide|r — crafting material counts + when to stock up.",
    "|cffaaaaaaDebug:|r |cff00ff00/p1quest|r · |cff00ff00/p1questie|r icons · |cff00ff00/p1minimal|r checklist.",
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

function P1_IsAutoQuestEnabled()
    return IsAutoQuestEnabled()
end

local function SetAutoQuestEnabled(enabled)
    db.autoQuestEnabled = enabled
    ApplyAutoQuestToQuestie(enabled)
    if P1AutoQuest_SetEnabled then P1AutoQuest_SetEnabled(enabled) end
    P1_AutoQuest_RefreshButtons()
    if enabled then
        print("|cff00ccffP1 Auto Q:|r |cff00ff00ON|r — accept/turn-in, TomTom arrow, idle walk.")
    else
        print("|cff00ccffP1 Auto Q:|r |cffaaaaaaOFF|r — manual questing.")
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

local function PrintMinimalAddons()
    print("|cff00ccffP1 Quest Pack|r — enable ONLY these at Character Select → AddOns:")
    print("  [x] PhaseOneLoader, P1AutoQuest, P1AdventureGuide")
    print("  [x] Questie-335, TomTom, !Astrolabe")
    print("  [x] Load out of date AddOns")
    print("|cffaaaaaaDisabled by PLAY.bat:|r HUD, Leatrix, WeakAuras, Bagnon, Auctionator")
    print("|cffaaaaaaToggle auto quests:|r /p1auto or Auto Q button (top-right)")
end

local function QuestieIconCount()
    local n = 0
    if QuestieLoader then
        local ok, QuestieMap = pcall(function() return QuestieLoader:ImportModule("QuestieMap") end)
        if ok and QuestieMap and QuestieMap.questIdFrames then
            for _, frames in pairs(QuestieMap.questIdFrames) do
                for _ in pairs(frames) do n = n + 1 end
            end
        end
    end
    return n
end

local function ForceQuestieIconRefresh()
    if QuestieLoader then
        local ok, AvailableQuests = pcall(function() return QuestieLoader:ImportModule("AvailableQuests") end)
        if ok and AvailableQuests and AvailableQuests.CalculateAndDrawAll then
            AvailableQuests.CalculateAndDrawAll()
            return true
        end
    end
    if Questie and Questie.RefreshQuestIcon then
        Questie:RefreshQuestIcon()
        return true
    end
    return false
end

local function ApplyQuestiePresets()
    if not Questie or not Questie.db or not Questie.db.profile then return false end
    local p = Questie.db.profile
    p.enabled = true
    p.enableMapIcons = true
    p.enableMiniMapIcons = true
    p.lowLevelStyle = 3
    p.manualLevelOffset = 4
    p.minLevelFilter = 1
    p.maxLevelFilter = 80
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
    p.useWotlkMapData = true
    if QuestieCompat and QuestieCompat.LoadUiMapData and QuestieCompat.WOW_PROJECT_WRATH_CLASSIC then
        QuestieCompat.LoadUiMapData(QuestieCompat.WOW_PROJECT_WRATH_CLASSIC)
    end
    p.autoaccept = IsAutoQuestEnabled()
    p.autocomplete = IsAutoQuestEnabled()
    p.autoModifier = "disabled"
    if Questie.db.char then
        Questie.db.char.complete = Questie.db.char.complete or {}
    end
    ForceQuestieIconRefresh()
    return true
end

local function ApplyPresets()
    if ApplyQuestiePresets() then
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
        print("|cff00ccffP1 Fix:|r Cleared stuck TomTom arrow.")
        if WeakAuras and WeakAuras.Toggle then
            if WeakAuras.IsPaused and not WeakAuras.IsPaused() then
                WeakAuras.Toggle()
                print("|cff00ccffP1 Fix:|r WeakAuras paused. /p1fix again to un-pause.")
            else
                WeakAuras.Toggle()
                print("|cff00ccffP1 Fix:|r WeakAuras un-paused.")
            end
        end
    end

    SLASH_P1MINIMAL1 = "/p1minimal"
    SlashCmdList["P1MINIMAL"] = function()
        PrintMinimalAddons()
    end

    SLASH_P1QUESTIE1 = "/p1questie"
    SlashCmdList["P1QUESTIE"] = function()
        if not Questie or not Questie.db or not Questie.db.profile then
            print("|cff00ccffP1 Questie:|r |cffff0000Questie not loaded|r — enable Questie-335 and /reload")
            return
        end
        local p = Questie.db.profile
        local yn = function(v) return v and "|cff00ff00yes|r" or "|cffff0000no|r" end
        print("|cff00ccffP1 Questie|r v" .. PACK_VERSION .. " — map icon debug")
        print("  enabled: " .. yn(p.enabled))
        print("  enableMapIcons: " .. yn(p.enableMapIcons))
        print("  enableMiniMapIcons: " .. yn(p.enableMiniMapIcons))
        print("  enableAvailable: " .. yn(p.enableAvailable))
        print("  enableTurnins: " .. yn(p.enableTurnins))
        print("  enableObjectives: " .. yn(p.enableObjectives))
        print("  hideIconsOnContinents: " .. yn(p.hideIconsOnContinents))
        print("  useWotlkMapData: " .. yn(p.useWotlkMapData))
        print(string.format("  level filter: style=%s offset=%s min=%s max=%s",
            tostring(p.lowLevelStyle), tostring(p.manualLevelOffset),
            tostring(p.minLevelFilter), tostring(p.maxLevelFilter)))
        print(string.format("  scale: global=%.2f minimap=%.2f available=%.2f",
            p.globalScale or 0, p.globalMiniMapScale or 0, p.availableScale or 0))
        print("  autoaccept: " .. yn(p.autoaccept) .. "  autocomplete: " .. yn(p.autocomplete))
        print("  autoModifier: " .. tostring(p.autoModifier))
        print("  map icon frames: " .. QuestieIconCount())
        ForceQuestieIconRefresh()
        print("  refreshed — check world map / minimap for ! icons")
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

    if db.lastSeenVersion and db.lastSeenVersion ~= PACK_VERSION then
        print("|cff00ccff" .. PACK_NAME .. "|r updated to v" .. PACK_VERSION .. " — |cff00ff00/reload|r was enough.")
    end
    db.lastSeenVersion = PACK_VERSION

    RetryPresets(1)
    Delay(2, function()
        ApplyAutoQuestToQuestie(IsAutoQuestEnabled())
        if P1AutoQuest_SetEnabled then P1AutoQuest_SetEnabled(IsAutoQuestEnabled()) end
        if P1AutoQuest_Refresh then P1AutoQuest_Refresh(true) end
        P1_AutoQuest_RefreshButtons()
    end)
    Delay(5, function() ForceQuestieIconRefresh() end)

    if not db.welcomed or db.presetsApplied == PACK_VERSION then
        Delay(3, function()
            PrintWelcome()
            db.welcomed = true
        end)
    end
end)
