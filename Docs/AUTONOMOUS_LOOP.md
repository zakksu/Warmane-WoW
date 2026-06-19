# Autonomous agent loop

Agents run **without asking the user**. User only does `PLAY.bat` + `/reload`.

## Default decision tree

```
1. Read STATUS.md + GROK_TASKS.md
2. If Grok tasks pending → research via Questie DB (grok CLI optional)
3. Implement in Lua → bump version → RELEASE.txt → README
4. PLAY.bat sync (tools/sync-addons.ps1)
5. git commit + push + tag + gh release (if gh auth)
6. Write next GROK_TASKS.md queue
```

## Who decides what

| Question | Answer |
|----------|--------|
| Grok or Cursor for IDs? | **Questie `wotlkItemDB.lua` wins**; Grok when available |
| Version bump? | Patch +1 per ship (`2.0.2` → next `2.0.3`) |
| Push to main? | **Yes** — user requested full autonomy |
| Ask user? | **No** — unless gh auth missing or WoW path missing |

## One command (maintainer)

```powershell
.\tools\quick-release.ps1 -Notes "Optional changelog body"
```

## Player (unchanged)

Double-click **PLAY.bat** → **/reload**

## Handoff files

| File | After each cycle |
|------|------------------|
| `grok-handoff/STATUS.md` | SHIPPED + next queue |
| `grok-handoff/GROK_TASKS.md` | Next G1–G5 |
| `grok-handoff/CURSOR_TASKS.md` | All [x] |
