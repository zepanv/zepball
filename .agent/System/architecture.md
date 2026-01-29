# Zep Ball - System Architecture

## Overview
Zep Ball is a 2D breakout/arkanoid-style game built with Godot. The paddle sits on the right side of the playfield, and the ball travels leftward to break bricks. The current implementation is a single main scene with reusable gameplay scenes and GDScript-driven systems for game state, power-ups, and UI.

## Project Structure
- `project.godot`: Project configuration (window size, input map, autoloads).
- `scenes/main/main.tscn`: Root scene for gameplay.
- `scenes/gameplay/`: Reusable gameplay scenes (`ball.tscn`, `paddle.tscn`, `brick.tscn`, `power_up.tscn`).
- `scripts/`: All gameplay logic in GDScript.
- `assets/graphics/`: Sprites, backgrounds, and particle textures.
- `levels/`: Reserved for future level data (currently empty).

## Runtime Scene Graph (main.tscn)
```
Main (Node2D) [scripts/main.gd]
├── GameManager (Node) [scripts/game_manager.gd] (group: game_manager)
├── Camera2D [scripts/camera_shake.gd]
├── Background (ColorRect) [runtime: replaced by TextureRect in CanvasLayer]
├── PlayArea (Node2D)
│   ├── Walls (Node2D)
│   │   ├── TopWall (StaticBody2D + CollisionShape2D)
│   │   ├── BottomWall (StaticBody2D + CollisionShape2D)
│   │   └── LeftWall (StaticBody2D + CollisionShape2D)
│   ├── Paddle (CharacterBody2D) [instance: paddle.tscn] (group: paddle)
│   ├── Ball (CharacterBody2D) [instance: ball.tscn] (group: ball)
│   └── BrickContainer (Node2D) [instanced bricks added at runtime]
└── UI (CanvasLayer)
    └── HUD (Control) [scripts/hud.gd]
        ├── TopBar (Score/Logo/Lives labels)
        └── PowerUpIndicators (VBoxContainer)
```

### Runtime Notes
- `scripts/main.gd` replaces the `Background` ColorRect with a `TextureRect` inside a new `CanvasLayer` (layer -100) so it fills the viewport and scales with resize.
- Bricks are created at runtime in `create_test_level()` and added under `PlayArea/BrickContainer`.

## Core Systems and Responsibilities

### Main Controller (`scripts/main.gd`)
- Connects signals between the ball, GameManager, HUD, and bricks.
- Creates a test level (5x8 grid) at startup.
- Tracks `remaining_breakable_bricks` to determine level completion.
- Handles ball loss logic (life loss only if last ball in play).
- Spawns and manages power-ups and multi-ball behavior.
- Loads a random background image at startup.

### Game State (`scripts/game_manager.gd`)
- Owns score, lives, and current level counters.
- Defines state machine: `MAIN_MENU`, `READY`, `PLAYING`, `PAUSED`, `LEVEL_COMPLETE`, `GAME_OVER`.
- Uses Godot pause system (`get_tree().paused`) when state is `PAUSED`.
- Emits signals for UI updates and state changes.

### Paddle (`scripts/paddle.gd` + `scenes/gameplay/paddle.tscn`)
- CharacterBody2D with vertical movement on the right side.
- Input:
  - Keyboard uses `move_up` / `move_down` actions.
  - Mouse movement directly sets `position.y` for instant response.
- Tracks actual vertical velocity for ball spin.
- Power-up effects adjust paddle height and collision shape via tween.

### Ball (`scripts/ball.gd` + `scenes/gameplay/ball.tscn`)
- CharacterBody2D with constant-speed movement.
- Launches from paddle on `launch_ball` action.
- Collision handling:
  - Paddle: reflect + spin based on paddle velocity.
  - Bricks: reflect + notify brick.
  - Walls: reflect.
- Ball-to-ball collisions are explicitly ignored.
- Out-of-bounds:
  - Right boundary (`x > 1300`): triggers `ball_lost`.
  - Left/top/bottom escape is treated as an error; extra balls are removed, main ball resets.

### Bricks (`scripts/brick.gd` + `scenes/gameplay/brick.tscn`)
- StaticBody2D with multiple brick types and hit counts.
- Types include Normal, Strong, Unbreakable, and themed variants (Gold/Red/Blue/Green/Purple/Orange).
- Uses square textures scaled to 48x48 (collision shape is 48x48).
- On break:
  - Emits `brick_broken(score_value)`.
  - 20% chance to spawn a power-up.
  - Plays particle burst and frees after 0.6s.

### Power-Ups (`scripts/power_up.gd` + `scenes/gameplay/power_up.tscn`)
- Area2D that moves horizontally to the right.
- Types: `EXPAND`, `CONTRACT`, `SPEED_UP`, `TRIPLE_BALL`.
- Uses a 5x5 sprite atlas (`assets/graphics/powerups/powerups.jpg`).
- Emits `collected` when the paddle overlaps and then frees itself.

### Power-Up Timer Manager (`scripts/power_up_manager.gd`)
- Autoload singleton (`PowerUpManager`) used for timed effects.
- Tracks active effects and time remaining.
- Resets paddle size or ball speed when effects expire.
- `TRIPLE_BALL` is immediate and does not use timers.

### HUD (`scripts/hud.gd`)
- Displays score and lives via GameManager signals.
- Shows active timed power-ups with countdown timers.
- Shows a pause label when state is `PAUSED`.

### Camera Shake (`scripts/camera_shake.gd`)
- Camera2D script that provides `shake(intensity, duration)`.
- Main controller triggers shake on brick breaks.

## Input Map (project.godot)
- `move_up`: Up Arrow, W
- `move_down`: Down Arrow, S
- `launch_ball`: Space, Left Mouse Button
- `ui_cancel`: Escape (pause toggle)

## Gameplay Flow
- Game starts in `READY` state with ball attached to paddle.
- `launch_ball` sets the state to `PLAYING` and releases the ball.
- Losing the last ball decrements lives and returns to `READY`.
- When all breakable bricks are destroyed, state becomes `LEVEL_COMPLETE` and the ball stops.
- Escape toggles `PAUSED` only while in `PLAYING` or `PAUSED`.

## Power-Up Effects
- `EXPAND`: Paddle height 130 -> 180 (15s).
- `CONTRACT`: Paddle height 130 -> 80 (10s).
- `SPEED_UP`: Ball speed 500 -> 650 (12s).
- `TRIPLE_BALL`: Spawns two extra balls with safe angles; no timer.

## Visual Polish and Assets (Implemented)
- Brick sprites are square textures scaled to 48x48 with multiple themed variants.
- Ball has a CPUParticles2D trail enabled when in motion.
- Brick break particles emit 40 particles with rotation and color matching.
- Backgrounds: 7 images randomly selected at startup with 0.85 alpha dimming.
- Camera shake is triggered on brick breaks; intensity scales with score.
- Power-up icons are pulled from a 5x5 sprite atlas (`powerups.jpg`).

## Data and Persistence (Database Schema)
There is no database or persistent storage in the current codebase.
- All state is in-memory (score, lives, active power-ups).
- Save/high-score systems are not implemented yet.

## Complex or Risky Areas
- **Triple ball spawn logic**: `scripts/main.gd` clamps launch angles to a safe range and cancels spawns near edges to prevent balls escaping.
- **Background rendering**: `scripts/main.gd` replaces a ColorRect with a TextureRect inside a CanvasLayer to keep screen-space scaling correct.
- **Ball out-of-bounds handling**: extra balls are removed immediately when escaping left/top/bottom to avoid stuck collisions.

## Related Docs
- `System/tech-stack.md`
- `Tasks/core-mechanics.md`
- `Tasks/power-ups.md`
- `SOP/godot-workflow.md`
