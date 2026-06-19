# Grok tasks — parallel cycle (G5–G7)

**State:** READY  
**Mode:** **3 parallel Grok agents** via `task-manifest.json`

## Run

```powershell
.\tools\agent-handoff.ps1 -RunGrok          # parallel (default when manifest exists)
.\tools\grok-parallel.ps1                   # direct
.\tools\agent-handoff.ps1 -RunGrok -Sequential   # legacy single-agent
```

## Lanes

| ID | Grok spec | Cursor lane | Owns |
|----|-----------|-------------|------|
| G5 | `tasks/G5-icc-bis.md` | druid-data | P1DruidGuide/Data.lua (ICC BiS) |
| G6 | `tasks/G6-warlock-70.md` | warlock-data | P1WarlockGuide/Data.lua (70-80) |
| G7 | `tasks/G7-waypoints.md` | druid-waypoints | P1DruidGuide/Data.lua (coords only) |

Outputs merge to `grok-response.md`. Per-lane `CURSOR_TASKS-<lane>.md` for parallel Cursor agents.

Spawn Cursor lanes: `.\tools\emit-handoff-lane.ps1 -All`

See `Docs/PARALLEL_AGENTS.md`.
