-- TomTom (Phase One lightweight 3.3.5a build)
-- Questie-compatible waypoint API with crazy-taxi arrow.

local TomTom = {}
_G.TomTom = TomTom

TomTom.waypoints = {}
TomTom.activeWaypoint = nil
TomTom.uidCounter = 0
TomTom.arrow = nil
TomTom.cleardistance = 15
TomTom.arrivaldistance = 15

local function GetAstrolabe()
    if DongleStub then
        local ok, lib = pcall(DongleStub, "Astrolabe-1.0")
        if ok and lib then return lib end
    end
    return nil
end

local function NormalizeCoord(v)
    if not v then return 0 end
    if v > 1 then return v / 100 end
    return v
end

function TomTom:AddWaypoint(mapId, x, y, options)
    options = options or {}
    x = NormalizeCoord(x)
    y = NormalizeCoord(y)

    if QuestieCompat and QuestieCompat.TomTom_AddWaypoint and QuestieCompat.UiMapData and QuestieCompat.UiMapData[mapId] then
        local uid = QuestieCompat.TomTom_AddWaypoint(options.title or options.desc or "Waypoint", mapId, x * 100, y * 100)
        if uid and options.crazy ~= false then
            self:SetActiveWaypoint(uid)
        end
        return uid
    end

    self.uidCounter = self.uidCounter + 1
    local uid = self.uidCounter

    local wp = {
        uid = uid,
        mapId = mapId,
        x = x,
        y = y,
        title = options.title or options.desc or "Waypoint",
        crazy = options.crazy,
        c = nil,
        z = nil,
    }

    -- Questie often passes UiMapID; try to resolve to continent/zone via current map if needed.
    local ast = GetAstrolabe()
    if ast and ast.GetCurrentPlayerPosition then
        local c, z = ast:GetCurrentPlayerPosition()
        wp.c, wp.z = c, z
    end

    self.waypoints[uid] = wp

    if options.crazy ~= false then
        self:SetActiveWaypoint(uid)
    end

    if options.title and DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ccffTomTom:|r " .. wp.title)
    end

    return uid
end

function TomTom:AddZWaypoint(c, z, x, y, title, persistent, minimap, world)
    x = NormalizeCoord(x)
    y = NormalizeCoord(y)

    self.uidCounter = self.uidCounter + 1
    local uid = self.uidCounter

    local wp = {
        uid = uid,
        c = c,
        z = z,
        x = x,
        y = y,
        title = title or "Waypoint",
        crazy = true,
    }

    self.waypoints[uid] = wp
    self:SetActiveWaypoint(uid)

    if title and DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ccffTomTom:|r " .. title)
    end

    return uid
end

function TomTom:RemoveWaypoint(uid)
    if not uid then return end
    self.waypoints[uid] = nil
    if self.activeWaypoint == uid then
        self.activeWaypoint = nil
        if self.arrow then self.arrow:Hide() end
    end
end

function TomTom:SetActiveWaypoint(uid)
    if self.waypoints[uid] then
        self.activeWaypoint = uid
        if self.arrow then
            self.arrow:SetFrameStrata("HIGH")
            self.arrow:SetFrameLevel(200)
            self.arrow:Show()
        end
    end
end

function TomTom:GetActiveWaypoint()
    local uid = self.activeWaypoint
    if uid then return self.waypoints[uid] end
end

-- Questie checks TomTom.AddWaypoint as a function field
TomTom.AddWaypoint = TomTom.AddWaypoint

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    TomTom.arrow = TomTom_CreateArrow()
    TomTom.arrow:Hide()
end)

SLASH_TOMTOM1 = "/tomtom"
SlashCmdList["TOMTOM"] = function()
    if TomTom.arrow and TomTom.arrow:IsShown() then
        TomTom.arrow:Hide()
        TomTom.activeWaypoint = nil
        print("|cff00ccffTomTom:|r Arrow hidden.")
    else
        print("|cff00ccffTomTom:|r Waypoint arrow active when Questie sets a target (Ctrl+click map icon).")
    end
end
