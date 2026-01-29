# Power-Up System

## Status: 🔶 PARTIALLY IMPLEMENTED (4 power-ups)

## Overview
Power-ups spawn from broken bricks and move horizontally toward the paddle. Four power-ups are implemented with timers and HUD indicators.

## Implemented Power-Ups
1. **Expand**: Paddle height 130 → 180 (15s)
2. **Contract**: Paddle height 130 → 80 (10s)
3. **Speed Up**: Ball speed 500 → 650 (12s)
4. **Triple Ball**: Spawns 2 additional balls (instant)

## Core Mechanics (Implemented)
- **Spawn Chance**: 20% per breakable brick.
- **Spawn Position**: Brick’s global position.
- **Movement**: Horizontal to the right at 150 px/s.
- **Miss Behavior**: Despawns if `x > 1300`.
- **Collection**: Area2D `body_entered` with paddle group.
- **HUD**: Timed effects show countdowns in HUD.

## Architecture
- `scenes/gameplay/power_up.tscn` + `scripts/power_up.gd`
- `scripts/power_up_manager.gd` (autoload) manages timed effects.

## Not Implemented (Tracked in Backlog)
Additional power-ups listed in the original plan are not implemented yet.
See `Tasks/Backlog/power-up-expansion.md`.

## Related Docs
- `Tasks/Backlog/power-up-expansion.md`
- `System/architecture.md`
