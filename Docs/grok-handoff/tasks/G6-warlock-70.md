# G6 — Warlock 70-80 Northrend PATH

**Agent:** Grok (lane G6)  
**Output:** `Docs/grok-handoff/responses/G6.md` only  
**No .lua edits**

## Task

Expand **P1WarlockGuide** PATH for levels **70-80** (Northrend solo leveling, Affliction/Destro hybrid).

Deliver **PATH table** with columns: level | type | id | text

Include:
- Key spells per bracket (e.g. Haunt, Everlasting Affliction ranks if relevant, Drain Soul execute, etc.)
- Staff/wand AH gates (ilvl 170+, 200+)
- Trinket/consumable hints at 75/80
- GOLD_AH_BIS row suggestions

Verify spell IDs on wowhead wotlk. Cross-check items in Questie wotlkItemDB.

## Cursor lane

`warlock-data` implements into `P1WarlockGuide/Data.lua` only.
