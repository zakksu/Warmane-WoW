-- P1Waypoint — embedded quest arrow (cloned from pack TomTom; avoids separate-addon conflicts)

local P1Waypoint = {}
_G.P1Waypoint = P1Waypoint

P1Waypoint.waypoints = {}
P1Waypoint.activeWaypoint = nil
P1Waypoint.uidCounter = 0
P1Waypoint.arrow = nil
P1Waypoint.cleardistance = 15
P1Waypoint.arrivaldistance = 15

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

local function Bearing(pc, pz, px, py, wc, wz, wx, wy)
    local ast = GetAstrolabe()
    if ast and ast.TranslateWorldMapPosition and pc and wc then
        wx, wy = ast:TranslateWorldMapPosition(wc, wz, wx, wy, pc, pz)
    end
    local dx, dy = wx - px, wy - py
    if dx == 0 and dy == 0 then return 0 end
    return math.atan2(dx, -dy)
end

local function SetArrowRotation(texture, angle)
    local sin = math.sin(angle)
    local cos = math.cos(angle)
    local ULx, ULy = 0.5 - sin / 2, 0.5 + cos / 2
    local LLx, LLy = 0.5 + cos / 2, 0.5 + sin / 2
    local URx, URy = 0.5 - cos / 2, 0.5 - sin / 2
    local LRx, LRy = 0.5 + sin / 2, 0.5 - cos / 2
    texture:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy)
end

local function CreateArrow()
    local frame = CreateFrame("Button", "P1QuestArrow", UIParent)
    frame:SetSize(56, 56)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, -120)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    local tex = frame:CreateTexture(nil, "OVERLAY")
    tex:SetTexture("Interface\\Minimap\\MinimapArrow")
    tex:SetSize(56, 56)
    tex:SetPoint("CENTER")
    tex:SetVertexColor(1, 0.82, 0)
    frame.texture = tex

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOP", frame, "BOTTOM", 0, -4)
    frame.title = title

    local dist = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    dist:SetPoint("TOP", title, "BOTTOM", 0, -2)
    frame.distance = dist

    frame:SetScript("OnUpdate", function(self)
        local wp = P1Waypoint:GetActiveWaypoint()
        if not wp then
            self:Hide()
            return
        end

        local ast = GetAstrolabe()
        if not ast then
            self.title:SetText(wp.title or "Waypoint")
            self:Show()
            return
        end

        local pc, pz, px, py = ast:GetCurrentPlayerPosition()
        if not pc then
            self.title:SetText(wp.title or "Waypoint")
            self.distance:SetText("")
            self:Show()
            return
        end

        local wc, wz = wp.c or pc, wp.z or pz
        local wx, wy = wp.x, wp.y
        if not wx or not wy then return end

        local distance = ast:ComputeDistance(pc, pz, px, py, wc, wz, wx, wy)
        if distance and distance < P1Waypoint.cleardistance then
            P1Waypoint:RemoveWaypoint(wp.uid)
            return
        end

        local angle = Bearing(pc, pz, px, py, wc, wz, wx, wy)
        SetArrowRotation(self.texture, angle)

        self.title:SetText(wp.title or "Waypoint")
        if distance then
            self.distance:SetText(string.format("%.0f yd", distance))
        end
        self:Show()
    end)

    frame:SetScript("OnClick", function()
        P1Waypoint.activeWaypoint = nil
        frame:Hide()
    end)

    return frame
end

function P1Waypoint:AddWaypoint(mapId, x, y, options)
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
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ccffP1 Nav:|r " .. wp.title)
    end

    return uid
end

function P1Waypoint:AddZWaypoint(c, z, x, y, title, persistent, minimap, world)
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
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ccffP1 Nav:|r " .. title)
    end

    return uid
end

function P1Waypoint:RemoveWaypoint(uid)
    if not uid then return end
    self.waypoints[uid] = nil
    if self.activeWaypoint == uid then
        self.activeWaypoint = nil
        if self.arrow then self.arrow:Hide() end
    end
end

function P1Waypoint:SetActiveWaypoint(uid)
    if self.waypoints[uid] then
        self.activeWaypoint = uid
        if self.arrow then
            self.arrow:SetFrameStrata("HIGH")
            self.arrow:SetFrameLevel(200)
            self.arrow:Show()
        end
    end
end

function P1Waypoint:GetActiveWaypoint()
    local uid = self.activeWaypoint
    if uid then return self.waypoints[uid] end
end

function P1Waypoint:ClearActive()
    self.activeWaypoint = nil
    if self.arrow then self.arrow:Hide() end
end

local init = CreateFrame("Frame")
init:RegisterEvent("PLAYER_LOGIN")
init:SetScript("OnEvent", function()
    P1Waypoint.arrow = CreateArrow()
    P1Waypoint.arrow:Hide()
end)

-- Questie expects global TomTom; only register if no external TomTom addon is present.
if not _G.TomTom and not IsAddOnLoaded("TomTom") then
    _G.TomTom = P1Waypoint
end