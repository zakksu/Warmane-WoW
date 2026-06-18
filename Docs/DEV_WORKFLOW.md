# Dev workflow (repo → WoW → /reload)

Fast loop for developing Phase One packs against a local Warmane 3.3.5 client.

## Daily workflow (recommended)

1. Edit addon Lua/XML in this repo (`PhaseOne_*/Interface/AddOns/`).
2. **Double-click `SYNC_AND_PLAY.bat`** at the repo root.
3. In game, type **`/reload`**.

`SYNC_AND_PLAY.bat` will:

- Read your saved WoW path from `tools/wow-path.cfg`
- `git pull origin main` (skips gracefully if not a git repo)
- **Quick sync** — copies only P1 custom addons (`PhaseOneLoader`, `P1AutoQuest`, `P1AdventureGuide`, class HUD)
- Updates all `WTF/Account/**/AddOns.txt` from `tools/addons-manifest.txt`
- Prints **"In game: /reload"**

First install or big dependency changes: run **`SYNC_AND_PLAY.bat /FULL`** (or `INSTALL.bat` once) to copy Questie, TomTom, Leatrix, etc.

After a loader bump, chat shows: **"P1 updated — /reload was enough"** (no in-game download).

---

## WoW path config

| File | Purpose |
|------|---------|
| `tools/wow-path.cfg` | One line: full path to folder containing `Wow.exe` |
| `tools/set-wow-path.bat` | Change saved path |
| `tools/find-warmane-path.bat` | Used by installers — cfg first, then env/common paths |

`INSTALL.bat` saves the path automatically after a successful install.

---

## AddOns.txt auto-enable

WotLK 3.3.5 stores addon on/off state in:

- `WTF/Account/<account>/AddOns.txt` (account-wide)
- `WTF/Account/<account>/<realm>/<character>/AddOns.txt` (per character)

Format: `AddonFolderName: 1` (on) or `: 0` (off).

`tools/addons-manifest.txt` lists required ON/OFF addons. `tools/write-addons-txt.ps1` merges the manifest into every existing `AddOns.txt` under `WTF/Account`, preserving unknown addons as-is.

**Required ON:** PhaseOneLoader, P1AutoQuest, P1FeralHUD / P1WarlockHUD, P1AdventureGuide, Questie-335, TomTom, !Astrolabe, Leatrix_Plus  

**OFF (conflicts / optional):** WeakAuras*, Bagnon*, Auctionator

In game: **`/p1minimal`** prints the same checklist.

**Leatrix:** keep **Automate quests** and **Automate gossip** OFF — use Questie + `/p1auto` instead (loader forces this on login).

---

## SYNC_AND_PLAY vs symlink mode

| Method | Best for | Notes |
|--------|----------|-------|
| **`SYNC_AND_PLAY.bat`** | Default dev loop | Robocopy changed P1 folders; safe; works without admin |
| **Symlink junctions** | Live-edit repo files | Advanced; WoW reads addons directly from git checkout |

### Symlink setup (optional)

Run PowerShell **as Administrator** (junctions into Program Files may need it):

```powershell
$wow = (Get-Content "tools\wow-path.cfg" -Raw).Trim()
.\tools\enable-dev-symlink.ps1 -WowPath $wow -Pack DRUID   # or WARLOCK / BOTH
```

Then edit files in the repo and `/reload` — no copy step. To undo, delete the junction folders under `Interface/AddOns` (repo files are untouched).

---

## GitHub releases (`gh`)

Maintainers use **`QUICK_UPDATE.bat`** to bump version, rebuild zips, push, and publish.

One-time setup for releases:

```powershell
gh auth login
```

Players without git can download zips from [GitHub Releases](https://github.com/zakksu/Warmane-WoW/releases) and run `INSTALL.bat`.

---

## Related docs

- [INCREMENTAL_UPDATES.md](INCREMENTAL_UPDATES.md) — player-facing update guide
- [README.md](../README.md) — install and pack overview
