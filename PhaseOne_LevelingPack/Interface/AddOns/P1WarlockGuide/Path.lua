-- P1 Warlock Guide — path engine (shared logic with druid Path.lua)

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
    if step.type == "spell" then return HasSpell(step.spellId) end
    if step.type == "gear" then
        if step.itemId and step.equipSlot and EquippedId(step.equipSlot) == step.itemId then return true end
        if step.equipSlot and step.minIlvl then return EquippedIlvl(step.equipSlot) >= step.minIlvl end
        return false
    end
    if step.type == "profession" then return FaSkill() >= (step.skill or 0) end
    if step.type == "consume" then return CountItem(step.itemId) >= (step.goal or 1) end
    if step.type == "level" then return playerLevel > (step.level or 0) end
    if step.type == "hint" then return playerLevel > (step.maxLevel or step.level or 0) end
    return false
end

function P1DG.GetOptimalSteps(playerLevel, maxN)
    maxN = maxN or 5
    local out = {}
    if not P1DG.PATH_STEPS then return out end
    for _, step in ipairs(P1DG.PATH_STEPS) do
        if playerLevel >= (step.level or 1) and not P1DG.IsStepDone(step, playerLevel) then
            out[#out + 1] = step
        end
    end
    table.sort(out, function(a, b)
        if a.impact ~= b.impact then return (a.impact or 0) > (b.impact or 0) end
        return (a.level or 0) < (b.level or 0)
    end)
    while #out > maxN do table.remove(out) end
    return out
end
