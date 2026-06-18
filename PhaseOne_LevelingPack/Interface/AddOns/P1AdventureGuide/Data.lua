-- Static Horde / Icecrown leveling data (3.3.5a)

P1AG = P1AG or {}

-- First Aid tiers: cloth + crafted bandages count as equivalent linen/wool/etc.
P1AG.FIRST_AID = {
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

-- Herb milestones by level band (alchemy prep)
P1AG.HERB_MILESTONES = {
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

-- Leather / tailoring basics (simple raw counts)
P1AG.MAT_WATCH = {
    { id = 2939, name = "Ruined Leather Scraps", goal = 20, levelMin = 1, levelMax = 15, hint = "Leatherworking" },
    { id = 2318, name = "Light Leather", goal = 30, levelMin = 10, levelMax = 25, hint = "Skinning" },
    { id = 2320, name = "Coarse Thread", goal = 10, levelMin = 10, levelMax = 20, hint = "Tailoring" },
    { id = 4231, name = "Cured Light Hide", goal = 10, levelMin = 20, levelMax = 35, hint = "Leatherworking" },
}

P1AG.LEVEL_ACTIONS = {
    { lvl = 10,  text = "Pick up Skinning + Herbalism in starter zone — huge gold saver." },
    { lvl = 10,  text = "Complete Cat Form / Bear Form class quests." },
    { lvl = 12,  text = "Train weapon skills; set hearth to Crossroads (Barrens)." },
    { lvl = 16,  text = "Stock food/water; keep Rejuvenation up between pulls." },
    { lvl = 20,  text = "Switch to Cat Form full-time — train Mangle when available." },
    { lvl = 22,  text = "Head to Barrens south — dense quest hub, great XP/hour." },
    { lvl = 25,  text = "Train professions to Journeyman (75+) if not yet." },
    { lvl = 28,  text = "Consider Thousand Needles or Ashenvale for next quest block." },
    { lvl = 32,  text = "Keep Rip uptime; skin every beast for leather gold." },
    { lvl = 40,  text = "Prep for Outland — stock 20+ food, repair all gear." },
}

P1AG.ZONE_RARES = {
    ["Mulgore"] = "Arra'chea (8) — east plains | Mazzranache (9) — south",
    ["Durotar"] = "Felweaver Scornn (11) — cave north | Death Flayer (11)",
    ["The Barrens"] = "Razormaw (25) — river | Oversized Plainstrider (24) | Aean Swiftriver (25)",
    ["Stonetalon Mountains"] = "Sister Hatelash (22) — east | Boahn (28) — cave",
    ["Thousand Needles"] = "Achellios (26) — racetrack | Ironeye (28)",
    ["Ashenvale"] = "Ursol'lok (31) | Terrowulf Packlord (28)",
    ["Hillsbrad Foothills"] = "Narillasanz (31) | Snarlmane (29)",
}

P1AG.PROF_TIPS = {
    ["Skinning"] = "Skin every kill — pairs perfectly with Feral leveling.",
    ["Herbalism"] = "Pick herbs while traveling between quest hubs.",
    ["Mining"] = "Sell ore stacks on AH for mount money.",
    ["First Aid"] = "Turn linen into bandages — free heals.",
    ["Tailoring"] = "Linen bags sell well on Icecrown AH.",
}
