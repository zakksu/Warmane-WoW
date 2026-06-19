-- P1 Warlock Guide — Horde warlock PATH (3.3.5a, Questie-verified IDs)

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
    { level = 32, impact = 78, type = "spell", spellId = 5740,
      text = "Rain of Fire — AoE quest packs" },
    { level = 34, impact = 76, type = "hint", maxLevel = 36,
      text = "Rotation: CoA → Corruption → SB → Drain Life <40% HP" },
    { level = 36, impact = 74, type = "gear", equipSlot = 13, minIlvl = 50, itemId = 12930,
      text = "AH: Briarwood Reed trinket (Int spike)" },
    { level = 40, impact = 72, type = "spell", spellId = 19028,
      text = "Soul Link — survivability for long chains" },
    { level = 42, impact = 70, type = "spell", spellId = 6789,
      text = "Death Coil — panic button / execute" },
    { level = 46, impact = 68, type = "gear", equipSlot = 16, minIlvl = 42, itemId = 9427,
      text = "AH: Golem Skull Staff or +Int staff upgrade" },
    { level = 50, impact = 66, type = "spell", spellId = 28176,
      text = "Fel Armor — armor + spell power buff" },
}

P1WG.GOLD_AH_BIS = {
    { levelMin = 10, levelMax = 20, itemId = 5210, label = "Wand", equipSlot = 18, minIlvl = 12 },
    { levelMin = 16, levelMax = 28, itemId = 3902, label = "Staff", equipSlot = 16, minIlvl = 18 },
    { levelMin = 34, levelMax = 50, itemId = 12930, label = "Trinket", equipSlot = 13, minIlvl = 50 },
    { levelMin = 44, levelMax = 55, itemId = 9427, label = "Staff", equipSlot = 16, minIlvl = 42 },
}
