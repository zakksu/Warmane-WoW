# Phase One Quest Pack (Minimal)

v1.6.4 ships a **quest-only** addon set focused on druid leveling, with embedded waypoint arrow and Auctionator AH integration. No class HUDs, no TomTom folder, no range/damage clutter.

## Installed (7 addons — druid pack)

| Addon | Purpose |
|-------|---------|
| **PhaseOneLoader** | Questie presets, welcome, `/p1settings`, `/p1minimal` |
| **P1AutoQuest** | Auto accept/turn-in + target assist, **Auto Q** button |
| **P1QuestNav** | Numbered minimap pins, dotted path, **P1Waypoint** arrow to #1 |
| **P1DruidGuide** | Character-aware overlay — NEXT, MATS, GATHER, BIS (`/p1guide`) |
| **Questie-335** | Quest tracking, map icons, objective nodes |
| **!Astrolabe** | Map library (coords, cross-zone pin placement) |
| **Auctionator** | AH search + price hints from guide clicks and `/p1ah` |

Warlock pack uses **P1AdventureGuide** (mats only) instead of P1DruidGuide.

**P1Waypoint:** quest arrow lives inside `P1QuestNav/Waypoint.lua`. TomTom is **not** copied or enabled by PLAY.bat.

## Not installed by default

PLAY.bat moves these to `Interface/AddOns/_disabled/`:

- **TomTom** — replaced by embedded P1Waypoint
- P1RangeDisplay, P1RangeRadar, P1DamageText — removed v1.3.0
- P1FeralHUD / P1WarlockHUD — class combat HUDs
- Leatrix_Plus, WeakAuras*, Bagnon*

## How PLAY.bat works

1. `git pull origin main`
2. `sync-addons.ps1` — copies 7 quest pack addons (no TomTom)
3. `cleanup-wow-addons.ps1` — moves manifest-OFF addons to `_disabled/`
4. `write-addons-txt.ps1` — enables pack addons in `WTF/Account/*/AddOns.txt`

Then log in and type **`/reload`**.

## Character-aware guide

The druid guide adapts to **who you are logged in as**:

- Header shows **`[AH]`** when that toon has pending gear upgrades, else **`[GO]`** for top quest
- NEXT mixes AH lines (up to 2) + ranked quests (up to 3 total) based on level and inventory
- BIS / PATH / GATHER sections reflect equipped items, bags, and profession skill on that character

Panel position, scale, and collapsed sections are stored in `P1DruidGuideDB` per account; feature toggles sync via loader DB on login.

## Auction House click flow

1. **Open the Auction House** (Orgrimmar, Undercity, etc.).
2. Guide shows **`[AH] ItemName — price`** in the header when gear is missing.
3. **Click** the header, a yellow **AH** line in NEXT, or a gold BIS icon → Auctionator searches that item.
4. **`/p1ah`** — same as clicking header `[AH]` (top pending upgrade).
5. **`/p1scan`** — print pending upgrades; refresh price tags after an Auctionator AH scan.

If AH is closed, clicks print a reminder: *open the Auction House, then click [AH] again*.

## In-game commands

| Command | Action |
|---------|--------|
| `/p1` or `/p1guide` | Toggle druid guide overlay |
| `/p1ah` | Search top pending AH upgrade (open AH first) |
| `/p1scan` | List pending AH upgrades + refresh buyout prices |
| `/p1guide reset` | Reset guide position/size |
| `/p1guide min\|max` | Minimize/restore the panel |
| `/p1guide scale 0.8` | Scale overlay |
| `/p1guide go` | P1Waypoint arrow or `[AH]` search (whichever is top priority) |
| `/p1auto` | Toggle Auto Q |
| `/p1nav` | Toggle quest pins / P1Waypoint arrow |
| `/p1nav debug` | Zone id, spawn coords, pin placement for #1 |
| `/p1path` | Toggle path scoring (feeds guide NEXT) |
| `/p1settings` | Feature table |
| `/p1minimal` | Print addon checklist |