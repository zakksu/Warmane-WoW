# Grok Build + Cursor integration

Honest feasibility guide for using **xAI Grok Build** alongside **Cursor** on the Warmane WoW repo.

Last updated: 2026-06-18

---

## What is Grok Build?

**Grok Build** is xAI's terminal-native coding agent (beta, May 2026). It is **not** a Cursor plugin — it is a separate CLI (`grok`) that:

- Runs an interactive TUI, **headless** one-shot mode (`grok -p "..."`), or **ACP** (`grok agent stdio`) for IDE sidebar clients
- Supports **plan mode**, **parallel subagents**, git worktrees, MCP servers, skills, and hooks
- Uses the **grok-build** / **grok-build-0.1** model (also on the xAI API)
- Reads project rules from **AGENTS.md**, **`.cursor/rules/`**, and **`.grok/`** (Cursor/Claude compat built in)

Subscription: SuperGrok / X Premium Plus for CLI login, **or** pay-as-you-go via **`XAI_API_KEY`**.

---

## Can Grok Build run *inside* Cursor Agent chat?

**No — not today.** There is no official "Grok Build as Cursor subagent" bridge.

| Approach | Works? | Notes |
|----------|--------|-------|
| Grok inside Cursor Agent panel | ❌ | Different runtimes; no public API to embed Grok Build in Cursor chat |
| **Grok sidebar extension in Cursor** | ✅ | Community extension speaks ACP to `grok agent stdio` |
| **Shared repo rules** (AGENTS.md, `.cursor/rules`) | ✅ | Both agents read the same instructions |
| **grok-build-0.1 as Cursor model** | ✅ | Pick model in Cursor settings (API key); model only — not Grok's tool loop |
| **Headless Grok in scripts/CI** | ✅ | `grok -p` / `tools/grok-headless.ps1` |
| **MCP shared config** | ✅ | Grok auto-loads `.cursor/mcp.json` |

**Practical setup:** use **Cursor Agent** and **Grok Build sidebar/terminal** as **complementary** agents on the same repo, not nested.

---

## What is already on this machine

Verified on your environment:

| Item | Status |
|------|--------|
| Grok CLI | ✅ `C:\Users\godin\.grok\bin\grok.exe` (v0.2.54) |
| User config | ✅ `~/.grok/config.toml` (minimal) |
| Repo AGENTS.md | ✅ Added at repo root |
| Repo `.grok/config.toml` | ✅ Added (project scope) |
| Repo `.cursor/rules/grok-style-workflows.mdc` | ✅ Added |

Run `grok inspect` from the repo root to confirm project instructions load after pulling these files.

---

## Recommended setup (best integration)

### 1. Sign in to Grok CLI (once)

```powershell
grok /login
# Or for CI/headless only:
# $env:XAI_API_KEY = "xai-..."
```

### 2. Install Grok Build sidebar in Cursor

```powershell
.\tools\install-grok-cursor-ext.ps1
```

Then **Reload Window**. Extension ID: `PawelHuryn.grok-vscode-phuryn` — spawns `grok agent stdio` over [Agent Client Protocol (ACP)](https://agentclientprotocol.com).

Configure CLI path if needed: setting `grok.cliPath` → `C:\Users\godin\.grok\bin\grok.exe`.

### 3. Use both agents deliberately

See **[TASK_DIVISION.md](TASK_DIVISION.md)** for the current sprint split and copy-paste prompts.

| Task | Prefer |
|------|--------|
| In-editor multi-file edits, Cursor subagents, Bugbot | **Cursor Agent** (this chat) |
| Grok plan mode, 8 parallel Grok subagents, Grok plugins | **Grok sidebar** or `grok` TUI |
| Quick scripted review | `tools\grok-headless.ps1` |
| Ship addons to Warmane client | **`PLAY.bat`** (see below) |

### 4. Optional: grok-build-0.1 in Cursor model picker

Add an xAI API key in Cursor → use **grok-build-0.1** as the LLM for Cursor Agent. You get the model, not Grok's full tool/subagent harness.

---

## Repo files added for integration

| File | Purpose |
|------|---------|
| [AGENTS.md](../AGENTS.md) | Shared rules (Cursor + Grok + CI) |
| [.cursor/rules/grok-style-workflows.mdc](../.cursor/rules/grok-style-workflows.mdc) | Plan-first / parallel patterns for Cursor |
| [.grok/config.toml](../.grok/config.toml) | Project-scoped Grok permissions (extend with MCP via `grok mcp add --scope project`) |
| [tools/grok-headless.ps1](../tools/grok-headless.ps1) | Headless wrapper with repo `--cwd` |
| [tools/install-grok-cursor-ext.ps1](../tools/install-grok-cursor-ext.ps1) | Install ACP sidebar extension into Cursor |
| [.github/workflows/grok-agent.yml](../.github/workflows/grok-agent.yml) | Optional manual CI job (needs secret) |

### Headless examples

```powershell
# Explain an addon
.\tools\grok-headless.ps1 -Prompt "Outline P1AutoQuest event handlers"

# JSON for scripting
.\tools\grok-headless.ps1 -Prompt "List slash commands in P1*" -OutputFormat json

# Unattended (careful — modifies files)
.\tools\grok-headless.ps1 -Prompt "Fix typo in welcome text" -Yolo
```

---

## MCP bridge (Cursor ↔ Grok)

Grok **automatically merges** MCP configs (priority: `.grok/config.toml` > Claude > **`.cursor/mcp.json`** > `.mcp.json`).

To share MCP servers:

1. Add servers in Cursor: **Settings → MCP** (writes `~/.cursor/mcp.json` or project `.cursor/mcp.json`), **or**
2. Add project servers: `grok mcp add --scope project filesystem -- npx -y @modelcontextprotocol/server-filesystem .`

No custom bridge code required — Grok reads Cursor's MCP JSON when `[compat.cursor] mcps` is enabled (default).

---

## GitHub Actions (xAI API / headless Grok)

Workflow: [`.github/workflows/grok-agent.yml`](../.github/workflows/grok-agent.yml)

- Trigger: **workflow_dispatch** only (manual)
- Secret: **`XAI_API_KEY`**
- Installs Grok CLI on `ubuntu-latest`, runs a read-only repo summary prompt

This is a **template**, not enabled on every push — avoids cost and unintended edits. Extend for PR review bots using `grok -p ... --yolo --output-format json`.

Direct API alternative (no CLI): call `https://api.x.ai/v1/responses` with `"model": "grok-build-0.1"` — see [xAI docs](https://docs.x.ai/build/overview).

---

## Best alternative when full Grok↔Cursor fusion is impossible

You already have a strong local loop. **Recommended daily workflow:**

```
Edit Lua in repo
    → Cursor Agent (implementation, review, subagents)
    → PLAY.bat (sync to Warmane, git pull, AddOns.txt)
    → /reload in game
```

Add Grok where it adds unique value:

```
Heavy parallel exploration / Grok plan mode
    → Grok sidebar or `grok` in terminal (same AGENTS.md)
    → merge diffs in git
    → PLAY.bat → /reload
```

Optional automation:

```
Issue triage / release notes draft
    → grok-headless.ps1 or GitHub Actions workflow
```

This matches how xAI positions Grok Build: **terminal/portable agent** that respects **AGENTS.md, MCP, and Cursor rules** — not a replacement for Cursor's IDE agent.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `grok inspect` shows 0 project instructions | Pull latest repo; ensure `AGENTS.md` exists at root |
| Extension can't find CLI | Set `grok.cliPath` to `~/.grok/bin/grok.exe` |
| Headless auth fails in CI | Set `XAI_API_KEY` repo secret; use `--yolo` only in trusted jobs |
| Grok and Cursor both edit files | Use git branches/worktrees; Grok supports `--worktree` |
| Project trusted: no | Run `grok` once interactively and approve trust for this repo |

---

## References

- [Introducing Grok Build](https://x.ai/news/grok-build-cli)
- [Grok Build 0.1 API](https://x.ai/news/grok-build-0-1)
- [Grok Build VS Code extension (ACP)](https://github.com/phuryn/grok-build-vscode)
- [xAI Build docs](https://docs.x.ai/build/overview)
- [Dev workflow (PLAY.bat)](DEV_WORKFLOW.md)
