# Warmane WotLK — Phase One Quest Pack

**Latest release: v1.2.0** (Jun 18, 2026) — see [RELEASE.txt](RELEASE.txt)

Quest-focused addon bundle for **Warmane Icecrown** (3.3.5a): tracking, auto accept/complete, waypoint arrow, idle walk, and crafting mat hints. **No class HUD, Leatrix, or WeakAuras** in the default install.

Full details: **[Docs/MINIMAL_PACK.md](Docs/MINIMAL_PACK.md)**

## Choose your pack

| Pack | Class | Folder | Zip |
|------|-------|--------|-----|
| **Warlock** | Horde Warlock | `PhaseOne_LevelingPack/` | `PhaseOne_LevelingPack.zip` |
| **Feral Druid** | Horde Feral Druid | `PhaseOne_Druid_LevelingPack/` | `PhaseOne_Druid_LevelingPack.zip` |

Both packs install the **same 6 addons**; only PhaseOneLoader welcome text differs.

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

## What's installed (6 addons)

| Addon | Role |
|-------|------|
| **PhaseOneLoader** | Questie presets, `/p1auto`, `/p1minimal`, `/p1fix` |
| **P1AutoQuest** | Auto waypoint + idle walk + **Auto Q** button (top-right) |
| **P1AdventureGuide** | Crafting mats only — `/p1guide` |
| **Questie-335** | Quest tracking + auto accept/complete |
| **TomTom** + **!Astrolabe** | Waypoint arrow + ClickToMove walk |

**Not installed:** P1FeralHUD, P1WarlockHUD, Leatrix_Plus, WeakAuras, Bagnon, Auctionator (PLAY.bat moves these to `AddOns/_disabled/`).

---

## In-game commands

| Command | Action |
|---------|--------|
| `/p1auto` | Toggle Auto Q (accept/turn-in + arrow + idle walk) |
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
