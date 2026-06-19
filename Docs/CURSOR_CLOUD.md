# Cursor Cloud Agents — Warmane WoW

Run this repo on **Cursor Cloud** so agents can ship updates while you're away. You still use **PLAY.bat → /reload** in game.

## One-time setup (easy)

### 1. Push repo to GitHub
Already at `zakksu/Warmane-WoW` — ensure latest `main` is pushed.

### 2. Enable Cloud Agents in Cursor
1. Open [cursor.com](https://cursor.com) → **Dashboard** → **Cloud Agents** (or Settings → Beta)
2. Connect your **GitHub** account
3. Select repository: **Warmane-WoW**
4. Default branch: **main**

### 3. Project instructions (already in repo)
Cloud agents read:
- **`AGENTS.md`** — dev loop, Lua 3.3.5 rules, PLAY.bat workflow
- **`.cursor/rules/`** — plan-first patterns

No extra config required.

### 4. Optional: Grok side-by-side
```powershell
grok /login
.\tools\install-grok-cursor-ext.ps1
```
Reload Cursor → Grok sidebar for parallel research (BIS data, quest chains). See [GROK_INTEGRATION.md](GROK_INTEGRATION.md).

## Daily workflow

| You | Cloud / local agent |
|-----|---------------------|
| Start Cloud Agent task: *"Ship v1.5.x druid guide tweak"* | Edits Lua, commits to `main` |
| `git pull` or wait for PLAY.bat pull | — |
| Double-click **PLAY.bat** | Syncs addons to WoW |
| **`/reload`** in game | Done |

## Cloud Agent prompt template

```
Repo: Warmane-WoW druid pack.
Task: [one scoped change]
Rules: AGENTS.md, WoW 3.3.5 API only.
Ship: bump loader version, RELEASE.txt, commit push main.
Do not edit vendored Questie unless Warmane bug.
```

## Local path (your PC)

`tools/wow-path.cfg` points at your WoW install. **PLAY.bat** uses it automatically — Cloud agents do not need your local path.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Cloud agent can't push | Check GitHub repo permissions in Cursor dashboard |
| No changes in game | Run **PLAY.bat** then `/reload` |
| Wrong WoW folder | `tools\set-wow-path.bat` |

## What Cloud cannot do

- Run Warmane client or test in-game UI
- Run **PLAY.bat** on your machine (you do that once per update)

That is why **PLAY.bat** stays the one-click install step.
