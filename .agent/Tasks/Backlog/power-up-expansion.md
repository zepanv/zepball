# Power-Up Expansion - Additional Types

## Status: 📋 BACKLOG

## Why
`Tasks/Completed/power-ups.md` lists several power-ups beyond the current six (Expand, Contract, Speed Up, Triple Ball, Big Ball, Small Ball). Those additional power-ups are not implemented in code or assets.

## Scope
Implement the next batch of power-ups plus infrastructure updates to support future additions.

## Missing Power-Ups (from existing plan)
- Slow Down (inverse of Speed Up)
- Extra Life
- Grab (ball sticks to paddle)
- Brick Through (pierce bricks)
- Warp (skip to next level)
- Double Score
- Bomb / Bomb Ball
- Magnet / Repel
- Mystery (random)
- Air Ball

## Implementation Notes
- Extend `PowerUpType` enum in `scripts/power_up.gd` and add icon PNG bindings.
- Add effect logic:
  - Ball behavior (speed, collision modifiers).
  - Paddle state changes (grab, magnet, repel).
  - Score modifiers (double score) via GameManager.
  - Progression effects (warp) via MenuController/LevelLoader.
- Update `PowerUpManager` durations and resets.
- Update HUD power-up indicators to handle new types and icons.
- Confirm power-up spawn list in `scripts/brick.gd` includes new types.

## Acceptance Criteria
- New power-ups spawn and apply correctly.
- Timed effects expire and reset cleanly.
- HUD shows active effects for all timed power-ups.
- Save/load does not break when new effects are active (no new save fields required unless needed).

## Related Docs
- `Tasks/Completed/power-ups.md`
- `System/architecture.md`
