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
    { levelMin = 40, levelMax = 50, items = {
        { id = 3818, name = "Fadeleaf", goal = 10 },
        { id = 3821, name = "Goldthorn", goal = 10 },
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
    { levelMin = 40, levelMax = 50, items = {
        { id = 10620, name = "Thorium Ore", goal = 8 },
        { id = 7912, name = "Solid Stone", goal = 10 },
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

-- BIS by level bracket — ordered by impact (Weapon first). Real Horde druid quest/AH picks.
P1DG.BIS_BRACKETS = {
    {
        levelMin = 10, levelMax = 15,
        slots = {
            { key = "Weapon", order = 1, equipSlot = 16, minIlvl = 15,
              suggest = "Crooked Staff / BoE Agi 2H", itemName = "Crooked Staff",
              source = "Mulgore quests / AH ~5g" },
            { key = "Chest", order = 2, equipSlot = 5, minIlvl = 14,
              suggest = "Rugged Leather Vest", itemName = "Rugged Leather Vest",
              source = "Quest: Dwarven Digging" },
            { key = "Legs", order = 3, equipSlot = 7, minIlvl = 13,
              suggest = "+Agi legs any green", source = "Quest rewards" },
            { key = "Trinket", order = 4, equipSlot = 13, minIlvl = 12,
              suggest = "Ritual Totem / any +Sta", source = "Quest drop" },
        },
    },
    {
        levelMin = 15, levelMax = 20,
        slots = {
            { key = "Weapon", order = 1, equipSlot = 16, minIlvl = 18,
              suggest = "Staff of Nobles", itemName = "Staff of Nobles", itemId = 5201,
              source = "Quest: The Den (Barrens)" },
            { key = "Chest", order = 2, equipSlot = 5, minIlvl = 17,
              suggest = "Savage Trodders / +Agi chest", source = "Quest chain" },
            { key = "Legs", order = 3, equipSlot = 7, minIlvl = 16,
              suggest = "Leggings of the Fang (dungeon)", itemName = "Leggings of the Fang",
              source = "Wailing Caverns" },
            { key = "Hands", order = 4, equipSlot = 10, minIlvl = 15,
              suggest = "+Agi gloves", source = "Quest" },
            { key = "Trinket", order = 5, equipSlot = 13, minIlvl = 15,
              suggest = "Runed Ring / Stamina trinket", source = "Quest" },
        },
    },
    {
        levelMin = 20, levelMax = 25,
        slots = {
            { key = "Weapon", order = 1, equipSlot = 16, minIlvl = 22,
              suggest = "Crescent Staff", itemName = "Crescent Staff", itemId = 6630,
              source = "Quest: The Crescent Grove" },
            { key = "Chest", order = 2, equipSlot = 5, minIlvl = 21,
              suggest = "Embrace of the Viper", itemName = "Embrace of the Viper",
              source = "Wailing Caverns" },
            { key = "Legs", order = 3, equipSlot = 7, minIlvl = 20,
              suggest = "+Agi legs ilvl 20+", source = "Barrens quests" },
            { key = "Cloak", order = 4, equipSlot = 15, minIlvl = 18,
              suggest = "+Agi cloak", source = "Quest/AH" },
            { key = "Trinket", order = 5, equipSlot = 13, minIlvl = 18,
              suggest = "Orb of the Darkmoon", itemName = "Orb of the Darkmoon",
              source = "Darkmoon Faire (optional)" },
        },
    },
    {
        levelMin = 25, levelMax = 30,
        slots = {
            { key = "Weapon", order = 1, equipSlot = 16, minIlvl = 26,
              suggest = "Mograine's Might (2H) or Agi staff", itemName = "Mograine's Might",
              source = "Scarlet Monastery / AH" },
            { key = "Chest", order = 2, equipSlot = 5, minIlvl = 25,
              suggest = "Armor of the Fang", itemName = "Armor of the Fang",
              source = "Wailing Caverns set" },
            { key = "Legs", order = 3, equipSlot = 7, minIlvl = 24,
              suggest = "+Agi legs ilvl 24+", source = "Thousand Needles" },
            { key = "Head", order = 4, equipSlot = 1, minIlvl = 22,
              suggest = "Glowing Lizardscale Cloak alt / +Agi helm", source = "Quest" },
            { key = "Trinket", order = 5, equipSlot = 13, minIlvl = 20,
              suggest = "Horn of the Beast", itemName = "Horn of the Beast", itemId = 5821,
              source = "Quest: The Sacred Flame" },
        },
    },
    {
        levelMin = 30, levelMax = 40,
        slots = {
            { key = "Weapon", order = 1, equipSlot = 16, minIlvl = 32,
              suggest = "Pole of the Ages", itemName = "Pole of the Ages", itemId = 10648,
              source = "Quest: The Swarm Grows (Thousand Needles)" },
            { key = "Chest", order = 2, equipSlot = 5, minIlvl = 30,
              suggest = "Wildheart Vest / +Agi chest", source = "Quest chain" },
            { key = "Legs", order = 3, equipSlot = 7, minIlvl = 28,
              suggest = "+Agi legs ilvl 28+", source = "Desolace / Stranglethorn" },
            { key = "Trinket", order = 4, equipSlot = 13, minIlvl = 25,
              suggest = "Mark of the Chosen", itemName = "Mark of the Chosen",
              source = "Maraudon / quest" },
            { key = "Enchants", order = 5, equipSlot = nil, minIlvl = 0,
              suggest = "+Agi cloak, minor stamina boots", source = "AH when spare gold" },
        },
    },
    {
        levelMin = 40, levelMax = 50,
        slots = {
            { key = "Weapon", order = 1, equipSlot = 16, minIlvl = 42,
              suggest = "Golem Skull Staff / +Agi 2H", itemName = "Golem Skull Staff", itemId = 9427,
              source = "Uldaman / AH" },
            { key = "Chest", order = 2, equipSlot = 5, minIlvl = 40,
              suggest = "Wildheart Vest", itemName = "Wildheart Vest", itemId = 16706,
              source = "Dire Maul / quest chain" },
            { key = "Legs", order = 3, equipSlot = 7, minIlvl = 40,
              suggest = "Wildheart Kilt", itemName = "Wildheart Kilt", itemId = 16709,
              source = "Dire Maul / STV quests" },
            { key = "Head", order = 4, equipSlot = 1, minIlvl = 38,
              suggest = "Wildheart Cowl", itemName = "Wildheart Cowl", itemId = 16707,
              source = "Dire Maul set piece" },
            { key = "Trinket", order = 5, equipSlot = 13, minIlvl = 35,
              suggest = "Hand of Justice", itemName = "Hand of Justice", itemId = 11815,
              source = "Blackrock Depths (optional)" },
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
    { levelMin = 40, levelMax = 50, itemId = 3827, itemName = "Mana Potion",
      tip = "Buy: Mana Potion stacks for caster pulls / Innervate gaps", goal = 10 },
}

-- Level-bracketed Horde Feral/Caster leveling tips (lvl 10-50)
P1DG.TIPS_BRACKETS = {
    {
        levelMin = 10, levelMax = 15,
        zone = "Mulgore / Bloodhoof",
        rotation = "Cat at 10: Rake → Mangle → Shred\nRejuv between pulls",
        talents = "Next: Furor (shift w/ energy) or Feral Aggression",
        survival = "Bear if 2+ mobs; run below 35% HP",
        quests = "Rite of Vision · Mazzranache · The Ravaged Caravan · Dwarven Digging",
        gather = "Peacebloom/Silverleaf · Copper at Red Rocks",
    },
    {
        levelMin = 15, levelMax = 20,
        zone = "The Barrens",
        rotation = "Rake → 5cp Rip → Shred filler\nThorns + Mark of the Wild on pull",
        talents = "Next: Sharpened Claws / Feral Swiftness",
        survival = "Bear tough casters; bandage between pulls",
        quests = "The Den (Staff of Nobles) · Raptor Horns · Plainstrider Menace",
        gather = "Briarthorn/Mageroyal north Barrens · Tin ridges",
    },
    {
        levelMin = 20, levelMax = 30,
        zone = "Ashenvale / Stonetalon",
        rotation = "Travel Form between nodes\nCat: Rake → Rip at 5cp → Ferocious Bite",
        talents = "Next: Feral Charge (30) — save points until then",
        survival = "Bear elites; Innervate before long chains",
        quests = "The Sacred Flame (Horn of Beast) · WC set pieces",
        gather = "Stranglekelp coast · Iron in Stonetalon",
    },
    {
        levelMin = 30, levelMax = 40,
        zone = "Shimmering Flats / Desolace / Arathi",
        rotation = "Cat grind: Rake → Rip → Shred\nFa pots on cooldown in bear",
        talents = "Next: Leader of the Pack (if grouping) or Savage Fury",
        survival = "Bear + Fa pot vs 3+ mobs; run at 25%",
        quests = "The Swarm Grows (Pole of Ages) · Reclaiming the Charred Vale",
        gather = "Mithril Flats · Silk/Mageweave for FA Expert",
    },
    {
        levelMin = 40, levelMax = 50,
        zone = "Tanaris / Feralas / STV",
        rotation = "Wildheart cat: maintain Rip/Rake\nShift bear for pull, cat for burn",
        talents = "Next: Predatory Strikes · prep 60 mount gold",
        survival = "Bear STV elites; always Mark/Thorns",
        quests = "Wildheart set in Dire Maul · Zul'Farrak for XP",
        gather = "Fadeleaf/Goldthorn STV · Thorium later zones",
    },
}
