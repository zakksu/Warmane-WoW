# Warmane WoW — Phase One Quest Pack

Shared agent instructions for **Cursor**, **Grok Build**, and other coding agents.

## Project

Warmane WotLK 3.3.5a quest addon bundle (Warlock + Feral Druid packs). Lua/XML addons under:

- `PhaseOne_LevelingPack/Interface/AddOns/`
- `PhaseOne_Druid_LevelingPack/Interface/AddOns/`

## Dev loop

1. Edit addon Lua/XML in this repo.
2. Double-click **`PLAY.bat`** (git pull → sync addons → cleanup → update AddOns.txt).
3. In game: **`/reload`**.

See `Docs/DEV_WORKFLOW.md` for symlink mode, manifest, and release tooling.

## Coding conventions

- **Lua 5.1** (WoW 3.3.5 client). No `goto`, no `\z` escapes, no 5.2+ features.
- Match existing addon style: local functions, `CreateFrame`, event handlers, slash commands.
- Pack-specific logic lives in `P1*` addons; Questie/TomTom are vendored — avoid editing unless fixing a Warmane-specific bug.
- Keep changes minimal and scoped. Do not refactor unrelated addons.
- Test mentally against 3.3.5 API (`GetQuestLogTitle`, `Questie`, `TomTom`, etc.).

## File layout

| Path | Role |
|------|------|
| `PLAY.bat` | Player/maintainer sync to Warmane client |
| `tools/sync-addons.ps1` | Robocopy pack addons to WoW |
| `tools/addons-manifest.txt` | Required ON/OFF addon list |
| `Docs/MINIMAL_PACK.md` | What ships in the default install |
| `Docs/GROK_INTEGRATION.md` | Grok Build + Cursor setup |
| `Docs/AUTONOMOUS_LOOP.md` | Full autonomy — no user prompts between cycles |

## Commits and releases

- **Autonomous mode:** commit, push, tag, and `gh release` without asking (see `Docs/AUTONOMOUS_LOOP.md`).

- Conventional, concise commit messages focused on *why*.
- Maintainers: `QUICK_UPDATE.bat` / `RELEASE.bat` for version bumps and zips.
- Do not commit secrets (API keys, `tools/wow-path.cfg` with personal paths is local-only).

## Agent workflow hints

- **Plan first** for multi-addon or cross-pack changes.
- **Parallel agents:** see `Docs/TASK_DIVISION.md` — one agent per lane (Guide / Nav / Loader / Release).
- **Parallel exploration** is fine for Questie vs P1* boundaries, Warlock vs Druid pack diffs.
- After Lua edits, remind the user to run `PLAY.bat` and `/reload` — agents cannot run the game client.
