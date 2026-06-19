# Parallel agents — Grok + Cursor

Grok was hitting **max-turn timeouts** on monolithic G1–G4 bundles. Split work into **lanes** so each agent does one focused task.

## Grok (3 parallel)

| Script | What |
|--------|------|
| `Docs/grok-handoff/task-manifest.json` | Lane definitions (G5, G6, G7) |
| `tools/grok-parallel.ps1` | Runs up to 3 `grok.exe` jobs at once |
| `Docs/grok-handoff/responses/G5.md` etc. | Per-lane output |
| `grok-response.md` | Auto-merged |

Each lane gets **18 turns** (not 30 on one giant prompt), so failures are isolated and retried per lane.

## Cursor (3 parallel)

| Script | What |
|--------|------|
| `CURSOR_TASKS-druid-data.md` | Lane owns druid Data.lua ICC section |
| `CURSOR_TASKS-warlock-data.md` | Lane owns warlock Data.lua 70-80 |
| `CURSOR_TASKS-druid-waypoints.md` | Lane owns waypoint coord fixes |
| `tools/emit-handoff-lane.ps1 -All` | Copy-paste prompts for 3 Composer sessions |
| `CURSOR_WAKE-<lane>.md` | Hook pickup per lane |

**You:** open 3 Cursor agents (or Cloud agents), paste one lane prompt each, work in parallel.

## Loop integration

`LOOP.bat` now calls `grok-parallel.ps1` by default. On `GROK_DONE`, `cursor-parallel.ps1` writes lane wake files.

Fallback: `-Sequential` on `agent-handoff.ps1` for old single-prompt mode.

## Add a lane

1. Add task to `task-manifest.json`
2. Add spec under `Docs/grok-handoff/tasks/`
3. Re-run `grok-parallel.ps1`
