-- Static Horde / Icecrown leveling data (3.3.5a)

P1AG = P1AG or {}

-- itemId = { name, goal, profHint }
P1AG.MAT_WATCH = {
    [2589]  = { "Linen Cloth", 40, "Tailoring / First Aid" },
    [2939]  = { "Ruined Leather Scraps", 20, "Leatherworking" },
    [2318]  = { "Light Leather", 20, "Skinning" },
    [2320]  = { "Coarse Thread", 10, "Tailoring" },
    [2447]  = { "Peacebloom", 15, "Herbalism / Alchemy" },
    [765]   = { "Silverleaf", 15, "Herbalism" },
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
