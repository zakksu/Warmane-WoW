# Autonomous agent loop

Agents run **without asking the user**. User only does `PLAY.bat` + `/reload`.

## Start the loop (one command)

Double-click **`LOOP.bat`** at the repo root, or:

```powershell
.\tools\agent-loop.ps1
# or
.\tools\start-agent-loop.ps1
```

Leave the window open. The loop polls `Docs/grok-handoff/STATUS.md` and drives:

```
IDLE → GROK_PENDING → GROK_WORKING → GROK_DONE
  → CURSOR_PENDING → CURSOR_WORKING → CURSOR_SHIPPED → SHIPPED → (repeat)
```

Log file: `Docs/grok-handoff/loop.log`

### Options

```powershell
.\tools\agent-loop.ps1 -PollSeconds 60      # slower poll
.\tools\agent-loop.ps1 -Once -DryRun          # smoke test state machine
.\tools\agent-handoff.ps1 -RunGrok            # manual Grok only (unchanged)
.\tools\agent-handoff.ps1 -RunGrok -NotifyCursor
```

## Cursor integration

| Mechanism | Role |
|-----------|------|
| `LOOP.bat` / `agent-loop.ps1` | Background daemon — Grok, wake, ship |
| `.cursor/rules/handoff-always.mdc` | Every agent session checks STATUS first |
| `.cursor/hooks.json` | `sessionStart` injects context; `stop` chains unfinished tasks |
| `Docs/grok-handoff/CURSOR_WAKE.md` | Written when headless Cursor unavailable |

**Headless Cursor** (optional): set `CURSOR_API_KEY` and install `pip install cursor-sdk`. Otherwise keep Cursor IDE open — hooks pick up `CURSOR_WAKE.md`.

## Default decision tree

```
1. Read STATUS.md + GROK_TASKS.md
2. Loop runs Grok when GROK_PENDING
3. Cursor implements CURSOR_TASKS (CLI, SDK, or IDE hooks)
4. Ship: sync-addons → commit → quick-release if Data.lua changed
5. Write next GROK_TASKS.md queue
```

## Who decides what

| Question | Answer |
|----------|--------|
| Grok or Cursor for IDs? | **Questie `wotlkItemDB.lua` wins**; Grok when available |
| Version bump? | Patch +1 per ship (`2.0.2` → next `2.0.3`) via `quick-release.ps1` |
| Push to main? | **Yes** when `gh auth` works |
| Ask user? | **No** — unless gh auth missing or WoW path missing |

## One command (maintainer release)

```powershell
.\tools\quick-release.ps1 -Notes "Optional changelog body"
```

## Player (unchanged)

Double-click **PLAY.bat** → **/reload**

## Handoff files

| File | After each cycle |
|------|------------------|
| `grok-handoff/STATUS.md` | State machine + notes |
| `grok-handoff/GROK_TASKS.md` | Next G1–G5 for Grok |
| `grok-handoff/CURSOR_TASKS.md` | Checkbox list for Cursor |
| `grok-handoff/loop.log` | Daemon log |

## Failure handling

- Grok auth/exit errors → `GROK_FAILED` → retry with exponential backoff
- Missing `wow-path.cfg` → ship logs warning, skips sync (run `PLAY.bat` once)
- Missing `gh auth` → commit locally, skip push/release
- Cursor timeout (default 120 min) → re-writes `CURSOR_WAKE.md`
