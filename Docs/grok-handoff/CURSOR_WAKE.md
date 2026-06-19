# Cursor wake  - implement handoff

**Triggered:** 2026-06-19 01:22:08

Read in order:
1. Docs/grok-handoff/STATUS.md  - set **State:** CURSOR_WORKING when you start
2. Docs/grok-handoff/grok-response.md  - Grok research output
3. Docs/grok-handoff/CURSOR_TASKS.md  - check off each item as you complete it

## Autonomous rules (AGENTS.md + Docs/AUTONOMOUS_LOOP.md)

- Implement all unchecked CURSOR_TASKS into Lua/Data.lua as appropriate
- Questie wotlkItemDB.lua wins for item IDs
- Run sync via 	ools/sync-addons.ps1 (wow-path.cfg) after Lua edits
- Commit locally when done; push/tag only if gh auth works
- Set STATUS to **CURSOR_SHIPPED** when all tasks are [x]
- Queue next GROK_TASKS.md items for the following Grok cycle

Delete or rename this file after starting work (optional).
