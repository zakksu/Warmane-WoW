# Cursor follow-up (from Grok Build handoff)

Apply after reviewing `grok-response.md`. Edit Lua only in Cursor; Grok did not touch addons.

## `PhaseOne_Druid_LevelingPack/Interface/AddOns/P1DruidGuide/Data.lua`

- **PATH_STEPS item FIXes (existing rows):**
  - `5201` → `3902` (Staff of Nobles)
  - `6630` → `6505` (Crescent Staff)
  - `5821` → `17774` (Mark of the Chosen) — update quest text; remove “Horn of the Beast” / Sacred Flame wording
  - `10648` → remove or replace with `6505` hold / generic AH +Agi 2H step (no Pole of the Ages)
  - `16707` → `16720` (Wildheart Cowl)
  - `16709` → `16719` (Wildheart Kilt)
- **BIS_BRACKETS:** same Wildheart ID fixes (`16707`/`16709`); fix weapon rows (`5201`, `6630`, `10648`).
- **GOLD_AH_BIS:** update `itemId` columns to match FIXes above.
- **Append PATH_STEPS** rows from `grok-response.md` Task 2 table (levels 50–58).
- **Mangle step:** change `level = 14` → `50` for spell `33876` (Wrath training), or gate behind `maxLevel` hint until 50.
- **TIPS_BRACKETS:** add 50–58 bracket (Felwood / Steppes / EPL, Savage Roar rotation).

## `PhaseOne_Druid_LevelingPack/Interface/AddOns/P1DruidGuide/Path.lua`

- No logic change expected; confirm `GetItemIcon` / equip checks work with corrected IDs.

## Future: `PhaseOne_LevelingPack/Interface/AddOns/P1WarlockGuide/`

- New addon (mirror P1DruidGuide): `Data.lua` with PATH_STEPS skeleton from `grok-response.md` Task 3.
- Reuse `Path.lua` pattern from druid pack; wire to `P1WarlockHUD` spell IDs.

## Verify in-game

1. Run `PLAY.bat`, `/reload`.
2. `/dump GetSpellInfo(52610)` at level 50 druid (Savage Roar).
3. Hover PATH gear icons — confirm Wildheart / Chillpike / Truestrike tooltips.
