# Cursor follow-up — v2.0.3 (Grok G1–G4, 2026-06-19)

Review full tables + audit details in grok-response.md (Grok performed research/tables/audits only; data in current files already largely aligned — implement/sync minimally if needed). Grok used web + Questie reads only; no .lua edits performed by Grok.

- [ ] Review full tables + audit details in grok-response.md
- [ ] Implement G1 Feral ICC/raid AH fill-ins (table) into P1DruidGuide/Data.lua
  - [ ] 80 slots: consolidate/sync Bloodfall 50178, Cryptmaker 49919 alt, Bladeborn 49899 legs (primary), Legwraps 49898 caster trap note, Footpads 49895, Shoulder 51830, Trinket+ 50351
  - [ ] PATH 264 refs (weapon, legs, shoulders, boots, trinket) if any flavor/emphasis updates
  - [ ] GOLD_AH_BIS synced (7-entry G1 table refs)
  - [ ] Note: patterns from Alchemist Finklestein (ICC) + Primordial Saronite; shoulder is raid drop only (no 264 LW shoulder craft)
- [ ] Implement G2 Warlock 58–70 Outland PATH (table) into P1WarlockGuide/Data.lua
  - [ ] Expanded PATH (58 hints, UA 30108, CoD 603, Shadowfury 30283 + note vs 47897, wand 25806, staff 31308, 70 hint) — staff/wand emphasis
  - [ ] GOLD_AH_BIS 25786/25806/31308 (already present — verify)
  - [ ] Staff ilvl priority for power spikes at 58/68 emphasized
- [ ] Cross-check G3 spell IDs (17877/28176 OK; Shadowfury 30283 already noted correctly)
- [ ] G4 dungeon waypoint audit (confirm Scholo 69.7/73.2 zone28, DM 59.2/45.1 zone357, Blackrock 51/34.8/85.3 zone51 primary; texts consistency for "Scholomance"/"Chillpike"/"Dire Maul"/"Blackrock Depths (optional)"/"LBRS / AH" etc. — druid only; warlock no action)
  - [ ] All refs (BIS, PATH, TIPS, level hints) cross-checked vs Questie zoneTables.lua
- [ ] Version bump to 2.0.3 in manifest / relevant if data changes
- [ ] Sync to WoW client (via PLAY.bat or tools)
- [ ] Mental 3.3.5 API check + pack style match
- [ ] STATUS -> CURSOR_SHIPPED

**You:** `/reload` in game.

```powershell
.\tools\agent-handoff.ps1 -RunGrok   # optional (for next)
```
