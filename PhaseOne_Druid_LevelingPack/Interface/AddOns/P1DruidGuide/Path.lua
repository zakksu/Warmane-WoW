-- P1 Druid Guide — optimal path engine (feral leveling, gold-budget AH)

P1DG = P1DG or {}

local function CountItem(itemId)
    if not itemId then return 0 end
    local total = 0
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local link = GetContainerItemLink(bag, slot)
            if link and tonumber(link:match("item:(%d+)")) == itemId then
                local _, c = GetContainerItemInfo(bag, slot)
                total = total + (c or 1)
            end
        end
    end
    return total
end

local function EquippedId(slot)
    if not slot then return nil end
    local link = GetInventoryItemLink("player", slot)
    if not link then return nil end
    return tonumber(link:match("item:(%d+)"))
end

local function EquippedIlvl(slot)
    if not slot then return 0 end
    local link = GetInventoryItemLink("player", slot)
    if not link then return 0 end
    local _, _, _, lvl = GetItemInfo(link)
    return lvl or 0
end

local function HasSpell(spellId)
    if not spellId then return false end
    local name = GetSpellInfo(spellId)
    if not name then return false end
    for i = 1, 300 do
        local n = GetSpellName(i, BOOKTYPE_SPELL)
        if not n then break end
        if n == name then return true end
    end
    return false
end

local function FaSkill()
    for i = 1, GetNumSkillLines() do
        local name, _, _, rank = GetSkillLineInfo(i)
        if name == "First Aid" then return rank or 0 end
    end
    return 0
end

function P1DG.IsStepDone(step, playerLevel)
    if playerLevel < (step.level or 1) then return true end
    if step.type == "spell" then
        return HasSpell(step.spellId)
    end
    if step.type == "gear" then
        if step.itemId and step.equipSlot then
            if EquippedId(step.equipSlot) == step.itemId then return true end
        end
        if step.equipSlot and step.minIlvl then
            return EquippedIlvl(step.equipSlot) >= step.minIlvl
        end
        return false
    end
    if step.type == "profession" then
        return FaSkill() >= (step.skill or 0)
    end
    if step.type == "consume" then
        return CountItem(step.itemId) >= (step.goal or 1)
    end
    if step.type == "level" then
        return playerLevel > (step.level or 0)
    end
    if step.type == "hint" then
        return playerLevel > (step.maxLevel or step.level or 0)
    end
    return false
end

function P1DG.GetOptimalSteps(playerLevel, maxN)
    maxN = maxN or 5
    local out = {}
    if not P1DG.PATH_STEPS then return out end
    for _, step in ipairs(P1DG.PATH_STEPS) do
        if playerLevel >= (step.level or 1) then
            if not P1DG.IsStepDone(step, playerLevel) then
                out[#out + 1] = step
            end
        end
    end
    table.sort(out, function(a, b)
        if a.impact ~= b.impact then return (a.impact or 0) > (b.impact or 0) end
        return (a.level or 0) < (b.level or 0)
    end)
    while #out > maxN do table.remove(out) end
    return out
end

function P1DG.IsBisSlotDone(slot)
    if not slot then return true end
    if slot.itemId and slot.equipSlot then
        if EquippedId(slot.equipSlot) == slot.itemId then return true end
    end
    if slot.equipSlot and slot.minIlvl and slot.minIlvl > 0 then
        return EquippedIlvl(slot.equipSlot) >= slot.minIlvl
    end
    if not slot.equipSlot then return false end
    return false
end

function P1DG.GetBisBracket(playerLevel)
    for _, bracket in ipairs(P1DG.BIS_BRACKETS or {}) do
        if playerLevel >= bracket.levelMin and playerLevel <= bracket.levelMax then
            return bracket
        end
    end
    return P1DG.BIS_BRACKETS and P1DG.BIS_BRACKETS[#P1DG.BIS_BRACKETS]
end

function P1DG.GetNextBisUpgrade(playerLevel)
    local bracket = P1DG.GetBisBracket(playerLevel)
    if not bracket then return nil end
    local slots = {}
    for _, s in ipairs(bracket.slots) do slots[#slots + 1] = s end
    table.sort(slots, function(a, b) return (a.order or 99) < (b.order or 99) end)
    for _, slot in ipairs(slots) do
        if not P1DG.IsBisSlotDone(slot) then
            return slot
        end
    end
    return nil
end

function P1DG.GetPendingBisIcons(playerLevel, maxN)
    maxN = maxN or 4
    local icons = {}
    local bracket = P1DG.GetBisBracket(playerLevel)
    if not bracket then return icons end
    local slots = {}
    for _, s in ipairs(bracket.slots) do slots[#slots + 1] = s end
    table.sort(slots, function(a, b) return (a.order or 99) < (b.order or 99) end)
    for _, slot in ipairs(slots) do
        if slot.itemId and slot.equipSlot then
            local done = EquippedId(slot.equipSlot) == slot.itemId
            if not done and EquippedIlvl(slot.equipSlot) < (slot.minIlvl or 0) then
                icons[#icons + 1] = {
                    itemId = slot.itemId,
                    label = slot.key,
                    source = slot.source,
                    why = slot.why,
                    flavor = slot.flavor,
                    waypoint = slot.waypoint,
                    goldAh = true,
                }
            end
        end
        if #icons >= maxN then break end
    end
    for _, ah in ipairs(P1DG.GOLD_AH_BIS or {}) do
        if #icons >= maxN then break end
        if playerLevel >= ah.levelMin and playerLevel <= ah.levelMax then
            if ah.itemId and ah.equipSlot then
                if EquippedIlvl(ah.equipSlot) < (ah.minIlvl or 0) and EquippedId(ah.equipSlot) ~= ah.itemId then
                    local dup = false
                    for _, ic in ipairs(icons) do if ic.itemId == ah.itemId then dup = true break end end
                    if not dup then
                        icons[#icons + 1] = { itemId = ah.itemId, label = ah.label, source = "AH", goldAh = true }
                    end
                end
            end
        end
    end
    return icons
end

function P1DG.GetItemIcon(itemId)
    if not itemId then return "Interface\\Icons\\INV_Misc_QuestionMark" end
    local _, _, _, _, _, _, _, _, _, tex = GetItemInfo(itemId)
    if tex then return tex end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

function P1DG.GetTalentTip(playerLevel)
    if not P1DG.TALENT_SCHEDULE then return nil end
    for _, row in ipairs(P1DG.TALENT_SCHEDULE) do
        if row.level == playerLevel then return row.tip end
    end
    return nil
end

function P1DG.FindBisSlotForStep(step)
    if not step or step.type ~= "gear" then return nil end
    if step.waypoint then return step end
    if not step.itemId then return nil end
    for _, bracket in ipairs(P1DG.BIS_BRACKETS or {}) do
        for _, slot in ipairs(bracket.slots) do
            if slot.itemId == step.itemId then return slot end
        end
    end
    return nil
end