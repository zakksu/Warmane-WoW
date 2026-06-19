-- P1 Druid Guide — dev self-test harness + structured logging for external automation

P1DG = P1DG or {}

local LOG_PREFIX = "[P1TEST]"
local MAX_LOG = 300

local function EnsureDevLog()
    P1DruidGuideDB = P1DruidGuideDB or {}
    P1DruidGuideDB.devLog = P1DruidGuideDB.devLog or {}
    return P1DruidGuideDB.devLog
end

local function MirrorHarnessLog(level, msg)
    P1DruidGuideDB = P1DruidGuideDB or {}
    P1DruidGuideDB.harnessLog = P1DruidGuideDB.harnessLog or {}
    local line = string.format("%s %s %s", LOG_PREFIX, string.upper(level or "INFO"), msg or "")
    P1DruidGuideDB.harnessLog[#P1DruidGuideDB.harnessLog + 1] = { t = GetTime(), line = line }
    while #P1DruidGuideDB.harnessLog > 100 do table.remove(P1DruidGuideDB.harnessLog, 1) end
end

function P1DG.DevLog(level, msg)
    level = string.upper(level or "INFO")
    local line = string.format("%s %s %s", LOG_PREFIX, level, msg or "")
    local log = EnsureDevLog()
    log[#log + 1] = { t = GetTime(), level = level, msg = msg or "" }
    while #log > MAX_LOG do table.remove(log, 1) end
    if level == "PASS" then
        print("|cff00ff00" .. line .. "|r")
    elseif level == "FAIL" then
        print("|cffff0000" .. line .. "|r")
    elseif level == "WARN" then
        print("|cffff8800" .. line .. "|r")
    else
        print("|cff888888" .. line .. "|r")
    end
    MirrorHarnessLog(level, msg)
    return line
end

local function AssertTrue(name, cond, detail)
    if cond then
        P1DG.DevLog("PASS", name)
        return true
    end
    P1DG.DevLog("FAIL", name .. (detail and (" — " .. detail) or ""))
    return false
end

function P1DG.RunModuleTests()
    local pass, total = 0, 0
    local function check(name, cond, detail)
        total = total + 1
        if AssertTrue(name, cond, detail) then pass = pass + 1 end
    end

    P1DG.DevLog("INFO", "=== module smoke ===")
    check("addon:P1DruidGuide", IsAddOnLoaded("P1DruidGuide"))
    check("addon:PhaseOneLoader", IsAddOnLoaded("PhaseOneLoader"))
    check("table:P1DG", P1DG ~= nil)
    check("fn:ScanCharacter", P1DG.ScanCharacter ~= nil)
    check("fn:PrintCharacterScan", P1DG.PrintCharacterScan ~= nil)
    check("fn:SearchAuctionItem", P1DG.SearchAuctionItem ~= nil)
    check("fn:PrintAhDiagnostics", P1DG.PrintAhDiagnostics ~= nil)
    check("fn:GetRealmPrice", P1DG.GetRealmPrice ~= nil)
    check("fn:ScanBrowseList", P1DG.ScanBrowseList ~= nil)
    check("fn:BuildRelistSuggestions", P1DG.BuildRelistSuggestions ~= nil)
    check("fn:BuildShopList", P1DG.BuildShopList ~= nil)
    check("fn:RankNextActions", P1DG.RankNextActions ~= nil)
    check("fn:RecordScan", P1DG.RecordScan ~= nil)
    check("ui:P1DruidGuide_Refresh", P1DruidGuide_Refresh ~= nil)

    local _, class = UnitClass("player")
    check("class:druid", class == "DRUID", "got " .. tostring(class))
    return pass, total
end

function P1DG.RunScanTests()
    local pass, total = 0, 0
    local function check(name, cond, detail)
        total = total + 1
        if AssertTrue(name, cond, detail) then pass = pass + 1 end
    end

    P1DG.DevLog("INFO", "=== scan ===")
    if not P1DG.ScanCharacter then
        P1DG.DevLog("FAIL", "scan:skipped — ScanCharacter missing")
        return 0, 1
    end
    local ok, scan = pcall(P1DG.ScanCharacter)
    check("scan:pcall", ok, ok and nil or tostring(scan))
    if ok and scan then
        check("scan:level", (scan.level or 0) > 0, "level=" .. tostring(scan.level))
        check("scan:gold", scan.gold ~= nil)
        check("scan:zone", scan.zone ~= nil and scan.zone ~= "")
    end
    return pass, total
end

function P1DG.RunAhTests()
    local pass, total = 0, 0
    local function check(name, cond, detail)
        total = total + 1
        if AssertTrue(name, cond, detail) then pass = pass + 1 end
    end

    P1DG.DevLog("INFO", "=== auction bridge ===")
    check("ah:Auctionator", IsAddOnLoaded("Auctionator"))
    check("ah:EnsureAuctionator", P1DG.EnsureAuctionator and P1DG.EnsureAuctionator())
    check("ah:IsAuctionatorLoaded", P1DG.IsAuctionatorLoaded and P1DG.IsAuctionatorLoaded())
    local st = P1DG.GetAhSearchStatus and P1DG.GetAhSearchStatus()
    if st then
        check("ah:frame_open", st.ahOpen, st.ahOpen and "open" or "closed (open AH for live search test)")
        check("ah:canQuery", st.canQuery ~= false, "CanSendAuctionQuery=false means wait")
        if st.ahOpen then
            check("ah:shopPane", st.hasShopPane, "reopen AH if false")
            check("ah:buyTabIndex", (st.buyTabIndex or 0) > 0, "index=" .. tostring(st.buyTabIndex))
        else
            P1DG.DevLog("WARN", "ah:live_search skipped — AH closed")
        end
    end
    if P1DG.BuildShopList then
        local shop = P1DG.BuildShopList(UnitLevel("player"), 3)
        check("ah:shop_list", type(shop) == "table")
    end
    if P1DG.GetRealmKey then
        check("ah:realm_key", P1DG.GetRealmKey() ~= "")
    end
    if P1DG.BuildRelistSuggestions then
        local relist = P1DG.BuildRelistSuggestions(3)
        check("ah:relist_table", type(relist) == "table")
    end
    return pass, total
end

function P1DG.RunShopRankTests()
    local pass, total = 0, 0
    local function check(name, cond, detail)
        total = total + 1
        if AssertTrue(name, cond, detail) then pass = pass + 1 end
    end

    P1DG.DevLog("INFO", "=== shop + rank ===")
    local lvl = UnitLevel("player")
    if P1DG.RankNextActions then
        local ranked = P1DG.RankNextActions(lvl, 5)
        check("rank:list", type(ranked) == "table")
        check("rank:count", #ranked >= 0)
    end
    return pass, total
end

function P1DG.RunSelfTests(scope)
    scope = scope or "all"
    P1DG.EmitHarnessState()
    P1DG.DevLog("INFO", "run scope=" .. scope .. " toon=" .. (UnitName("player") or "?")
        .. " zone=" .. (GetRealZoneText() or "?"))

    local pass, total = 0, 0
    local function merge(p, t)
        pass = pass + p
        total = total + t
    end

    if scope == "all" or scope == "mod" or scope == "modules" then
        local p, t = P1DG.RunModuleTests()
        merge(p, t)
    end
    if scope == "all" or scope == "scan" then
        local p, t = P1DG.RunScanTests()
        merge(p, t)
    end
    if scope == "all" or scope == "ah" or scope == "auction" then
        local p, t = P1DG.RunAhTests()
        merge(p, t)
    end
    if scope == "all" or scope == "shop" or scope == "rank" then
        local p, t = P1DG.RunShopRankTests()
        merge(p, t)
    end

    local summary = string.format("summary %d/%d pass", pass, total)
    if pass == total then
        P1DG.DevLog("PASS", summary)
    else
        P1DG.DevLog("FAIL", summary)
    end
    P1DruidGuideDB = P1DruidGuideDB or {}
    P1DruidGuideDB.lastTestAt = GetTime()
    P1DruidGuideDB.lastTestPass = pass
    P1DruidGuideDB.lastTestTotal = total
    P1DG.EmitState("summary_pass", pass)
    P1DG.EmitState("summary_total", total)
    P1DG.EmitState("summary_ok", (pass == total) and 1 or 0)
    return pass, total
end

function P1DG.PrintDevLog(lastN)
    lastN = lastN or 40
    local log = EnsureDevLog()
    P1DG.DevLog("INFO", "log dump last " .. lastN .. " of " .. #log)
    local start = math.max(1, #log - lastN + 1)
    for i = start, #log do
        local e = log[i]
        print(string.format("|cff666666%04d|r %s %s %s", i, LOG_PREFIX, e.level, e.msg))
    end
end

function P1DG.EmitState(key, value)
    P1DG.DevLog("STATE", (key or "?") .. "=" .. tostring(value))
end

function P1DG.EmitHarnessState()
    local _, class = UnitClass("player")
    P1DG.EmitState("addon_P1DruidGuide", IsAddOnLoaded("P1DruidGuide") and 1 or 0)
    P1DG.EmitState("addon_P1QuestNav", IsAddOnLoaded("P1QuestNav") and 1 or 0)
    P1DG.EmitState("addon_P1AutoQuest", IsAddOnLoaded("P1AutoQuest") and 1 or 0)
    P1DG.EmitState("addon_Auctionator", IsAddOnLoaded("Auctionator") and 1 or 0)
    P1DG.EmitState("class", class or "?")
    P1DG.EmitState("level", UnitLevel("player"))
    P1DG.EmitState("zone", GetRealZoneText() or "?")
    P1DG.EmitState("ah_open", (AuctionFrame and AuctionFrame:IsShown()) and 1 or 0)
    if P1DG.GetAhSearchStatus then
        local st = P1DG.GetAhSearchStatus()
        if st then
            P1DG.EmitState("ah_shopPane", st.hasShopPane and 1 or 0)
            P1DG.EmitState("ah_canQuery", (st.canQuery ~= false) and 1 or 0)
        end
    end
    if P1DruidGuideFrame then
        local shown = P1DruidGuideFrame:IsShown() and 1 or 0
        P1DG.EmitState("guide_visible", shown)
        P1DG.EmitState("guide_left", math.floor(P1DruidGuideFrame:GetLeft() or 0))
        P1DG.EmitState("guide_bottom", math.floor(P1DruidGuideFrame:GetBottom() or 0))
        P1DG.EmitState("guide_width", math.floor(P1DruidGuideFrame:GetWidth() or 0))
        P1DG.EmitState("guide_height", math.floor(P1DruidGuideFrame:GetHeight() or 0))
    else
        P1DG.EmitState("guide_visible", 0)
    end
    P1DruidGuideDB = P1DruidGuideDB or {}
    if P1DruidGuideDB.lastTestPass and P1DruidGuideDB.lastTestTotal then
        P1DG.EmitState("last_pass", P1DruidGuideDB.lastTestPass)
        P1DG.EmitState("last_total", P1DruidGuideDB.lastTestTotal)
    end
end

function P1DG.PrintCalibrateHint()
    P1DG.DevLog("INFO", "calibrate: hover guide line/icon, note cursor % — automation uses window-relative clicks")
    if P1DruidGuideFrame then
        local l, b = P1DruidGuideFrame:GetLeft(), P1DruidGuideFrame:GetBottom()
        local w, h = P1DruidGuideFrame:GetWidth(), P1DruidGuideFrame:GetHeight()
        P1DG.DevLog("INFO", string.format("guide_frame left=%.0f bottom=%.0f w=%.0f h=%.0f",
            l or 0, b or 0, w or 0, h or 0))
    end
    local x, y = GetCursorPosition()
    local s = P1DruidGuideFrame and P1DruidGuideFrame:GetEffectiveScale() or 1
    P1DG.DevLog("INFO", string.format("cursor_ui %.0f,%.0f scale=%.2f", x / s, y / s, s))
    P1DG.EmitHarnessState()
end

local function HandleP1Test(msg)
    msg = string.lower((msg or ""):match("^%s*(.-)%s*$") or "")
    if msg == "" or msg == "run" or msg == "all" then
        P1DG.RunSelfTests("all")
    elseif msg == "mod" or msg == "modules" then
        P1DG.RunSelfTests("mod")
    elseif msg == "scan" then
        P1DG.RunSelfTests("scan")
    elseif msg == "ah" or msg == "auction" then
        P1DG.RunSelfTests("ah")
    elseif msg == "log" then
        P1DG.PrintDevLog(60)
    elseif msg == "clear" then
        P1DruidGuideDB.devLog = {}
        P1DG.DevLog("INFO", "log cleared")
    elseif msg == "cal" or msg == "calibrate" then
        P1DG.PrintCalibrateHint()
    elseif msg == "state" or msg == "status" then
        P1DG.EmitHarnessState()
    else
        P1DG.DevLog("INFO", "usage: /p1test run|mod|scan|ah|state|log|clear|calibrate")
    end
end

SLASH_P1TEST1 = "/p1test"
SlashCmdList["P1TEST"] = HandleP1Test