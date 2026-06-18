-- P1QuestNav — subtle quest mob nameplate glow (Warmane 3.3.5a)

local GLOW_INTERVAL = 0.5
local SCAN_INTERVAL = 0.15
local NP_BORDER = "Interface\\Tooltips\\Nameplate-Border"
local GLOW_TEX = "Interface\\Buttons\\UI-ActionButton-Border"

local glowEnabled = true
local targetNames = {}
local npNameRegions = {}
local activeGlows = {}
local lastUpdate = 0
local lastScan = 0
local lastChildCount = 0
local targetGlowFrame

local function SyncLoaderGlow(on)
    if PhaseOneLoaderDB then PhaseOneLoaderDB.questGlowEnabled = on end
    if PhaseOneDruidLoaderDB then PhaseOneDruidLoaderDB.questGlowEnabled = on end
end

local function ReadGlowEnabled()
    if PhaseOneLoaderDB and PhaseOneLoaderDB.questGlowEnabled ~= nil then
        return PhaseOneLoaderDB.questGlowEnabled
    end
    if PhaseOneDruidLoaderDB and PhaseOneDruidLoaderDB.questGlowEnabled ~= nil then
        return PhaseOneDruidLoaderDB.questGlowEnabled
    end
    return true
end

local function NormalizeName(name)
    if not name then return nil end
    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then return nil end
    return name:lower()
end

local function ParseLeaderBoardName(text)
    if not text then return nil end
    local _, _, name = text:match("(%d+)/(%d+)%s+(.+)")
    if name then return name end
    name = text:match("(.+):%s*%d+/%d+")
    if name then return name end
    name = text:match("(.+)%s+%(%d+/%d+%)")
    return name
end

local function CollectFromQuestLog(names)
    for i = 1, GetNumQuestLogEntries() do
        local _, _, _, _, _, _, _, qid = GetQuestLogTitle(i)
        if qid then
            SelectQuestLogEntry(i)
            for j = 1, GetNumQuestLeaderBoards() do
                local text, objType, finished = GetQuestLogLeaderBoard(j)
                if not finished and objType ~= "reputation" and objType ~= "log" then
                    local parsed = ParseLeaderBoardName(text)
                    if parsed then
                        local key = NormalizeName(parsed)
                        if key then names[key] = parsed end
                    end
                end
            end
        end
    end
end

local function CollectFromQuestie(names)
    if not QuestieLoader then return end
    local ok, QuestiePlayer = pcall(function() return QuestieLoader:ImportModule("QuestiePlayer") end)
    if not ok or not QuestiePlayer or not QuestiePlayer.currentQuestlog then return end
    local ok2, QuestieDB = pcall(function() return QuestieLoader:ImportModule("QuestieDB") end)
    if not ok2 or not QuestieDB then return end

    for _, quest in pairs(QuestiePlayer.currentQuestlog) do
        if quest and quest.Objectives then
            for _, obj in ipairs(quest.Objectives) do
                if obj and not obj.Completed then
                    local mobName
                    if obj.Type == "monster" and obj.Id then
                        mobName = QuestieDB.QueryNPCSingle(obj.Id, "name")
                    elseif obj.Name and (obj.Type == "monster" or obj.Icon == "slay") then
                        mobName = obj.Name
                    end
                    if mobName then
                        local key = NormalizeName(mobName)
                        if key then names[key] = mobName end
                    end
                end
            end
        end
    end
end

local function RefreshTargetNames()
    wipe(targetNames)
    CollectFromQuestLog(targetNames)
    CollectFromQuestie(targetNames)
end

local function IsQuestTargetName(name)
    local key = NormalizeName(name)
    return key and targetNames[key] ~= nil
end

local function IsNamePlate(frame)
    if not frame or not frame.GetRegions then return false end
    if frame.UnitFrame or frame.extended or frame.aloftData or frame.kui then
        return true
    end
    local _, borderRegion = frame:GetRegions()
    if borderRegion and borderRegion.GetObjectType and borderRegion:GetObjectType() == "Texture" then
        return borderRegion:GetTexture() == NP_BORDER
    end
    return false
end

local function GetNameRegion(frame)
    if npNameRegions[frame] then return npNameRegions[frame] end
    local region = select(7, frame:GetRegions())
    if region and region.GetText then
        npNameRegions[frame] = region
        return region
    end
end

local function RemoveGlowFrame(glow)
    if not glow then return end
    glow:SetScript("OnUpdate", nil)
    glow:Hide()
    if glow.tex then glow.tex:SetAlpha(0) end
    activeGlows[glow] = nil
end

local function RemoveGlowFromPlate(plate)
    if plate and plate.p1Glow then
        RemoveGlowFrame(plate.p1Glow)
        plate.p1Glow = nil
    end
end

local function EnsureGlow(plate)
    if plate.p1Glow then return plate.p1Glow end
    local glow = CreateFrame("Frame", nil, plate)
    glow:SetAllPoints(plate)
    glow:SetFrameLevel((plate.GetFrameLevel and plate:GetFrameLevel() or 0) + 2)
    local tex = glow:CreateTexture(nil, "OVERLAY")
    tex:SetTexture(GLOW_TEX)
    tex:SetBlendMode("ADD")
    tex:SetVertexColor(1.0, 0.82, 0.15)
    tex:SetPoint("CENTER")
    local w = plate:GetWidth() > 1 and plate:GetWidth() or 120
    local h = plate:GetHeight() > 1 and plate:GetHeight() or 32
    tex:SetSize(w * 1.75, h * 2.1)
    glow.tex = tex
    glow.pulse = 0
    glow.plate = plate
    glow:SetScript("OnUpdate", function(self, elapsed)
        self.pulse = (self.pulse or 0) + elapsed * 1.8
        self.tex:SetAlpha(0.16 + math.sin(self.pulse) * 0.10)
    end)
    plate.p1Glow = glow
    activeGlows[glow] = true
    return glow
end

local function ShowGlow(plate)
    local glow = EnsureGlow(plate)
    glow:Show()
end

local function IsUnitNearby(unit)
    if not unit or not UnitExists(unit) then return false end
    if UnitIsDead(unit) then return false end
    if CheckInteractDistance(unit, 4) then return true end
    if CheckInteractDistance(unit, 1) then return true end
    return false
end

local function UpdateTargetGlow()
    if not glowEnabled then
        if targetGlowFrame then targetGlowFrame:Hide() end
        return
    end
    local tName = UnitName("target")
    local show = tName and IsQuestTargetName(tName) and IsUnitNearby("target")
    if not show then
        if targetGlowFrame then targetGlowFrame:Hide() end
        return
    end
    if not targetGlowFrame then
        targetGlowFrame = CreateFrame("Frame", "P1QuestGlowTarget", TargetFrame)
        targetGlowFrame:SetFrameStrata("MEDIUM")
        targetGlowFrame:SetFrameLevel(TargetFrame:GetFrameLevel() + 4)
        targetGlowFrame:SetAllPoints(TargetFrame)
        local tex = targetGlowFrame:CreateTexture(nil, "OVERLAY")
        tex:SetTexture(GLOW_TEX)
        tex:SetBlendMode("ADD")
        tex:SetVertexColor(1.0, 0.82, 0.15)
        tex:SetPoint("CENTER")
        tex:SetSize(260, 72)
        targetGlowFrame.tex = tex
        targetGlowFrame.pulse = 0
        targetGlowFrame:SetScript("OnUpdate", function(self, elapsed)
            self.pulse = (self.pulse or 0) + elapsed * 1.8
            self.tex:SetAlpha(0.14 + math.sin(self.pulse) * 0.08)
        end)
    end
    targetGlowFrame:Show()
end

local function ScanNameplates()
    local numChildren = WorldFrame:GetNumChildren()
    if numChildren ~= lastChildCount then
        lastChildCount = numChildren
        local function walk(frame, ...)
            if not frame then return end
            if IsNamePlate(frame) and not npNameRegions[frame] then
                local region = GetNameRegion(frame)
                if region then
                    frame:HookScript("OnHide", function()
                        RemoveGlowFromPlate(frame)
                    end)
                end
            end
            return walk(...)
        end
        walk(WorldFrame:GetChildren())
    end

    for frame, region in pairs(npNameRegions) do
        if frame:IsShown() then
            local name = region:GetText()
            if name and IsQuestTargetName(name) then
                ShowGlow(frame)
            else
                RemoveGlowFromPlate(frame)
            end
        else
            RemoveGlowFromPlate(frame)
        end
    end
end

local function ClearAllGlows()
    for plate in pairs(npNameRegions) do
        RemoveGlowFromPlate(plate)
    end
    if targetGlowFrame then targetGlowFrame:Hide() end
end

function P1QuestGlow_SetEnabled(on)
    glowEnabled = on and true or false
    SyncLoaderGlow(glowEnabled)
    if glowEnabled then
        RefreshTargetNames()
        P1QuestGlow_Update(true)
    else
        ClearAllGlows()
    end
end

function P1QuestGlow_IsEnabled()
    return glowEnabled
end

function P1QuestGlow_Update(force)
    if not glowEnabled then return end
    local now = GetTime()
    if not force and (now - lastUpdate) < GLOW_INTERVAL then return end
    lastUpdate = now
    RefreshTargetNames()
    UpdateTargetGlow()
    ScanNameplates()
end

local scanFrame = CreateFrame("Frame")
scanFrame:SetScript("OnUpdate", function(_, elapsed)
    if not glowEnabled then return end
    lastScan = lastScan + elapsed
    if lastScan >= SCAN_INTERVAL then
        lastScan = 0
        local now = GetTime()
        if (now - lastUpdate) >= GLOW_INTERVAL then
            P1QuestGlow_Update(true)
        else
            ScanNameplates()
            UpdateTargetGlow()
        end
    end
end)

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
eventFrame:RegisterEvent("QUEST_WATCH_UPDATE")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        glowEnabled = ReadGlowEnabled()
        SyncLoaderGlow(glowEnabled)
        return
    end
    if glowEnabled then
        RefreshTargetNames()
        P1QuestGlow_Update(true)
    end
end)

SLASH_P1GLOW1 = "/p1glow"
SlashCmdList["P1GLOW"] = function(msg)
    msg = string.lower((msg or ""):match("^%s*(.-)%s*$") or "")
    if msg == "on" then P1QuestGlow_SetEnabled(true)
    elseif msg == "off" then P1QuestGlow_SetEnabled(false)
    else P1QuestGlow_SetEnabled(not glowEnabled) end
    print("|cff00ccffP1 Glow|r — quest mob nameplate highlight "
        .. (glowEnabled and "|cff00ff00ON|r" or "|cffaaaaaaOFF|r"))
    print("  Soft gold pulse on kill/collect targets · clears when objective done")
end
