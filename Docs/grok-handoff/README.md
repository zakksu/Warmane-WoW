# Agent handoff — Cursor ↔ Grok

Autonomous task queue between **Cursor Agent** and **Grok Build**.

## Files

| File | Owner writes | Reader implements |
|------|--------------|-------------------|
| `GROK_TASKS.md` | Cursor | Grok |
| `grok-response.md` | Grok | Cursor |
| `CURSOR_TASKS.md` | Grok | Cursor |
| `STATUS.md` | Either | Both |

## Run one Grok cycle

```powershell
.\tools\agent-handoff.ps1 -RunGrok
```

Then Cursor reads `grok-response.md` and checks off `CURSOR_TASKS.md`.

## Run full loop (Grok → implement hint)

```powershell
.\tools\agent-handoff.ps1 -RunGrok -NotifyCursor
```

Cursor Agent should run after pull when `STATUS.md` shows `GROK_DONE`.

## Status values

- `IDLE` — nothing pending
- `GROK_WORKING` — Grok task in flight
- `GROK_DONE` — response ready for Cursor
- `CURSOR_WORKING` — Cursor implementing
- `SHIPPED` — PLAY.bat synced, version bumped
