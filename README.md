# Warmane WotLK — Phase One Quest Pack

**Latest release: v1.6.4** (Jun 18, 2026) — see [RELEASE.txt](RELEASE.txt)

Quest-focused addon bundle for **Warmane Icecrown** (3.3.5a): tracking, auto accept/complete, embedded waypoint arrow, Auctionator AH search, and a **character-aware P1 Druid Guide** overlay. **No class HUD, range HUD, damage numbers, Leatrix, WeakAuras, or TomTom** in the default install.

Full details: **[Docs/MINIMAL_PACK.md](Docs/MINIMAL_PACK.md)**

## Choose your pack

| Pack | Class | Folder | Zip |
|------|-------|--------|-----|
| **Warlock** | Horde Warlock | `PhaseOne_LevelingPack/` | `PhaseOne_LevelingPack.zip` |
| **Feral Druid** | Horde Feral Druid | `PhaseOne_Druid_LevelingPack/` | `PhaseOne_Druid_LevelingPack.zip` |

Druid pack: **P1DruidGuide** (NEXT + MATS + GATHER + BIS). Warlock pack: **P1AdventureGuide** (mats only).

---

## Install (easiest)

**Double-click `PLAY.bat` at the repo root** — git pull, sync quest addons, disable conflicts, update AddOns.txt, then **`/reload`** in game.

First time only: paste your Warmane folder when prompted (must contain `Wow.exe`). Path is saved to `tools/wow-path.cfg`.

| Goal | Double-click |
|------|----------------|
| One-click play + updates | **`PLAY.bat`** (repo root) |
| Pick pack manually | `INSTALL.bat` (repo root) |
| Warlock only | `INSTALL_WARLOCK.bat` |
| Feral Druid only | `INSTALL_DRUID.bat` |

**Maintainers / dev:** see **[Docs/DEV_WORKFLOW.md](Docs/DEV_WORKFLOW.md)** · **[Cursor Cloud](Docs/CURSOR_CLOUD.md)** · **[Cursor ↔ Grok tasks](Docs/TASK_DIVISION.md)** · `PLAY.bat FULL` for full pack mirror (dev only).

---

## What's installed (7 addons — druid pack)

| Addon | Role |
|-------|------|
| **PhaseOneLoader** | Questie presets, smart defaults, `/p1settings`, `/p1fix` |
| **P1AutoQuest** | Auto accept/turn-in + **Auto Q** button (top-right) |
| **P1QuestNav** | Ranked minimap pins, **P1Waypoint** arrow to #1 — `/p1nav` |
| **P1DruidGuide** | Character-aware overlay: NEXT, MATS, GATHER, BIS — `/p1guide` |
| **Questie-335** | Quest tracking + map/objective icons |
| **!Astrolabe** | Map library (minimap coords, cross-zone pins) |
| **Auctionator** | AH search from guide — `/p1ah`, click `[AH]` lines |

**Waypoint arrow:** embedded **P1Waypoint** in P1QuestNav (not a separate TomTom addon). Questie ctrl+click still works via a TomTom shim.

**Not installed:** TomTom, P1RangeDisplay, P1DamageText, P1FeralHUD, P1WarlockHUD, Leatrix_Plus, WeakAuras, Bagnon.

---

## Auction House click flow

1. Travel to an Auction House and **open it** (required).
2. In the guide, pending gear shows as **`[AH]`** in the header or **`AH`** lines in NEXT.
3. **Click** the header `[AH]`, a NEXT line, a BIS icon, or type **`/p1ah`** — Auctionator searches that item.
4. **`/p1scan`** lists pending upgrades and refreshes buyout prices after an Auctionator scan.

Each alt sees its own priorities (level, equipped gear, bags, quest log).

---

## In-game commands

| Command | Action |
|---------|--------|
| `/p1` or `/p1guide` | Toggle druid guide overlay (character-aware per toon) |
| `/p1ah` | Search top pending AH upgrade in Auctionator (open AH first) |
| `/p1scan` | List pending AH upgrades + refresh buyout prices |
| `/p1guide reset` | Reset guide position/size |
| `/p1guide min` / `max` | Minimize / restore guide |
| `/p1guide scale 0.8` | Scale overlay |
| `/p1guide go` | P1Waypoint arrow to top quest, or `[AH]` search if gear gap |
| `/p1auto` | Toggle Auto Q (accept/turn-in + arrows) |
| `/p1nav` | Toggle quest nav pins + P1Waypoint arrow |
| `/p1path` | Toggle path scoring (feeds guide NEXT) |
| `/p1settings` | Feature toggles |
| `/p1questie` | Debug Questie map icons |
| `/p1minimal` | Print addon checklist |