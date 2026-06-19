-- P1 Warlock Guide — Horde warlock PATH data (scaffold, 3.3.5a)

P1WG = P1WG or {}
P1DG = P1WG

P1WG.PATH_STEPS = {
    { level = 10, impact = 100, type = "spell", spellId = 686,
      text = "Train Shadow Bolt — main filler" },
    { level = 10, impact = 98, type = "spell", spellId = 172,
      text = "Train Corruption — apply on pull" },
    { level = 10, impact = 95, type = "gear", equipSlot = 16, minIlvl = 12, itemId = 5214,
      text = "AH: Wand of Orman — first wand upgrade" },
    { level = 12, impact = 90, type = "spell", spellId = 980,
      text = "Train Curse of Agony — long fight DoT" },
    { level = 14, impact = 88, type = "profession", skill = 1,
      text = "Train First Aid + Tailoring (optional) — bandages + cloth bags" },
    { level = 16, impact = 86, type = "spell", spellId = 1120,
      text = "Train Drain Soul — execute + shard farm" },
    { level = 18, impact = 84, type = "consume", itemId = 118, goal = 10,
      text = "AH: Minor Healing Potions ×10" },
    { level = 20, impact = 82, type = "spell", spellId = 5782,
      text = "Train Fear — panic button vs melee" },
    { level = 22, impact = 80, type = "gear", equipSlot = 16, minIlvl = 22, itemId = 6630,
      text = "Quest/AH: Crescent Staff or +Int staff" },
    { level = 24, impact = 78, type = "spell", spellId = 6223,
      text = "Train Corruption rank 2" },
    { level = 26, impact = 76, type = "hint", maxLevel = 28,
      text = "Rotation: CoA → Corruption → SB → Drain Soul <25% HP" },
    { level = 28, impact = 74, type = "gear", equipSlot = 13, minIlvl = 20, itemId = 12930,
      text = "AH: Briarwood Reed trinket (Int spike)" },
    { level = 30, impact = 72, type = "spell", spellId = 696,
      text = "Train Demon Skin / Voidwalker — pet tank unlocked" },
}

P1WG.GOLD_AH_BIS = {
    { levelMin = 10, levelMax = 18, itemId = 5214, label = "Wand", equipSlot = 16, minIlvl = 12 },
    { levelMin = 18, levelMax = 28, itemId = 6630, label = "Staff", equipSlot = 16, minIlvl = 22 },
    { levelMin = 26, levelMax = 35, itemId = 12930, label = "Trinket", equipSlot = 13, minIlvl = 20 },
}
