-- P1QuestNav — visual multi-quest navigation (Warmane 3.3.5a)
-- Minimap numbered arrows, dotted path to #1, TomTom crazy arrow on click / priority refresh.

P1QuestNavDB = P1QuestNavDB or { enabled = true }

local MAX_TRACKED = 5
local REFRESH_INTERVAL = 1.5
local REFRESH_THROTTLE = 0.35
local AVAIL_CACHE_TTL = 3
local DOT_COUNT = 14
local LINE_DOT_SIZE = 4

local MODE_COLORS = {
    available = { 1.0, 0.92, 0.15 },
    objective = { 0.25, 0.65, 1.0 },
    ["turn-in"] = { 0.25, 1.0, 0.35 },
}

local SLOT_HUES = {
    { 1.0, 0.85, 0.0 },
    { 0.35, 0.75, 1.0 },
    { 0.35, 1.0, 0.55 },
    { 1.0, 0.45, 0.85 },
    { 0.75, 0.55, 1.0 },
}

local enabled = P1QuestNavDB.enabled ~= false
local debugMode = false
local lastRefresh = 0
local lastRescan = 0
local lastAvailScan = 0
local availCache = nil
local tracked = {}
local minimapDots = {}
local worldDots = {}
local pinFrames = {}
local legendLines = {}

local QuestieDB, QuestieMap, QuestiePlayer, QuestieCompat, ZoneDB, HBD
local LoadQuestieModules

local function GetAstrolabe()
    if DongleStub then
        local ok, lib = pcall(DongleStub, "Astrolabe-1.0")
        if ok and lib then return lib end
    end
end

local function GetHBD()
    if HBD then return HBD end
    if QuestieCompat and QuestieCompat.HBD then
        HBD = QuestieCompat.HBD
        return HBD
    end
    if LibStub then
        local ok, lib = pcall(LibStub, "HereBeDragonsQuestie-2.0")
        if ok and lib then HBD = lib end
    end
    return HBD
end

local function IsAutoQuestOn()
    if _G.P1_IsAutoQuestEnabled then return P1_IsAutoQuestEnabled() end
    return enabled
end

local function IsNavEnabled()
    return enabled and IsAutoQuestOn()
end

local function BlendColor(mode, slot)
    local mc = MODE_COLORS[mode] or MODE_COLORS.objective
    local sc = SLOT_HUES[slot] or SLOT_HUES[1]
    return (mc[1] + sc[1]) * 0.5, (mc[2] + sc[2]) * 0.5, (mc[3] + sc[3]) * 0.5
end

local function TruncateName(name, maxLen)
    if not name then return "?" end
    if #name <= maxLen then return name end
    return string.sub(name, 1, maxLen - 1) .. "…"
end

LoadQuestieModules = function()
    if QuestieDB and QuestieMap and QuestiePlayer then return true end
    if not QuestieLoader or not QuestieLoader.ImportModule then return false end
    local ok
    ok, QuestieDB = pcall(function() return QuestieLoader:ImportModule("QuestieDB") end)
    if not ok or not QuestieDB then return false end
    ok, QuestieMap = pcall(function() return QuestieLoader:ImportModule("QuestieMap") end)
    if not ok or not QuestieMap then return false end
    ok, QuestiePlayer = pcall(function() return QuestieLoader:ImportModule("QuestiePlayer") end)
    if not ok or not QuestiePlayer then return false end
    if not ZoneDB then
        ok, ZoneDB = pcall(function() return QuestieLoader:ImportModule("ZoneDB") end)
        if not ok then ZoneDB = nil end
    end
    QuestieCompat = _G.QuestieCompat
    GetHBD()
    return Questie and Questie.db and Questie.db.profile
end

local function AreaIdToCZ(areaId)
    if not areaId then return nil, nil end
    if QuestieCompat and QuestieCompat.AreaIdToCZ then
        return QuestieCompat.AreaIdToCZ(areaId)
    end
    if not ZoneDB or not QuestieCompat or not QuestieCompat.UiMapData then return nil, nil end
    local uiMapId = ZoneDB:GetUiMapIdByAreaId(areaId)
    if not uiMapId then return nil, nil end
    local data = QuestieCompat.UiMapData[uiMapId]
    if not data or not data.mapID then return nil, nil end
    return nil, nil
end

local function ConsiderStarterSpawns(spawns, areaId, name, playerX, playerY, playerI, best)
    local hbd = GetHBD()
    if not hbd or not ZoneDB or not spawns or not areaId then return best end
    local uiMapId = ZoneDB:GetUiMapIdByAreaId(areaId)
    if not uiMapId then return best end
    for _, spawn in pairs(spawns) do
        if spawn[1] and spawn[2] and spawn[1] >= 0 and spawn[2] >= 0 then
            local dX, dY, dInstance = hbd:GetWorldCoordinatesFromZone(spawn[1] / 100, spawn[2] / 100, uiMapId)
            local dist = hbd:GetWorldDistance(dInstance, playerX, playerY, dX, dY)
            if dist then
                if dInstance ~= playerI then dist = 500000 + dist * 100 end
                if not best.dist or dist < best.dist then
                    best.dist = dist
                    best.spawn = spawn
                    best.zone = areaId
                    best.name = name
                end
            end
        end
    end
    return best
end

local function GetNearestStarterForQuestId(questId)
    if not QuestieDB or not QuestieDB.GetQuest then return nil end
    local quest = QuestieDB.GetQuest(questId)
    if not quest or not quest.Starts then return nil end
    local hbd = GetHBD()
    if not hbd or not ZoneDB then return nil end
    local playerX, playerY, playerI = hbd:GetPlayerWorldPosition()
    if not playerX then return nil end
    local best = { dist = nil, spawn = nil, zone = nil, name = nil }
    if quest.Starts.NPC then
        for _, npcId in ipairs(quest.Starts.NPC) do
            local npc = QuestieDB:GetNPC(npcId)
            if npc and npc.spawns and npc.friendly ~= false then
                for zone, spawns in pairs(npc.spawns) do
                    best = ConsiderStarterSpawns(spawns, zone, npc.name, playerX, playerY, playerI, best)
                end
            end
        end
    end
    if quest.Starts.GameObject then
        for _, objId in ipairs(quest.Starts.GameObject) do
            local obj = QuestieDB:GetObject(objId)
            if obj and obj.spawns then
                for zone, spawns in pairs(obj.spawns) do
                    best = ConsiderStarterSpawns(spawns, zone, obj.name, playerX, playerY, playerI, best)
                end
            end
        end
    end
    if not best.spawn then return nil end
    return best.spawn, best.zone, best.name, best.dist
end

local function FindAvailableFromQuestieFrames()
    if not LoadQuestieModules() or not QuestieMap or not QuestieMap.questIdFrames then return {} end
    local hbd = GetHBD()
    if not hbd or not ZoneDB then return {} end
    local playerX, playerY, playerI = hbd:GetPlayerWorldPosition()
    if not playerX then return {} end
    local completed = Questie.db.char.complete or {}
    local log = QuestiePlayer.currentQuestlog or {}
    local results = {}
    for questId, frameNames in pairs(QuestieMap.questIdFrames) do
        if not completed[questId] and not log[questId] then
            for _, frameName in pairs(frameNames) do
                local frame = _G[frameName]
                if frame and frame.data and frame.data.Type == "available" and frame.x and frame.y then
                    local uiMapId = frame.UiMapID or frame.data.UiMapID
                    local areaId = uiMapId and ZoneDB:GetAreaIdByUiMapId and ZoneDB:GetAreaIdByUiMapId(uiMapId)
                    if areaId then
                        local spawn = { frame.x * 100, frame.y * 100 }
                        local dX, dY, dInstance = hbd:GetWorldCoordinatesFromZone(frame.x, frame.y, uiMapId)
                        local dist = hbd:GetWorldDistance(dInstance, playerX, playerY, dX, dY)
                        if dist then
                            local questName = QuestieDB.QueryQuestSingle(questId, "name") or ("Quest #" .. questId)
                            table.insert(results, {
                                questId = questId,
                                questName = questName,
                                mode = "available",
                                dist = dist,
                                spawn = spawn,
                                zone = areaId,
                                targetName = frame.data.Name or frame.data.name,
                                title = "Pick up: " .. questName,
                            })
                        end
                    end
                end
            end
        end
    end
    return results
end

local function FindAvailableQuestTargets()
    local now = GetTime()
    if availCache and (now - lastAvailScan) < AVAIL_CACHE_TTL then
        return availCache
    end
    if not LoadQuestieModules() then return {} end
    local completed = Questie.db.char.complete or {}
    local log = QuestiePlayer.currentQuestlog or {}
    local results = {}
    local candidates = {}
    if QuestieMap.questIdFrames then
        for questId in pairs(QuestieMap.questIdFrames) do candidates[questId] = true end
    end
    if not next(candidates) then
        local questData = QuestieDB.QuestPointers or QuestieDB.questData
        if questData then
            local playerLevel = QuestiePlayer.GetPlayerLevel and QuestiePlayer.GetPlayerLevel() or UnitLevel("player")
            local greenRange = GetQuestGreenRange and GetQuestGreenRange("player") or 10
            local minLevel = playerLevel - greenRange
            for questId in pairs(questData) do
                local reqLevel = QuestieDB.QueryQuestSingle(questId, "requiredLevel") or 1
                if reqLevel <= playerLevel + 3 and reqLevel >= minLevel - 5 then
                    candidates[questId] = true
                end
            end
        end
    end
    for questId in pairs(candidates) do
        if not completed[questId] and not log[questId] and QuestieDB.IsDoable(questId) then
            local spawn, zone, name, dist = GetNearestStarterForQuestId(questId)
            if spawn and dist then
                local questName = QuestieDB.QueryQuestSingle(questId, "name") or ("Quest #" .. questId)
                table.insert(results, {
                    questId = questId,
                    questName = questName,
                    mode = "available",
                    dist = dist,
                    spawn = spawn,
                    zone = zone,
                    targetName = name,
                    title = "Pick up: " .. questName,
                })
            end
        end
    end
    if #results == 0 then
        results = FindAvailableFromQuestieFrames()
        if #results == 0 and QuestieLoader then
            local ok, AvailableQuests = pcall(function() return QuestieLoader:ImportModule("AvailableQuests") end)
            if ok and AvailableQuests and AvailableQuests.CalculateAndDrawAll then
                AvailableQuests.CalculateAndDrawAll()
            end
        end
    end
    lastAvailScan = now
    availCache = results
    return results
end

local function FindActiveQuestTargets()
    if not LoadQuestieModules() or not QuestiePlayer.currentQuestlog then return {} end
    local results = {}
    for _, quest in pairs(QuestiePlayer.currentQuestlog) do
        if quest and quest.Id then
            local spawn, zone, name, _, _, dist = QuestieMap:GetNearestQuestSpawn(quest)
            if spawn and zone and dist then
                local mode = quest:IsComplete() == 1 and "turn-in" or "objective"
                table.insert(results, {
                    questId = quest.Id,
                    questName = quest.name,
                    mode = mode,
                    dist = dist,
                    spawn = spawn,
                    zone = zone,
                    targetName = name or quest.name,
                    title = (mode == "turn-in" and "Turn in: " or "") .. (name or quest.name or "Quest"),
                })
            end
        end
    end
    return results
end

local function HasIncompleteActiveQuest()
    if not QuestiePlayer or not QuestiePlayer.currentQuestlog then return false end
    for _, quest in pairs(QuestiePlayer.currentQuestlog) do
        if quest and quest.Id and quest.IsComplete and quest:IsComplete() ~= 1 then return true end
    end
    return false
end

local function CollectTrackedQuests()
    if not LoadQuestieModules() then return {} end
    local list = FindActiveQuestTargets()
    if #list == 0 and not HasIncompleteActiveQuest() then
        list = FindAvailableQuestTargets()
    end
    table.sort(list, function(a, b) return (a.dist or 999999) < (b.dist or 999999) end)
    local out = {}
    for i = 1, math.min(MAX_TRACKED, #list) do
        out[i] = list[i]
        out[i].slot = i
    end
    return out
end

local function SetTomTomWaypoint(target)
    if not TomTom or not target or not target.spawn or not target.zone then return nil end
    if Questie and Questie.db and Questie.db.char and Questie.db.char._tom_waypoint and TomTom.RemoveWaypoint then
        TomTom:RemoveWaypoint(Questie.db.char._tom_waypoint)
    end
    local uid
    local uiMapId = target.zone
    if ZoneDB and ZoneDB.GetUiMapIdByAreaId then
        uiMapId = ZoneDB:GetUiMapIdByAreaId(target.zone) or target.zone
    end
    if QuestieCompat and QuestieCompat.TomTom_AddWaypoint then
        uid = QuestieCompat.TomTom_AddWaypoint(target.title, uiMapId, target.spawn[1], target.spawn[2])
    else
        uid = TomTom:AddWaypoint(uiMapId, target.spawn[1] / 100, target.spawn[2] / 100, {
            title = target.title, crazy = true,
        })
    end
    if Questie and Questie.db and Questie.db.char then
        Questie.db.char._tom_waypoint = uid
    end
    if uid and TomTom.SetActiveWaypoint then
        TomTom:SetActiveWaypoint(uid)
        if TomTom.arrow then
            TomTom.arrow:SetFrameStrata("HIGH")
            TomTom.arrow:Show()
        end
    end
    return uid
end

local function EnsurePinFrames()
    for i = 1, MAX_TRACKED do
        if not pinFrames[i] then
            local pin = CreateFrame("Button", "P1QuestNavPin" .. i, Minimap)
            pin:SetSize(22, 22)
            pin:SetFrameStrata("TOOLTIP")
            pin.slot = i
            local bg = pin:CreateTexture(nil, "BACKGROUND")
            bg:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
            bg:SetSize(22, 22)
            bg:SetPoint("CENTER")
            pin.bg = bg
            local num = pin:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            num:SetPoint("CENTER", 0, 1)
            pin.numText = num
            pin:SetScript("OnEnter", function(self)
                local t = tracked[self.slot]
                if t then
                    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
                    GameTooltip:SetText(t.slot .. ". " .. (t.questName or "?"), 1, 1, 1)
                    GameTooltip:AddLine(t.title or "", 0.8, 0.8, 0.8)
                    if t.dist then GameTooltip:AddLine(string.format("%.0f yd", t.dist), 0.6, 0.9, 1) end
                    GameTooltip:AddLine("Click: TomTom arrow", 0.5, 1, 0.5)
                    GameTooltip:Show()
                end
            end)
            pin:SetScript("OnLeave", function() GameTooltip:Hide() end)
            pin:SetScript("OnClick", function(self)
                local t = tracked[self.slot]
                if t then SetTomTomWaypoint(t) end
            end)
            pinFrames[i] = pin
        end
    end
end

local function EnsureMinimapDots()
    if #minimapDots >= DOT_COUNT then return end
    for i = #minimapDots + 1, DOT_COUNT do
        local t = Minimap:CreateTexture(nil, "OVERLAY")
        t:SetTexture("Interface\\Buttons\\WHITE8X8")
        t:SetSize(LINE_DOT_SIZE, LINE_DOT_SIZE)
        t:Hide()
        minimapDots[i] = t
    end
end

local function EnsureWorldDots()
    if #worldDots >= DOT_COUNT then return end
    for i = #worldDots + 1, DOT_COUNT do
        local t = WorldMapFrame:CreateTexture(nil, "OVERLAY")
        t:SetTexture("Interface\\Buttons\\WHITE8X8")
        t:SetSize(LINE_DOT_SIZE + 1, LINE_DOT_SIZE + 1)
        t:Hide()
        worldDots[i] = t
    end
end

local function HideAllVisuals()
    local ast = GetAstrolabe()
    for _, pin in ipairs(pinFrames) do
        if ast then ast:RemoveIconFromMinimap(pin) end
        pin:Hide()
    end
    for _, d in ipairs(minimapDots) do d:Hide() end
    for _, d in ipairs(worldDots) do d:Hide() end
    if P1QuestNavLegend then P1QuestNavLegend:Hide() end
end

local function UpdateLegend()
    if not P1QuestNavLegend then
        local f = CreateFrame("Frame", "P1QuestNavLegend", UIParent)
        f:SetSize(220, MAX_TRACKED * 14 + 8)
        f:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 12, 130)
        f:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 10,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        f:SetBackdropColor(0.05, 0.05, 0.08, 0.75)
        f:SetBackdropBorderColor(0.25, 0.55, 0.75, 0.6)
        for i = 1, MAX_TRACKED do
            local line = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            line:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -6 - (i - 1) * 14)
            line:SetJustifyH("LEFT")
            line:SetWidth(200)
            legendLines[i] = line
        end
    end
    local shown = 0
    for i = 1, MAX_TRACKED do
        local t = tracked[i]
        local line = legendLines[i]
        if t and line then
            local r, g, b = BlendColor(t.mode, t.slot)
            line:SetText(string.format("|cff%02x%02x%02x%d|r %s",
                math.floor(r * 255), math.floor(g * 255), math.floor(b * 255),
                t.slot, TruncateName(t.questName, 26)))
            line:Show()
            shown = shown + 1
        elseif line then
            line:Hide()
        end
    end
    if shown > 0 then
        P1QuestNavLegend:SetHeight(shown * 14 + 10)
        P1QuestNavLegend:Show()
    else
        P1QuestNavLegend:Hide()
    end
end

local function UpdateMinimapLine(target)
    EnsureMinimapDots()
    local ast = GetAstrolabe()
    if not ast or not target or not target.spawn then
        for _, d in ipairs(minimapDots) do d:Hide() end
        return
    end
    local pc, pz, px, py = ast:GetCurrentPlayerPosition()
    if not pc then
        for _, d in ipairs(minimapDots) do d:Hide() end
        return
    end
    local wc, wz = AreaIdToCZ(target.zone)
    if not wc then wc, wz = pc, pz end
    local wx, wy = target.spawn[1] / 100, target.spawn[2] / 100
    if ast.TranslateWorldMapPosition then
        wx, wy = ast:TranslateWorldMapPosition(wc, wz, wx, wy, pc, pz)
    end
    local angle = math.atan2(wx - px, -(wy - py))
    local r, g, b = BlendColor(target.mode, 1)
    local radius = (Minimap:GetWidth() / 2) - 10
    for i, dot in ipairs(minimapDots) do
        local frac = i / (DOT_COUNT + 1)
        local dist = radius * frac
        dot:ClearAllPoints()
        dot:SetPoint("CENTER", Minimap, "CENTER", math.sin(angle) * dist, -math.cos(angle) * dist)
        dot:SetVertexColor(r, g, b, 0.55 + frac * 0.35)
        dot:Show()
    end
end

local function UpdateWorldMapLine(target)
    EnsureWorldDots()
    if not WorldMapFrame:IsShown() or not target or not target.spawn then
        for _, d in ipairs(worldDots) do d:Hide() end
        return
    end
    local ast = GetAstrolabe()
    if not ast then return end
    local pc, pz, px, py = ast:GetCurrentPlayerPosition()
    if not pc then return end
    local wc, wz = AreaIdToCZ(target.zone)
    if not wc then wc, wz = pc, pz end
    local wx, wy = target.spawn[1] / 100, target.spawn[2] / 100
    if ast.TranslateWorldMapPosition then
        wx, wy = ast:TranslateWorldMapPosition(wc, wz, wx, wy, pc, pz)
    end
    local C, Z = GetCurrentMapContinent(), GetCurrentMapZone()
    local nPx, nPy = ast:TranslateWorldMapPosition(pc, pz, px, py, C, Z)
    local nWx, nWy = ast:TranslateWorldMapPosition(pc, pz, wx, wy, C, Z)
    if not nPx or not nWx then
        for _, d in ipairs(worldDots) do d:Hide() end
        return
    end
    local r, g, b = BlendColor(target.mode, 1)
    local w, h = WorldMapButton:GetWidth(), WorldMapButton:GetHeight()
    for i, dot in ipairs(worldDots) do
        local frac = i / (DOT_COUNT + 1)
        local x = nPx + (nWx - nPx) * frac
        local y = nPy + (nWy - nPy) * frac
        dot:ClearAllPoints()
        dot:SetPoint("CENTER", WorldMapButton, "TOPLEFT", x * w, -y * h)
        dot:SetVertexColor(r, g, b, 0.5 + frac * 0.4)
        dot:Show()
    end
end

local function UpdatePins()
    EnsurePinFrames()
    local ast = GetAstrolabe()
    if not ast then return end
    for i = 1, MAX_TRACKED do
        local pin = pinFrames[i]
        local t = tracked[i]
        if t and t.spawn and t.zone then
            local wc, wz = AreaIdToCZ(t.zone)
            if wc then
                local r, g, b = BlendColor(t.mode, i)
                pin.numText:SetText(tostring(i))
                pin.numText:SetTextColor(r, g, b)
                pin.bg:SetVertexColor(r, g, b)
                local xPos, yPos = t.spawn[1] / 100, t.spawn[2] / 100
                ast:PlaceIconOnMinimap(pin, wc, wz, xPos, yPos)
            else
                ast:RemoveIconFromMinimap(pin)
                pin:Hide()
            end
        else
            ast:RemoveIconFromMinimap(pin)
            pin:Hide()
        end
    end
end

function P1QuestNav_Refresh(force)
    if not IsNavEnabled() then
        HideAllVisuals()
        tracked = {}
        return
    end

    local now = GetTime()
    if not force and (now - lastRefresh) < REFRESH_THROTTLE then return end
    lastRefresh = now
    if force then availCache = nil end

    tracked = CollectTrackedQuests()
    UpdatePins()
    UpdateLegend()

    if tracked[1] then
        UpdateMinimapLine(tracked[1])
        UpdateWorldMapLine(tracked[1])
        SetTomTomWaypoint(tracked[1])
    else
        for _, d in ipairs(minimapDots) do d:Hide() end
        for _, d in ipairs(worldDots) do d:Hide() end
    end

    if debugMode then
        print("|cff00ccffP1 Nav|r tracked: " .. #tracked)
        for i, t in ipairs(tracked) do
            print(string.format("  %d. %s (%.0f yd, %s)", i, t.questName or "?", t.dist or 0, t.mode or "?"))
        end
    end
end

function P1QuestNav_SetEnabled(on)
    enabled = on and true or false
    P1QuestNavDB.enabled = enabled
    if on then
        P1QuestNav_Refresh(true)
    else
        HideAllVisuals()
        tracked = {}
    end
end

function P1QuestNav_GetStatus()
    return {
        enabled = enabled and IsAutoQuestOn(),
        navOn = enabled,
        autoOn = IsAutoQuestOn(),
        tracked = tracked,
        questieLoaded = LoadQuestieModules(),
        astrolabeLoaded = not not GetAstrolabe(),
        tomtomLoaded = not not (TomTom and TomTom.AddWaypoint),
    }
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
eventFrame:RegisterEvent("QUEST_ACCEPTED")
eventFrame:RegisterEvent("QUEST_COMPLETE")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        enabled = P1QuestNavDB.enabled ~= false
        local elapsed = 0
        self:SetScript("OnUpdate", function(f, e)
            elapsed = elapsed + e
            if elapsed >= 4 then
                f:SetScript("OnUpdate", nil)
                if IsNavEnabled() then P1QuestNav_Refresh(true) end
            end
        end)
        return
    end
    if event == "QUEST_ACCEPTED" or event == "QUEST_LOG_UPDATE" or event == "QUEST_COMPLETE" then
        availCache = nil
    end
    if event == "PLAYER_ENTERING_WORLD" then
        local t = 0
        self:SetScript("OnUpdate", function(f, e)
            t = t + e
            if t >= 5 then
                f:SetScript("OnUpdate", nil)
                if IsNavEnabled() then P1QuestNav_Refresh(true) end
            end
        end)
        return
    end
    if IsNavEnabled() then P1QuestNav_Refresh(false) end
end)

local tickFrame = CreateFrame("Frame")
tickFrame:SetScript("OnUpdate", function()
    if not IsNavEnabled() then return end
    local now = GetTime()
    if now - lastRescan >= REFRESH_INTERVAL then
        lastRescan = now
        P1QuestNav_Refresh(false)
    end
end)

WorldMapFrame:HookScript("OnShow", function()
    if IsNavEnabled() and tracked[1] then UpdateWorldMapLine(tracked[1]) end
end)

SLASH_P1NAV1 = "/p1nav"
SlashCmdList["P1NAV"] = function(msg)
    msg = string.lower(strtrim and strtrim(msg) or (msg or ""):match("^%s*(.-)%s*$") or "")
    if msg == "debug" then
        debugMode = not debugMode
        print("|cff00ccffP1 Nav|r debug " .. (debugMode and "|cff00ff00ON|r" or "OFF"))
        P1QuestNav_Refresh(true)
        return
    end
    if msg == "on" or msg == "off" then
        P1QuestNav_SetEnabled(msg == "on")
    else
        P1QuestNav_SetEnabled(not enabled)
    end
    local s = P1QuestNav_GetStatus()
    print("|cff00ccffP1 Nav|r v1.2.2 — " .. (s.enabled and "|cff00ff00ON|r" or "|cffaaaaaaOFF|r"))
    print("  Tracked: " .. #s.tracked .. " quest arrows · dotted line to #1")
    print("  Click minimap pin to switch TomTom arrow")
end
