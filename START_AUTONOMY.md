# START_AUTONOMY.md

**Status**: ACTIVE — Begin Full Autonomous Execution  
**Budget Cap**: Maximum $20 total cloud spend (strict)  
**Stop Condition**: Do not stop until the entire scope below is released, committed, tested, and working in-game.

---

## Project Vision (Non-Negotiable)

Build a fast, reliable, self-improving autonomous system for Warmane Icecrown (WotLK 3.3.5a) that can:
- Log into the game reliably and autonomously
- Control the WoW UI (movement, abilities, targeting, quests, AH)
- Provide meaningful autonomous assistance for Feral Druid leveling
- Continuously improve itself through multi-agent collaboration

**Core Rule**: Work fast, autonomously, and in parallel where possible. Use cloud only when it accelerates delivery. Stay under $20 cloud total. Commit frequently. Test with `PLAY.bat` + in-game reload after major changes.

---

## Execution Order (Follow This Sequence Strictly)

### Phase 1: Foundation (Start Here)
**Goal**: Make autonomous login reliable.

**Tasks**:
1. Create robust password field detection (template matching + coordinate fallback + Tab navigation).
2. Build full login flow with retries, error recovery, and screenshot logging on failure.
3. Make the system toggleable and safe.
4. Test thoroughly and commit working version.

**Success Criteria**: Login succeeds consistently on every attempt with recovery.

---

### Phase 2: Agent Intelligence
**Goal**: Make the multi-agent system smarter and faster.

**Tasks**:
1. Improve failure detection and automatic handoff between Grok and Cursor.
2. Add structured logging (what failed + context + screenshot).
3. Enhance task decomposition so agents can break down work better.
4. Update `AUTONOMY_VISION_AND_EXECUTION.md` and `AGENTS.md` if needed.

**Success Criteria**: Agents can recover from failures and continue without user intervention.

---

### Phase 3: Core UI Autonomy
**Goal**: Give the system basic in-game control.

**Tasks**:
1. Implement reliable click-to-move / coordinate-based movement.
2. Build basic ability casting system (with awareness of current form for Druid).
3. Add simple targeting and interaction logic.
4. Integrate with existing P1DruidGuide where useful.

**Success Criteria**: Agent can move and use abilities autonomously in a controlled test.

---

### Phase 4: Feral Druid Specialization (Final Phase)
**Goal**: Deliver real value for Druid leveling.

**Tasks**:
1. Add smart form swapping logic (Cat ↔ Bear) based on situation.
2. Create basic combat assistance (auto-target, ability suggestions, form management).
3. Enhance `P1DruidGuide` with real-time autonomous suggestions.
4. Add quality-of-life features (e.g., auto Dash usage, better quest navigation).

**Success Criteria**: Druid has meaningful autonomous help while leveling (form management + combat assist).

---

## Agent Collaboration Rules

- **Grok**: Owns architecture, planning, prompt quality, cloud coordination, and final review.
- **Cursor**: Owns implementation, coding, debugging, and rapid iteration.
- Use `LOOP.bat` for handoff. Log decisions clearly.
- When blocked: Take screenshot + log context → hand off to the other agent.
- Work in parallel on independent tasks when possible.

## Cloud Usage Guidelines (Strict)

- Only use cloud when it significantly speeds up delivery.
- Total spend across the entire project **must not exceed $20**.
- Prefer local Cursor execution by default.
- Log any cloud usage with approximate cost.

## Workflow (Repeat Until Done)

1. Read current task from this file.
2. Plan the smallest useful increment.
3. Implement + test locally with `PLAY.bat`.
4. Commit with clear message.
5. Update this file or related docs if scope changes.
6. Hand off to the other agent if needed.
7. Move to next task.

**Do not create new big features outside this scope** unless they are required to complete the vision.

---

## Final Stop Condition

Stop autonomous execution only when:
- Phase 1 (Login) is reliable
- Phase 2 (Agent Intelligence) is improved
- Phase 3 (UI Control) is functional
- Phase 4 (Druid Specialization) delivers real value
- Everything is committed, documented, and tested in-game

**This file + AUTONOMY_VISION_AND_EXECUTION.md are the master directives.**

**Begin execution now.**
