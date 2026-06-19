# Grok Build — Horde Feral Druid 50–58 / ID Verification

**Repo:** Warmane WoW (WotLK 3.3.5a)  
**Source:** `P1DruidGuide/Data.lua` PATH_STEPS, Questie-335 `classicItemDB.lua` / `wotlkItemDB.lua`, `GROK_TASKS.md`  
**Note:** `GROK_TASKS.md` read; no Lua edited.

---

## Task 1 — Spell ID verification (PATH_STEPS)

Cross-checked against `P1FeralHUD/Core.lua`, Cavern of Time / EvoWoW references, and 3.3.5 spell tables.

| spellId | Expected ability | Verdict | Notes |
|--------:|------------------|---------|-------|
| 768 | Cat Form | **OK** | Correct shapeshift ID for 3.3.5. |
| 1822 | Rake | **OK** | Correct. |
| 33876 | Mangle (Cat) | **OK** | Correct ID (not Bear 33878). In **Wrath**, rank 1 trains at **level 50**, not 14 — PATH `level` is wrong for 3.3.5, not the ID. |
| 783 | Travel Form | **OK** | Correct (Swift Flight Form is 34067, out of scope). |
| 5217 | Tiger's Fury | **OK** | Correct. |
| 49376 | Feral Charge (Cat) | **OK** | Correct talent ability ID. |

**Spell summary:** All six spell IDs are correct for 3.3.5a. No `FIX` on IDs. Cursor should fix **training levels** for Mangle (33876) when implementing Wrath-accurate PATH.

---

## Task 1 — Item ID verification

Verified via Questie item DB in this repo (authoritative for 3.3.5a client data).

| itemId | Used as in Data.lua | Actual item (Questie DB) | Verdict |
|-------:|---------------------|--------------------------|---------|
| 5201 | Staff of Nobles | **Emberstone Staff** | **FIX: 5201 → 3902** (Staff of Nobles) |
| 6630 | Crescent Staff | **Seedcloud Buckler** (shield) | **FIX: 6630 → 6505** (Crescent Staff) |
| 5821 | Horn of the Beast | **No item** — 5821 is Shadowcraft Boots (Classic lookup) / quest NPC id | **FIX: 5821 → 17774** (Mark of the Chosen, Maraudon) or **17692** (Horn Ring, low-level quest trinket ring). *“Horn of the Beast” is not a real item.* |
| 10410 | Leggings of the Fang | Leggings of the Fang | **OK** |
| 10648 | Pole of the Ages | **Blank Parchment** | **FIX: 10648 → remove or replace** — no “Pole of the Ages”; *The Swarm Grows* gives rep only. Use **6505** until **9427**, or AH BoE +Agi 2H ilvl 32+. |
| 16706 | Wildheart Vest | Wildheart Vest | **OK** |
| 9427 | Golem Skull Staff | Golem Skull Staff (Stonevault Bonebreaker) | **OK** |
| 16709 | Wildheart Kilt | **Shadowcraft Pants** (rogue T0) | **FIX: 16709 → 16719** (Wildheart Kilt) |
| 11815 | Hand of Justice | Hand of Justice | **OK** |
| 16707 | Wildheart Cowl | **Shadowcraft Cap** (rogue T0) | **FIX: 16707 → 16720** (Wildheart Cowl) |

### GROK_TASKS draft IDs (50–58)

| itemId | Name (Questie) | Verdict |
|-------:|----------------|---------|
| 16705 | Dreadmist Wraps (warlock) | **FIX: not druid** — omit from feral PATH |
| 12927 | Truestrike Shoulders | **OK** — strong +hit leather shoulders |
| 13148 | Chillpike | **OK** — excellent 2H polearm for 50–58 |
| 13965 | Blackhand's Breadth | **OK** — strong trinket through Outland |
| 16708 | Shadowcraft Spaulders | **FIX: 16708 → 16718** (Wildheart Spaulders) |
| 16710 | Shadowcraft Bracers | **FIX: 16710 → 16714** (Wildheart Bracers) |
| 16714 | Wildheart Bracers | **OK** |
| 16716 | Wildheart Belt | **OK** |

### Wildheart set reference (correct IDs)

| Slot | itemId | Name |
|------|-------:|------|
| Chest | 16706 | Wildheart Vest |
| Head | 16720 | Wildheart Cowl |
| Legs | 16719 | Wildheart Kilt |
| Hands | 16717 | Wildheart Gloves |
| Feet | 16715 | Wildheart Boots |
| Waist | 16716 | Wildheart Belt |
| Wrist | 16714 | Wildheart Bracers |
| Shoulder | 16718 | Wildheart Spaulders |

---

## Task 2 — Proposed PATH_STEPS 50–58 (Horde feral, gold AH)

Impact descends from 48 → 38 (continues existing 10–48 scale). Zones: Felwood → Searing Gorge / Burning Steppes → EPL/WPL → Scholo/LBRS optional → mount savings at 58.

| level | type | id | slot | text | impact |
|------:|------|----:|-----:|------|-------:|
| 50 | spell | 52610 | — | Train **Savage Roar** — keep up 100% uptime in cat | 48 |
| 50 | spell | 33876 | — | Train **Mangle (Cat)** rank 1 (Wrath baseline if missing) | 47 |
| 51 | gear | 16720 | 1 | AH/DM: **Wildheart Cowl** (replace wrong 16707) | 46 |
| 52 | gear | 16719 | 7 | AH/DM: **Wildheart Kilt** (replace wrong 16709) | 45 |
| 53 | gear | 13148 | 16 | AH/Scholo: **Chillpike** — largest weapon spike before Outland | 44 |
| 54 | gear | 16717 | 10 | AH/DM: **Wildheart Gloves** | 43 |
| 55 | gear | 12927 | 3 | AH/LBRS: **Truestrike Shoulders** | 42 |
| 56 | gear | 16714 | 9 | AH/DM: **Wildheart Bracers** | 41 |
| 57 | gear | 13965 | 13 | Quest BRD/AH: **Blackhand's Breadth** (pairs with HoJ) | 40 |
| 58 | hint | — | — | Rotation: Savage Roar → Rip/Rake → Mangle → Shred; bank **400g+** for epic mount | 38 |

**Optional consumes (not in table):** Superior Healing Potion (3928), Major Healing Potion (13446), Swiftness Potion (2459) for Steppes/EPL travel.

**Suggested `GOLD_AH_BIS` rows (50–58):** 13148 (weapon), 16720/16719/16717/16714 (set), 12927 (shoulders), 13965 (trinket).

---

## Task 3 — Warlock PATH 10–30 skeleton (future P1WarlockGuide)

Affliction-leaning Horde leveling; mirrors `P1WarlockHUD` spell IDs. Five rows at requested levels.

| level | type | id | slot | text | impact |
|------:|------|----:|-----:|------|-------:|
| 10 | spell | 697 | — | **Summon Voidwalker** — complete Durotar/Barrens pet quest | 100 |
| 14 | spell | 980 | — | **Curse of Agony** — second DoT layer on every pull | 95 |
| 18 | gear | 5210 | 16 | AH/vendor: **Burning Wand** (+shadow dmg) | 90 |
| 24 | spell | 689 | — | **Drain Life** — filler + self-heal while DoTs tick | 85 |
| 30 | spell | 691 | — | **Summon Felhunter** — dispels + better vs casters | 80 |

**Alt row at 14:** `spell` **348** (Immolate) for Destruction skeleton.  
**Alt row at 18:** `gear` **3902** (Staff of Nobles) if questing Barrens instead of wand.

---

## Task 4 — Cursor follow-up

See `Docs/grok-handoff/CURSOR_TASKS.md`.

---

## Method

- Read `AGENTS.md`, `Docs/grok-handoff/GROK_TASKS.md`, `P1DruidGuide/Data.lua`.
- Validated IDs against vendored Questie-335 item databases (no external fetch; evowow returned 403).
- Spell IDs confirmed via in-repo `P1FeralHUD` + public 3.3.5 references.

**Confidence:** High on item FIX rows (Questie DB). High on spell IDs. Medium-high on Savage Roar **52610** (standard WotLK rank 1; verify in-game with `/dump GetSpellInfo(52610)`).
