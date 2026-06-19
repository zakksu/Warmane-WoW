# Grok tasks — current cycle

**From:** Cursor Orchestrator  
**Target release:** v1.6.4 / v2.0.x  
**Reply to:** `grok-response.md` + update `CURSOR_TASKS.md`  
**Rule:** Do **not** edit `.lua` — tables and verification only.

---

## Grok owns (research)

| # | Task | Output |
|---|------|--------|
| G1 | **Feral 58–80 AH table** — `itemId`, slot, name, `minIlvl`, gold tier, source | Markdown table for `Data.lua` `BIS_BRACKETS` + `GOLD_AH_BIS` |
| G2 | **Verify v1.6.3 IDs** — 3902, 6505, 17774, 16719/20/17/15/14, 13148, 52610, 13965, 12927 | OK or FIX rows |
| G3 | **Consumables** — audit `P1DG.AH_TIPS` itemIds vs Questie `wotlkItemDB.lua` | List wrong IDs |
| G4 | **Warlock PATH 30–50** — spells, wand/staff, trinkets (Horde, gold AH) | 8–10 PATH rows table |
| G5 | **Outland prep 58–60** — mount gold, first Outland gear gates | Bullet list for PATH hints |

---

## Cursor owns (after Grok)

| # | Task | Files |
|---|------|-------|
| C1 | Paste G1 into `Data.lua` | `P1DruidGuide/Data.lua` |
| C2 | Apply G2/G3 fixes | `Data.lua`, `Auction.lua` if AH tips |
| C3 | Warlock PATH 30–50 | `P1WarlockGuide/Data.lua` |
| C4 | Guide polish (parallel lane A) | `P1DruidGuide/*` — see TASK_DIVISION Agent A |
| C5 | Ship: version bump, RELEASE, PLAY.bat | Orchestrator |

---

## Run Grok

```powershell
.\tools\agent-handoff.ps1 -RunGrok
.\tools\agent-handoff.ps1 -Status
```

Or paste into **Grok sidebar**:

```
Repo: Warmane-WoW. Read AGENTS.md + Docs/grok-handoff/GROK_TASKS.md.
Complete tasks G1–G5. Write ONLY to Docs/grok-handoff/grok-response.md.
Update CURSOR_TASKS.md with checkbox list for Cursor. No Lua edits.
Cross-check item IDs against PhaseOne_*/Interface/AddOns/Questie-335/Database/Wotlk/wotlkItemDB.lua.
```
