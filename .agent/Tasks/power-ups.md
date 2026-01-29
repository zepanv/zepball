# Power-Up System Implementation Plan

## Status: ✅ PARTIALLY IMPLEMENTED (4 power-ups)

## Overview
Power-ups add variety and momentum to the core gameplay loop. They spawn when bricks are broken and move horizontally toward the paddle on the right. The player collects them with the paddle.

## Power-Up Types

### Implemented (Current)
1. **Expand**: Big paddle (height 130 → 180, 15s).
2. **Contract**: Small paddle (height 130 → 80, 10s).
3. **Speed Up**: Faster ball (speed 500 → 650, 12s).
4. **Triple Ball**: Spawns 2 additional balls (instant; no timer).

### Planned (Not Implemented)
5. **Big Ball**: Makes ball jumbo sized.  
6. **Small Ball**: Makes ball miniature.  
7. **Bomb Ball**: Engulfs ball with fire.  
8. **Grab**: Causes ball to stick onto bar.  
9. **Slow Down**: Decreases speed of ball.  
10. **Brick Through**: Lets ball slice through bricks.  
11. **Warp**: Lets you instantly reach the next level.  
12. **Air Ball**: Lets ball bounce off screen and bounce back like a grenade.  
13. **Double Score**: Gives you twice the usual points for brick breaking.  
14. **Extra Life**: Gives you extra bar of life.  
15. **Mystery**: Gives you one power-up at random.  
16. **Bomb**: Transforms bricks into an explosive.  
17. **Repel**: Causes ball to deviate away from bar more strongly.  
18. **Magnet**: Causes ball to gravitate toward bar more strongly.  

## Mechanics (Current)

### Spawning
- **Chance**: 20% per breakable brick.
- **Spawn point**: Brick's global position.
- **Movement**: Horizontal to the right at 150 px/s.
- **Miss behavior**: If `x > 1300`, power-up is freed.

### Collection
- **Collision**: Area2D `body_entered` with the paddle group.
- **Effect**: Signal emitted to main controller; power-up is freed.

### Duration
- **Time-based**: Expand (15s), Contract (10s), Speed Up (12s).
- **Instant**: Triple Ball.

## Implementation Architecture (Current)

### `PowerUp` Scene (`scenes/gameplay/power_up.tscn`)
- `Area2D` for collision.
- `Sprite2D` icon from sprite atlas (`assets/graphics/powerups/powerups.jpg`).
- `PowerUpType` enum (Expand, Contract, Speed Up, Triple Ball).

### `PowerUpManager` (autoload)
- Tracks active timed effects in a dictionary.
- Refreshes timers on re-collection.
- Resets paddle size and ball speed on expiry.

## Visuals (Current)
- Icons from a 5x5 power-up atlas.
- HUD shows active timed effects with countdown text.

## Tasks
- [x] Create base `power_up.tscn` and script.
- [x] Define `PowerUpType` enum.
- [x] Implement spawning logic in `Brick`.
- [x] Implement collision logic in `PowerUp` (Area2D `body_entered`).
- [x] Implement effect logic in `Main` / `Paddle` / `Ball`.
- [x] Add HUD indicators for active timed effects.
- [ ] Expand power-up catalog beyond current 4 types.
