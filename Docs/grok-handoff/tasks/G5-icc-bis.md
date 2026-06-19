# G5 — Feral ICC BiS depth (ilvl 264+)

**Agent:** Grok (lane G5)  
**Output:** `Docs/grok-handoff/responses/G5.md` only  
**No .lua edits**

## Task

Research **full feral cat** ICC/AH fill-ins for level 80 beyond current 7-entry table (Bloodfall, Bladeborn, Footpads, Skinned Whelp, Tiny Abom, Cryptmaker alt).

Deliver a **table only** with columns: itemId | slot | name | tier | notes

Cover if AH-accessible on Warmane:
- Chest, head, hands, wrists, belt, neck, ring, off-hand (if any)
- T10 token alternatives vs 264 LW/raid BoE
- Any ilvl 264+ upgrades missing from current `P1DruidGuide/Data.lua` 80 bracket

Cross-check Questie `wotlkItemDB.lua`. Wowhead wotlk links in notes.

## Cursor lane

`druid-data` implements into `P1DruidGuide/Data.lua` only (BIS_BRACKETS 80, GOLD_AH_BIS, PATH_STEPS).
