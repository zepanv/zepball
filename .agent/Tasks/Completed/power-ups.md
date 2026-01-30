# Power-Up System

## Status: ✅ IMPLEMENTED (13 power-ups)

## Overview
Power-ups spawn from broken bricks and move horizontally toward the paddle. All power-ups are implemented with timers and HUD indicators.

## Implemented Power-Ups
1. **Expand**: Paddle height 130 → 180 (15s) - Green glow
2. **Contract**: Paddle height 130 → 80 (10s) - Red glow
3. **Speed Up**: Ball speed 500 → 650 (12s) - Red glow
4. **Triple Ball**: Spawns 2 additional balls (instant) - Green glow
5. **Big Ball**: Ball size 2x (12s) - Green glow
6. **Small Ball**: Ball size 0.5x (12s) - Red glow
7. **Slow Down**: Ball speed 500 → 350 (12s) - Green glow
8. **Extra Life**: Adds one life (instant) - Green glow
9. **Grab**: Ball sticks to paddle on contact (15s) - Green glow
10. **Brick Through**: Ball passes through bricks (12s) - Green glow
11. **Double Score**: 2x score multiplier (15s) - Green glow
12. **Mystery**: Applies random power-up effect (instant) - Yellow glow
13. **Bomb Ball**: Ball destroys surrounding bricks on impact (12s) - Green glow, ball has orange-red glow

## Core Mechanics (Implemented)
- **Spawn Chance**: 20% per breakable brick.
- **Spawn Position**: Brick's global position.
- **Movement**: Horizontal to the right at 150 px/s.
- **Miss Behavior**: Despawns if `x > 1300`.
- **Collection**: Area2D `body_entered` with paddle group.
- **HUD**: Timed effects show countdowns in HUD. Double Score shows in multiplier display.
- **Icons**: Power-up sprites now use individual PNGs in `assets/graphics/powerups/` (configured in `scripts/power_up.gd`).
- **Glow**: Icons render with a colored additive glow:
  - Green glow: Expand, Triple Ball, Big Ball, Slow Down, Extra Life, Grab, Brick Through, Double Score
  - Red glow: Contract, Speed Up, Small Ball
  - Yellow glow: Mystery
- **Expand/Contract Conflict**: If both are active, paddle returns to base size until one expires, then the remaining effect applies.
- **Ball Size Conflict**: If Big Ball + Small Ball are both active, ball returns to base size until one expires.
- **Application Source**: Expand/Contract and Big/Small sizing are managed by `PowerUpManager` to avoid stacking conflicts.
- **Triple Ball Inheritance**: Extra balls inherit the active size multiplier when spawned (Big=2x, Small=0.5x, both/none=1x).
- **Ball Speed Effects**: Speed Up changes trail to yellow-orange, Slow Down changes trail to blue. Both reset to white on expiration.
- **Grab Mechanic**: When active (15s), balls stick to paddle at exact contact point. Balls grabbed on back of paddle are automatically repositioned to front (play area side) to prevent immediate loss. Player can click to re-launch at any time. Released balls have 200ms grab immunity to prevent immediate re-grab. When timer expires, new balls won't stick, but already-grabbed balls remain held until player releases them. Multiple balls can be grabbed at different positions on the paddle. Small random variation on launch prevents stacked balls from colliding.
- **Brick Through**: Ball passes through bricks without bouncing, breaking them but maintaining trajectory.
- **Double Score**: Multiplies all score gains by 2x while active, shown in HUD multiplier display.
- **Mystery**: Randomly applies one of the other 12 power-up effects (excluding another Mystery).
- **Bomb Ball**: When ball hits a brick, immediately adjacent bricks (75-pixel radius) are also destroyed. Ball glows orange-red while active. Useful for clearing tight clusters.
- **HUD Indicators**: All timed power-ups show name and countdown timer. Colors: green (beneficial), red (risky), blue (slow), gold (score), yellow (mystery), orange-red (bomb ball).
- **Debug Spawns**: Key 1 spawns bomb_ball for testing (see `scripts/main.gd`).

## Architecture
- `scenes/gameplay/power_up.tscn` + `scripts/power_up.gd`
- `scripts/power_up_manager.gd` (autoload) manages timed effects.

## Additional Power-Ups (Future)
Other power-ups remain in backlog for future expansion:
- Warp (skip to next level)
- Bomb / Bomb Ball (destroy nearby bricks)
- Magnet / Repel (attract/repel ball)
- Air Ball (ball ignores gravity)
- Block (temporary shield brick)

See `Tasks/Backlog/power-up-expansion.md` for details.

## Related Docs
- `Tasks/Backlog/power-up-expansion.md`
- `System/architecture.md`
