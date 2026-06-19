# Cursor follow-up — pending v2.0.3 (from Grok 2026-06-19)

All G1–G4 research/audits/tables complete in grok-response.md (full verified 2026-06-19 via wowhead + Questie zoneTables + wotlkItemDB reads + web_search tool results). Review full before coding. **Do NOT edit non-Data files unless per AGENTS.md.** Grok performed **zero .lua edits** (read-only + web tools only; no search_replace/write on any *.lua). Remind user after ship: run `PLAY.bat` + `/reload`.

- [ ] Review full tables + audit details in grok-response.md (G1 table with 7 entries incl. shoulder 51830 + Cryptmaker alt; G2 expanded PATH with 9 rows + staff/wand emphasis + Shadowfury fix note; G3 OK no action; G4 exact fixes/coords from Questie zoneTables.lua; note: druid Data.lua audit shows current waypoints already use correct 28/69.7/73.2, 357/59.2/45.1, 51/34.8/85.3 everywhere — verify/sync texts only)
- [ ] Implement G1 Feral ICC/raid AH fill-ins (ilvl 264+) table into P1DruidGuide/Data.lua (80-level slots + GOLD_AH_BIS / AhAutopilot + PATH refs):
  - [ ] Review/ensure 80 slots cover: Weapon (50178 Bloodfall primary), Weapon+ alt 49919 Cryptmaker, Legs primary Bladeborn 49899 (correct feral agi/arp), Legs alt note Legwraps 49898 (caster trap only), Boots 49895, Trinket+ 50351, Shoulder 51830 Skinned Whelp Shoulders (already present in current read but consolidate per G1 table)
  - [ ] Prefer correct agi/arp feral variants; update 80 PATH steps if any 264 refs (current ~690 already references 51830)
  - [ ] Sync GOLD_AH_BIS (ensure shoulder entry 51830, legs 49899 primary + alt note, include Cryptmaker alt 49919, 50178/50351/49895 — current GOLD already has most but verify per G1 7-entry table)
- [ ] Implement G2 Warlock 58–70 Outland PATH (expanded spells + staff/wand) table into P1WarlockGuide/Data.lua (PATH_STEPS + 58-70 sections + GOLD_AH_BIS sync):
  - [ ] Use/verify expanded table (58 hint+gear, 60 UA 30108, 62 CoD 603 + trinket 25786, 64 spell 30283 Shadowfury with full NOTE on 47897=Shadowflame vs real Shadowfury ranks 30283/30413/47847, 66 wand 25806, 68 staff 31308, 70 hint)
  - [ ] Add/ensure staff/wand emphasis in texts (staff ilvl > other slots); include/correct the 47897 note (current PATH already close match but sync per G2 table)
  - [ ] Sync GOLD_AH_BIS entries for 25786/25806/31308
- [ ] Cross-check G3 spell IDs (Grok confirmed **OK** for 17877/28176; no action unless tying into G2 Shadowfury fix — use 30283)
- [ ] Audit + apply G4 dungeon waypoint fixes from grok-response (apply to **all** refs in Data.lua **only** — P1DruidGuide; note current already matches Questie coords per fresh grep/audit, so focus on text/consistent titles if editing):
  - [ ] Scholo: zone=28, 69.7, 73.2 (confirm; update texts ("Scholomance", "Chillpike" etc.))
  - [ ] DM: zone=357, 59.2, 45.1 (confirm; update all DM refs incl. pre-60 Wildheart (vest/kilt/cowl etc.))
  - [ ] All blackrock (BRD/LBRS/UBRS + Truestrike + "Blackrock Depths" / BRD texts/refs): confirm 51/34.8/85.3 (Searing Gorge primary) or dual per Questie; update texts e.g. "Blackrock Depths (optional)", "LBRS / AH", "Upper Blackrock Spire", "Truestrike Shoulders", "Quest BRD/AH", "WPL / EPL / BRD", "Farm BRD"
- [ ] Bump to v2.0.3 (use QUICK_UPDATE.bat or edit manifest/addons/version strings) if any Data.lua changes land
- [ ] Run PLAY.bat (git pull + sync + cleanup + AddOns.txt)
- [ ] Test mentally vs 3.3.5 API + pack style (Questie/TomTom compat, local funcs, no lua 5.2+); no in-game required from agent
- [ ] Update STATUS.md (set to CURSOR_SHIPPED or per loop) + handoff if loop not auto
- [ ] Optional: commit/push if standalone (but prefer loop ship)

All G1–G4 Grok research complete — tables/audits ready in grok-response.md. **Do NOT edit non-Data files unless per AGENTS.md.** Remind user: after ship, `/reload` + PLAY.bat. (Grok did zero .lua edits. Full answer ONLY in grok-response.md per query.)

(Reference: AGENTS.md, handoff rules, Questie wotlkItemDB for IDs, zoneTables for entrances.)
