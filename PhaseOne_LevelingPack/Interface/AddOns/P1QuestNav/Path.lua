-- P1QuestPath — optimal quest route (exp + gear), extends P1QuestNav

P1QuestPathDB = P1QuestPathDB or { enabled = true }

local MAX_PATH = 5
local REFRESH_INTERVAL = 30
local VERSION = "1.4.0"

local function SyncLoaderPath(on)
    if PhaseOneLoaderDB then PhaseOneLoaderDB.pathEnabled = on end
    if PhaseOneDruidLoaderDB then PhaseOneDruidLoaderDB.pathEnabled = on end
end

local function ReadPathEnabled()
    if PhaseOneLoaderDB and PhaseOneLoaderDB.pathEnabled ~= nil then
        return PhaseOneLoaderDB.pathEnabled
    end
    if PhaseOneDruidLoaderDB and PhaseOneDruidLoaderDB.pathEnabled ~= nil then
        return PhaseOneDruidLoaderDB.pathEnabled
    end
    return P1QuestPathDB.enabled ~= false
end

local pathEnabled = ReadPathEnabled()
local lastRefresh = 0
local pathEntries = {}
local pathLines = {}
local questRewardIndex = nil

local panel
local QuestieDB, ZoneDB

local EQUIP_LOC_SLOTS = {
    INVTYPE_HEAD = { 1 },
    INVTYPE_NECK = { 2 },
    INVTYPE_SHOULDER = { 3 },
    INVTYPE_BODY = { 4 },
    INVTYPE_CHEST = { 5 },
    INVTYPE_ROBE = { 5 },
    INVTYPE_WAIST = { 6 },
    INVTYPE_LEGS = { 7 },
    INVTYPE_FEET = { 8 },
    INVTYPE_WRIST = { 9 },
    INVTYPE_HAND = { 10 },
    INVTYPE_FINGER = { 11, 12 },
    INVTYPE_TRINKET = { 13, 14 },
    INVTYPE_CLOAK = { 15 },
    INVTYPE_2HWEAPON = { 16 },
    INVTYPE_WEAPON = { 16 },
    INVTYPE_WEAPONMAINHAND = { 16 },
    INVTYPE_WEAPONOFFHAND = { 17 },
    INVTYPE_SHIELD = { 17 },
    INVTYPE_HOLDABLE = { 17 },
}

local function LoadModules()
    local api = P1QuestNav_API
    if not api or not api.LoadQuestie or not api.LoadQuestie() then return false end
    if QuestieLoader then
        local ok
        ok, QuestieDB = pcall(function() return QuestieLoader:ImportModule("QuestieDB") end)
        if not ok then QuestieDB = nil end
        ok, ZoneDB = pcall(function() return QuestieLoader:ImportModule("ZoneDB") end)
        if not ok then ZoneDB = nil end
    end
    return QuestieDB ~= nil
end

local function BuildRewardIndex()
    if questRewardIndex then return questRewardIndex end
    questRewardIndex = {}
    if not QuestieDB or not QuestieDB.ItemPointers then return questRewardIndex end
    for itemId in pairs(QuestieDB.ItemPointers) do
        local rewards = QuestieDB.QueryItemSingle(itemId, "questRewards")
        if rewards then
            for _, qid in ipairs(rewards) do
                questRewardIndex[qid] = questRewardIndex[qid] or {}
                table.insert(questRewardIndex[qid], itemId)
            end
        end
    end
    return questRewardIndex
end

local function GetItemLevel(itemId)
    local name, link, _, level = GetItemInfo(itemId)
    if level and level > 0 then return level end
    if QuestieDB and QuestieDB.QueryItemSingle then
        return QuestieDB.QueryItemSingle(itemId, "itemLevel") or 0
    end
    return 0
end

local function GetEquippedLevelForLoc(equipLoc)
    local slots = EQUIP_LOC_SLOTS[equipLoc]
    if not slots then return 0 end
    local best = 0
    for _, slot in ipairs(slots) do
        local link = GetInventoryItemLink("player", slot)
        if link then
            local _, _, _, level = GetItemInfo(link)
            if level and level > best then best = level end
        end
    end
    return best
end

local function GetGearUpgradeBonus(questId)
    local index = BuildRewardIndex()
    local items = index[questId]
    if not items then return 0, nil end
    local bestBonus, bestLabel = 0, nil
    for _, itemId in ipairs(items) do
        local itemClass = QuestieDB.QueryItemSingle(itemId, "class")
        if itemClass == 2 or itemClass == 4 then
            local iLevel = GetItemLevel(itemId)
            if iLevel > 0 then
                local _, _, _, _, _, _, _, _, equipLoc = GetItemInfo(itemId)
                if not equipLoc or equipLoc == "" then
                    if itemClass == 2 then equipLoc = "INVTYPE_WEAPON" end
                end
                local equipped = GetEquippedLevelForLoc(equipLoc or "INVTYPE_WEAPON")
                if iLevel > equipped then
                    local bonus = (iLevel - equipped) * 8
                    if bonus > bestBonus then
                        bestBonus = bonus
                        local itemName = QuestieDB.QueryItemSingle(itemId, "name") or "gear"
                        bestLabel = "+" .. (iLevel - equipped) .. " ilvl " .. itemName
                    end
                end
            end
        end
    end
    return bestBonus, bestLabel
end

local function GetChainBonus(questId)
    if not QuestieDB then return 0 end
    local nextId = QuestieDB.QueryQuestSingle(questId, "nextQuestInChain")
    if not nextId or nextId == 0 then return 0 end
    local nextXp = 0
    if P1QuestNav_API and P1QuestNav_API.GetQuestXP then
        nextXp = P1QuestNav_API.GetQuestXP(nextId) or 0
    end
    if nextXp == 0 then
        local lvl = QuestieDB.QueryQuestSingle(nextId, "questLevel") or 5
        nextXp = math.max(50, lvl * 40)
    end
    return nextXp * 0.25
end

local function GetQuestXP(questId)
    if P1QuestNav_API and P1QuestNav_API.GetQuestXP then
        return P1QuestNav_API.GetQuestXP(questId) or 0
    end
    return 0
end

local function GetDirectionLabel(entry)
    local api = P1QuestNav_API
    if not api or not api.GetHBD then return "" end
    local hbd = api.GetHBD()
    if not hbd or not entry.spawn or not entry.zone then return "" end
    local px, py = hbd:GetPlayerWorldPosition()
    if not px then return "" end
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

local function ScorePathQuest(entry)
    local api = P1QuestNav_API
    if api and api.ScoreQuest then api.ScoreQuest(entry) end

    local xp = entry.xp or GetQuestXP(entry.questId)
    if xp == 0 and QuestieDB then
        local lvl = QuestieDB.QueryQuestSingle(entry.questId, "questLevel") or 5
        xp = math.max(50, lvl * 40)
        entry.xp = xp
    end

    local playerLevel = UnitLevel("player")
    local questLevel = QuestieDB and QuestieDB.QueryQuestSingle(entry.questId, "questLevel") or playerLevel
    local greenLevels = math.max(0, questLevel - playerLevel)
    local xpScore = xp * (1 + 0.1 * greenLevels)

    local gearBonus, gearLabel = GetGearUpgradeBonus(entry.questId)
    entry.gearLabel = gearLabel

    local dist = entry.dist or 500
    local travelPenalty = dist / 120
    local chainBonus = GetChainBonus(entry.questId)

    entry.pathScore = xpScore + gearBonus + chainBonus - travelPenalty
    return entry.pathScore
end

local function CollectPathQuests()
    local api = P1QuestNav_API
    if not api then return {} end
    local list = {}
    local seen = {}
    local function add(entries)
        for _, e in ipairs(entries) do
            if not seen[e.questId] then
                seen[e.questId] = true
                table.insert(list, e)
            end
        end
    end
    add(api.FindActive and api.FindActive() or {})
    add(api.FindAvailable and api.FindAvailable() or {})
    for _, entry in ipairs(list) do
        ScorePathQuest(entry)
    end
    table.sort(list, function(a, b) return (a.pathScore or 0) > (b.pathScore or 0) end)
    local out = {}
    for i = 1, math.min(MAX_PATH, #list) do
        out[i] = list[i]
        out[i].slot = i
        out[i].dirLabel = GetDirectionLabel(list[i])
    end
    return out
end

local function EnsurePanel()
    if panel then return end
    panel = CreateFrame("Frame", "P1QuestPathPanel", UIParent)
    panel:SetSize(300, MAX_PATH * 20 + 36)
    panel:SetFrameStrata("MEDIUM")
    panel:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 10,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    panel:SetBackdropColor(0.04, 0.06, 0.08, 0.88)
    panel:SetBackdropBorderColor(0.2, 0.55, 0.35, 0.75)

    local hdr = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hdr:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -6)
    hdr:SetText("|cff00ccffOPTIMAL PATH|r (exp/gear) |cff888888(/p1path)|r")
    panel.header = hdr

    for i = 1, MAX_PATH do
        local line = CreateFrame("Button", "P1QuestPathLine" .. i, panel)
        line:SetSize(284, 18)
        line:SetPoint("TOPLEFT", panel, "TOPLEFT", 6, -24 - (i - 1) * 20)
        line.slot = i
        local fs = line:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetPoint("LEFT", line, "LEFT", 0, 0)
        fs:SetJustifyH("LEFT")
        fs:SetWidth(280)
        line.text = fs
        line:SetScript("OnEnter", function(self)
            local e = pathEntries[self.slot]
            if not e then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(e.questName or "?", 1, 1, 1)
            GameTooltip:AddLine("Score: " .. string.format("%.0f", e.pathScore or 0), 0.7, 0.9, 0.5)
            if e.gearLabel then GameTooltip:AddLine(e.gearLabel, 0.4, 1, 0.4) end
            GameTooltip:AddLine("Click: TomTom + map", 0.5, 1, 0.5)
            GameTooltip:Show()
        end)
        line:SetScript("OnLeave", function() GameTooltip:Hide() end)
        line:SetScript("OnClick", function(self)
            local e = pathEntries[self.slot]
            if e and P1QuestNav_API and P1QuestNav_API.SetWaypoint then
                P1QuestNav_API.SetWaypoint(e)
            end
        end)
        pathLines[i] = line
    end
end

local function UseIntegratedGuide()
    return P1DruidGuideFrame and P1DruidGuideFrame:IsShown()
end

function P1QuestPath_GetTop(n)
    if not pathEnabled then return {} end
    if not LoadModules() then return {} end
    pathEntries = CollectPathQuests()
    local out = {}
    for i = 1, math.min(n or 3, #pathEntries) do
        out[i] = pathEntries[i]
    end
    return out
end

local function AnchorPanel()
    if not panel then return end
    panel:ClearAllPoints()
    if UseIntegratedGuide() then
        panel:Hide()
        return
    end
    if P1DruidGuideFrame and P1DruidGuideFrame:IsShown() then
        panel:SetPoint("TOPLEFT", P1DruidGuideFrame, "BOTTOMLEFT", 0, -6)
    elseif P1AdventureGuideFrame and P1AdventureGuideFrame:IsShown() then
        panel:SetPoint("TOPLEFT", P1AdventureGuideFrame, "BOTTOMLEFT", 0, -6)
    elseif P1QuestNavLegend and P1QuestNavLegend:IsShown() then
        panel:SetPoint("TOPLEFT", P1QuestNavLegend, "BOTTOMLEFT", 0, -6)
    else
        panel:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 12, -340)
    end
end

local function Truncate(s, n)
    if not s then return "?" end
    if #s <= n then return s end
    return string.sub(s, 1, n - 1) .. "…"
end

function P1QuestPath_Refresh(force)
    if not pathEnabled then
        if panel then panel:Hide() end
        pathEntries = {}
        return
    end
    if not LoadModules() then return end

    local now = GetTime()
    if not force and (now - lastRefresh) < 2 then return end
    lastRefresh = now

    pathEntries = CollectPathQuests()
    EnsurePanel()
    AnchorPanel()

    local shown = 0
    for i = 1, MAX_PATH do
        local line = pathLines[i]
        local e = pathEntries[i]
        if e and line then
            local xpTag = e.xp and e.xp > 0 and string.format("[%dxp", e.xp) or "[?"
            local gearTag = e.gearLabel and (", " .. e.gearLabel .. "]") or "]"
            local dir = e.dirLabel and (" — " .. e.dirLabel) or ""
            line.text:SetText(string.format("%d. %s%s%s%s",
                i, Truncate(e.questName, 20), xpTag, gearTag, dir))
            line:Show()
            shown = shown + 1
        elseif line then
            line:Hide()
        end
    end

    if UseIntegratedGuide() then
        if panel then panel:Hide() end
        if P1DruidGuide_Refresh then P1DruidGuide_Refresh() end
        return
    end

    if shown > 0 then
        panel:SetHeight(shown * 20 + 32)
        panel:Show()
    else
        panel:Hide()
    end
end

function P1QuestPath_SetEnabled(on)
    pathEnabled = on and true or false
    P1QuestPathDB.enabled = pathEnabled
    SyncLoaderPath(pathEnabled)
    P1QuestPath_Refresh(true)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
eventFrame:RegisterEvent("QUEST_ACCEPTED")
eventFrame:RegisterEvent("QUEST_COMPLETE")
eventFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        pathEnabled = ReadPathEnabled()
        P1QuestPathDB.enabled = pathEnabled
        local elapsed = 0
        eventFrame:SetScript("OnUpdate", function(f, e)
            elapsed = elapsed + e
            if elapsed >= 5 then
                f:SetScript("OnUpdate", nil)
                P1QuestPath_Refresh(true)
            end
        end)
        return
    end
    P1QuestPath_Refresh(false)
end)

local tick = CreateFrame("Frame")
tick:SetScript("OnUpdate", function()
    if not pathEnabled then return end
    tick.elapsed = (tick.elapsed or 0) + 1
    if tick.elapsed >= REFRESH_INTERVAL then
        tick.elapsed = 0
        P1QuestPath_Refresh(false)
    end
end)

SLASH_P1PATH1 = "/p1path"
SlashCmdList["P1PATH"] = function(msg)
    msg = string.lower((msg or ""):match("^%s*(.-)%s*$") or "")
    if msg == "refresh" then
        P1QuestPath_Refresh(true)
        print("|cff00ccffP1 Path|r v" .. VERSION .. " — refreshed")
        return
    end
    if msg == "on" or msg == "off" then
        P1QuestPath_SetEnabled(msg == "on")
    else
        P1QuestPath_SetEnabled(not pathEnabled)
    end
    print("|cff00ccffP1 Path|r v" .. VERSION .. " — " .. (pathEnabled and "|cff00ff00ON|r" or "|cffaaaaaaOFF|r"))
    print("  Ranked route by xp, gear upgrades, chain bonus · click line for TomTom")
end
