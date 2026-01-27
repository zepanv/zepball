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
├── Background (ColorRect or Sprite2D)
│   └── Solid color or tiled texture
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
└── UI (CanvasLayer) [Instance of hud.tscn]
    └── Always rendered on top
```

### Paddle Scene (paddle.tscn)

```
Paddle (CharacterBody2D) [Script: paddle.gd]
├── Sprite (Sprite2D or ColorRect)
│   └── Visual representation (placeholder: colored rectangle)
│
├── CollisionShape (CollisionShape2D)
│   └── Shape: RectangleShape2D
│
└── PaddleTrail (Line2D) [Optional visual effect]
```

**Key Properties:**
- Position: Fixed X (~1200), variable Y (40 to 680)
- Size: ~20px wide, ~120px tall
- Movement: Vertical only (keyboard + mouse)
- Velocity tracking: For spin mechanics

### Ball Scene (ball.tscn)

```
Ball (CharacterBody2D) [Script: ball.gd]
├── Sprite (Sprite2D or ColorRect)
│   └── Visual: Circle (placeholder: colored square)
│
├── CollisionShape (CollisionShape2D)
│   └── Shape: CircleShape2D (radius ~8px)
│
└── Trail (CPUParticles2D or Line2D) [Optional effect]
```

**Key Properties:**
- Initial position: Attached to paddle
- Velocity: Constant magnitude (~400 px/s)
- Physics: Reflection on collision + spin from paddle

### Brick Scene (brick.tscn)

```
Brick (StaticBody2D) [Script: brick.gd]
├── Sprite (Sprite2D or ColorRect)
│   └── Visual: Rectangle with color based on type
│
├── CollisionShape (CollisionShape2D)
│   └── Shape: RectangleShape2D
│
└── BreakParticles (GPUParticles2D)
    └── Emitted on brick destruction
```

**Key Properties:**
- Types: Normal, Strong (2 hits), Unbreakable
- Size: ~60px wide, ~30px tall
- Grid layout: 5x8 typical starting configuration
- Score value: Based on type

### HUD Scene (hud.tscn)

```
HUD (CanvasLayer) [Script: hud.gd]
└── Container (Control)
    ├── TopBar (HBoxContainer)
    │   ├── ScoreLabel (Label)
    │   │   └── Position: Top-left
    │   │
    │   ├── LogoPlaceholder (Label or TextureRect)
    │   │   └── Position: Top-center
    │   │
    │   └── LivesLabel (Label)
    │       └── Position: Top-right
    │
    └── GameOverScreen (Panel) [Initially hidden]
        └── Shows: Final score, retry/quit options
```

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
       └──→ Pause → PAUSED
```

**Implemented in:** `game_manager.gd`

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
- `PADDLE_SPEED = 500` (pixels/second)
- `PADDLE_WIDTH = 20`
- `PADDLE_HEIGHT = 120`
- `MIN_Y = 40`, `MAX_Y = 680`

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
- **GameManager**: `res://scripts/game_manager.gd`
- **SaveManager**: `res://scripts/save_manager.gd` (when implemented)
- **AudioManager**: `res://scripts/audio_manager.gd` (when implemented)

**Usage:**
```gdscript
# From any script:
GameManager.add_score(10)
SaveManager.save_high_score(GameManager.score)
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
- Background: z-index -1
- Bricks: z-index 0
- Ball: z-index 1
- Paddle: z-index 1
- Particles: z-index 2
- UI: CanvasLayer (always on top)

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
- `scripts/game_manager.gd` - Global game state (Autoload)
- `scripts/paddle.gd` - Paddle movement logic
- `scripts/ball.gd` - Ball physics and collision
- `scripts/brick.gd` - Brick destruction logic
- `scripts/hud.gd` - UI update handlers

### To Be Created
- `scripts/save_manager.gd` - Save/load system
- `scripts/audio_manager.gd` - Sound and music control
- `scripts/level_loader.gd` - Load levels from data files
- `scripts/power_up.gd` - Power-up base class

---

*Last Updated: 2026-01-27*
*Architecture Version: 1.0 (Initial Design)*
*See: tech-stack.md for technology decisions*
