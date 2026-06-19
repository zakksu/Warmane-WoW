# Agent handoff — Cursor ↔ Grok

Autonomous task queue between **Cursor Agent** and **Grok Build**.

## Continuous loop

```powershell
# Leave running (recommended)
.\LOOP.bat

# Or PowerShell directly
.\tools\agent-loop.ps1
```

See [AUTONOMOUS_LOOP.md](../AUTONOMOUS_LOOP.md) for full autonomy rules.

## Files

| File | Owner writes | Reader implements |
|------|--------------|-------------------|
| `GROK_TASKS.md` | Cursor / loop | Grok |
| `grok-response.md` | Grok | Cursor |
| `CURSOR_TASKS.md` | Grok | Cursor |
| `STATUS.md` | Loop / agents | Both |
| `CURSOR_WAKE.md` | Loop | Cursor hooks |
| `loop.log` | Loop | Maintainer |

## Manual (unchanged)

```powershell
.\tools\agent-handoff.ps1 -RunGrok
.\tools\agent-handoff.ps1 -RunGrok -NotifyCursor
.\tools\agent-handoff.ps1 -Status
```

## Status values

- `IDLE` — waiting for GROK_TASKS queue
- `GROK_PENDING` — queued for Grok
- `GROK_WORKING` — Grok task in flight
- `GROK_DONE` — response ready for Cursor
- `GROK_FAILED` — Grok error (loop retries)
- `CURSOR_PENDING` — wake file / CLI triggered
- `CURSOR_WORKING` — Cursor implementing
- `CURSOR_SHIPPED` — tasks done, shipping
- `SHIPPED` — synced, committed, cycle complete
