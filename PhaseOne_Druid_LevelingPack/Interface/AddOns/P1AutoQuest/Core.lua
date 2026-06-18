-- P1AutoQuest — Questie auto arrow + gentle idle click-to-move (Warmane 3.3.5a)
-- Phases: available pickup → objectives → turn-in. Not full autopilot.

local IDLE_SECONDS = 3
local MOVE_INTERVAL = 2.5
local MOVE_MIN_DIST = 10
local MOVE_MAX_DIST = 800
local REFRESH_THROTTLE = 0.4
local AVAIL_CACHE_TTL = 5
local INTERACT_RANGE = 10
local INTERACT_COOLDOWN = 3

local enabled = true
local lastRefresh = 0
local lastMove = 0
local lastInteract = 0
local idleSince = GetTime()
local ourMoveUntil = 0
local lastAvailScan = 0
local availCache = nil
local promptedAtGiver = false

local status = {
    enabled = true,
    questId = nil,
    questName = nil,
    mode = nil,
    dist = nil,
    waypoint = nil,
    lastRefresh = 0,
    autoMove = false,
    questieLoaded = false,
    tomtomLoaded = false,
    astrolabeLoaded = false,
    targetName = nil,
    coordX = nil,
    coordY = nil,
    zoneId = nil,
    whyNotMoving = nil,
    activeQuestCount = 0,
}

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
    if _G.P1_IsAutoQuestEnabled then
        return P1_IsAutoQuestEnabled()
    end
    if PhaseOneLoaderDB and PhaseOneLoaderDB.autoQuestEnabled ~= nil then
        return PhaseOneLoaderDB.autoQuestEnabled
    end
    if PhaseOneDruidLoaderDB and PhaseOneDruidLoaderDB.autoQuestEnabled ~= nil then
        return PhaseOneDruidLoaderDB.autoQuestEnabled
    end
    return enabled
end

local function UpdateDepStatus()
    status.questieLoaded = LoadQuestieModules()
    status.tomtomLoaded = not not (TomTom and TomTom.AddWaypoint)
    status.astrolabeLoaded = not not GetAstrolabe()
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

local function InvalidateAvailCache()
    availCache = nil
    lastAvailScan = 0
    promptedAtGiver = false
end

local function CountActiveQuests()
    if not QuestiePlayer or not QuestiePlayer.currentQuestlog then return 0 end
    local n = 0
    for _ in pairs(QuestiePlayer.currentQuestlog) do n = n + 1 end
    return n
end

local function HasIncompleteActiveQuest()
    if not QuestiePlayer or not QuestiePlayer.currentQuestlog then return false end
    for _, quest in pairs(QuestiePlayer.currentQuestlog) do
        if quest and quest.Id and quest.IsComplete and quest:IsComplete() ~= 1 then
            return true
        end
    end
    return false
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
                if dInstance ~= playerI then
                    dist = 500000 + dist * 100
                end
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

local function FindAvailableQuestTarget()
    local now = GetTime()
    if availCache and (now - lastAvailScan) < AVAIL_CACHE_TTL then
        return availCache
    end

    if not LoadQuestieModules() then return nil end

    local completed = Questie.db.char.complete or {}
    local log = QuestiePlayer.currentQuestlog or {}
    local bestDist, bestQuestId, bestSpawn, bestZone, bestName

    local candidates = {}
    if QuestieMap.questIdFrames then
        for questId in pairs(QuestieMap.questIdFrames) do
            candidates[questId] = true
        end
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
            if spawn and dist and (not bestDist or dist < bestDist) then
                bestDist = dist
                bestQuestId = questId
                bestSpawn = spawn
                bestZone = zone
                bestName = name
            end
        end
    end

    lastAvailScan = now
    if not bestQuestId then
        availCache = nil
        return nil
    end

    local questName = QuestieDB.QueryQuestSingle(bestQuestId, "name") or ("Quest #" .. bestQuestId)
    local title = "Pick up: " .. questName
    if bestName then title = title .. " (" .. bestName .. ")" end

    availCache = {
        questId = bestQuestId,
        questName = questName,
        mode = "available",
        dist = bestDist,
        spawn = bestSpawn,
        zone = bestZone,
        targetName = bestName,
        title = title,
    }
    return availCache
end

local function FindActiveQuestTarget()
    if not LoadQuestieModules() then return nil end
    if not QuestiePlayer.currentQuestlog then return nil end

    local bestQuest, bestSpawn, bestZone, bestName, bestDist, bestMode

    for _, quest in pairs(QuestiePlayer.currentQuestlog) do
        if quest and quest.Id then
            local spawn, zone, name, _, _, dist = QuestieMap:GetNearestQuestSpawn(quest)
            if spawn and zone and dist and (not bestDist or dist < bestDist) then
                bestDist = dist
                bestQuest = quest
                bestSpawn = spawn
                bestZone = zone
                bestName = name or quest.name
                if quest:IsComplete() == 1 then
                    bestMode = "turn-in"
                else
                    bestMode = "objective"
                end
            end
        end
    end

    if not bestQuest or not bestSpawn then return nil end

    local title = (bestMode == "turn-in" and "Turn in: " or "") .. (bestName or bestQuest.name or "Quest")
    return {
        questId = bestQuest.Id,
        questName = bestQuest.name,
        mode = bestMode,
        dist = bestDist,
        spawn = bestSpawn,
        zone = bestZone,
        targetName = bestName,
        title = title,
    }
end

local function FindBestQuestTarget()
    status.activeQuestCount = CountActiveQuests()

    local target = FindActiveQuestTarget()
    if target then return target end

    if not HasIncompleteActiveQuest() then
        return FindAvailableQuestTarget()
    end

    return nil
end

local function SetTomTomWaypoint(title, areaId, x, y)
    if not TomTom or not TomTom.AddWaypoint then return nil end
    if Questie and Questie.db and Questie.db.char and Questie.db.char._tom_waypoint and TomTom.RemoveWaypoint then
        TomTom:RemoveWaypoint(Questie.db.char._tom_waypoint)
    end
    local uid
    local uiMapId = areaId
    if ZoneDB and ZoneDB.GetUiMapIdByAreaId then
        uiMapId = ZoneDB:GetUiMapIdByAreaId(areaId)
    elseif QuestieLoader then
        local ok, zdb = pcall(function() return QuestieLoader:ImportModule("ZoneDB") end)
        if ok and zdb and zdb.GetUiMapIdByAreaId then
            ZoneDB = zdb
            uiMapId = ZoneDB:GetUiMapIdByAreaId(areaId)
        end
    end
    if QuestieCompat and QuestieCompat.Is335 and QuestieCompat.TomTom_AddWaypoint then
        uid = QuestieCompat.TomTom_AddWaypoint(title, uiMapId, x, y)
    else
        uid = TomTom:AddWaypoint(uiMapId, x / 100, y / 100, { title = title, crazy = true })
    end
    if Questie and Questie.db and Questie.db.char then
        Questie.db.char._tom_waypoint = uid
    end
    return uid
end

function P1AutoQuest_Refresh(force)
    UpdateDepStatus()

    if not IsAutoQuestOn() then
        status.autoMove = false
        status.whyNotMoving = "Auto Q off"
        return false
    end

    local now = GetTime()
    if not force and (now - lastRefresh) < REFRESH_THROTTLE then return false end
    lastRefresh = now

    if force then InvalidateAvailCache() end

    local target = FindBestQuestTarget()
    if not target then
        status.questId = nil
        status.questName = nil
        status.mode = nil
        status.dist = nil
        status.waypoint = nil
        status.targetName = nil
        status.coordX = nil
        status.coordY = nil
        status.zoneId = nil
        status.lastRefresh = now
        if not status.questieLoaded then
            status.whyNotMoving = "Questie not loaded yet"
        elseif status.activeQuestCount == 0 then
            status.whyNotMoving = "No available quest found (Questie still scanning?)"
        else
            status.whyNotMoving = "Active quest has no coords"
        end
        return false
    end

    promptedAtGiver = false
    local uid = SetTomTomWaypoint(target.title, target.zone, target.spawn[1], target.spawn[2])
    status.enabled = IsAutoQuestOn()
    status.questId = target.questId
    status.questName = target.questName
    status.mode = target.mode
    status.dist = target.dist
    status.waypoint = uid
    status.targetName = target.targetName
    status.coordX = target.spawn[1]
    status.coordY = target.spawn[2]
    status.zoneId = target.zone
    status.lastRefresh = now
    if not uid then
        status.whyNotMoving = "TomTom waypoint failed"
    elseif not status.astrolabeLoaded then
        status.whyNotMoving = "Astrolabe missing (no auto-walk)"
    else
        status.whyNotMoving = "waiting idle " .. IDLE_SECONDS .. "s"
    end
    return true
end

function P1AutoQuest_SetEnabled(on)
    enabled = on and true or false
    status.enabled = enabled
    if on then
        P1AutoQuest_Refresh(true)
    else
        status.autoMove = false
        status.whyNotMoving = "Auto Q off"
    end
end

function P1AutoQuest_GetStatus()
    status.enabled = IsAutoQuestOn()
    UpdateDepStatus()
    return status
end

local function ResetIdleTimer()
    idleSince = GetTime()
    status.autoMove = false
end

local function TryQuestGiverInteract()
    if status.mode ~= "available" or not status.targetName then return end
    if not status.dist or status.dist > INTERACT_RANGE then return end

    local now = GetTime()
    if now - lastInteract < INTERACT_COOLDOWN then return end

    if TargetByName then
        TargetByName(status.targetName, true)
    end

    if UnitExists("target") and CheckInteractDistance("target", 3) then
        if InteractUnit then
            pcall(InteractUnit, "target")
        elseif not promptedAtGiver then
            print("|cff00ccffP1 Auto Quest|r — at |cff00ff00" .. status.targetName .. "|r — interact to accept")
            promptedAtGiver = true
        end
        lastInteract = now
    end
end

local function TryAutoMove()
    status.enabled = IsAutoQuestOn()
    if not status.enabled then
        status.whyNotMoving = "Auto Q off"
        return
    end
    if UnitAffectingCombat("player") then
        status.whyNotMoving = "in combat"
        return
    end
    if UnitCastingInfo("player") or UnitChannelInfo("player") then
        status.whyNotMoving = "casting"
        return
    end
    if IsMouseButtonDown("LeftButton") or IsMouseButtonDown("RightButton") then
        ResetIdleTimer()
        status.whyNotMoving = "mouse held"
        return
    end

    local now = GetTime()
    if now - idleSince < IDLE_SECONDS then
        status.whyNotMoving = string.format("idle %.1fs / %ds", now - idleSince, IDLE_SECONDS)
        return
    end
    if now - lastMove < MOVE_INTERVAL then
        status.whyNotMoving = "move cooldown"
        return
    end

    if not TomTom or not TomTom.GetActiveWaypoint then
        status.whyNotMoving = "TomTom missing"
        return
    end

    local wp = TomTom:GetActiveWaypoint()
    if not wp or not wp.x or not wp.y then
        status.whyNotMoving = "no TomTom waypoint"
        return
    end

    local ast = GetAstrolabe()
    if not ast or not ast.GetCurrentPlayerPosition or not ast.ComputeDistance then
        status.whyNotMoving = "Astrolabe missing"
        return
    end

    local pc, pz, px, py = ast:GetCurrentPlayerPosition()
    if not pc then
        status.whyNotMoving = "player position unknown"
        return
    end

    local wc, wz, wx, wy = wp.c or pc, wp.z or pz, wp.x, wp.y
    if ast.TranslateWorldMapPosition then
        wx, wy = ast:TranslateWorldMapPosition(wc, wz, wx, wy, pc, pz)
    end

    local dist = ast:ComputeDistance(pc, pz, px, py, pc, pz, wx, wy)
    status.dist = dist

    if not dist or dist < MOVE_MIN_DIST then
        status.whyNotMoving = dist and "at destination" or "distance unknown"
        TryQuestGiverInteract()
        return
    end
    if dist > MOVE_MAX_DIST then
        status.whyNotMoving = string.format("too far (%.0f yd)", dist)
        return
    end

    local step = 0.82
    local tx = px + (wx - px) * step
    local ty = py + (wy - py) * step

    ourMoveUntil = now + 1.2
    ClickToMove(tx, ty)
    lastMove = now
    status.autoMove = true
    status.whyNotMoving = nil
end

local function CreateAutoQuestToggle()
    if _G.P1AutoQuestToggleBtn then return end
    local btn = CreateFrame("Button", "P1AutoQuestToggleBtn", UIParent)
    btn:SetSize(48, 18)
    btn:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -8, -8)
    btn:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    btn:SetBackdropColor(0.05, 0.05, 0.08, 0.85)
    btn:SetBackdropBorderColor(0.3, 0.6, 0.85, 0.8)
    local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    txt:SetPoint("CENTER")
    txt:SetText("Auto Q")
    btn.text = txt
    btn:SetScript("OnClick", function()
        if P1_AutoQuest_Toggle then P1_AutoQuest_Toggle() end
    end)
    P1AutoQuestButtons = P1AutoQuestButtons or {}
    P1AutoQuestButtons[#P1AutoQuestButtons + 1] = btn
    if P1_AutoQuest_RefreshButtons then P1_AutoQuest_RefreshButtons() end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
eventFrame:RegisterEvent("QUEST_ACCEPTED")
eventFrame:RegisterEvent("QUEST_COMPLETE")
eventFrame:RegisterEvent("GOSSIP_SHOW")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_STARTED_MOVING")
eventFrame:RegisterEvent("START_AUTORUN")
eventFrame:RegisterEvent("STOP_AUTORUN")
eventFrame:RegisterEvent("UNIT_SPELLCAST_START")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_LOGIN" then
        CreateAutoQuestToggle()
        local elapsed = 0
        self:SetScript("OnUpdate", function(f, e)
            elapsed = elapsed + e
            if elapsed >= 3 then
                f:SetScript("OnUpdate", nil)
                enabled = IsAutoQuestOn()
                P1AutoQuest_Refresh(true)
            end
        end)
        return
    end

    if event == "QUEST_ACCEPTED" or event == "QUEST_LOG_UPDATE" or event == "QUEST_COMPLETE" then
        InvalidateAvailCache()
    end

    if event == "PLAYER_REGEN_DISABLED" then
        ResetIdleTimer()
        return
    end

    if event == "PLAYER_STARTED_MOVING" then
        if GetTime() > ourMoveUntil then ResetIdleTimer() end
        return
    end

    if event == "START_AUTORUN" or event == "STOP_AUTORUN" then
        ResetIdleTimer()
        return
    end

    if event == "UNIT_SPELLCAST_START" and arg1 == "player" then
        if GetTime() > ourMoveUntil then ResetIdleTimer() end
        return
    end

    if IsAutoQuestOn() then
        P1AutoQuest_Refresh(false)
    end
end)

local moveFrame = CreateFrame("Frame")
moveFrame:SetScript("OnUpdate", function()
    if not IsAutoQuestOn() then return end
    TryAutoMove()
end)

SLASH_P1QUEST1 = "/p1quest"
SlashCmdList["P1QUEST"] = function()
    P1AutoQuest_Refresh(true)
    local s = P1AutoQuest_GetStatus()
    local on = s.enabled and "|cff00ff00ON|r" or "|cffaaaaaaOFF|r"
    print("|cff00ccffP1 Auto Quest|r v1.2.0 — " .. on)
    print("  Questie: " .. (s.questieLoaded and "|cff00ff00loaded|r" or "|cffff0000MISSING|r"))
    print("  TomTom:  " .. (s.tomtomLoaded and "|cff00ff00loaded|r" or "|cffff0000MISSING|r"))
    print("  Astrolabe: " .. (s.astrolabeLoaded and "|cff00ff00loaded|r" or "|cffff0000MISSING|r"))
    print("  Active quests in log: " .. tostring(s.activeQuestCount or 0))
    print("  Mode: " .. (s.mode or "|cffaaaaaanone|r"))
    if s.questName then
        print("  Target quest: " .. s.questName .. " (#" .. tostring(s.questId or "?") .. ")")
    end
    if s.targetName then
        print("  Target NPC/object: " .. s.targetName)
    end
    if s.coordX and s.coordY then
        print(string.format("  Coords: %.1f, %.1f (zone %s)", s.coordX, s.coordY, tostring(s.zoneId or "?")))
    end
    print("  Distance: " .. string.format("%.0f", s.dist or 0) .. " yd")
    print("  Waypoint: " .. (s.waypoint and "set" or "|cffff0000none|r"))
    print("  Auto-move: " .. (s.autoMove and "|cff00ff00active|r" or "idle/waiting"))
    print("  Why not moving: " .. (s.whyNotMoving or "|cff00ff00ok|r"))
    print("  |cffaaaaaaScope:|r pickup (!) + objectives + turn-in; accept via Questie gossip")
end
