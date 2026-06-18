-- P1 Druid Guide — Horde druid leveling data (3.3.5a)

P1DG = P1DG or {}
P1AG = P1DG

P1DG.FIRST_AID = {
    finalLevel = 40,
    tiers = {
        {
            skillMin = 1, skillMax = 75, levelMin = 1, levelMax = 15,
            label = "Apprentice FA (1-75)",
            clothId = 2589, clothName = "Linen",
            bandageIds = { [1251] = 1, [2581] = 1 },
            goalTotal = 80,
        },
        {
            skillMin = 75, skillMax = 150, levelMin = 15, levelMax = 30,
            label = "Journeyman FA (75-150)",
            clothId = 2592, clothName = "Wool",
            bandageIds = { [3530] = 1, [3531] = 1 },
            goalTotal = 60,
        },
        {
            skillMin = 150, skillMax = 225, levelMin = 30, levelMax = 40,
            label = "Expert FA (150-225)",
            clothId = 4306, clothName = "Silk",
            bandageIds = { [6450] = 2, [6451] = 2, [8544] = 3, [8545] = 3 },
            altClothId = 4338, altClothName = "Mageweave",
            goalTotal = 50,
        },
    },
}

P1DG.HERB_MILESTONES = {
    { levelMin = 1, levelMax = 15, items = {
        { id = 2447, name = "Peacebloom", goal = 20 },
        { id = 765,  name = "Silverleaf", goal = 20 },
    }},
    { levelMin = 15, levelMax = 30, items = {
        { id = 2450, name = "Briarthorn", goal = 15 },
        { id = 785,  name = "Mageroyal", goal = 15 },
    }},
    { levelMin = 30, levelMax = 40, items = {
        { id = 3820, name = "Stranglekelp", goal = 12 },
        { id = 3355, name = "Wild Steelbloom", goal = 12 },
    }},
}

P1DG.ORE_MILESTONES = {
    { levelMin = 1, levelMax = 15, items = {
        { id = 2770, name = "Copper Ore", goal = 20 },
    }},
    { levelMin = 15, levelMax = 30, items = {
        { id = 2771, name = "Tin Ore", goal = 15 },
        { id = 2772, name = "Iron Ore", goal = 10 },
    }},
    { levelMin = 30, levelMax = 40, items = {
        { id = 3858, name = "Mithril Ore", goal = 10 },
    }},
}

P1DG.MAT_WATCH = {
    { id = 2939, name = "Ruined Leather Scraps", goal = 20, levelMin = 1, levelMax = 15, hint = "Leatherworking" },
    { id = 2318, name = "Light Leather", goal = 30, levelMin = 10, levelMax = 25, hint = "Skinning" },
    { id = 2320, name = "Coarse Thread", goal = 10, levelMin = 10, levelMax = 20, hint = "Tailoring" },
    { id = 4231, name = "Cured Light Hide", goal = 10, levelMin = 20, levelMax = 35, hint = "Leatherworking" },
}

-- Farm hints when bag counts fall below herb/ore goals
P1DG.GATHER_FARM = {
    [2447] = { name = "Peacebloom", farms = {
        { zone = "Mulgore", dir = "plains", levelMin = 1, levelMax = 15 },
        { zone = "Durotar", dir = "valley", levelMin = 1, levelMax = 15 },
    }},
    [765] = { name = "Silverleaf", farms = {
        { zone = "Mulgore", dir = "NE", levelMin = 1, levelMax = 15 },
        { zone = "Tirisfal", dir = "fields", levelMin = 1, levelMax = 15 },
    }},
    [2450] = { name = "Briarthorn", farms = {
        { zone = "Barrens", dir = "north", levelMin = 15, levelMax = 25 },
        { zone = "Silverpine", dir = "forest", levelMin = 15, levelMax = 25 },
    }},
    [785] = { name = "Mageroyal", farms = {
        { zone = "Barrens", dir = "Oasis", levelMin = 15, levelMax = 25 },
    }},
    [2770] = { name = "Copper Ore", farms = {
        { zone = "Mulgore", dir = "Red Rocks", levelMin = 1, levelMax = 15 },
        { zone = "Durotar", dir = "caves", levelMin = 1, levelMax = 15 },
    }},
    [2771] = { name = "Tin Ore", farms = {
        { zone = "Barrens", dir = "east ridges", levelMin = 15, levelMax = 25 },
    }},
}

-- BIS by level bracket — ordered by impact (Weapon first)
P1DG.BIS_BRACKETS = {
    {
        levelMin = 10, levelMax = 15,
        slots = {
            { key = "Weapon", order = 1, equipSlot = 16, minIlvl = 15,
              suggest = "Agi 2H Staff/Mace ilvl 15+", source = "Quest/AH" },
            { key = "Chest", order = 2, equipSlot = 5, minIlvl = 14,
              suggest = "+Agi/+Sta chest", source = "Quest" },
            { key = "Legs", order = 3, equipSlot = 7, minIlvl = 13,
              suggest = "+Agi legs", source = "Quest" },
            { key = "Trinket", order = 4, equipSlot = 13, minIlvl = 12,
              suggest = "Any +Sta trinket", source = "Quest drop" },
        },
    },
    {
        levelMin = 15, levelMax = 20,
        slots = {
            { key = "Weapon", order = 1, equipSlot = 16, minIlvl = 18,
              suggest = "Agi 2H ilvl 18+ (Staff of Nobles)", source = "Quest/AH" },
            { key = "Chest", order = 2, equipSlot = 5, minIlvl = 17,
              suggest = "+Agi chest ilvl 17+", source = "Quest" },
            { key = "Legs", order = 3, equipSlot = 7, minIlvl = 16,
              suggest = "+Agi legs", source = "Quest" },
            { key = "Hands", order = 4, equipSlot = 10, minIlvl = 15,
              suggest = "+Agi gloves", source = "Quest" },
            { key = "Trinket", order = 5, equipSlot = 13, minIlvl = 15,
              suggest = "Stamina trinket", source = "Quest" },
        },
    },
    {
        levelMin = 20, levelMax = 25,
        slots = {
            { key = "Weapon", order = 1, equipSlot = 16, minIlvl = 22,
              suggest = "Agi 2H ilvl 22+ (Crescent Staff)", source = "Quest" },
            { key = "Chest", order = 2, equipSlot = 5, minIlvl = 21,
              suggest = "+Agi chest", source = "Quest/AH" },
            { key = "Legs", order = 3, equipSlot = 7, minIlvl = 20,
              suggest = "+Agi legs", source = "Quest" },
            { key = "Cloak", order = 4, equipSlot = 15, minIlvl = 18,
              suggest = "+Agi cloak", source = "Quest" },
            { key = "Trinket", order = 5, equipSlot = 13, minIlvl = 18,
              suggest = "Stamina/Agi trinket", source = "Quest" },
        },
    },
    {
        levelMin = 25, levelMax = 30,
        slots = {
            { key = "Weapon", order = 1, equipSlot = 16, minIlvl = 26,
              suggest = "Agi 2H ilvl 26+ (Mograine's Might alt)", source = "Dungeon/AH" },
            { key = "Chest", order = 2, equipSlot = 5, minIlvl = 25,
              suggest = "+Agi chest", source = "Quest" },
            { key = "Legs", order = 3, equipSlot = 7, minIlvl = 24,
              suggest = "+Agi legs", source = "Quest" },
            { key = "Head", order = 4, equipSlot = 1, minIlvl = 22,
              suggest = "+Agi helm", source = "Quest" },
            { key = "Trinket", order = 5, equipSlot = 13, minIlvl = 20,
              suggest = "Stamina trinket", source = "Quest" },
        },
    },
    {
        levelMin = 30, levelMax = 40,
        slots = {
            { key = "Weapon", order = 1, equipSlot = 16, minIlvl = 32,
              suggest = "Agi 2H ilvl 32+ (Pole of the Ages)", source = "Quest chain" },
            { key = "Chest", order = 2, equipSlot = 5, minIlvl = 30,
              suggest = "+Agi chest ilvl 30+", source = "Quest" },
            { key = "Legs", order = 3, equipSlot = 7, minIlvl = 28,
              suggest = "+Agi legs", source = "Quest" },
            { key = "Trinket", order = 4, equipSlot = 13, minIlvl = 25,
              suggest = "Stamina trinket", source = "Quest" },
            { key = "Enchants", order = 5, equipSlot = nil, minIlvl = 0,
              suggest = "Later: +Agi to cloak, minor stamina boots", source = "AH" },
        },
    },
}

P1DG.AH_TIPS = {
    { levelMin = 11, levelMax = 20, itemId = 2589, itemName = "Linen Cloth",
      tip = "Buy: Linen stacks if <20 total healing", skipIfHave = 20,
      checkBandages = true },
    { levelMin = 11, levelMax = 20, itemId = 118, itemName = "Minor Healing Potion",
      tip = "Buy: Minor Healing Potion — sustain between pulls", goal = 10 },
    { levelMin = 15, levelMax = 30, itemId = 2592, itemName = "Wool Cloth",
      tip = "Buy: Wool Cloth stacks for FA 75+", goal = 40 },
    { levelMin = 11, levelMax = 25, itemName = "BoE +Agi weapon",
      tip = "Buy: BoE +Agi 2H Mace ilvl 15-20 (~5g) — big dps boost",
      equipSlot = 16, maxIlvl = 22, isGeneric = true },
    { levelMin = 25, levelMax = 35, itemId = 2459, itemName = "Swiftness Potion",
      tip = "Buy: Swiftness Potion for long travel legs", goal = 5 },
}
