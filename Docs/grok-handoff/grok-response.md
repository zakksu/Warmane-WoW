# Grok handoff — G1-G4 complete (from GROK_TASKS.md)

**From:** Grok Build (research + tables + audits only; 2026-06-19)  
**State:** GROK_DONE — full tables/audits ready; Cursor to implement  
**Tasks completed:** ALL G1–G4 from GROK_TASKS.md (read + researched via tools)  
**Research sources:** web_search + open_page on wowhead wotlk (spells/items/feral bis) [web:0][web:5][web:29][web:19][web:39][web:59][web:69][web:78], Questie-335 (druid + warlock pack copies) /Database/Zones/zoneTables.lua (entrances exact) + /Database/Wotlk/wotlkItemDB.lua (item ID/ilvl verification via read_file/grep), read-only read_file + grep on P1DruidGuide/Data.lua + P1WarlockGuide/Data.lua (current tables/waypoints without any edit), standard 3.3.5 WotLK references (Warmane context, Outland/ICC AH fills for Horde leveling). All cross-checked 2026-06-19.  

**Critical per user query + AGENTS.md:** Grok performed **zero .lua edits** (read-only + web tools only; no search_replace/write on any *.lua, no other non-handoff files touched except the two specified mds). Full answer written ONLY here. Remind user after ship: run `PLAY.bat` + `/reload`.

## G1 — Feral ICC/raid AH fill-ins (ilvl 264+) — table only

**Research summary (tool verified 2026-06-19):** 264 ilvl items from ICC (10H/25N drops + LW BoE crafts via Ashen Verdict rep patterns sold by Alchemist Finklestein in ICC for Honored/Revered + Primordial Saronite). On Warmane AH these are common flip/fill-ins for fresh 80 feral (pre full heroic ICC/T10). Feral priorities: agi > arp > crit/hit/expertise > AP (weapons get form multipliers). Prefer feral agi/arp variants. No major LW 264 shoulder craft (only raid drop shoulder fill). Weapon #1 priority (DPS lever + /p1scan flags it).

Read-only audit of PhaseOne_Druid_LevelingPack/Interface/AddOns/P1DruidGuide/Data.lua (BIS_BRACKETS 80 block ~374-412, PATH_STEPS ~678-692, GOLD_AH_BIS ~698-723): already covers most 80 264s (including 51830 shoulder, 49899 legs primary with alt note, weapons, boots, trinkets) but G1 table consolidates the 7 entries with correct primary/alt + Cryptmaker for reference. Current 80 slots already use correct 49899 Bladeborn as primary legs (with caster trap alt for 49898), 51830 shoulder etc.

**Verified item IDs + sources (wowhead wotlk + wotlkItemDB.lua exact matches):**
- 50178 Bloodfall: https://www.wowhead.com/wotlk/item=50178/bloodfall (ilvl 264 polearm, +form AP 3358/crit/haste from Blood-Queen Lana'thel 25N; wotlkItemDB confirms 264)
- 49919 Cryptmaker: https://www.wowhead.com/wotlk/item=49919/cryptmaker (ilvl 264 mace, str/hit/arp +form AP from Prince Valanar; wotlkItemDB 264)
- 49899 Bladeborn Leggings: https://www.wowhead.com/wotlk/item=49899/bladeborn-leggings (ilvl 264 LW craft Pattern 49959 Revered; agi/AP/arp/crit feral BiS fill; wotlkItemDB)
- 49898 Legwraps of Unleashed Nature: https://www.wowhead.com/wotlk/item=49898/legwraps-of-unleashed-nature (ilvl 264 LW caster Pattern 49957; int/sp only — trap for cat)
- 49895 Footpads of Impending Death: https://www.wowhead.com/wotlk/item=49895/footpads-of-impending-death (ilvl 264 LW craft (Pattern 49961, Honored). +agi/AP/crit/exp boots)
- 50351 Tiny Abomination in a Jar: https://www.wowhead.com/wotlk/item=50351/tiny-abomination-in-a-jar (ilvl 264 trinket from Prof Putricide 25N; melee proc)
- 51830 Skinned Whelp Shoulders: https://www.wowhead.com/wotlk/item=51830/skinned-whelp-shoulders (ilvl 264 heroic leather from Valithria 10H cache; AP/crit/arp; normal 51565=251; wotlkItemDB confirms; raid drop, good AH shoulder fill)

**G1 Table (7 entries; use for BIS_BRACKETS 80 slots, GOLD_AH_BIS sync, PATH 80 refs):**

| itemId | slot/key | name | priceTier | notes (for feral) |
|-------:|----------|------|-----------|-------------------|
| 50178 | Weapon / Weapon+ | Bloodfall | splurge | 264 agi/crit/haste polearm (ICC 25N Blood-Queen Lana'thel). Primary weapon fill-in. Form AP bonus. Top scan priority. |
| 49919 | Weapon+ alt | Cryptmaker | alt | 264 mace (ICC 25N Prince Valanar). Str + hit/arp + form AP. Filler if Bloodfall not on AH. |
| 49899 | Legs | Bladeborn Leggings | splurge (primary feral) | 264 LW craft (Pattern: 49959, Revered Ashen Verdict). +AP/arp/crit — correct agi/arp feral variant. Set as primary legs. |
| 49898 | Legs alt | Legwraps of Unleashed Nature | alt (caster trap only) | 264 LW (Pattern 49957). Int/sp/spellpower version — list only as avoid note for cat (do not primary). |
| 49895 | Boots | Footpads of Impending Death | splurge | 264 LW craft (Pattern 49961, Honored). +agi/AP/crit/expertise. Closes weak slot. |
| 50351 | Trinket+ | Tiny Abomination in a Jar | splurge | 264 proc trinket (ICC 25N Professor Putricide). Motes proc scales cat bleeds/melee. |
| 51830 | Shoulder | Skinned Whelp Shoulders | splurge | 264 heroic leather (ICC 10H Valithria Dreamwalker cache). AP/crit/arp + red sockets. Good AH flip; add explicit shoulder slot. |

**Notes for Cursor (Data.lua only, per AGENTS.md):** In P1DruidGuide/Data.lua 80-level BIS_BRACKETS (the slots array ~374+): current already has 8 entries with good coverage (Weapon 50267/50178 primary +49919 alt, Trinket 50342, Chest generic, Legs 49899 primary +49898 alt note, Boots 49895, Shoulder 51830, Trinket+ 50351). G1 table provides the consolidated 7 for reference/sync. GOLD_AH_BIS (~698+) already includes 80 264 entries for 50178/49919/49899/49895/51830/50351 (plus lower). Minor PATH 80 step ~690 has 51830 shoulder already. Keep splurge tier, flavor texts matching pack style. Confirmed no other 264 feral LW shoulder craft. Warmane AH common for these post-80. Prefer correct agi/arp feral variants; update 80 PATH steps if any 264 refs needed for emphasis.

(Also present in current read: 50267 ilvl200 weapon etc for pre-264.)

## G2 — Warlock 58–70 Outland PATH (spells + staff/wand)

**Research summary:** Outland leveling 58-70 (Hellfire Peninsula entry → Zangarmarsh/Terokkar/Nagrand/Blade's Edge/Netherstorm) is Affliction friendly for questing (DoTs + Drain sustain vs packs). Key power spikes at 60/62/64. Staff > wand emphasis (high +SP/int 2H staff = largest ilvl/SP power spike for locks; wands secondary; AH abundant/cheap greens at 58/60/65 gates on Warmane). Fel Armor + Shadowburn from pre-58 carry. Current P1WarlockGuide/Data.lua PATH_STEPS (read ~lines 37-56) already has expanded 58-70 skeleton matching ~9 rows + staff/wand focus + correct Shadowfury (see below).

**Verified via web + wotlkItemDB (warlock pack):**
- UA 30108: https://www.wowhead.com/wotlk/spell=30108/unstable-affliction (rank1 at 60)
- CoD 603: https://www.wowhead.com/wotlk/spell=603/curse-of-doom
- Shadowfury 30283 (r1): https://www.wowhead.com/wotlk/spell=30283/shadowfury (AoE stun 8yd; ranks 30283/30413/47847). NOTE: 47897 is Shadowflame (front cone + DoT), later talent ~75+; fix any misref (current Data already uses 30283 + note).
- Hypnotist's Watch 25786: https://www.wowhead.com/wotlk/item=25786/hypnotists-watch (ilvl93, Hellfire quest 9351 or AH; wotlkItemDB confirms)
- Nethekurse's Rod 25806: https://www.wowhead.com/wotlk/item=25806/nethekurses-rod-of-torment (ilvl109 wand, SLabs/Shattered Halls quest/AH; wotlkItemDB)
- The Bringer of Death 31308: https://www.wowhead.com/wotlk/item=31308/the-bringer-of-death (ilvl115 +121SP 2H staff, AH/drops; wotlkItemDB)

**Expanded PATH table (9 rows; for PATH_STEPS 58-70 + GOLD_AH_BIS sync + 58/70 hints):**

| level | type | spellId/itemId | text (with staff/wand emphasis) |
|------:|------|---------------:|---------------------------------|
| 58 | hint | - | Pre-Outland: bank mount gold · buy Outland green staff/wand on AH (ilvl 80+ +SP/int; 2H staff = biggest immediate spike for warlock) |
| 58 | gear | - | AH: any solid +SP 2H staff (ilvl 90-110 greens common in Hellfire) as first Outland upgrade. Staff ilvl beats most armor slots. |
| 60 | spell | 30108 | Unstable Affliction — third DoT (1.5s cast; anti-dispel silence on break). Core Affliction power spike. |
| 62 | spell | 603 | Curse of Doom — long fight opener (60s CD big nuke after 1 min). |
| 62 | gear | 25786 | Quest/AH: Hypnotist's Watch trinket (Hellfire; threat reduce). Early Outland filler. |
| 64 | spell | 30283 | Shadowfury — stun AoE for Hellfire packs (ranks 30283/30413/47847). NOTE: NOT 47897 Shadowflame (cone front shadow+fire DoT, learned ~75/80). Use correct Shadowfury ranks. |
| 66 | gear | 25806 | Quest/AH: Nethekurse's Rod wand (+SP; SLabs/Shattered Halls). Solid wand upgrade. |
| 68 | gear | 31308 | AH: The Bringer of Death 2H staff (+121 SP) or equivalent high-ilvl +SP staff. Staff ilvl > other slots emphasis. |
| 70 | hint | - | Cap Outland: stock runed orbs · Northrend blues staff (ilvl 170+) · keep Fel Armor (28176) up. |

**Notes for Cursor:** In P1WarlockGuide/Data.lua: PATH_STEPS 58-70 section (~37-56) already expanded to match the 9-row version above (incl. 58 hints + gear, 60/62/64/66/68/70). GOLD_AH_BIS already covers 25786 (Trinket 58-68), 25806 (Wand 66-70), 31308 (Weapon 68-72). 64 entry uses 30283 + NOTE on 47897 vs real Shadowfury (good). Add/keep staff/wand emphasis in texts + 58/70 hints (staff ilvl priority) if expanding flavor. Cross-ref G3 (spell IDs base OK). Confirmed via wotlkItemDB in warlock pack copy.

## G3 — Verify 17877 Shadowburn, 28176 Fel Armor spell IDs

**Verification (web_search + open_page wowhead wotlk + cross with Data.lua usage + note item vs spell namespace):**

| spellId | Name | Verdict | Details |
|--------:|------|---------|---------|
| 17877 | Shadowburn | **OK** (no action) | WotLK Destruction talent rank 1 base ID. https://www.wowhead.com/wotlk/spell=17877/shadowburn . Instant SS blast, returns shard on kill. Higher ranks 18869/47827. Used in pack Data at level 52 — correct per 3.3.5. |
| 28176 | Fel Armor | **OK** (no action) | WotLK Demonology base spell. https://www.wowhead.com/wotlk/spell=28176/fel-armor (SP +30% spirit, 2% HP/5s regen, 30min). Requires ~62 in some tooltips but ID is the correct spell for the armor buff (higher rank 47893 exists). Item 28176 is unrelated plate feet. Used in pack Data at level 50 (pre-Outland prep) + 70 hint ref — correct ID usage. |

**G3 complete: OK, no changes.** Ties to G2 only for the separate Shadowfury 30283 correction (already noted correctly in current data). Confirmed in current warlock Data.lua lines 29-32,56 (and web confirms).

## G4 — Dungeon waypoint audit for Scholo/LBRS/BRD coords

**Audit (read-only tools):** 
- Read P1DruidGuide/Data.lua for all waypoints/texts (BIS_BRACKETS, TIPS_BRACKETS, PATH_STEPS, level hints; multiple Wildheart DM pre-60, BRD optional, Blackhand, Truestrike, Chillpike, UBRS etc.; also zone strings "WPL/EPL/BRD", "Scholomance chains · BRD attunement", "Farm BRD", "Quest BRD/AH", "AH/LBRS", "AH/Scholo", "Blackrock Depths (optional)").
- P1WarlockGuide/Data.lua + Path.lua: zero dungeon waypoints (no changes needed there).
- Authoritative: Questie-335/Database/Zones/zoneTables.lua (druid pack + warlock pack copies match) entrance table (~lines 548-560):
  - Scholomance [2057]: {{28, 69.7, 73.2}}
  - Dire Maul [2557]: {{357, 59.2, 45.1}}
  - Blackrock Spire [1583] / Depths [1584]: {{51, 34.8, 85.3}, {46, 29.4, 38.3}} (Searing Gorge 51 primary/common; Burning Steppes 46 alt)
- Zone map confirms: 28=WPL (Scholo/Caer Darrow), 357=Feralas (DM), 51=Searing Gorge (Blackrock Mountain entrances), 36=Alterac (wrong/old for BRD/LBRS).

**Current state in druid Data (from grep/read):** Uses correct Questie coords everywhere:
  - Scholo: 28, 69.7, 73.2 (Chillpike, AH/Scholo texts)
  - DM: 357, 59.2, 45.1 (all Wildheart vest/kilt/cowl/gloves/boots/bracers + pre-60 refs)
  - Blackrock: 51, 34.8, 85.3 (HoJ BRD, Truestrike LBRS, Blackhand UBRS, PATH steps for BRD texts, "Blackrock Depths (optional)", "LBRS / AH", "Upper Blackrock Spire", "Quest BRD/AH", "WPL / EPL / BRD", "Farm BRD")
No legacy bad coords (e.g. no 69.2/73.0, no 45.8, no 36/80.4/46.8) present in the file. Texts already use "Scholomance", "Chillpike", "Dire Maul", "Blackrock Depths (optional)", "LBRS / AH" etc.

**Exact fixes from Questie (apply to ALL refs in P1DruidGuide/Data.lua only if any drift found — but audit shows already aligned):**
- Scholo: use zone=28, 69.7, 73.2 (current exact). Update texts/titles ("Scholomance", "Chillpike", "AH/Scholo") if needed for consistency.
- DM: use zone=357, 59.2, 45.1 (current exact). Update all DM refs incl. pre-60 Wildheart (vest/kilt/cowl etc.) + "Dire Maul".
- All blackrock (BRD/LBRS/UBRS + Truestrike + BRD texts/refs): use 51/34.8/85.3 (Searing Gorge primary) or dual {{51,34.8,85.3},{46,29.4,38.3}} per Questie (current uses primary 51). Replace any 36/80.4/46.8 if found (none). Update texts e.g. "Blackrock Depths (optional)", "LBRS / AH", "Upper Blackrock Spire", "Truestrike Shoulders", "Quest BRD/AH", "WPL / EPL / BRD", "Farm BRD".

**G4 complete:** Full audit + exact coords + list of affected texts/refs provided. (DM/Scholo/Blackrock appear in 50s/58-70/80 sections + PATH + BIS + TIPS.) Current Data.lua already matches Questie authoritative entrances; no coord value changes needed, just ensure text consistency during any other edits. (P1Warlock no action.)

## Summary / Handoff to Cursor

All G1-G4 completed by Grok (research + verified tables + audit details). 
- G1: 7-entry table + verification links + notes for 80 slots/GOLD_AH_BIS/PATH. (Data already largely populated correctly.)
- G2: 9-row expanded PATH table + staff/wand notes + spell fixes. (Data already matches expanded.)
- G3: Verified OK (table).
- G4: Questie-sourced exact coords + full list of updates needed across Data.lua sections. (Current already correct on coords; texts audit clean.)

**Grok did zero .lua edits** (only read/grep/web on repo; edits limited to grok-response.md + CURSOR_TASKS.md per query). 

See updated CURSOR_TASKS.md (written next) for the checkbox implementation list (Cursor owns Data.lua changes + v bump + ship steps). Prefer minimal scoped changes to Data.lua only (P1DruidGuide for G1/G4; P1WarlockGuide for G2). Match pack Lua style, Questie/TomTom waypoint compat, 3.3.5 API.

After Cursor ship: user runs PLAY.bat then `/reload`. (Agents cannot run client.)

Full tool research in this session (web + multiple read_file/grep on Questie/Data allowed paths, no lua writes). All tasks from GROK_TASKS.md done.

(Also read STATUS.md first per AGENTS.md workflow.)

## Post notes
- Update STATUS.md to GROK_DONE or per loop rules after this write.
- Next cycle per STATUS may have G5+ but not in current GROK_TASKS.
- Use .\tools\agent-handoff.ps1 etc for loop.
- Remind: after ship, run PLAY.bat + /reload in game.
