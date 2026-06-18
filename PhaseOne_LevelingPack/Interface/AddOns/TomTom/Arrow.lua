-- Crazy-taxi style arrow (lightweight, 3.3.5a)

local function GetAstrolabe()
    if DongleStub then
        local ok, lib = pcall(DongleStub, "Astrolabe-1.0")
        if ok then return lib end
    end
end

local function Bearing(pc, pz, px, py, wc, wz, wx, wy)
    -- Translate waypoint to player map if needed
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

function TomTom_CreateArrow()
    local frame = CreateFrame("Button", "TomTomCrazyArrow", UIParent)
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
        local wp = TomTom:GetActiveWaypoint()
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
        if distance and distance < TomTom.cleardistance then
            TomTom:RemoveWaypoint(wp.uid)
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
        TomTom.activeWaypoint = nil
        frame:Hide()
    end)

    return frame
end
