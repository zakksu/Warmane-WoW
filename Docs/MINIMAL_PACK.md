# Phase One Quest Pack (Minimal)

v1.2.0 ships a **quest-only** addon set. No class HUDs, no Leatrix, no WeakAuras in the default install.

## Installed (6 addons)

| Addon | Purpose |
|-------|---------|
| **PhaseOneLoader** | Questie presets, welcome, `/p1auto`, `/p1minimal`, `/p1fix` |
| **P1AutoQuest** | Auto waypoint, idle walk, available-quest mode, **Auto Q** button (top-right) |
| **P1AdventureGuide** | **Mats only** — bag counts + “stock up by level X” hints (`/p1guide`) |
| **Questie-335** | Quest tracking, auto accept/complete |
| **TomTom** | Waypoint arrow (Questie integration) |
| **!Astrolabe** | Map library (TomTom + ClickToMove walk) |

## Not installed by default

These stay in the repo for optional manual use but **PLAY.bat does not copy them** and moves existing copies to `Interface/AddOns/_disabled/`:

- P1FeralHUD / P1WarlockHUD — class combat HUDs (conflicts)
- Leatrix_Plus — QoL suite (user conflicts)
- WeakAuras + related folders — large, conflicts with minimal pack
- Bagnon*, Auctionator — never installed

## How PLAY.bat works

1. `git pull origin main`
2. `sync-addons.ps1` — copies only the 6 folders above (use `PLAY.bat FULL` for dev full mirror)
3. `cleanup-wow-addons.ps1` — moves manifest-OFF addons (HUD, Leatrix, WeakAuras, Bagnon, etc.) to `_disabled/`
4. `write-addons-txt.ps1` — enables the 6 addons in `WTF/Account/*/AddOns.txt`

Then log in and type **`/reload`**.

## In-game commands

| Command | Action |
|---------|--------|
| `/p1auto` | Toggle Auto Q (accept/turn-in + arrow + idle walk) |
| `/p1guide` | Show/hide crafting mats panel |
| `/p1quest` | Debug auto-quest status |
| `/p1minimal` | Print addon checklist |
| `/p1fix` | Clear stuck TomTom arrow; pause WeakAuras if still installed |

## Warlock vs Druid

Both packs use the same 6-addon layout. **PhaseOneLoader** differs (class-specific welcome text). PLAY.bat detects your pack from the installed loader file.

## Dev: full pack sync

```
powershell -File tools\sync-addons.ps1 -WowPath "C:\path\to\WoW" -Full -Pack DRUID
```

Use only when you need HUD/Leatrix/WeakAuras from the repo for testing.
