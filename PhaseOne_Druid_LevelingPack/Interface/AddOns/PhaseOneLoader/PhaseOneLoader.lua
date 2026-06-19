-- Phase One Druid Loader: quest pack welcome + Questie presets + smart defaults

PhaseOneDruidLoaderDB = PhaseOneDruidLoaderDB or {}
local db = PhaseOneDruidLoaderDB

local PACK_VERSION = "2.0.2-druid"
local PACK_NAME = "Phase One Quest Pack (Druid)"

local WELCOME_LINE = "|cff00ccffP1 Druid Guide v2.0|r — SHOP + fused NEXT · |cff00ff00/p1guide|r · |cff00ff00/p1scan|r"

_G.P1AutoQuestButtons = _G.P1AutoQuestButtons or {}

local function Trim(s)
    return (s or ""):match("^%s*(.-)%s*$") or ""
end

local function IsFeatureOn(key)
    return db[key] ~= false
end

local function IsAutoQuestEnabled()
    return IsFeatureOn("autoQuestEnabled")
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

local function SetAutoQuestEnabled(enabled, quiet)
    db.autoQuestEnabled = enabled
    ApplyAutoQuestToQuestie(enabled)
    if P1AutoQuest_SetEnabled then P1AutoQuest_SetEnabled(enabled) end
    P1_AutoQuest_RefreshButtons()
    if not quiet then
        if enabled then
            print("|cff00ccffP1 Auto Q:|r |cff00ff00ON|r — accept/turn-in + quest arrows.")
        else
            print("|cff00ccffP1 Auto Q:|r |cffaaaaaaOFF|r — manual questing.")
        end
    end
end

function P1_AutoQuest_Toggle()
    SetAutoQuestEnabled(not IsAutoQuestEnabled())
end

local function PrintWelcome()
    DEFAULT_CHAT_FRAME:AddMessage(WELCOME_LINE)
end

local function PrintMinimalAddons()
    print("|cff00ccffP1 Quest Pack|r — enable ONLY these at Character Select → AddOns:")
    print("  [x] PhaseOneLoader, P1AutoQuest, P1QuestNav, P1DruidGuide")
    print("  [x] Questie-335, !Astrolabe, Auctionator")
    print("  [ ] TomTom — not required (quest arrow in P1QuestNav)")
    print("  [x] Load out of date AddOns")
    print("|cffaaaaaaDisabled by PLAY.bat:|r HUD, Leatrix, WeakAuras, Bagnon")
    print("|cffaaaaaaToggle features:|r /p1settings")
end

local function Yn(on)
    return on and "|cff00ff00ON|r" or "|cffaaaaaaOFF|r"
end

local function PrintSettings()
    print("|cff00ccffP1 Settings|r v" .. PACK_VERSION)
    print("  Auto Q:  " .. Yn(IsFeatureOn("autoQuestEnabled")) .. "  — /p1auto")
    print("  Nav:     " .. Yn(IsFeatureOn("navEnabled")) .. "  — /p1nav")
    print("  Path:    " .. Yn(IsFeatureOn("pathEnabled")) .. "  — /p1path (feeds guide NEXT)")
    print("  Guide:   " .. Yn(IsFeatureOn("guideVisible")) .. "  — /p1guide  (new: PATH + BIS icons + min btn)")
    print("  Autogo:  " .. Yn(IsFeatureOn("guideAutoWaypoint")) .. "  — /p1guide autogo")
    print("  AH pri:  " .. Yn(IsFeatureOn("guideAhPriority")) .. "  — /p1settings ah on|off")
    print("  Tips:    " .. Yn(IsFeatureOn("tipsVisible")) .. "  — /p1tips")
    print("  Glow:    " .. Yn(IsFeatureOn("questGlowEnabled")) .. "  — /p1glow")
    print("  Questie: |cff00ff00ON|r (presets)  — /p1questie")
    print("|cffaaaaaaPower:|r /p1settings all on  ·  /p1settings all off")
end

local function SetGuideAhPriority(on, quiet)
    db.guideAhPriority = on
    PhaseOneLoaderDB = PhaseOneLoaderDB or {}
    PhaseOneDruidLoaderDB = PhaseOneDruidLoaderDB or {}
    PhaseOneLoaderDB.guideAhPriority = on
    PhaseOneDruidLoaderDB.guideAhPriority = on
    if not quiet then
        print("|cff00ccffP1 Settings:|r AH priority " .. (on and "|cff00ff00ON|r" or "|cffaaaaaaOFF|r")
            .. " — guide shows AH before quests")
    end
end

local function SetAllFeatures(on)
    db.autoQuestEnabled = on
    db.navEnabled = on
    db.pathEnabled = on
    db.guideVisible = on
    db.guideAutoWaypoint = on
    db.tipsVisible = on
    db.questGlowEnabled = on
    ApplyFeatureDefaults(1)
    -- ensure new v1.5 PATH section visible when powering on
    if P1DruidGuide_SetPathCollapsed then
        P1DruidGuide_SetPathCollapsed(false)
    elseif P1DruidGuideDB and on then
        P1DruidGuideDB.collapsed = P1DruidGuideDB.collapsed or {}
        P1DruidGuideDB.collapsed.path = false
    end
    print("|cff00ccffP1 Settings:|r all features " .. (on and "|cff00ff00ON|r" or "|cffaaaaaaOFF|r"))
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

function ApplyFeatureDefaults(attempt)
    attempt = attempt or 1
    SetAutoQuestEnabled(IsFeatureOn("autoQuestEnabled"), true)
    if P1QuestNav_SetEnabled then P1QuestNav_SetEnabled(IsFeatureOn("navEnabled")) end
    if P1QuestPath_SetEnabled then P1QuestPath_SetEnabled(IsFeatureOn("pathEnabled")) end
    if P1DruidGuide_SetVisible then P1DruidGuide_SetVisible(IsFeatureOn("guideVisible"))
    elseif P1AdventureGuide_SetVisible then P1AdventureGuide_SetVisible(IsFeatureOn("guideVisible")) end
    if P1DruidGuide_SetTipsVisible then P1DruidGuide_SetTipsVisible(IsFeatureOn("tipsVisible")) end
    if P1DruidGuide_SetAutoWaypoint then P1DruidGuide_SetAutoWaypoint(IsFeatureOn("guideAutoWaypoint")) end
    if P1QuestGlow_SetEnabled then P1QuestGlow_SetEnabled(IsFeatureOn("questGlowEnabled")) end
    -- default new PATH section visible (for old DBs or retries)
    if IsFeatureOn("guideVisible") then
        if P1DruidGuide_SetPathCollapsed then
            -- only force if not explicitly set; caller can leave as-is for user collapsed state
            if P1DruidGuideDB and P1DruidGuideDB.collapsed and P1DruidGuideDB.collapsed.path == nil then
                P1DruidGuide_SetPathCollapsed(false)
            end
        elseif P1DruidGuideDB then
            P1DruidGuideDB.collapsed = P1DruidGuideDB.collapsed or {}
            if P1DruidGuideDB.collapsed.path == nil then P1DruidGuideDB.collapsed.path = false end
        end
    end
    ApplyQuestiePresets()
    if P1AutoQuest_Refresh then P1AutoQuest_Refresh(true) end
    if P1QuestNav_Refresh then P1QuestNav_Refresh(true) end
    if P1QuestPath_Refresh then P1QuestPath_Refresh(true) end

    local needRetry = false
    if IsFeatureOn("navEnabled") and not P1QuestNav_SetEnabled then needRetry = true end
    if IsFeatureOn("pathEnabled") and not P1QuestPath_SetEnabled then needRetry = true end
    if IsFeatureOn("guideVisible") and not P1DruidGuide_SetVisible and not P1AdventureGuide_SetVisible then needRetry = true end
    if not P1DruidGuide_SetAutoWaypoint then needRetry = true end
    if needRetry and attempt < 6 then
        Delay(attempt == 1 and 2 or 1, function() ApplyFeatureDefaults(attempt + 1) end)
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

    SLASH_P1SCAN1 = "/p1scan"
    SlashCmdList["P1SCAN"] = function()
        local _, class = UnitClass("player")
        if class ~= "DRUID" then
            print("|cff00ccffP1 Scan|r — druid characters only")
            return
        end
        if P1DG and P1DG.PrintCharacterScan then
            local ok, err = pcall(function()
                P1DG.PrintCharacterScan()
                if P1DruidGuide_Refresh then P1DruidGuide_Refresh() end
            end)
            if not ok then
                print("|cffff0000P1 Scan error:|r " .. tostring(err))
            end
        else
            print("|cff00ccffP1 Scan|r — enable |cff00ff00P1DruidGuide|r at character select, then /reload")
        end
    end

    SLASH_P1SETTINGS1 = "/p1settings"
    SlashCmdList["P1SETTINGS"] = function(msg)
        msg = string.lower(Trim(msg))
        if msg == "all on" then
            SetAllFeatures(true)
            return
        end
        if msg == "all off" then
            SetAllFeatures(false)
            return
        end
        if msg == "ah on" then
            SetGuideAhPriority(true)
            return
        end
        if msg == "ah off" then
            SetGuideAhPriority(false)
            return
        end
        PrintSettings()
    end

    SLASH_P1FIX1 = "/p1fix"
    SlashCmdList["P1FIX"] = function()
        if P1Waypoint and P1Waypoint.ClearActive then
            P1Waypoint:ClearActive()
        elseif TomTom and TomTom.activeWaypoint then
            TomTom.activeWaypoint = nil
            if TomTom.arrow then TomTom.arrow:Hide() end
        end
        print("|cff00ccffP1 Fix:|r Cleared stuck quest arrow.")
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

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
    EnsureSlash()

    if db.lastSeenVersion and db.lastSeenVersion ~= PACK_VERSION then
        print("|cff00ccff" .. PACK_NAME .. "|r updated to v" .. PACK_VERSION .. " — |cff00ff00/reload|r was enough.")
    end
    db.lastSeenVersion = PACK_VERSION

    if db.guideAutoWaypoint == nil then db.guideAutoWaypoint = true end
    if db.guideAhPriority == nil then db.guideAhPriority = true end

    if db.onboardingVersion ~= PACK_VERSION then
        db.onboardingVersion = PACK_VERSION
        Delay(4, function()
            print("|cff00ccffP1 v2.0:|r SHOP section — affordable AH list from your gear scan")
            print("|cff00ccffP1 v2.0:|r Fused NEXT — gear ROI + quests ranked together")
            print("|cff00ccffP1 v2.0:|r /p1scan shows delta since login")
        end)
    end

    RetryPresets(1)
    Delay(2, function() ApplyFeatureDefaults(1) end)
    Delay(5, function()
        ApplyFeatureDefaults(1)
        ForceQuestieIconRefresh()
    end)
    Delay(3, function() PrintWelcome() end)
end)
