# Power-Up System

## Status: 🔶 PARTIALLY IMPLEMENTED (6 power-ups)

## Overview
Power-ups spawn from broken bricks and move horizontally toward the paddle. Four power-ups are implemented with timers and HUD indicators.

## Implemented Power-Ups
1. **Expand**: Paddle height 130 → 180 (15s)
2. **Contract**: Paddle height 130 → 80 (10s)
3. **Speed Up**: Ball speed 500 → 650 (12s)
4. **Triple Ball**: Spawns 2 additional balls (instant)
5. **Big Ball**: Ball size 2x (12s)
6. **Small Ball**: Ball size 0.5x (12s)

## Core Mechanics (Implemented)
- **Spawn Chance**: 20% per breakable brick.
- **Spawn Position**: Brick’s global position.
- **Movement**: Horizontal to the right at 150 px/s.
- **Miss Behavior**: Despawns if `x > 1300`.
- **Collection**: Area2D `body_entered` with paddle group.
- **HUD**: Timed effects show countdowns in HUD.
- **Icons**: Power-up sprites now use individual PNGs in `assets/graphics/powerups/` (configured in `scripts/power_up.gd`):
  - Expand → `expand.png`
  - Contract → `contract.png`
  - Speed Up → `speed_up.png`
  - Triple Ball → `triple_ball.png`
  - Big Ball → `big_ball.png`
  - Small Ball → `small_ball.png`
- **Glow**: Icons render with a colored additive glow (green for Expand/Triple Ball/Big Ball, red for Contract/Speed Up/Small Ball).
- **Expand/Contract Conflict**: If both are active, paddle returns to base size until one expires, then the remaining effect applies.
- **Ball Size Conflict**: If Big Ball + Small Ball are both active, ball returns to base size until one expires.
- **Application Source**: Expand/Contract and Big/Small sizing are managed by `PowerUpManager` to avoid stacking conflicts.
- **Triple Ball Inheritance**: Extra balls inherit the active size multiplier when spawned (Big=2x, Small=0.5x, both/none=1x).
- **Debug Spawns**: In debug builds, `1` spawns Triple Ball, `2` spawns Expand, `3` spawns Contract, `4` spawns Big Ball, `5` spawns Small Ball (see `scripts/main.gd`).

## Architecture
- `scenes/gameplay/power_up.tscn` + `scripts/power_up.gd`
- `scripts/power_up_manager.gd` (autoload) manages timed effects.

## Not Implemented (Tracked in Backlog)
Additional power-ups listed in the original plan are not implemented yet.
See `Tasks/Backlog/power-up-expansion.md`.

## Related Docs
- `Tasks/Backlog/power-up-expansion.md`
- `System/architecture.md`
