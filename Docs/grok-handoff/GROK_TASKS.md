# Grok tasks — next cycle (queued)

**State:** READY  
**After:** v2.0.2 shipped

## Grok owns

| # | Task |
|---|------|
| G1 | Feral **ICC/raid** AH fill-ins (ilvl 264+) — table only |
| G2 | Warlock **58–70** Outland PATH (spells + staff/wand) |
| G3 | Verify **17877** Shadowburn, **28176** Fel Armor spell IDs |
| G4 | **Dungeon waypoint** audit for Scholo/LBRS/BRD coords |

## Cursor owns (auto on next wake)

- Implement G1–G2 into Data.lua when handoff lands
- v2.0.3 if any data changes

```powershell
.\tools\agent-handoff.ps1 -RunGrok   # optional
```
