# Incremental updates (keep playing)

You do **not** need a full reinstall for small pack updates. Pick one method below, then type **`/reload`** in game.

## Easiest: run the installer again

1. Pull the latest repo (or download the newest release zips).
2. Double-click **`INSTALL.bat`** at the repo root (or `INSTALL_WARLOCK.bat` / `INSTALL_DRUID.bat`).
3. Confirm your Warmane folder — the script overwrites addon files in `Interface/AddOns/`.
4. Log in and type **`/reload`**.

Your Questie/Leatrix/P1 settings are kept in WoW saved variables; Phase One presets re-apply when the loader version changes.

## Faster: copy only what changed

If you know which addons were updated (e.g. only `P1FeralHUD` or `PhaseOneLoader`):

1. Copy just those folders from:
   - `PhaseOne_LevelingPack/Interface/AddOns/` (Warlock), or
   - `PhaseOne_Druid_LevelingPack/Interface/AddOns/` (Druid)
2. Paste into your Warmane `Interface/AddOns/` (overwrite when prompted).
3. **`/reload`** in game.

When in doubt, use **INSTALL.bat** — it is safe and only takes a few seconds.

## Check you are on the new version

After `/reload`, chat should show the Phase One welcome line with the new version (e.g. `v1.1.4`), or presets will re-apply once automatically.

## Maintainers: ship a small release

After committing addon fixes on `main`:

```text
QUICK_UPDATE.bat
```

That bumps the patch version in both `PhaseOneLoader` addons, updates `RELEASE.txt`, rebuilds zips, pushes `main`, tags `vX.Y.Z`, and uploads zips to GitHub Releases when `gh` is authenticated.

Optional release notes:

```powershell
.\tools\quick-release.ps1 -Notes "Questie auto-quest toggle on HUD"
```
