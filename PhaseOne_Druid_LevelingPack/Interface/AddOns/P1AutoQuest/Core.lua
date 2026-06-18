-- P1AutoQuest — Questie auto arrow + gentle idle click-to-move (Warmane 3.3.5a)
-- Scope: accept/turn-in (Questie) + TomTom arrow + walk when idle. Not full autopilot.

local IDLE_SECONDS = 3
local MOVE_INTERVAL = 2.5
local MOVE_MIN_DIST = 10
local MOVE_MAX_DIST = 800
local REFRESH_THROTTLE = 0.4

local enabled = true
local lastRefresh = 0
local lastMove = 0
local idleSince = GetTime()
local ourMoveUntil = 0
local status = {
    enabled = true,
    questId = nil,
    questName = nil,
    mode = nil,
    dist = nil,
    waypoint = nil,
    lastRefresh = 0,
    autoMove = false,
}

local QuestieDB, QuestieMap, QuestiePlayer, QuestieCompat

local function GetAstrolabe()
    if DongleStub then
        local ok, lib = pcall(DongleStub, "Astrolabe-1.0")
        if ok and lib then return lib end
    end
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

local function LoadQuestieModules()
    if QuestieDB and QuestieMap and QuestiePlayer then return true end
    if not QuestieLoader or not QuestieLoader.ImportModule then return false end
    local ok
    ok, QuestieDB = pcall(function() return QuestieLoader:ImportModule("QuestieDB") end)
    if not ok or not QuestieDB then return false end
    ok, QuestieMap = pcall(function() return QuestieLoader:ImportModule("QuestieMap") end)
    if not ok or not QuestieMap then return false end
    ok, QuestiePlayer = pcall(function() return QuestieLoader:ImportModule("QuestiePlayer") end)
    if not ok or not QuestiePlayer then return false end
    QuestieCompat = _G.QuestieCompat
    return Questie and Questie.db and Questie.db.profile
end

local function SetTomTomWaypoint(title, areaId, x, y)
    if not TomTom or not TomTom.AddWaypoint then return nil end
    if Questie and Questie.db and Questie.db.char and Questie.db.char._tom_waypoint and TomTom.RemoveWaypoint then
        TomTom:RemoveWaypoint(Questie.db.char._tom_waypoint)
    end
    local uid
    local uiMapId = areaId
    if QuestieLoader then
        local ok, ZoneDB = pcall(function() return QuestieLoader:ImportModule("ZoneDB") end)
        if ok and ZoneDB and ZoneDB.GetUiMapIdByAreaId then
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

local function FindBestQuestTarget()
    if not LoadQuestieModules() then return nil end
    if not QuestiePlayer.currentQuestlog then return nil end

    local bestQuest, bestSpawn, bestZone, bestName, bestDist, bestMode

    for questId, quest in pairs(QuestiePlayer.currentQuestlog) do
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

    return {
        questId = bestQuest.Id,
        questName = bestQuest.name,
        mode = bestMode,
        dist = bestDist,
        spawn = bestSpawn,
        zone = bestZone,
        title = (bestMode == "turn-in" and "Turn in: " or "") .. (bestName or bestQuest.name or "Quest"),
    }
end

function P1AutoQuest_Refresh(force)
    if not IsAutoQuestOn() then
        status.autoMove = false
        return false
    end

    local now = GetTime()
    if not force and (now - lastRefresh) < REFRESH_THROTTLE then return false end
    lastRefresh = now

    local target = FindBestQuestTarget()
    if not target then
        status.questId = nil
        status.questName = nil
        status.mode = nil
        status.dist = nil
        status.waypoint = nil
        status.lastRefresh = now
        return false
    end

    local uid = SetTomTomWaypoint(target.title, target.zone, target.spawn[1], target.spawn[2])
    status.enabled = IsAutoQuestOn()
    status.questId = target.questId
    status.questName = target.questName
    status.mode = target.mode
    status.dist = target.dist
    status.waypoint = uid
    status.lastRefresh = now
    return true
end

function P1AutoQuest_SetEnabled(on)
    enabled = on and true or false
    status.enabled = enabled
    if on then
        P1AutoQuest_Refresh(true)
    else
        status.autoMove = false
    end
end

function P1AutoQuest_GetStatus()
    status.enabled = IsAutoQuestOn()
    return status
end

local function ResetIdleTimer()
    idleSince = GetTime()
    status.autoMove = false
end

local function TryAutoMove()
    status.enabled = IsAutoQuestOn()
    if not status.enabled then return end
    if UnitAffectingCombat("player") then return end
    if UnitCastingInfo("player") or UnitChannelInfo("player") then return end
    if IsMouseButtonDown("LeftButton") or IsMouseButtonDown("RightButton") then
        ResetIdleTimer()
        return
    end

    local now = GetTime()
    if now - idleSince < IDLE_SECONDS then return end
    if now - lastMove < MOVE_INTERVAL then return end

    local wp = TomTom and TomTom.GetActiveWaypoint and TomTom:GetActiveWaypoint()
    if not wp or not wp.x or not wp.y then return end

    local ast = GetAstrolabe()
    if not ast or not ast.GetCurrentPlayerPosition or not ast.ComputeDistance then return end

    local pc, pz, px, py = ast:GetCurrentPlayerPosition()
    if not pc then return end

    local wc, wz, wx, wy = wp.c or pc, wp.z or pz, wp.x, wp.y
    if ast.TranslateWorldMapPosition then
        wx, wy = ast:TranslateWorldMapPosition(wc, wz, wx, wy, pc, pz)
    end

    local dist = ast:ComputeDistance(pc, pz, px, py, pc, pz, wx, wy)
    if not dist or dist < MOVE_MIN_DIST or dist > MOVE_MAX_DIST then return end

    local step = 0.82
    local tx = px + (wx - px) * step
    local ty = py + (wy - py) * step

    ourMoveUntil = now + 1.2
    ClickToMove(tx, ty)
    lastMove = now
    status.autoMove = true
    status.dist = dist
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
moveFrame:SetScript("OnUpdate", function(_, elapsed)
    if not IsAutoQuestOn() then return end
    TryAutoMove()
end)

SLASH_P1QUEST1 = "/p1quest"
SlashCmdList["P1QUEST"] = function()
    local s = P1AutoQuest_GetStatus()
    local on = s.enabled and "|cff00ff00ON|r" or "|cffaaaaaaOFF|r"
    print("|cff00ccffP1 Auto Quest|r — " .. on)
    if s.questName then
        print("  Quest: " .. (s.questName or "?") .. " (#" .. tostring(s.questId or "?") .. ")")
        print("  Mode: " .. (s.mode or "?") .. " | dist: " .. string.format("%.0f", s.dist or 0) .. " yd")
        print("  Auto-move: " .. (s.autoMove and "active" or "idle/waiting"))
    else
        print("  No active quest target (Questie log empty or no coords).")
    end
    print("  |cffaaaaaaScope:|r accept/turn-in (Questie) + arrow + walk when idle 3s+")
end
