-- P1 Druid Guide v2 — scan history + session delta

P1DG = P1DG or {}

local MAX_HISTORY = 20

local function EnsureBrainDB()
    P1DruidGuideDB = P1DruidGuideDB or {}
    P1DruidGuideDB.scanHistory = P1DruidGuideDB.scanHistory or {}
    return P1DruidGuideDB
end

function P1DG.RecordScan(scan)
    if not scan then return end
    local db = EnsureBrainDB()
    local snap = {
        at = scan.scannedAt or GetTime(),
        level = scan.level,
        gold = scan.gold,
        activeQuests = scan.activeQuests,
        zone = scan.zone,
        weaponIlvl = scan.slots and scan.slots[16] and scan.slots[16].ilvl or 0,
    }
    table.insert(db.scanHistory, 1, snap)
    while #db.scanHistory > MAX_HISTORY do
        table.remove(db.scanHistory)
    end
    if not P1DG._sessionBaseline then
        P1DG._sessionBaseline = snap
    end
    return snap
end

function P1DG.ResetSessionBaseline()
    P1DG._sessionBaseline = nil
    if P1DruidGuideDB and P1DruidGuideDB.characterScan then
        P1DG.RecordScan(P1DruidGuideDB.characterScan)
    end
end

function P1DG.GetScanDelta()
    local scan = P1DG.GetScan and P1DG.GetScan()
    if not scan then return nil end
    local base = P1DG._sessionBaseline
    if not base then return nil end
    local weaponIlvl = scan.slots and scan.slots[16] and scan.slots[16].ilvl or 0
    return {
        gold = (scan.gold or 0) - (base.gold or 0),
        quests = (scan.activeQuests or 0) - (base.activeQuests or 0),
        level = (scan.level or 0) - (base.level or 0),
        weaponIlvl = weaponIlvl - (base.weaponIlvl or 0),
    }
end

function P1DG.FormatDeltaGold(copper)
    if not copper or copper == 0 then return "±0" end
    local sign = copper > 0 and "+" or ""
    if P1DG.FormatGoldShort then
        return sign .. P1DG.FormatGoldShort(math.abs(copper))
    end
    return sign .. tostring(copper) .. "c"
end

function P1DG.PrintScanDelta()
    local d = P1DG.GetScanDelta()
    if not d then
        print("  |cff888888(no session baseline yet)|r")
        return
    end
    print(string.format("  |cff666666Since login:|r gold %s · quests %+d · weapon ilvl %+d",
        P1DG.FormatDeltaGold(d.gold), d.quests or 0, d.weaponIlvl or 0))
end