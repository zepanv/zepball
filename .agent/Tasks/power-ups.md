# Power-Up System Implementation Plan

## Overview
Power-ups are a critical component of Zep Ball, adding variety, strategy, and chaos to the core gameplay loop. They appear when bricks are broken and fall towards the bottom of the screen. The player collects them with the paddle.

## Power-Up Types
Based on the z-ball review, we will implement the following power-ups:

### Player Benefiting (Buffs)
1.  **Big Ball**: Makes ball jumbo sized.
2.  **Small Ball**: Makes ball miniature.
3.  **Expand**: Lengthens bar size (Big Paddle).
4.  **Triple Ball**: Makes one ball become three.
5.  **Bomb Ball**: Engulfs ball with fire.
6.  **Grab**: Causes ball to stick onto bar.
7.  **Slow Down**: Decreases speed of ball.
8.  **Brick Through**: Lets ball slice through bricks.
9.  **Warp**: Lets you instantly reach the next level.
10. **Air Ball**: Lets ball bounce off screen and bounce back like a grenade.
11. **Double Score**: Gives you twice the usual points for brick breaking.
12. **Extra Life**: Gives you extra bar of life.
13. **Mystery**: Gives you one powerup at random.
14. **Bomb**: Transforms bricks into an explosive.

### Player Hinderance (Debuffs) - "Anxiety Inducing"
15. **Contract**: Shortens bar size (Small Paddle).
16. **Speed Up**: Increases speed of ball.
17. **Repel**: Causes ball to deviate away from bar more strongly.
18. **Magnet**: Causes ball to gravitate toward bar more strongly.

## Mechanics

### Spawning
- **Chance**: Each brick has a chance to spawn a power-up (e.g., 20%).
- **Drop Logic**: Power-ups spawn at the brick's location and move horizontally towards the right (towards the paddle).
- **Gravity/Physics**: They should move in a straight line or have slight gravity. They are *not* the ball; if they pass the paddle, they are lost.

### Collection
- **Collision**: Area2D on the power-up detects `body_entered` with the Paddle (CharacterBody2D).
- **Effect**: On collision, the power-up calls an `apply_effect()` method on the GameManager or Paddle and then `queue_free()`.

### Duration
- **Time-based**: Most effects last for varying durations (e.g., 10-15 seconds).
- **Life-based**: Some persist until a life is lost (e.g., Guns, Sticky).
- **Instant**: Warp, Extra Life.

## Implementation Architecture

### `PowerUp` Class (Base Scene)
- `Area2D` for collision.
- `Sprite2D` for the icon.
- `type`: Enum or String identifier.
- `duration`: Float.

### `PowerUpManager` (or Game Manager extension)
- Handles the active power-up timers.
- Stacks effects (e.g., Big Paddle + Guns).
- Clears effects on level complete or life lost.

## Visuals
- Distinct icons for each power-up.
- Color coding: Green/Blue for Buffs, Red for Debuffs.
- Timer UI: Show active power-ups and remaining time on the HUD.

## Tasks
- [ ] Create base `power_up.tscn` and script.
- [ ] Define `PowerUpType` enum.
- [ ] Implement spawning logic in `Brick`.
- [ ] Implement collision logic in `Paddle`.
- [ ] Implement effect logic in `GameManager` / `Paddle` / `Ball`.
- [ ] Create assets/icons for 18 power-ups.
- [ ] Add HUD indicators for active effects.
