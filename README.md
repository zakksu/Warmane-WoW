# Warmane WotLK — Phase One Leveling Packs

**Latest release: v1.1.2** (Jun 18, 2026) — see [RELEASE.txt](RELEASE.txt)

Beginner-friendly, lightweight addon bundles for **Warmane Icecrown** (3.3.5a). Copy one folder to `Interface/AddOns`, enable addons, level fast.

## Choose your pack

| Pack | Class | Folder | Zip |
|------|-------|--------|-----|
| **Warlock** | Horde Warlock | `PhaseOne_LevelingPack/` | `PhaseOne_LevelingPack.zip` |
| **Feral Druid** | Horde Feral Druid | `PhaseOne_Druid_LevelingPack/` | `PhaseOne_Druid_LevelingPack.zip` |

Install **one pack** per character (don't mix loaders unless you know what you're doing).

---

## Install (easiest)

**Double-click `INSTALL.bat` at the repo root** → choose Warlock (1) or Feral Druid (2) → confirm or paste your Warmane folder (must contain `Wow.exe`) → enable addons at character select → `/reload`.

Shortcuts:

| Goal | Double-click |
|------|----------------|
| Either pack (menu) | **`INSTALL.bat`** (repo root) |
| Warlock only | `INSTALL_WARLOCK.bat` or `PhaseOne_LevelingPack/INSTALL.bat` |
| Feral Druid only | `INSTALL_DRUID.bat` or `PhaseOne_Druid_LevelingPack/INSTALL.bat` |

Manual copy works too: copy `PhaseOne_*/Interface/AddOns/*` into your Warmane `Interface/AddOns/`.

---

## Feral Druid — quick install (Icecrown)

1. Run **`INSTALL.bat`** at repo root and pick **2**, or run `PhaseOne_Druid_LevelingPack/INSTALL.bat`
   - Manual: copy `PhaseOne_Druid_LevelingPack/Interface/AddOns/*` → your Warmane `Interface/AddOns/`
2. Character select → **AddOns** → enable all → **Load out of date AddOns**
3. Log in on your **Druid** → `/reload`
4. **Done** — Questie, Leatrix, **P1 Feral HUD**, and **P1 Adventure Guide** configure automatically (no WeakAuras import needed)
5. `/p1d` for tips · `/p1hud` to toggle the HUD · `/p1guide` for the Adventure Guide

Optional extra WeakAuras: `WeakAuras/Feral_MANUAL_SETUP.txt`

Full guide: **[PhaseOne_Druid_LevelingPack/README.txt](PhaseOne_Druid_LevelingPack/README.txt)**  
Class tips: **[HORDE_FERAL_DRUID_TIPS.txt](PhaseOne_Druid_LevelingPack/Docs/HORDE_FERAL_DRUID_TIPS.txt)**

---

## Warlock — quick install

1. Run **`INSTALL.bat`** at repo root and pick **1**, or run `PhaseOne_LevelingPack/INSTALL.bat`
   - Manual: copy `PhaseOne_LevelingPack/Interface/AddOns/*` → your Warmane `Interface/AddOns/`
2. Same addon enable steps as above
3. `/reload` on first login — **auto-configures** Questie, Leatrix, P1 Warlock HUD, P1 Adventure Guide
4. `/p1` for tips · `/p1whud` to toggle HUD · `/p1guide` for the Adventure Guide

Optional WeakAuras: `PhaseOne_LevelingPack/WeakAuras/Warlock_MANUAL_SETUP.txt`

Full guide: **[PhaseOne_LevelingPack/README.txt](PhaseOne_LevelingPack/README.txt)**  
Class tips: **[HORDE_WARLOCK_TIPS.txt](PhaseOne_LevelingPack/Docs/HORDE_WARLOCK_TIPS.txt)**

---

## What's in every pack (core)

| Addon | Role |
|-------|------|
| **Questie-335** | Quest helper ([widxwer/Questie](https://github.com/widxwer/Questie) @ 335) |
| **TomTom** + **!Astrolabe** | Waypoint arrow for Questie |
| **Leatrix_Plus** | Auto-repair, auto-sell greys, QoL |
| **WeakAuras** | Bunny67 [WotLK port](https://github.com/Bunny67/WeakAuras-WotLK) — **optional** |
| **P1FeralHUD** / **P1WarlockHUD** | Built-in rotation/DoT HUD (no import) |
| **P1AdventureGuide** | Next action, profs, mats, zone rares — `/p1guide` |
| **PhaseOneLoader** | Auto presets + welcome |
| *Bagnon* / *Auctionator* | Optional |

**Target:** 5–6 core addons + 2 optional. WeakAuras is bundled but not required — P1 HUDs cover the basics.

---

## Pre-configured (first login — no manual setup)

- **Questie:** ±4 levels, sort by proximity, hide completed in tracker
- **Leatrix Plus:** Auto-repair, auto-sell junk, faster loot, FPS-friendly options
- **P1 Feral HUD / P1 Warlock HUD:** Energy/CP or DoT alerts — appears automatically
- **P1 Adventure Guide:** Next best action, professions, mat counts, zone rares — `/p1guide`  
  Preview and tab details: **[Docs/ADVENTURE_GUIDE.md](Docs/ADVENTURE_GUIDE.md)**

**WeakAuras is optional** (for advanced customization). Stuck icon or glow on screen? Type **`/p1fix`**.

---

## Feral Druid beginner highlights

- **1–19:** Moonfire + Wrath; learn heals between pulls
- **20+:** Cat Form leveling — Mangle → Rip (5 CP) → Rake → Shred
- **Self-heal:** Rejuvenation on the run; leave Cat to cast if low
- **Movement:** Dash to engage/escape; Prowl + Ravage when safe
- **Horde route:** Mulgore/Durotar → Barrens → Stonetalon → Thousand Needles

Details: [PhaseOne_Druid_LevelingPack/Docs/HORDE_FERAL_DRUID_TIPS.txt](PhaseOne_Druid_LevelingPack/Docs/HORDE_FERAL_DRUID_TIPS.txt)

---

## Warlock beginner highlights

- **1–10:** Corruption + Wand; Immolate when mana allows
- **10+:** Drain Tank with Siphon Life + Corruption; Life Tap between pulls
- **Pets:** Voidwalker for safety; Felhunter when comfortable
- **Horde route:** Durotar → Barrens → Stonetalon → Thousand Needles

Details: [PhaseOne_LevelingPack/Docs/HORDE_WARLOCK_TIPS.txt](PhaseOne_LevelingPack/Docs/HORDE_WARLOCK_TIPS.txt)

---

## Performance (Warmane)

```text
/console scriptErrors 1
/console maxfps 60
```

Disable WA animations. Turn off optional addons in cities if FPS drops.

---

## Build / release zips

```powershell
.\RELEASE.bat
# or
.\tools\build-all.ps1
```

Creates `PhaseOne_LevelingPack.zip` and `PhaseOne_Druid_LevelingPack.zip` (not in git — run locally).

---

## Credits

Questie (widxwer), Leatrix Plus (Sattva-108 backport), WeakAuras (Bunny67), Bagnon, Auctionator, Astrolabe (Trimitor). Pack layout & loaders: this repo.

## License

Third-party addons keep their licenses. Pack docs/loaders: MIT.
