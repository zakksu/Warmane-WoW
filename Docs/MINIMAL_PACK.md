# Phase One Quest Pack (Minimal)

v1.3.0 ships a **quest-only** addon set focused on druid leveling. No class HUDs, no range/damage clutter.

## Installed (7 addons — druid pack)

| Addon | Purpose |
|-------|---------|
| **PhaseOneLoader** | Questie presets, welcome, `/p1settings`, `/p1minimal` |
| **P1AutoQuest** | Auto accept/turn-in + target assist, **Auto Q** button |
| **P1QuestNav** | Numbered minimap pins, dotted path, TomTom arrow to #1 |
| **P1DruidGuide** | Unified overlay — NEXT, MATS, GATHER, BIS (`/p1guide`) |
| **Questie-335** | Quest tracking, map icons, objective nodes |
| **TomTom** | Waypoint arrow |
| **!Astrolabe** | Map library |

Warlock pack uses **P1AdventureGuide** (mats only) instead of P1DruidGuide.

## Not installed by default

PLAY.bat moves these to `Interface/AddOns/_disabled/`:

- P1RangeDisplay, P1RangeRadar, P1DamageText — removed v1.3.0
- P1FeralHUD / P1WarlockHUD — class combat HUDs
- Leatrix_Plus, WeakAuras*, Bagnon*, Auctionator

## How PLAY.bat works

1. `git pull origin main`
2. `sync-addons.ps1` — copies quest pack addons only
3. `cleanup-wow-addons.ps1` — moves manifest-OFF addons to `_disabled/`
4. `write-addons-txt.ps1` — enables pack addons in `WTF/Account/*/AddOns.txt`

Then log in and type **`/reload`**.

## In-game commands

| Command | Action |
|---------|--------|
| `/p1` or `/p1guide` | Toggle druid guide overlay |
| `/p1guide reset` | Reset guide position/size |
| `/p1guide scale 0.8` | Scale overlay |
| `/p1auto` | Toggle Auto Q |
| `/p1nav` | Toggle quest pins / TomTom |
| `/p1path` | Toggle path scoring (feeds guide NEXT) |
| `/p1settings` | Feature table |
| `/p1minimal` | Print addon checklist |
