# Core Mechanics Implementation - Phase 1

## Status: ✅ COMPLETE

Implementation of the fundamental gameplay mechanics for Zep Ball.

## Objectives

Create a playable prototype with:
- Paddle movement and control
- Ball physics with collision detection
- Brick breaking system
- Score tracking and lives
- Basic game state management

## Implementation Summary

### 1. Paddle System ✅

**Files:**
- `scenes/gameplay/paddle.tscn`
- `scripts/paddle.gd`

**Features Implemented:**
- CharacterBody2D-based paddle on right side (x=1200)
- Dual control scheme:
  - Keyboard: W/S and Up/Down arrow keys
  - Mouse: Direct Y-following with a deadzone
- Boundary clamping derived from wall offsets and current paddle height
- Velocity tracking for spin mechanics
- Movement speed: 1000 px/s (keyboard); mouse uses direct positioning

**Key Code Patterns:**
```gdscript
# Velocity calculation for spin
actual_velocity_y = (position.y - previous_y) / delta

# Boundary clamping (dynamic based on paddle height)
position.y = clamp(position.y, min_y, max_y)
```

### 2. Ball System ✅

**Files:**
- `scenes/gameplay/ball.tscn`
- `scripts/ball.gd`

**Features Implemented:**
- CharacterBody2D with circle collision (radius 16px)
- Constant speed physics (base 500 px/s)
- Launch from paddle on Space/Click
- Collision detection with:
  - Walls: Simple reflection
  - Paddle: Reflection + spin mechanics
  - Bricks: Reflection + destruction signal
- Ball lost detection (x > 1300), with safety handling for left/top/bottom escapes
- Auto-reset to paddle after life lost

**Physics Approach:**
- Arcade-style constant speed (normalized velocity each frame)
- Paddle spin: `velocity.y += paddle_velocity * SPIN_FACTOR`
- Reflection: `velocity = velocity.bounce(collision_normal)`
- Prevents pure vertical motion (MAX_VERTICAL_ANGLE = 0.8)

**Spin Mechanics:**
```gdscript
# On paddle collision
velocity = velocity.bounce(normal)
var paddle_velocity = paddle_reference.get_velocity_for_spin()
velocity.y += paddle_velocity * SPIN_FACTOR  # SPIN_FACTOR = 0.3
```

### 3. Brick System ✅

**Files:**
- `scenes/gameplay/brick.tscn`
- `scripts/brick.gd`

**Features Implemented:**
- StaticBody2D with rectangle collision (48x48)
- Multiple brick types:
  - Normal: 1 hit, 10 points
  - Strong: 2 hits, 20 points
  - Unbreakable: Never breaks
  - Gold/Red/Blue/Green/Purple/Orange variants (1-2 hits, 15-50 points)
- CPUParticles2D destruction effect
- Sprite-based visuals (square textures scaled to 48x48)
- Signal-based score integration

**Brick Hit Logic:**
```gdscript
func hit():
    hits_remaining -= 1
    if hits_remaining <= 0:
        break_brick()  # Emit particles, signal score, queue_free()
    else:
        # Darken color for damaged state
        $Sprite.modulate = brick_color.darkened(0.3)
```

### 4. Game Manager ✅

**Files:**
- `scripts/game_manager.gd`

**Features Implemented:**
- State machine with 6 states:
  - MAIN_MENU (future)
  - READY (ball on paddle)
  - PLAYING (ball in motion)
  - PAUSED
  - LEVEL_COMPLETE
  - GAME_OVER
- Score tracking
- Lives tracking (starts at 3)
- Signals for UI updates:
  - `score_changed(new_score)`
  - `lives_changed(new_lives)`
  - `level_complete()`
  - `game_over()`

**State Transitions:**
```
READY → (launch) → PLAYING
PLAYING → (ball lost, lives > 0) → READY
PLAYING → (ball lost, lives = 0) → GAME_OVER
PLAYING → (all bricks broken) → LEVEL_COMPLETE
```

### 5. HUD System ✅

**Files:**
- `scripts/hud.gd`
- Integrated in `scenes/main/main.tscn`

**Features Implemented:**
- Top bar with three sections:
  - Left: Score display
  - Center: "ZEP BALL" logo
  - Right: Lives display
- Signal-based updates (reactive to GameManager)
- Canvas layer (always on top of gameplay)
- Mouse-transparent (doesn't block input)

### 6. Main Scene Integration ✅

**Files:**
- `scenes/main/main.tscn`
- `scripts/main.gd`

**Features Implemented:**
- Random background selection (7 images), rendered in a CanvasLayer
- Three walls (top, bottom, left) with collision
- Paddle instance (right side)
- Ball instance
- BrickContainer for level layout
- HUD overlay
- Signal orchestration:
  - Ball → GameManager
  - Bricks → Main → GameManager
  - GameManager → HUD

**Level Generation (Fallback):**
```gdscript
func create_test_level():
    # 5 rows x 8 columns = 40 bricks
    # Row 0: Strong bricks
    # Rows 1-4: Normal bricks
    # Grid starts at (150, 150) with 48px bricks and 3px spacing
```
**Note**: This test grid is only used if `LevelLoader` fails to load JSON levels.

## Technical Decisions

### Why CharacterBody2D for Ball?
- Need precise control over velocity
- `move_and_collide()` returns collision data for reflection
- Avoid physics simulation quirks of RigidBody2D
- Arcade-style constant speed easier to implement

### Why StaticBody2D for Bricks?
- Bricks don't move
- Simple collision detection
- Less overhead than RigidBody2D
- Perfect for static obstacles

### Why Signals for Communication?
- Decoupled architecture (ball doesn't know about GameManager)
- Easy to extend (add new listeners)
- Godot-idiomatic pattern
- Prevents circular dependencies

### Why Groups for Node References?
```gdscript
# Instead of get_parent().get_parent().find_child()
paddle_reference = get_tree().get_first_node_in_group("paddle")
```
- More robust than node paths
- Survives scene restructuring
- Clear semantic meaning
- Recommended Godot pattern

## Challenges Encountered

### 1. Ball-to-ball collisions causing jitter
**Problem**: Multi-ball overlaps could cause collision jitter
**Solution**: Test-only collision check and ignore ball-to-ball collisions

### 2. Pure Vertical Ball Motion
**Problem**: Ball could get stuck bouncing purely vertically
**Solution**: Added MAX_VERTICAL_ANGLE constraint to force horizontal component

### 3. Brick Signal Connections
**Problem**: Bricks instantiated at runtime weren't connected
**Solution**: `connect_brick_signals()` in main.gd after level generation

### 4. Out-of-bounds safety
**Problem**: Extra balls could escape through non-right boundaries
**Solution**: Mark escape as error and remove extra balls immediately

## Testing Results

### Manual Playtest Checklist ✅
- [x] Paddle moves smoothly with keyboard
- [x] Paddle follows mouse accurately
- [x] Paddle respects screen boundaries
- [x] Ball launches from paddle on input
- [x] Ball bounces correctly off all walls
- [x] Ball bounces off paddle
- [x] Paddle spin visibly affects trajectory
- [x] Ball breaks normal bricks in 1 hit
- [x] Ball breaks strong bricks in 2 hits
- [x] Particles appear on brick destruction
- [x] Score increases correctly (10 or 20 points)
- [x] Lives decrease when ball is lost
- [x] Ball resets to paddle after life lost
- [x] Game over triggers at 0 lives
- [x] Level completes when all bricks broken

### Edge Cases to Monitor
- Ball stuck in vertical bounce (mitigated, not eliminated)
- Ball hitting brick corners (needs more testing)
- Multi-ball spawns near edges (spawn logic guards against this)
- Very fast ball speeds (currently capped at 650 px/s during power-up)

## Next Phase Pointers

- UI and game flow (menus, game over, level complete).
- Level system and external level data.
- Audio system.

## Success Criteria: ACHIEVED ✅

- [x] Core gameplay loop is complete
- [x] Ball physics feel responsive
- [x] Paddle spin creates interesting gameplay
- [x] Bricks break satisfyingly (particles help!)
- [x] Score and lives system works
- [x] Game has beginning, middle, end (launch, play, game over)
- [x] Code is clean and documented
- [x] Project is ready to open in Godot 4.6

**Phase 1 Status: COMPLETE**
**Ready to playtest!** 🎮

---

*Completed: 2026-01-27*  
*Godot Version: 4.6*
