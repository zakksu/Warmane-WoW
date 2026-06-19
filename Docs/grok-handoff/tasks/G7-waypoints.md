# G7 — Waypoint audit (remaining dungeons)

**Agent:** Grok (lane G7)  
**Output:** `Docs/grok-handoff/responses/G7.md` only  
**No .lua edits**

## Task

Audit **remaining** dungeon/raid entrance waypoints in `P1DruidGuide/Data.lua` not fixed in G4 (Scholo/DM/Blackrock already done).

Use Questie `zoneTables.lua` as authoritative. Compare current coords vs Questie for:
- Stratholme, Maraudon, Razorfen, ST, ZF, Gnomeregan, Stockade, RFD, RFK, SM, BFD, WC, Deadmines
- Outland: Hellfire Ramparts, Slave Pens, etc. (if any refs exist)
- Northrend: Nexus, UK, etc. (if any refs exist)

Deliver **audit table**: location title | current zone/x/y | Questie zone/x/y | action (fix/OK)

List every `waypoint = {` line that needs coord change. No .lua edits.

## Cursor lane

`druid-waypoints` applies fixes to `P1DruidGuide/Data.lua` only.
