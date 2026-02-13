# Advanced Tile Elements

## Status: ✅ COMPLETED

Special brick/zone mechanics beyond standard bricks. Adds depth to gameplay through physics-based interactions, enhanced spin control, and editor-placeable special tiles.

Last Updated: 2026-02-13 (Completed)

## Completion Summary
All features fully implemented and blocking issues resolved:

✅ **Enhanced Spin** - Persistent spin state with visual curve, decay, and trail effects
✅ **Penetrating Spin** - High-spin balls pass through breakable bricks
✅ **Force Arrow Tiles** - Non-collidable directional force fields with charge-up mechanic
✅ **Power-up Bricks** - Pass-through tiles granting immediate power-ups (all 16 types)
✅ **Schema Extension v2** - Backward-compatible pack format with new brick metadata
✅ **Editor Updates** - Full palette, pickers, and save/load support

**Blocking Issues Resolved (2026-02-13):**
- Force arrows now non-collidable with field-only repulsion (strength increased, charge-up added)
- Spin stabilized with angle limiting, boundary protection, and reduced curve strength

**Bonus Enhancements:**
- Pulsing visual effect for force arrows (breathing animation)
- Audio feedback with bzzrt.mp3 (volume scales with charge-up)
- Dwell time mechanic (force multiplier grows 1.0× to 2.5× over 0.8s)

---

## Features

### 1. Enhanced Spin (Persistent Spin & Dramatic Curve)

**Description**: Ball spin becomes a persistent, decaying state instead of a one-time velocity tweak. Fast paddle movement imparts spin that causes the ball to visibly arc through the air, rewarding skilled play.

**Current behavior** (`ball.gd`): `velocity.y += paddle_velocity * SPIN_FACTOR` (one-shot, `SPIN_FACTOR = 0.3`). Trail grows at `HIGH_SPIN_THRESHOLD = 250.0`. No persistent state.

**New behavior**:
- `spin_amount: float` tracks current spin (positive = one direction, negative = other)
- Imparted on paddle collision: `spin_amount = clampf(paddle_velocity * SPIN_IMPART_FACTOR, -SPIN_MAX, SPIN_MAX)`
- Per-frame curve: deflect velocity perpendicular to travel direction proportional to `spin_amount`
- Exponential decay: `spin_amount *= pow(SPIN_DECAY_RATE, delta)`
- Reduced on each brick hit: `spin_amount *= SPIN_ON_HIT_DECAY`
- Reset on ball reset/loss

**Visual indicators**:
- Trail size/color keyed to `abs(spin_amount)` (purple/pink trail at high spin)
- Ball sprite rotation speed scales with spin
- Optional subtle color tint at high spin values

**Constants**:
| Constant | Value | Purpose |
|----------|-------|---------|
| `SPIN_DECAY_RATE` | `0.85` | Exponential decay per second |
| `SPIN_CURVE_STRENGTH` | `600.0` | Curve influence (px/sec per spin unit) |
| `SPIN_IMPART_FACTOR` | `0.8` | How much paddle velocity becomes spin |
| `SPIN_ON_HIT_DECAY` | `0.5` | Spin multiplier on each brick hit |
| `SPIN_MAX` | `800.0` | Maximum spin magnitude |

**Implementation** (`scripts/ball.gd`):
```gdscript
# New state
var spin_amount: float = 0.0

# In _physics_process(), before move_and_collide():
func _apply_persistent_spin(delta: float) -> void:
    if absf(spin_amount) < 1.0:
        spin_amount = 0.0
        return
    var perp = Vector2(-velocity.normalized().y, velocity.normalized().x)
    velocity += perp * spin_amount * SPIN_CURVE_STRENGTH * delta
    spin_amount *= pow(SPIN_DECAY_RATE, delta)

# In handle_collision() paddle section:
spin_amount = clampf(paddle_velocity * SPIN_IMPART_FACTOR, -SPIN_MAX, SPIN_MAX)
```

Speed normalization (`velocity = velocity.normalized() * current_speed`) at end of `_physics_process()` maintains constant speed while allowing direction to bend - same pattern as magnet pull.

---

### 2. Penetrating Spin

**Description**: When spin exceeds a threshold, the ball passes through breakable bricks (breaking them) instead of bouncing. Always active - rewards skilled paddle work without needing a power-up.

**Threshold**: `PENETRATING_SPIN_THRESHOLD = 400.0`

**Rules**:
- Ball passes through and breaks any breakable brick when `abs(spin_amount) >= PENETRATING_SPIN_THRESHOLD`
- Does NOT penetrate: UNBREAKABLE, block bricks, FORCE_ARROW
- Spin reduces on each penetration via `SPIN_ON_HIT_DECAY` (spin eventually drops below threshold)
- Stacks with existing `brick_through` power-up (which has no spin cost)

**Implementation** (`scripts/ball.gd` `handle_collision()` brick section):
- Widen existing `frame_brick_through_active` condition at line ~342:
```gdscript
var has_penetrating_spin = abs(spin_amount) >= PENETRATING_SPIN_THRESHOLD
if not is_block_brick and not is_unbreakable and (frame_brick_through_active or has_penetrating_spin):
    # Existing pass-through + break logic
    if has_penetrating_spin:
        spin_amount *= SPIN_ON_HIT_DECAY  # Spin cost per penetration
```

---

### 3. Force Arrow Tiles

**Description**: Permanent, non-breakable force field tiles that apply a continuous directional push to the ball. Closer ball = stronger force. Direction matches the arrow's rotation. Placeable in editor with 4 rotation options.

**Behavior**:
- Continuous force: affects ball every physics frame while in range
- Proximity-based: force strength inversely proportional to distance
- Direction: force pushes in the arrow's visual rotation direction
- Non-breakable: ball bounces off normally on direct collision
- Non-scoring: does not award points, does not count toward level completion

**Asset**: `assets/graphics/powerups/arrow_down_right.png` (rotate for 4 directions)

**Constants**:
| Constant | Value | Purpose |
|----------|-------|---------|
| `FORCE_ARROW_RANGE` | `72.0` | Influence radius (1.5 brick widths) |
| `FORCE_ARROW_MAX_STRENGTH` | `900.0` | Acceleration at point-blank (px/sec^2) |
| `FORCE_ARROW_MIN_STRENGTH` | `120.0` | Acceleration at edge of range |

**Direction encoding** (stored as `direction` field in brick data):
| `direction` | Force Vector | Grid Display |
|-------------|-------------|--------------|
| `0` | Right | `R` |
| `45` | Down-Right | `DR` |
| `90` | Down | `D` |
| `135` | Down-Left | `DL` |
| `180` | Left | `L` |
| `225` | Up-Left | `UL` |
| `270` | Up | `U` |
| `315` | Up-Right | `UR` |

Force direction computed as: `Vector2.RIGHT.rotated(deg_to_rad(direction))`

**Implementation**:

`scripts/brick.gd`:
- Add `FORCE_ARROW` to `BrickType` enum (value 14)
- Add `@export var direction: int = 0`
- In `_ready()`: `hits_remaining = UNBREAKABLE_HITS`, `score_value = 0`
- In `setup_sprite()`: load arrow texture, rotate sprite by `direction` degrees
- Add pulsing alpha tween for visual feedback

`scripts/ball.gd`:
```gdscript
func _apply_force_arrows(delta: float) -> void:
    var arrows = main_controller_ref.get_cached_force_arrows()
    for arrow in arrows:
        if not is_instance_valid(arrow):
            continue
        var dist = position.distance_to(arrow.global_position)
        if dist > FORCE_ARROW_RANGE or dist < 0.001:
            continue
        var force_dir = Vector2.RIGHT.rotated(deg_to_rad(arrow.direction))
        var strength_factor = 1.0 - (dist / FORCE_ARROW_RANGE)
        var magnitude = lerpf(FORCE_ARROW_MIN_STRENGTH, FORCE_ARROW_MAX_STRENGTH, strength_factor)
        velocity += force_dir * magnitude * delta
```

`scripts/main.gd`:
- Add `cached_force_arrows: Array[Node] = []`
- Populate during `connect_brick_signals()` when `brick.brick_type == BrickType.FORCE_ARROW`
- Add `get_cached_force_arrows() -> Array[Node]` with stale-entry compaction (same pattern as `get_cached_level_bricks()`)

---

### 4. Power-up Bricks

**Description**: Pass-through tiles that grant a specific power-up when the ball contacts them. Like floating pickups in space - ball passes through without bouncing. Placeable in editor with power-up type selection from all 16 types.

**Behavior**:
- Ball passes through (no bounce, no collision response)
- Power-up effect applied immediately on contact (no floating pickup to catch)
- Brick disappears with particle effect after collection
- Does not count toward level completion (non-breakable for completion purposes)
- No score awarded

**Implementation**:

`scripts/brick.gd`:
- Add `POWERUP_BRICK` to `BrickType` enum (value 15)
- Add `@export var powerup_type_name: String = ""`
- Add `signal powerup_collected(powerup_type_int: int)`
- In `_ready()`: `hits_remaining = 1`, `score_value = 0`
- In `setup_sprite()`: load matching power-up icon from `POWERUP_TEXTURE_MAP`
- Add `collect_powerup()` method:
```gdscript
func collect_powerup():
    if is_breaking:
        return
    is_breaking = true
    var pu_type_int = _resolve_powerup_type(powerup_type_name)
    powerup_collected.emit(pu_type_int)
    break_brick(Vector2.ZERO)
```

`scripts/ball.gd` `handle_collision()`:
- Add check BEFORE standard brick bounce logic:
```gdscript
if "brick_type" in collider and collider.brick_type == BRICK_TYPE_POWERUP_BRICK:
    brick_hit.emit(collider)
    if collider.has_method("collect_powerup"):
        collider.collect_powerup()
    position += velocity * last_physics_delta
    return  # Pass through, no bounce
```

`scripts/main.gd` `connect_brick_signals()`:
- Connect `powerup_collected` signal to `_on_power_up_collected(type)` for POWERUP_BRICK bricks
- Reuses existing `_on_power_up_collected()` handler which routes through `MainPowerUpHandler.apply_collected_power_up()`

**Power-up texture mapping** (new const in `brick.gd`):
```gdscript
const POWERUP_TEXTURE_MAP: Dictionary = {
    "EXPAND": "res://assets/graphics/powerups/expand.png",
    "CONTRACT": "res://assets/graphics/powerups/contract.png",
    "SPEED_UP": "res://assets/graphics/powerups/speed_up.png",
    "SLOW_DOWN": "res://assets/graphics/powerups/slow_down.png",
    "TRIPLE_BALL": "res://assets/graphics/powerups/triple_ball.png",
    "BIG_BALL": "res://assets/graphics/powerups/big_ball.png",
    "SMALL_BALL": "res://assets/graphics/powerups/small_ball.png",
    "EXTRA_LIFE": "res://assets/graphics/powerups/extra_life.png",
    "GRAB": "res://assets/graphics/powerups/grab.png",
    "BRICK_THROUGH": "res://assets/graphics/powerups/brick_through.png",
    "DOUBLE_SCORE": "res://assets/graphics/powerups/double_score.png",
    "MYSTERY": "res://assets/graphics/powerups/mystery.png",
    "BOMB_BALL": "res://assets/graphics/powerups/bomb_ball.png",
    "AIR_BALL": "res://assets/graphics/powerups/air_ball.png",
    "MAGNET": "res://assets/graphics/powerups/magnet.png",
    "BLOCK": "res://assets/graphics/powerups/block.png",
}
```

---

## Schema Extension (zeppack_version 2)

### Backward Compatibility
- `SUPPORTED_PACK_VERSION` accepts both 1 and 2
- Version 1 packs load unchanged (no new fields required)
- Version 2 packs add optional per-brick fields

### Extended Brick Definition
```json
{"row": 0, "col": 0, "type": "NORMAL"}
{"row": 1, "col": 2, "type": "FORCE_ARROW", "direction": 90}
{"row": 2, "col": 3, "type": "POWERUP_BRICK", "powerup_type": "TRIPLE_BALL"}
```

| Field | Type | Required | Used By | Default |
|-------|------|----------|---------|---------|
| `row` | int | yes | all | - |
| `col` | int | yes | all | - |
| `type` | string | yes | all | - |
| `direction` | int | no | FORCE_ARROW | `45` |
| `powerup_type` | string | no | POWERUP_BRICK | `"EXPAND"` |

### PackLoader Changes (`scripts/pack_loader.gd`)
- Accept version 1 or 2 in `validate_pack()`
- Add to `BRICK_TYPE_MAP`: `"FORCE_ARROW": 14`, `"POWERUP_BRICK": 15`
- Add to `BRICK_BASE_SCORE_MAP`: both `0`
- Add to `BRICK_PREVIEW_COLOR_MAP`: `FORCE_ARROW` = yellow, `POWERUP_BRICK` = bright green
- Define `NON_BREAKABLE_TYPES: Array[String] = ["UNBREAKABLE", "FORCE_ARROW", "POWERUP_BRICK"]`
- Update `breakable_count` in `instantiate_level()` to exclude all `NON_BREAKABLE_TYPES`
- Pass `direction` and `powerup_type_name` to brick instances during instantiation
- Validate `direction` (must be one of 0/45/90/135/180/225/270/315) and `powerup_type` (must be known type) for v2 packs

---

## Editor Updates

### New Palette Entries (`scripts/ui/level_editor.gd`)
Add `"FORCE_ARROW"` and `"POWERUP_BRICK"` to `BRICK_TYPE_OPTIONS`.

### Direction Picker (Force Arrow)
- OptionButton with 8 options: Right, Down-Right, Down, Down-Left, Left, Up-Left, Up, Up-Right
- Visible only when `FORCE_ARROW` is selected in palette
- Value stored in brick data as `"direction": int`

### Power-up Type Picker (Power-up Brick)
- OptionButton listing all 16 power-up type names
- Visible only when `POWERUP_BRICK` is selected in palette
- Value stored in brick data as `"powerup_type": string`
- MYSTERY is the default selection

### Grid Cell Display
- Force Arrow: shows directional character (`>`, `v`, `<`, `^`)
- Power-up Brick: shows 2-char abbreviation of power-up type

### Brick Data Storage
Update `_set_brick_type_at()` to store extra fields:
```gdscript
var entry = {"row": row, "col": col, "type": brick_type}
if brick_type == "FORCE_ARROW":
    entry["direction"] = _get_selected_direction_degrees()
elif brick_type == "POWERUP_BRICK":
    entry["powerup_type"] = selected_powerup_type
```

### Pack Version on Save
`_build_pack_payload()` writes `zeppack_version: 2` when any brick uses FORCE_ARROW or POWERUP_BRICK.

### Undo/Redo
Snapshot-based system automatically captures custom fields - no changes needed.

---

## Files to Modify

| File | Changes |
|------|---------|
| `scripts/ball.gd` | Persistent spin state, per-frame curve, penetrating spin, force arrow physics, power-up brick pass-through |
| `scripts/brick.gd` | FORCE_ARROW + POWERUP_BRICK enum, direction/powerup_type_name properties, collect method, arrow visuals |
| `scripts/pack_loader.gd` | Schema v2, type/score/color maps, instantiation, non-breakable set, validation |
| `scripts/main.gd` | Force arrow cache, powerup_collected signal, breakable count for new non-breakable types |
| `scripts/ui/level_editor.gd` | Palette, direction/PU pickers, brick data storage, grid cell display |
| `scenes/ui/level_editor.tscn` | New OptionButton nodes (DirectionSelect, PowerupTypeSelect) |

## Existing Code to Reuse

- `frame_brick_through_active` pass-through logic (`ball.gd:342`) - extend condition for penetrating spin
- `_apply_magnet_pull()` pattern (`ball.gd`) - same proximity-based force pattern for force arrows
- `cached_level_bricks` / `get_cached_level_bricks()` (`main.gd:81,276`) - same cache pattern for force arrows
- `_on_power_up_collected(type)` (`main.gd:539`) - reuse for power-up brick collection
- Power-up textures in `assets/graphics/powerups/` - reuse for POWERUP_BRICK sprites

---

## Implementation Priority

| Phase | Feature | Dependencies | Complexity |
|-------|---------|--------------|------------|
| 1 | Enhanced Spin | None | Medium |
| 2 | Penetrating Spin | Phase 1 | Low |
| 3 | Schema Extension | None | Medium |
| 4 | Brick Types (FORCE_ARROW, POWERUP_BRICK) | Phase 3 | Medium |
| 5 | Force Arrow Physics | Phase 4 | Medium |
| 6 | Power-up Brick Collection | Phase 4 | Low |
| 7 | Editor Updates | Phase 3-4 | Medium |
| 8 | Documentation | All | Low |

Phases 1-2 (spin) and Phases 3-7 (new tiles) are independent tracks that can be developed in parallel.

---

## Verification Checklist

- [ ] **Spin**: Fast paddle swipe produces visible ball arc. Trail changes at high spin. Spin decays over time.
- [ ] **Penetrating Spin**: High-spin ball passes through breakable bricks (breaking them). Does NOT penetrate UNBREAKABLE, block, or FORCE_ARROW.
- [ ] **Force Arrow (editor)**: Place with rotation, save pack, reload. Direction and type preserved.
- [ ] **Force Arrow (gameplay)**: Ball curves in arrow's direction when near. Stronger effect when closer. Bounces on direct hit.
- [ ] **Power-up Brick (editor)**: Place with type, save pack, reload. Type preserved.
- [ ] **Power-up Brick (gameplay)**: Ball passes through, power-up granted immediately. Brick disappears. Does not count for level completion.
- [ ] **Backward compat**: All 3 built-in packs (v1) load without errors.
- [ ] **Editor undo/redo**: Direction and power-up type survive undo/redo.
- [ ] **Edge case**: Level with only FORCE_ARROW and POWERUP_BRICK tiles completes immediately (no breakable bricks).

---

## Notes
- Force arrow asset (`arrow_down_right.png`) already exists in unused assets
- All 16 power-up textures already exist in `assets/graphics/powerups/`
- Spin constants will likely need gameplay tuning after initial implementation
- Force arrow range (72px = 1.5 brick widths) balances visibility with precision

## Implementation Summary (2026-02-12)
- Implemented persistent spin state, spin decay/curve, high-spin trail color/size, and spin-scaled ball rotation in `scripts/ball.gd`.
- Implemented penetrating spin pass-through and integrated with existing brick-through behavior.
- Added `FORCE_ARROW` and `POWERUP_BRICK` to `scripts/brick.gd` with editor-configurable metadata (`direction`, `powerup_type_name`) plus collection/pulse behavior.
- Added force-arrow runtime caching and completion-brick filtering in `scripts/main.gd` so non-completion tiles do not affect level clear counts.
- Extended pack schema support in `scripts/pack_loader.gd` to accept `zeppack_version` 1 or 2, validate v2 brick metadata, and instantiate extra brick fields.
- Extended level editor palette and controls (`scripts/ui/level_editor.gd`, `scenes/ui/level_editor.tscn`) with direction and power-up selectors and v2 save promotion.

## Verification Notes (2026-02-12)
- Runtime launch via `godot --headless --path . --check-only` failed in this environment due a Godot log file crash (`user://logs/...`, signal 11), so in-engine manual verification remains pending.

## Follow-Up Fixes (2026-02-12)
- Force Arrow influence now uses global-space distance checks (`global_position.distance_to(...)`) to avoid missed range detection from mixed coordinate spaces.
- Added a small directional collision boost when directly bouncing off a Force Arrow tile so push feedback is visible on contact.
- Added `force_arrow` group fallback query path for ball runtime in case cached arrow list is empty/stale.
- Fixed `ball.gd` brick-collision indentation regression so non-unbreakable bricks still receive `brick_hit`/`hit(...)` callbacks in normal bounce paths.
- Reworked persistent spin curve to use normalized spin ratio (`spin_amount / SPIN_MAX`) instead of raw spin magnitude to prevent immediate erratic trajectory flips/losses.
- Increased Force Arrow field strength/range and added directional collision blending to make arrow push visibly steer the ball.
