# Zep Ball - System Architecture

## Overview

Zep Ball uses a scene-based architecture powered by Godot 4.x. This document describes the node hierarchy, scene organization, and system design patterns.

## Scene Hierarchy

### Main Game Scene (main.tscn)

```
Main (Node2D)
├── GameManager (Node) [Script: game_manager.gd]
│   └── Manages: score, lives, level state, game flow
│
├── BackgroundLayer (CanvasLayer, layer -100)
│   └── Background (TextureRect)
│       └── Random texture from asset pack, rendered in screen space
│
├── Camera2D [Script: camera_shake.gd]
│   └── Screen shake effects on brick impacts
│
├── PlayArea (Node2D)
│   ├── Walls (Node2D)
│   │   ├── TopWall (StaticBody2D + CollisionShape2D)
│   │   ├── BottomWall (StaticBody2D + CollisionShape2D)
│   │   └── LeftWall (StaticBody2D + CollisionShape2D)
│   │
│   ├── Paddle (CharacterBody2D) [Instance of paddle.tscn]
│   │   └── Position: Right side of screen (x ~1200)
│   │
│   ├── Ball (CharacterBody2D) [Instance of ball.tscn]
│   │   └── Launched from paddle
│   │
│   └── BrickContainer (Node2D)
│       └── Brick instances (from brick.tscn)
│
└── UI (CanvasLayer, process_mode: ALWAYS) [Script: hud.gd]
    └── HUD (Control)
        ├── TopBar (score, lives, logo)
        ├── PowerUpIndicators (active power-up timers)
        └── PauseLabel (shown when paused)
```

### Paddle Scene (paddle.tscn)

```
Paddle (CharacterBody2D) [Script: paddle.gd]
├── Visual (Sprite2D)
│   └── Texture: paddleBlu.png (Kenney asset), rotated 90°
│
└── CollisionShape (CollisionShape2D)
    └── Shape: RectangleShape2D (24x104)
```

**Key Properties:**
- Position: Fixed X (~1200), variable Y (60 to 660)
- Size: 24px wide, 104px tall (sprite dimensions when rotated)
- Movement: Vertical only (keyboard + mouse)
- Input priority: Mouse movement overrides keyboard while the mouse is moving; keyboard controls when mouse is idle
- Velocity tracking: For spin mechanics
- Pause behavior: Respects Godot's tree pause system
- Power-up effects: Scale sprite vertically for expand/contract

### Ball Scene (ball.tscn)

```
Ball (CharacterBody2D) [Script: ball.gd]
├── Sprite (Sprite2D)
│   └── Visual: Circle sprite
│
├── CollisionShape (CollisionShape2D)
│   └── Shape: CircleShape2D (radius ~8px)
│
└── Trail (CPUParticles2D)
    └── Particle trail effect when ball is moving
```

**Key Properties:**
- Initial position: Attached to paddle
- Velocity: Constant magnitude (500 px/s base, 650 with speed power-up)
- Physics: Reflection on collision + spin from paddle
- Pause behavior: Respects Godot's tree pause system
- Multiple balls: Triple ball power-up spawns additional ball instances

### Brick Scene (brick.tscn)

```
Brick (StaticBody2D) [Script: brick.gd]
├── Visual (Sprite2D)
│   └── Texture: Various brick sprites (Kenney assets)
│       └── Colors: Blue, Green, Grey, Purple, Red, Yellow
│       └── Shapes: Diamond, Polygon, Rectangle, Square
│       └── Variants: Normal and Glossy
│
├── CollisionShape (CollisionShape2D)
│   └── Shape: RectangleShape2D
│
└── BreakParticles (GPUParticles2D)
    └── Emitted on brick destruction, color-matched to brick
```

**Key Properties:**
- Types: Normal (1 hit, 10 pts), Strong (2 hits, 20 pts), Unbreakable
- Size: ~60px wide, ~30px tall
- Grid layout: 5x8 typical starting configuration
- Score value: Based on type
- Level completion: Main tracks a breakable-brick counter and completes when it reaches zero
- Break flow: On break, collisions are disabled immediately so the ball can't re-hit while particles play
- Power-ups: 20% chance to spawn power-up on break

### HUD Scene (hud.tscn)

```
UI (CanvasLayer, process_mode: ALWAYS) [Script: hud.gd]
└── HUD (Control)
    ├── TopBar (HBoxContainer)
    │   ├── ScoreLabel (Label) - Top-left
    │   ├── LogoLabel (Label) - Top-center
    │   └── LivesLabel (Label) - Top-right
    │
    ├── PowerUpIndicators (VBoxContainer)
    │   └── Dynamic power-up timers (top-right)
    │
    ├── PauseLabel (Label) - Center screen
    │   └── Shows "PAUSED" when game is paused
    │
    └── GameOverScreen (Panel) [WIP]
        └── Shows: Final score, retry/quit options
```

**Key Properties:**
- Process mode: ALWAYS (updates even when game is paused)
- Power-up indicators: Shows active effects with countdown timers
- Pause indicator: Automatically shown/hidden based on game state

## Coordinate System

### Screen Space (1280x720)
```
(0,0) ───────────────────── (1280,0)
  │                              │
  │   [Brick Grid]          [P]  │
  │   Left/Center           [a]  │
  │                         [d]  │
  │      Ball →             [d]  │
  │                         [l]  │
  │                         [e]  │
  │                              │
(0,720) ──────────────────── (1280,720)
```

**Window Scaling:**
- Viewport size: 1600x900 (design resolution)
- Stretch mode: canvas_items
- Window: Resizable, starts at 1600x900, no max size constraints
- Background: Rendered in CanvasLayer to fill screen properly during resize

### Key Positions
- **Paddle X**: 1200 (80px from right edge)
- **Paddle Y Range**: 40 to 680 (respects top/bottom margins)
- **Brick Grid**: X: 100-700, Y: 100-400 (example)
- **Ball Start**: Attached to paddle mid-point
- **Loss Zone**: Ball X > 1280 (passes right edge)

## Game State Machine

### States
```
┌─────────────┐
│  MAIN_MENU  │
└──────┬──────┘
       │ Start Game
       ▼
┌─────────────┐
│  READY      │ ← Ball attached to paddle
└──────┬──────┘
       │ Launch (Space/Click)
       ▼
┌─────────────┐
│  PLAYING    │ ← Ball in motion
└──────┬──────┘
       │
       ├──→ All bricks broken → LEVEL_COMPLETE
       ├──→ Ball lost → Decrement lives
       │                 │
       │                 ├─→ Lives > 0 → READY
       │                 └─→ Lives = 0 → GAME_OVER
       │
       └──→ Pause (Escape) ⇄ PAUSED
```

**Implemented in:** `game_manager.gd`

**Pause System:**
- Uses Godot's built-in `get_tree().paused` for automatic pause handling
- GameManager has `PROCESS_MODE_ALWAYS` to toggle pause
- UI has `PROCESS_MODE_ALWAYS` to show pause indicator and update timers
- All gameplay nodes automatically pause (ball, paddle, power-ups, etc.)
- Press ESC to pause/unpause

## Debug / Testing Controls
- `C`: Hit all bricks (breaks normals and strongs) for rapid level testing

### State Transitions
- **MAIN_MENU** → **READY**: User clicks "Start"
- **READY** → **PLAYING**: User presses space/click to launch ball
- **PLAYING** → **READY**: Ball lost, lives remain
- **PLAYING** → **LEVEL_COMPLETE**: All bricks destroyed
- **PLAYING** → **GAME_OVER**: Ball lost, no lives remaining
- **PLAYING** ⇄ **PAUSED**: User presses Escape

## Physics System

### Ball Physics (ball.gd)

**Movement:**
```gdscript
func _physics_process(delta):
    var collision = move_and_collide(velocity * delta)
    if collision:
        handle_collision(collision)

    # Maintain constant speed (arcade feel)
    velocity = velocity.normalized() * BALL_SPEED
```

**Collision Handling:**
1. **Walls**: Simple reflection (bounce_velocity = velocity.bounce(normal))
2. **Paddle**: Reflection + spin modifier
   ```gdscript
   # Reflect horizontally
   velocity.x *= -1

   # Add paddle spin (vertical velocity transfer)
   velocity.y += paddle.velocity.y * SPIN_FACTOR

   # Re-normalize to maintain speed
   velocity = velocity.normalized() * BALL_SPEED
   ```
3. **Bricks**: Reflection + signal to brick + particle effect

**Constants:**
- `BALL_SPEED = 400` (pixels/second)
- `SPIN_FACTOR = 0.3` (paddle influence on ball)
- `MAX_VERTICAL_VELOCITY = 300` (prevent pure vertical motion)

### Paddle Physics (paddle.gd)

**Movement:**
```gdscript
func _physics_process(delta):
    var input_direction = get_input_direction()
    velocity.y = input_direction * PADDLE_SPEED

    # Track velocity for spin mechanics
    var old_position = position.y
    position.y += velocity.y * delta
    position.y = clamp(position.y, MIN_Y, MAX_Y)

    # Actual velocity (for spin calculation)
    actual_velocity = (position.y - old_position) / delta
```

**Input Handling:**
- Keyboard: Arrow keys or W/S
- Mouse: Track mouse Y position, paddle follows
- Smoothing: Option to add lerp for smoother mouse tracking

**Constants:**
- `PADDLE_SPEED = 1000` (pixels/second)
- `PADDLE_WIDTH = 24`
- `BASE_HEIGHT = 104` (default paddle height)
- `MIN_Y = 60`, `MAX_Y = 660`

**Power-up Effects:**
- Expand: 180px height for 15 seconds
- Contract: 80px height for 10 seconds

### Brick Physics (brick.gd)

**Static bodies** - no movement
- Handle collision with ball via signals
- Track hit count (for multi-hit bricks)
- Emit particles on destruction
- Add to score via GameManager

## Signal Architecture

### Communication Pattern
Godot uses signals for decoupled communication between nodes.

**Key Signals:**

**Ball Signals (ball.gd):**
```gdscript
signal ball_lost  # Emitted when ball passes right edge
signal brick_hit(brick_node)  # Emitted on brick collision
```

**Brick Signals (brick.gd):**
```gdscript
signal brick_broken(score_value)  # Emitted when brick destroyed
```

**GameManager Signals:**
```gdscript
signal score_changed(new_score)
signal lives_changed(new_lives)
signal level_complete
signal game_over
signal state_changed(new_state)
```

**PowerUpManager Signals:**
```gdscript
signal effect_applied(type: PowerUpType)
signal effect_expired(type: PowerUpType)
```

**Signal Connections (in _ready()):**
```gdscript
# In main.tscn or game_manager.gd
ball.ball_lost.connect(_on_ball_lost)
ball.brick_hit.connect(_on_brick_hit)

# Bricks connect to GameManager
for brick in brick_container.get_children():
    brick.brick_broken.connect(_on_brick_broken)

# UI listens to GameManager
game_manager.score_changed.connect(hud.update_score)
game_manager.lives_changed.connect(hud.update_lives)
```

**Why Signals?**
- Decoupled: Ball doesn't need to know about GameManager
- Flexible: Easy to add new listeners
- Godot-idiomatic: Recommended pattern

## Data Management

### Game State (game_manager.gd)

```gdscript
extends Node

var score: int = 0
var lives: int = 3
var current_level: int = 1
var game_state: GameState = GameState.MAIN_MENU

enum GameState {
    MAIN_MENU,
    READY,
    PLAYING,
    PAUSED,
    LEVEL_COMPLETE,
    GAME_OVER
}

func add_score(points: int):
    score += points
    score_changed.emit(score)

func lose_life():
    lives -= 1
    lives_changed.emit(lives)
    if lives <= 0:
        game_over.emit()
```

### Level Data

**Option 1: JSON Files** (levels/*.json)
```json
{
  "level_id": 1,
  "name": "Beginner's Luck",
  "brick_layout": [
    [1, 1, 1, 1, 1],
    [2, 2, 2, 2, 2],
    [1, 1, 1, 1, 1]
  ],
  "brick_types": {
    "1": "normal",
    "2": "strong"
  }
}
```

**Option 2: Godot Resources** (levels/*.tres)
```gdscript
# level_data.gd
extends Resource
class_name LevelData

@export var level_id: int
@export var level_name: String
@export var brick_grid: Array[Array]  # 2D array of brick types
@export var background_color: Color
```

**Recommended: Start with JSON** (easier to edit), migrate to Resources later.

### Save Data (user://save_data.cfg)

```gdscript
# save_manager.gd (Autoload singleton)

var config = ConfigFile.new()
const SAVE_PATH = "user://save_data.cfg"

func save_high_score(score: int):
    var current_high = config.get_value("player", "high_score", 0)
    if score > current_high:
        config.set_value("player", "high_score", score)
        config.save(SAVE_PATH)

func load_high_score() -> int:
    var err = config.load(SAVE_PATH)
    if err != OK:
        return 0
    return config.get_value("player", "high_score", 0)
```

## Autoload Singletons

Godot's autoload system for global access:

**Project Settings → Autoload:**
- **PowerUpManager**: `res://scripts/power_up_manager.gd` - Manages timed power-up effects
- **SaveManager**: `res://scripts/save_manager.gd` (when implemented)
- **AudioManager**: `res://scripts/audio_manager.gd` (when implemented)

**Usage:**
```gdscript
# From any script:
PowerUpManager.apply_effect(PowerUpManager.PowerUpType.EXPAND, paddle)
var time_left = PowerUpManager.get_time_remaining(PowerUpManager.PowerUpType.EXPAND)
```

## Performance Considerations

### Object Pooling (Future Optimization)
For particles and power-ups, consider object pools:
- Pre-instantiate 20-30 particle effects
- Reuse instead of queue_free() + instantiate
- Only needed if performance issues arise

### Collision Optimization
- Use collision layers/masks to filter unnecessary checks
- Layer 1: Walls
- Layer 2: Paddle
- Layer 3: Bricks
- Ball checks all layers, but bricks only check ball

### Scene Instancing
- Bricks: Instance from template scene
- Power-ups: Instance when needed, queue_free when collected
- Levels: Load/unload scenes dynamically

## Rendering Architecture

### Camera Setup
- Use Camera2D for potential screen shake effects
- Anchor mode: Drag center
- Zoom: 1.0 (no zoom initially)
- Smoothing: Optional for camera shake

### Layering (Z-index)
- Background: CanvasLayer (layer -100)
- Bricks: z-index 0
- Ball: z-index 1
- Paddle: z-index 1
- Particles: z-index 2
- Power-ups: z-index 1
- UI: CanvasLayer (layer 0, always on top)

### Particle Effects

**Brick Break Effect:**
```
GPUParticles2D (one-shot: true)
├── Amount: 20-30 particles
├── Lifetime: 0.5 seconds
├── Emission Shape: Rectangle (brick size)
├── Velocity: Radial outward
└── Color: Match brick color
```

**Ball Trail (optional):**
```
CPUParticles2D (continuous)
├── Amount: 10
├── Lifetime: 0.2 seconds
├── Emission: Follow ball
└── Color: White/ball color
```

## Audio Architecture

### AudioStreamPlayer Nodes

**Music:**
```
AudioManager (Autoload)
└── MusicPlayer (AudioStreamPlayer)
    └── Stream: background_music.ogg
    └── Autoplay: true
    └── Volume: -10 dB
```

**Sound Effects:**
```
SFXPlayer (AudioStreamPlayer) [Multiple instances]
├── Paddle hit: paddle_hit.wav
├── Brick break: brick_break.wav
├── Wall bounce: wall_bounce.wav
└── Ball lost: ball_lost.wav
```

**Playing SFX:**
```gdscript
# In ball.gd on collision
func play_sound(sound_name: String):
    var sfx_player = AudioStreamPlayer.new()
    add_child(sfx_player)
    sfx_player.stream = load("res://assets/audio/sfx/" + sound_name + ".wav")
    sfx_player.play()
    sfx_player.finished.connect(sfx_player.queue_free)
```

**Volume Control:**
```gdscript
# AudioManager
func set_master_volume(volume: float):  # 0.0 to 1.0
    AudioServer.set_bus_volume_db(0, linear_to_db(volume))
```

## Testing Strategy

### Manual Testing Checklist
- [ ] Paddle moves smoothly with keyboard
- [ ] Paddle moves smoothly with mouse
- [ ] Ball launches from paddle on input
- [ ] Ball bounces correctly off walls
- [ ] Ball bounces off paddle with spin
- [ ] Bricks break on collision
- [ ] Score increases per brick
- [ ] Lives decrease when ball is lost
- [ ] Game over when lives = 0
- [ ] Level completes when all bricks broken

### Debug Tools (Built-in Godot)
- **Remote Inspector**: View live scene tree
- **Debugger**: Breakpoints, watch variables
- **Monitor**: FPS, physics time, memory
- **Collision Shapes**: Toggle visibility in editor

### Debug Mode Features (to implement)
```gdscript
# In game_manager.gd
const DEBUG_MODE = true

if DEBUG_MODE:
    # Infinite lives
    # Ball speed control
    # Level skip
    # Show collision shapes
```

## Future Architecture Enhancements

### Phase 2+
- **Power-up system**: Factory pattern for power-up creation
- **Level editor**: Visual grid editor for custom levels
- **Particle system**: Advanced effects with shaders
- **Replay system**: Record and playback ball trajectories
- **Achievements**: Track player milestones

### Scalability
- **Multiple balls**: Manage array of ball instances
- **Brick types**: Strategy pattern for different behaviors
- **Power-ups**: Observer pattern for temporary effects
- **Levels**: Scene management with loading screens

## File Reference

### Core Scene Files
- `scenes/main/main.tscn` - Root game scene
- `scenes/gameplay/paddle.tscn` - Paddle character
- `scenes/gameplay/ball.tscn` - Ball physics
- `scenes/gameplay/brick.tscn` - Reusable brick
- `scenes/ui/hud.tscn` - In-game UI overlay

### Core Script Files
- `scripts/game_manager.gd` - Game state management
- `scripts/power_up_manager.gd` - Timed power-up effects (Autoload)
- `scripts/paddle.gd` - Paddle movement logic
- `scripts/ball.gd` - Ball physics and collision
- `scripts/brick.gd` - Brick destruction logic
- `scripts/power_up.gd` - Power-up collectible
- `scripts/hud.gd` - UI update handlers
- `scripts/camera_shake.gd` - Camera shake effects
- `scripts/main.gd` - Main scene orchestration

### To Be Created
- `scripts/save_manager.gd` - Save/load system
- `scripts/audio_manager.gd` - Sound and music control
- `scripts/level_loader.gd` - Load levels from data files

---

*Last Updated: 2026-01-29*
*Architecture Version: 1.1 (Visual Polish + Power-ups)*
*See: tech-stack.md for technology decisions*
