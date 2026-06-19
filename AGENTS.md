Multi-Agent Coordination Protocol (Grok + Cursor)
Goal: Achieve fast, autonomous development toward a fully autonomous WoW client controller (UI navigation, login, questing, combat, etc.) while keeping the Phase One addon pack stable and lightweight.
Agent Roles (Shared Workload)
Grok (High-Level Intelligence)
Architecture, system design, and principles enforcement.
Prompt engineering and agent orchestration.
High-level planning, research, and creative solutions.
Code review, quality control, and documentation.
Cloud resource coordination (use your $70 credits wisely).
Autonomy & learning loop improvements.
Cursor (Execution & Implementation)
Heavy coding, file creation, refactoring, and testing.
Rapid iteration on Lua addons and automation scripts.
Debugging and fixing specific issues.
Running local tests (PLAY.bat, AUTO_TEST.bat).
UI automation code (image recognition, coordinate systems, OCR).
Parallel Work Rule: Grok plans + reviews. Cursor executes. They hand off via LOOP.bat / handoff files. Overlap only on critical decisions.
Hardcoded Efficiency Principles
Minimalism First — Never add bloat. Prefer lightweight Lua over heavy external tools.
Fail Fast, Learn Faster — Every agent must log failures with screenshots/context.
Robustness Over Cleverness — UI control must have fallbacks (image → coordinates → keyboard navigation).
Cloud Leverage — Use available credits for parallel agents, longer contexts, or better models when local Cursor is limited.
Version Control Discipline — Small, frequent commits with clear messages. Only push working code.
Safety First — All in-game automation must be toggleable and detectable-risk-aware (Warmane anti-cheat).
Druid Focus — Prioritize Feral leveling features unless otherwise specified.
Handoff & Autonomy Rules
Use Docs/AUTONOMOUS_LOOP.md as the main driver.
Before any major change: Grok creates/updates a task in TASKS/ or comments in the relevant file.
Cursor only implements approved tasks.
On failure (e.g., password field detection): Take screenshot, log details, hand back to Grok for better strategy.
Cloud Instruction: When local limits are hit, agents should propose "spawn cloud instance" or "use higher context model" using available credits.
Login & UI Control Strategy (Current Priority)
Robust password field detection (template matching + fallback coordinates + Tab navigation).
Full login flow with retries and recovery.
Future: In-game click-to-move, ability casting, quest interaction, etc.
