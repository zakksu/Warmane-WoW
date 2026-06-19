# AUTONOMY_VISION_AND_EXECUTION.md

**Project Vision**: Build a fast, reliable, self-improving autonomous system for Warmane Icecrown that can:
- Log in reliably
- Control the WoW UI autonomously (movement, abilities, quests, AH interaction, etc.)
- Power efficient Feral Druid leveling with real assistance
- Continuously improve through multi-agent collaboration (Grok + Cursor)

**Core Mandate**: Execute fast and autonomously. Use cloud resources only when beneficial and **never exceed $20 total cloud cost**. Do not wait for user approval on every step. Stop only when the full defined scope is released, committed, and working in-game.

## Current State (June 19, 2026)
- Solid Phase One addon pack with Questie, auto-quest, P1DruidGuide, AH integration, etc.
- Good dev automation (PLAY.bat, LOOP.bat, handoff system)
- Updated AGENTS.md with coordination rules
- Main blocker: Unreliable autonomous login + limited in-game UI control

## Execution Order (Strict Sequence)

### Phase 1 — Foundation (Do First)
1. **Robust Autonomous Login System**
   - Reliable password field + login flow with retries and recovery
   - Screenshot logging on failure

### Phase 2 — Intelligence Layer
2. **Improved Agent Self-Debug & Learning Loop**
   - Automatic failure analysis and handoff
   - Smarter task decomposition

### Phase 3 — Core Autonomy
3. **Basic UI Control Foundation**
   - Reliable click-to-move and ability casting
   - Form-aware logic for Druid

### Phase 4 — Druid Specialization
4. **Feral Druid Autonomous Features**
   - Smart form swapping, rotation assistance, combat support
   - Enhanced P1DruidGuide with real-time suggestions

## Hardcoded Principles (Follow Always)

- **Speed + Autonomy**: Move fast. Make decisions. Commit working code.
- **Budget**: Cloud usage ≤ $20 total. Prefer local execution.
- **Minimalism**: Keep everything lightweight. Avoid bloat.
- **Safety**: All automation must be toggleable. Respect Warmane rules.
- **Documentation**: Update relevant files after every major change.
- **Testing**: Use PLAY.bat + in-game verification.

## Agent Roles

- **Grok**: Architecture, planning, prompt engineering, review, cloud coordination, high-level decisions.
- **Cursor**: Implementation, coding, debugging, rapid iteration, local testing.

**Handoff**: Use existing LOOP.bat system. Log decisions clearly.

## Success Criteria (Stop Condition)

Stop only when:
- Login works reliably on every attempt
- Basic autonomous UI control (movement + abilities) is functional
- Druid has meaningful autonomous leveling assistance
- Everything is committed, documented, and tested in-game

**This file is the master directive. All agents must follow it until the scope is complete.**
