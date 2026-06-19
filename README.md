# Warmane WotLK — Phase One Quest Pack

**Latest release: v2.1.0** (Jun 19, 2026) — see [RELEASE.txt](RELEASE.txt)

Quest-focused addon bundle for **Warmane Icecrown** (3.3.5a): tracking, auto accept/complete, embedded waypoint arrow, Auctionator AH search, and **P1 Druid Guide v2** — SHOP + fused NEXT coach overlay. **No class HUD, range HUD, damage numbers, Leatrix, WeakAuras, or TomTom** in the default install.

Full details: **[Docs/MINIMAL_PACK.md](Docs/MINIMAL_PACK.md)**

## Choose your pack

| Pack | Class | Folder | Zip |
|------|-------|--------|-----|
| **Warlock** | Horde Warlock | `PhaseOne_LevelingPack/` | `PhaseOne_LevelingPack.zip` |
| **Feral Druid** | Horde Feral Druid | `PhaseOne_Druid_LevelingPack/` | `PhaseOne_Druid_LevelingPack.zip` |

Druid pack: **P1DruidGuide v2** (SHOP + fused NEXT + `/p1scan`). Warlock pack: **P1WarlockGuide** (`/p1wguide` PATH) + P1AdventureGuide.

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

**Maintainers / dev:** see **[Docs/DEV_WORKFLOW.md](Docs/DEV_WORKFLOW.md)** · **[Autonomous loop](Docs/AUTONOMOUS_LOOP.md)** · **[Cursor orchestration](Docs/CURSOR_ORCHESTRATION.md)** · **[Task lanes](Docs/TASK_DIVISION.md)** · `PLAY.bat FULL` for full pack mirror (dev only).

**Agent loop (Grok ↔ Cursor):** double-click **`LOOP.bat`** and leave it running — see [Docs/AUTONOMOUS_LOOP.md](Docs/AUTONOMOUS_LOOP.md).

---

## What's installed (7 addons — druid pack)

| Addon | Role |
|-------|------|
| **PhaseOneLoader** | Questie presets, smart defaults, `/p1settings`, `/p1fix` |
| **P1AutoQuest** | Auto accept/turn-in + **Auto Q** button (top-right) |
| **P1QuestNav** | Ranked minimap pins, **P1Waypoint** arrow to #1 — `/p1nav` |
| **P1DruidGuide** | v2 coach overlay: SHOP, fused NEXT, MATS, GATHER, BIS — `/p1guide` |
| **Questie-335** | Quest tracking + map/objective icons |
| **!Astrolabe** | Map library (minimap coords, cross-zone pins) |
| **Auctionator** | AH search from guide — `/p1ah`, click `[AH]` lines |

**Waypoint arrow:** embedded **P1Waypoint** in P1QuestNav (not a separate TomTom addon). Questie ctrl+click still works via a TomTom shim.

**Not installed:** TomTom, P1RangeDisplay, P1DamageText, P1FeralHUD, P1WarlockHUD, Leatrix_Plus, WeakAuras, Bagnon.

---

## Auction House click flow

1. Travel to an Auction House and **open it** (or click first — search queues until AH opens).
2. Pending gear shows as **`[AH]`** in the header, **SHOP** lines, fused **NEXT**, or **BIS** rows with item names.
3. **Click** any `[AH]` line, SHOP row, BIS slot, icon bar item, or type **`/p1ah`** — Auctionator **Buy** tab searches that item.
4. **`/p1scan`** lists pending upgrades and refreshes buyout prices after an Auctionator scan.

Each alt sees its own priorities (level, equipped gear, bags, quest log).

---

## In-game commands

| Command | Action |
|---------|--------|
| `/p1` or `/p1guide` | Toggle druid guide overlay (character-aware per toon) |
| `/p1ah` | Search top pending AH upgrade in Auctionator (open AH first) |
| `/p1ah scan` | Cache visible AH browse listings to realm market DB (assist-only) |
| `/p1ah relist` | Print relist suggestions from bag + cached prices (you post) |
| `/p1ah watch` | Queue SHOP item searches when AH opens |
| `/p1scan` | Gear scan + AH gaps + **delta since login** (gold, quests, weapon ilvl) |
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