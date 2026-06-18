# Warmane WotLK — Phase One Quest Pack

**Latest release: v1.2.7** (Jun 18, 2026) — see [RELEASE.txt](RELEASE.txt)

Quest-focused addon bundle for **Warmane Icecrown** (3.3.5a): tracking, auto accept/complete, waypoint arrow, idle walk, and crafting mat hints. **No class HUD, Leatrix, or WeakAuras** in the default install.

Full details: **[Docs/MINIMAL_PACK.md](Docs/MINIMAL_PACK.md)**

## Choose your pack

| Pack | Class | Folder | Zip |
|------|-------|--------|-----|
| **Warlock** | Horde Warlock | `PhaseOne_LevelingPack/` | `PhaseOne_LevelingPack.zip` |
| **Feral Druid** | Horde Feral Druid | `PhaseOne_Druid_LevelingPack/` | `PhaseOne_Druid_LevelingPack.zip` |

Both packs install the **same 9 quest addons**; only PhaseOneLoader welcome text differs.

---

## Install (easiest)

**Double-click `PLAY.bat` at the repo root** — git pull, sync 6 quest addons, disable conflicts, update AddOns.txt, then **`/reload`** in game.

First time only: paste your Warmane folder when prompted (must contain `Wow.exe`). Path is saved to `tools/wow-path.cfg`.

| Goal | Double-click |
|------|----------------|
| One-click play + updates | **`PLAY.bat`** (repo root) |
| Pick pack manually | `INSTALL.bat` (repo root) |
| Warlock only | `INSTALL_WARLOCK.bat` |
| Feral Druid only | `INSTALL_DRUID.bat` |

**Maintainers / dev:** see **[Docs/DEV_WORKFLOW.md](Docs/DEV_WORKFLOW.md)** · `PLAY.bat FULL` for full pack mirror (dev only).

---

## What's installed (9 addons)

| Addon | Role |
|-------|------|
| **PhaseOneLoader** | Questie presets, smart defaults, `/p1settings`, `/p1fix` |
| **P1AutoQuest** | Auto accept/turn-in + **Auto Q** button (top-right) |
| **P1QuestNav** | NEXT line, ranked pins, TomTom arrow to #1 — `/p1nav` |
| **P1RangeDisplay** | Target distance number — `/p1range` |
| **P1DamageText** | Floating combat damage — `/p1dmg` |
| **P1AdventureGuide** | Crafting mats + AH tips — `/p1guide` |
| **Questie-335** | Quest tracking + map icons |
| **TomTom** + **!Astrolabe** | Waypoint arrow + minimap coords |

**Not installed:** P1FeralHUD, P1WarlockHUD, Leatrix_Plus, WeakAuras, Bagnon, Auctionator (PLAY.bat moves these to `AddOns/_disabled/`).

---

## In-game commands

| Command | Action |
|---------|--------|
| `/p1auto` | Toggle Auto Q (accept/turn-in + arrows) |
| `/p1nav` | Toggle quest nav + NEXT line |
| `/p1range` | Toggle target distance number |
| `/p1dmg` | Toggle floating damage numbers |
| `/p1path` | Toggle optimal quest route panel |
| `/p1settings` | Feature table — all on/off |
| `/p1guide` | Show/hide crafting mats panel |
| `/p1quest` | Debug auto-quest status |
| `/p1minimal` | Addon checklist |
| `/p1fix` | Clear stuck TomTom arrow |
| `/p1` or `/p1d` | Pack welcome / tips |

---

## Getting updates

1. **Pull** latest repo or download [GitHub release](https://github.com/zakksu/Warmane-WoW/releases).
2. Double-click **`PLAY.bat`**, then **`/reload`**.

Details: **[Docs/INCREMENTAL_UPDATES.md](Docs/INCREMENTAL_UPDATES.md)**

---

## Class tips (still in repo)

- Feral: [HORDE_FERAL_DRUID_TIPS.txt](PhaseOne_Druid_LevelingPack/Docs/HORDE_FERAL_DRUID_TIPS.txt)
- Warlock: [HORDE_WARLOCK_TIPS.txt](PhaseOne_LevelingPack/Docs/HORDE_WARLOCK_TIPS.txt)

Optional legacy HUD/WeakAuras files remain in pack folders but are **not copied** by PLAY.bat.

---

## Build / release

**Maintainers:** `QUICK_UPDATE.bat` or `RELEASE.bat` · see [RELEASE.txt](RELEASE.txt)

## Credits

Questie (widxwer), TomTom, Astrolabe. Pack loaders: this repo.

## License

Third-party addons keep their licenses. Pack docs/loaders: MIT.
