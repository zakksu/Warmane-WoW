-- P1 Warlock Guide — Horde warlock PATH (Grok-verified skeleton, 3.3.5a)

P1WG = P1WG or {}
P1DG = P1WG

P1WG.PATH_STEPS = {
    { level = 10, impact = 100, type = "spell", spellId = 697,
      text = "Summon Voidwalker — complete Durotar/Barrens pet quest" },
    { level = 14, impact = 95, type = "spell", spellId = 980,
      text = "Curse of Agony — second DoT on every pull" },
    { level = 18, impact = 90, type = "gear", equipSlot = 18, minIlvl = 12, itemId = 5210,
      text = "AH/vendor: Burning Wand (+shadow dmg)" },
    { level = 24, impact = 85, type = "spell", spellId = 689,
      text = "Drain Life — filler + self-heal while DoTs tick" },
    { level = 30, impact = 80, type = "spell", spellId = 691,
      text = "Summon Felhunter — dispels + better vs casters" },
}

P1WG.GOLD_AH_BIS = {
    { levelMin = 10, levelMax = 20, itemId = 5210, label = "Wand", equipSlot = 18, minIlvl = 12 },
    { levelMin = 16, levelMax = 28, itemId = 3902, label = "Staff", equipSlot = 16, minIlvl = 18 },
}
