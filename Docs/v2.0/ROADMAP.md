# P1 Druid Guide v2.0 — druid only

**Ship target:** 2.0.0 — personal coach overlay (character-aware, AH-first, fused NEXT).

## In v2.0.0 (this sprint)

| Feature | Module | User-facing |
|---------|--------|-------------|
| Scan history | `Brain.lua` | `/p1scan` shows delta since login |
| AH shopping list | `AhAutopilot.lua` | **SHOP** section — affordable buys |
| Fused NEXT | `NextRank.lua` | AH + quests ranked by ROI |
| Coach line | `Data.lua` + TIPS | Rotation hint @ level |
| Orchestration | `tools/orchestrator/` | Parallel Cursor agents |

## Post-2.0 (not this sprint)

- Price alerts / scan reminders
- Auto waypoint to Orgrimmar AH
- WeakAuras-free combat HUD
- Warlock pack

## Commands

| Cmd | v2 action |
|-----|-----------|
| `/p1scan` | Full scan + delta + refresh guide |
| `/p1ah` | Top SHOP item → Auctionator |
| `/p1guide` | Toggle overlay (SHOP + fused NEXT) |