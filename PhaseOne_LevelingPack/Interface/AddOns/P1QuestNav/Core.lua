-- P1QuestNav — visual multi-quest navigation (Warmane 3.3.5a)
-- Numbered minimap pins, exp/min ranking, dotted path to #1, TomTom arrow.

P1QuestNavDB = P1QuestNavDB or { enabled = true }

local MAX_TRACKED = 5
local REFRESH_INTERVAL = 1.5
local REFRESH_THROTTLE = 0.35
local AVAIL_CACHE_TTL = 3
local DOT_COUNT = 12
local LINE_DOT_SIZE = 6
local PIN_SIZE = 28
local RUN_SPEED = 7
local KILL_SEC_PER_OBJ = 30

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

local VERSION = "1.4.0"

local function SyncLoaderNav(on)
    if PhaseOneLoaderDB then PhaseOneLoaderDB.navEnabled = on end
    if PhaseOneDruidLoaderDB then PhaseOneDruidLoaderDB.navEnabled = on end
end

local function ReadNavEnabled()
    if PhaseOneLoaderDB and PhaseOneLoaderDB.navEnabled ~= nil then
        return PhaseOneLoaderDB.navEnabled
    end
    if PhaseOneDruidLoaderDB and PhaseOneDruidLoaderDB.navEnabled ~= nil then
        return PhaseOneDruidLoaderDB.navEnabled
    end
    return P1QuestNavDB.enabled ~= false
end

local enabled = ReadNavEnabled()
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
local legendDots = {}
local worldBadges = {}
local nextLineFrame, nextLineText
local lastTomPrimaryId = nil
local lastTomZoneId = nil
local primaryPlacement = "none"
local areaIdFallbackLogged = {}

local QuestieDB, QuestieMap, QuestiePlayer, QuestieCompat, ZoneDB, QuestXP, HBD
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
    return enabled
end

local function BlendColor(mode, slot)
    local mc = MODE_COLORS[mode] or MODE_COLORS.objective
    local sc = SLOT_HUES[slot] or SLOT_HUES[1]
    return (mc[1] + sc[1]) * 0.5, (mc[2] + sc[2]) * 0.5, (mc[3] + sc[3]) * 0.5
end

local function ColorHex(r, g, b)
    return string.format("|cff%02x%02x%02x", math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))
end

local function TruncateName(name, maxLen)
    if not name then return "?" end
    if #name <= maxLen then return name end
    return string.sub(name, 1, maxLen - 1) .. "…"
end

local function GetDirectionLabel(entry)
    local hbd = GetHBD()
    if not hbd or not entry or not entry.spawn or not entry.zone then
        return entry and entry.dist and string.format("%dy", entry.dist) or ""
    end
    local px, py = hbd:GetPlayerWorldPosition()
    if not px then return string.format("%dy", entry.dist or 0) end
    local uiMapId = entry.zone
    if ZoneDB and ZoneDB.GetUiMapIdByAreaId then
        uiMapId = ZoneDB:GetUiMapIdByAreaId(entry.zone) or entry.zone
    end
    local dx, dy = hbd:GetWorldCoordinatesFromZone(entry.spawn[1] / 100, entry.spawn[2] / 100, uiMapId)
    if not dx then return string.format("%dy", entry.dist or 0) end
    local angle = math.atan2(dy - py, dx - px)
    local deg = math.deg(angle)
    if deg < 0 then deg = deg + 360 end
    local dirs = { "E", "NE", "N", "NW", "W", "SW", "S", "SE" }
    local idx = math.floor((deg + 22.5) / 45) % 8 + 1
    return string.format("%dy %s", entry.dist or 0, dirs[idx])
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
    if not QuestXP then
        ok, QuestXP = pcall(function() return QuestieLoader:ImportModule("QuestXP") end)
        if not ok then QuestXP = nil end
    end
    QuestieCompat = _G.QuestieCompat
    GetHBD()
    return Questie and Questie.db and Questie.db.profile
end

local function AreaIdToCZ(areaId)
    if not areaId then return nil, nil end
    if QuestieCompat and QuestieCompat.AreaIdToCZ then
        local c, z = QuestieCompat.AreaIdToCZ(areaId)
        if c then return c, z end
    end
    if debugMode and not areaIdFallbackLogged[areaId] then
        areaIdFallbackLogged[areaId] = true
        print(string.format("|cff00ccffP1 Nav|r AreaIdToCZ miss for zone %s — using world coords for edge pin",
            tostring(areaId)))
    end
    return nil, nil
end

local function ClearTomTomWaypoint()
    if Questie and Questie.db and Questie.db.char and Questie.db.char._tom_waypoint then
        if TomTom and TomTom.RemoveWaypoint then
            TomTom:RemoveWaypoint(Questie.db.char._tom_waypoint)
        end
        Questie.db.char._tom_waypoint = nil
    end
    if TomTom and TomTom.SetActiveWaypoint then
        TomTom:SetActiveWaypoint(nil)
    end
end

local function GetQuestXP(questId)
    if QuestXP and QuestXP.GetQuestLogRewardXP then
        local xp = QuestXP:GetQuestLogRewardXP(questId, true)
        if xp and xp > 0 then return xp end
    end
    if QuestieDB and QuestieDB.QueryQuestSingle then
        local lvl = QuestieDB.QueryQuestSingle(questId, "questLevel") or 1
        if QuestXP and QuestXP.db and QuestXP.db[questId] then
            return QuestXP:GetQuestLogRewardXP(questId, true)
        end
    end
    for i = 1, GetNumQuestLogEntries() do
        local _, _, _, _, _, _, _, qid = GetQuestLogTitle(i)
        if qid == questId then
            SelectQuestLogEntry(i)
            local xp = GetQuestLogRewardXP()
            if xp and xp > 0 then return xp end
            break
        end
    end
    return 0
end

local function GetQuestProgress(questId)
    for i = 1, GetNumQuestLogEntries() do
        local title, _, _, _, _, complete, _, qid = GetQuestLogTitle(i)
        if qid == questId then
            SelectQuestLogEntry(i)
            local num = GetNumQuestLeaderBoards()
            if num == 0 then
                if complete == 1 or complete == -1 then return "done", 0 end
                return "?", 1
            end
            local remaining = 0
            local parts = {}
            for j = 1, num do
                local text, _, finished = GetQuestLogLeaderBoard(j)
                if finished then
                    parts[#parts + 1] = text or "?"
                else
                    remaining = remaining + 1
                    local cur, need = string.match(text or "", "(%d+)/(%d+)")
                    if cur and need then
                        parts[#parts + 1] = cur .. "/" .. need
                    else
                        parts[#parts + 1] = text or "?"
                    end
                end
            end
            return table.concat(parts, ", "), remaining
        end
    end
    return "", 2
end

local function ScoreQuest(entry)
    local xp = GetQuestXP(entry.questId)
    if entry.mode == "available" and xp == 0 then
        local lvl = QuestieDB and QuestieDB.QueryQuestSingle(entry.questId, "questLevel") or 5
        xp = math.max(50, lvl * 40)
    end
    local dist = entry.dist or 500
    local travelTime = dist / RUN_SPEED
    local prog, remaining = GetQuestProgress(entry.questId)
    if entry.mode == "available" then remaining = 2 end
    if entry.mode == "turn-in" then remaining = 0 end
    local killTime = remaining * KILL_SEC_PER_OBJ
    local totalTime = math.max(15, travelTime + killTime)
    local score = xp / totalTime
    entry.xp = xp
    entry.progress = prog
    entry.remainingObjs = remaining
    entry.travelTime = travelTime
    entry.killTime = killTime
    entry.score = score
    return score
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
    for _, entry in ipairs(list) do
        ScoreQuest(entry)
    end
    table.sort(list, function(a, b) return (a.score or 0) > (b.score or 0) end)
    local out = {}
    for i = 1, math.min(MAX_TRACKED, #list) do
        out[i] = list[i]
        out[i].slot = i
        out[i].dirLabel = GetDirectionLabel(list[i])
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

local function GetMinimapParent()
    return MinimapCluster or Minimap
end

local function EnsurePinFrames()
    local parent = Minimap
    for i = 1, MAX_TRACKED do
        if not pinFrames[i] then
            local pin = CreateFrame("Button", "P1QuestNavPin" .. i, parent)
            pin:SetSize(PIN_SIZE, PIN_SIZE)
            pin:SetFrameStrata("FULLSCREEN_DIALOG")
            pin:SetFrameLevel(parent:GetFrameLevel() + 30 + i)
            pin.slot = i
            local bg = pin:CreateTexture(nil, "BACKGROUND")
            bg:SetTexture("Interface\\Buttons\\WHITE8X8")
            bg:SetSize(PIN_SIZE - 4, PIN_SIZE - 4)
            bg:SetPoint("CENTER")
            pin.bg = bg
            local ring = pin:CreateTexture(nil, "BORDER")
            ring:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
            ring:SetSize(PIN_SIZE + 2, PIN_SIZE + 2)
            ring:SetPoint("CENTER")
            pin.ring = ring
            local num = pin:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            num:SetPoint("CENTER", 0, 0)
            num:SetFontObject("GameFontNormal")
            pin.numText = num
            pin:SetScript("OnEnter", function(self)
                local t = tracked[self.slot]
                if t then
                    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
                    GameTooltip:SetText(t.slot .. ". " .. (t.questName or "?"), 1, 1, 1)
                    GameTooltip:AddLine(t.title or "", 0.8, 0.8, 0.8)
                    if t.dist then GameTooltip:AddLine(string.format("%.0f yd", t.dist), 0.6, 0.9, 1) end
                    if t.xp then GameTooltip:AddLine(string.format("%d xp · score %.1f", t.xp, t.score or 0), 0.9, 0.85, 0.4) end
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

local function PlacePinOnEdge(pin, target)
    if not target or not target.spawn then
        pin:Hide()
        return false, "hidden"
    end
    local radius = (Minimap:GetWidth() / 2) - 14
    local hbd = GetHBD()
    if hbd and target.zone then
        local px, py = hbd:GetPlayerWorldPosition()
        local uiMapId = target.zone
        if ZoneDB and ZoneDB.GetUiMapIdByAreaId then
            uiMapId = ZoneDB:GetUiMapIdByAreaId(target.zone) or target.zone
        end
        local tx, ty = hbd:GetWorldCoordinatesFromZone(target.spawn[1] / 100, target.spawn[2] / 100, uiMapId)
        if px and tx then
            local angle = math.atan2(tx - px, -(ty - py))
            pin:ClearAllPoints()
            pin:SetPoint("CENTER", Minimap, "CENTER", math.sin(angle) * radius, -math.cos(angle) * radius)
            pin:Show()
            pin.onEdge = true
            return true, "edge-world"
        end
    end
    local ast = GetAstrolabe()
    if not ast then
        pin:Hide()
        return false, "hidden"
    end
    local pc, pz, px, py = ast:GetCurrentPlayerPosition()
    if not pc then pin:Hide(); return false, "hidden" end
    local wc, wz = AreaIdToCZ(target.zone)
    if not wc then
        pin:Hide()
        return false, "hidden"
    end
    local wx, wy = target.spawn[1] / 100, target.spawn[2] / 100
    if ast.TranslateWorldMapPosition then
        wx, wy = ast:TranslateWorldMapPosition(wc, wz, wx, wy, pc, pz)
    end
    local angle = math.atan2(wx - px, -(wy - py))
    pin:ClearAllPoints()
    pin:SetPoint("CENTER", Minimap, "CENTER", math.sin(angle) * radius, -math.cos(angle) * radius)
    pin:Show()
    pin.onEdge = true
    return true, "edge-astro"
end

local function EnsureMinimapDots()
    if #minimapDots >= DOT_COUNT then return end
    for i = #minimapDots + 1, DOT_COUNT do
        local t = Minimap:CreateTexture(nil, "OVERLAY")
        t:SetDrawLayer("OVERLAY", 7)
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
        t:SetSize(LINE_DOT_SIZE + 2, LINE_DOT_SIZE + 2)
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
    for _, badge in pairs(worldBadges) do badge:Hide() end
    if P1QuestNavLegend then P1QuestNavLegend:Hide() end
    if nextLineFrame then nextLineFrame:Hide() end
end

function P1QuestNav_GetPrimary()
    return tracked[1]
end

local function UpdateNextLine()
    if P1DruidGuideFrame and P1DruidGuideFrame:IsShown() then
        if nextLineFrame then nextLineFrame:Hide() end
        return
    end
    if not nextLineFrame then
        nextLineFrame = CreateFrame("Frame", "P1QuestNavNext", UIParent)
        nextLineFrame:SetFrameStrata("MEDIUM")
        nextLineFrame:SetSize(340, 22)
        nextLineText = nextLineFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nextLineText:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
        nextLineText:SetPoint("CENTER", nextLineFrame, "CENTER", 0, 0)
        nextLineText:SetJustifyH("CENTER")
    end
    nextLineFrame:ClearAllPoints()
    local anchor = GetMinimapParent()
    nextLineFrame:SetPoint("TOP", anchor, "BOTTOM", 0, -4)

    local t = tracked[1]
    if not IsNavEnabled() or not t then
        nextLineFrame:Hide()
        return
    end
    local dir = GetDirectionLabel(t)
    local xpTag = t.xp and t.xp > 0 and string.format(" [%dxp]", t.xp) or ""
    nextLineText:SetText(string.format("|cff00ccffNEXT:|r %s — %s%s",
        TruncateName(t.questName, 26), dir, xpTag))
    nextLineFrame:Show()
end

local function AnchorLegend()
    if not P1QuestNavLegend then return end
    P1QuestNavLegend:ClearAllPoints()
    local anchor = GetMinimapParent()
    if Questie_BaseFrame and Questie_BaseFrame:IsShown() then
        P1QuestNavLegend:SetPoint("TOPRIGHT", Questie_BaseFrame, "TOPLEFT", -6, 0)
    else
        P1QuestNavLegend:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMLEFT", -4, 4)
    end
end

local function UpdateLegend()
    if not P1QuestNavLegend then
        local f = CreateFrame("Frame", "P1QuestNavLegend", UIParent)
        f:SetSize(260, MAX_TRACKED * 18 + 12)
        f:SetFrameStrata("MEDIUM")
        f:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 10,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        f:SetBackdropColor(0.04, 0.04, 0.07, 0.82)
        f:SetBackdropBorderColor(0.25, 0.55, 0.75, 0.65)
        local hdr = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        hdr:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -6)
        hdr:SetText("|cff00ccffP1 Nav|r — exp/min priority")
        for i = 1, MAX_TRACKED do
            local dot = f:CreateTexture(nil, "ARTWORK")
            dot:SetTexture("Interface\\Buttons\\WHITE8X8")
            dot:SetSize(10, 10)
            dot:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -22 - (i - 1) * 18)
            legendDots[i] = dot
            local line = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            line:SetPoint("LEFT", dot, "RIGHT", 6, 0)
            line:SetJustifyH("LEFT")
            line:SetWidth(220)
            legendLines[i] = line
        end
    end
    AnchorLegend()
    local shown = 0
    for i = 1, MAX_TRACKED do
        local t = tracked[i]
        local line = legendLines[i]
        local dot = legendDots[i]
        if t and line and dot then
            local r, g, b = BlendColor(t.mode, t.slot)
            dot:SetVertexColor(r, g, b)
            dot:Show()
            local prog = t.progress and t.progress ~= "" and (" (" .. t.progress .. ")") or ""
            local xpTag = t.xp and t.xp > 0 and string.format(" [%dxp]", t.xp) or ""
            line:SetText(string.format("%s%d.|r %s%s%s",
                ColorHex(r, g, b), t.slot, TruncateName(t.questName, 22), prog, xpTag))
            line:Show()
            shown = shown + 1
        else
            if line then line:Hide() end
            if dot then dot:Hide() end
        end
    end
    if shown > 0 then
        P1QuestNavLegend:SetHeight(shown * 18 + 28)
        P1QuestNavLegend:Show()
    else
        P1QuestNavLegend:Hide()
    end
end

local function UpdateMinimapLine(target)
    EnsureMinimapDots()
    if not target or not target.spawn then
        for _, d in ipairs(minimapDots) do d:Hide() end
        return
    end
    local hbd = GetHBD()
    if hbd and target.zone then
        local px, py = hbd:GetPlayerWorldPosition()
        local uiMapId = target.zone
        if ZoneDB and ZoneDB.GetUiMapIdByAreaId then
            uiMapId = ZoneDB:GetUiMapIdByAreaId(target.zone) or target.zone
        end
        local tx, ty = hbd:GetWorldCoordinatesFromZone(target.spawn[1] / 100, target.spawn[2] / 100, uiMapId)
        if px and tx then
            local angle = math.atan2(tx - px, -(ty - py))
            local r, g, b = BlendColor(target.mode, 1)
            local radius = (Minimap:GetWidth() / 2) - 10
            for i, dot in ipairs(minimapDots) do
                local frac = i / (DOT_COUNT + 1)
                local dist = radius * frac
                dot:ClearAllPoints()
                dot:SetPoint("CENTER", Minimap, "CENTER", math.sin(angle) * dist, -math.cos(angle) * dist)
                dot:SetVertexColor(r, g, b, 0.65 + frac * 0.35)
                dot:Show()
            end
            return
        end
    end
    local ast = GetAstrolabe()
    if not ast then
        for _, d in ipairs(minimapDots) do d:Hide() end
        return
    end
    local pc, pz, px, py = ast:GetCurrentPlayerPosition()
    if not pc then
        for _, d in ipairs(minimapDots) do d:Hide() end
        return
    end
    local wc, wz = AreaIdToCZ(target.zone)
    if not wc then
        for _, d in ipairs(minimapDots) do d:Hide() end
        return
    end
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
        dot:SetVertexColor(r, g, b, 0.65 + frac * 0.35)
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
    if not wc then
        for _, d in ipairs(worldDots) do d:Hide() end
        return
    end
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
        dot:SetVertexColor(r, g, b, 0.55 + frac * 0.45)
        dot:Show()
    end
end

local function EnsureWorldBadge(key)
    if not worldBadges[key] then
        local badge = CreateFrame("Frame", nil, WorldMapButton)
        badge:SetSize(16, 16)
        badge:SetFrameStrata("FULLSCREEN_DIALOG")
        badge:SetFrameLevel(WorldMapButton:GetFrameLevel() + 20)
        local bg = badge:CreateTexture(nil, "BACKGROUND")
        bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        bg:SetAllPoints()
        badge.bg = bg
        local txt = badge:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        txt:SetPoint("CENTER")
        badge.txt = txt
        worldBadges[key] = badge
    end
    return worldBadges[key]
end

local function UpdateWorldBadges()
    for _, badge in pairs(worldBadges) do badge:Hide() end
    if not LoadQuestieModules() or not QuestieMap or not QuestieMap.questIdFrames then return end
    for _, t in ipairs(tracked) do
        local frames = QuestieMap.questIdFrames[t.questId]
        if frames then
            for idx, frameName in pairs(frames) do
                local frame = _G[frameName]
                if frame and frame:IsShown() and frame.GetCenter then
                    local key = t.questId .. ":" .. tostring(idx)
                    local badge = EnsureWorldBadge(key)
                    local r, g, b = BlendColor(t.mode, t.slot)
                    badge.bg:SetVertexColor(r, g, b, 0.9)
                    badge.txt:SetText(tostring(t.slot))
                    badge.txt:SetTextColor(0, 0, 0)
                    badge:ClearAllPoints()
                    badge:SetPoint("CENTER", frame, "TOPRIGHT", 4, 4)
                    badge:Show()
                end
            end
        end
    end
end

local function UpdatePins()
    EnsurePinFrames()
    local ast = GetAstrolabe()
    for i = 1, MAX_TRACKED do
        local pin = pinFrames[i]
        local t = tracked[i]
        if t and t.spawn and t.zone then
            local r, g, b = BlendColor(t.mode, i)
            pin.numText:SetText(tostring(i))
            pin.numText:SetTextColor(0.05, 0.05, 0.05)
            pin.bg:SetVertexColor(r, g, b, 0.95)
            pin.ring:SetVertexColor(1, 1, 1, 0.85)
            local placed = false
            local mode = "hidden"
            if ast then
                local wc, wz = AreaIdToCZ(t.zone)
                if wc then
                    local xPos, yPos = t.spawn[1] / 100, t.spawn[2] / 100
                    local result = ast:PlaceIconOnMinimap(pin, wc, wz, xPos, yPos)
                    if result ~= -1 then
                        pin:SetFrameLevel(Minimap:GetFrameLevel() + 30 + i)
                        pin:Show()
                        pin.onEdge = false
                        placed = true
                        mode = "map"
                    end
                end
            end
            if not placed then
                if ast then ast:RemoveIconFromMinimap(pin) end
                local ok
                ok, mode = PlacePinOnEdge(pin, t)
                placed = ok
            end
            pin.placementMode = mode
            if i == 1 then primaryPlacement = mode end
        else
            if ast then ast:RemoveIconFromMinimap(pin) end
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
    UpdateNextLine()
    UpdateWorldBadges()

    if tracked[1] then
        UpdateMinimapLine(tracked[1])
        UpdateWorldMapLine(tracked[1])
        local primaryId = tracked[1].questId
        if lastTomPrimaryId and lastTomPrimaryId ~= primaryId then
            ClearTomTomWaypoint()
        end
        lastTomPrimaryId = primaryId
        SetTomTomWaypoint(tracked[1])
    else
        for _, d in ipairs(minimapDots) do d:Hide() end
        for _, d in ipairs(worldDots) do d:Hide() end
        ClearTomTomWaypoint()
        lastTomPrimaryId = nil
        primaryPlacement = "none"
    end

    if debugMode then
        print("|cff00ccffP1 Nav|r ranked quests (exp/min):")
        for i, t in ipairs(tracked) do
            print(string.format("  %d. %s — %d xp, %.0f yd, score %.2f (travel %.0fs + kill %.0fs)",
                i, t.questName or "?", t.xp or 0, t.dist or 0, t.score or 0,
                t.travelTime or 0, t.killTime or 0))
        end
        if tracked[1] and tracked[1].spawn then
            local t = tracked[1]
            print(string.format("  #1 zone=%s spawn=[%.0f,%.0f] placement=%s dir=%s",
                tostring(t.zone), t.spawn[1], t.spawn[2], primaryPlacement,
                t.dirLabel or GetDirectionLabel(t)))
        end
        if #tracked == 0 then
            print("  (none — check Questie tracker / map icons)")
        end
    end
end

function P1QuestNav_SetEnabled(on)
    enabled = on and true or false
    P1QuestNavDB.enabled = enabled
    SyncLoaderNav(enabled)
    if on then
        P1QuestNav_Refresh(true)
    else
        HideAllVisuals()
        tracked = {}
    end
end

function P1QuestNav_GetStatus()
    return {
        enabled = enabled,
        navOn = enabled,
        autoOn = IsAutoQuestOn(),
        tracked = tracked,
        questieLoaded = LoadQuestieModules(),
        astrolabeLoaded = not not GetAstrolabe(),
        tomtomLoaded = not not (TomTom and TomTom.AddWaypoint),
        primaryPlacement = primaryPlacement,
    }
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
eventFrame:RegisterEvent("QUEST_ACCEPTED")
eventFrame:RegisterEvent("QUEST_COMPLETE")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ZONE_CHANGED")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        enabled = ReadNavEnabled()
        P1QuestNavDB.enabled = enabled
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
        if event == "QUEST_COMPLETE" and IsNavEnabled() then
            P1QuestNav_Refresh(true)
        end
    end
    if event == "ZONE_CHANGED" or event == "ZONE_CHANGED_NEW_AREA" then
        availCache = nil
        local zoneId = GetCurrentMapAreaID and GetCurrentMapAreaID() or nil
        if zoneId and lastTomZoneId and zoneId ~= lastTomZoneId then
            ClearTomTomWaypoint()
            lastTomPrimaryId = nil
        end
        lastTomZoneId = zoneId
        if IsNavEnabled() then P1QuestNav_Refresh(true) end
        return
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

if Minimap then
    Minimap:HookScript("OnShow", function()
        if IsNavEnabled() then P1QuestNav_Refresh(false) end
    end)
end

WorldMapFrame:HookScript("OnShow", function()
    if IsNavEnabled() then
        if tracked[1] then UpdateWorldMapLine(tracked[1]) end
        UpdateWorldBadges()
    end
end)

SLASH_P1NAV1 = "/p1nav"
SlashCmdList["P1NAV"] = function(msg)
    msg = string.lower(strtrim and strtrim(msg) or (msg or ""):match("^%s*(.-)%s*$") or "")
    if msg == "debug" then
        debugMode = not debugMode
        print("|cff00ccffP1 Nav|r debug " .. (debugMode and "|cff00ff00ON|r" or "OFF"))
        if debugMode then
            print("  Shows zone id, spawn coords, placement mode for #1 quest")
        end
        P1QuestNav_Refresh(true)
        return
    end
    if msg == "on" or msg == "off" then
        P1QuestNav_SetEnabled(msg == "on")
    else
        P1QuestNav_SetEnabled(not enabled)
    end
    local s = P1QuestNav_GetStatus()
    print("|cff00ccffP1 Nav|r v" .. VERSION .. " — " .. (s.enabled and "|cff00ff00ON|r" or "|cffaaaaaaOFF|r"))
    print("  Tracked: " .. #s.tracked .. " ranked quests · dotted line to #1")
    print("  Click minimap pin to switch TomTom arrow · /p1nav debug for scores")
    print("  Optimal route: |cff00ff00/p1path|r — xp + gear ranked path panel")
end

P1QuestNav_API = {
    LoadQuestie = LoadQuestieModules,
    FindAvailable = FindAvailableQuestTargets,
    FindActive = FindActiveQuestTargets,
    ScoreQuest = ScoreQuest,
    SetWaypoint = SetTomTomWaypoint,
    GetHBD = GetHBD,
    GetQuestXP = GetQuestXP,
    AreaIdToCZ = AreaIdToCZ,
    GetDirectionLabel = GetDirectionLabel,
    ClearTomTom = ClearTomTomWaypoint,
}
