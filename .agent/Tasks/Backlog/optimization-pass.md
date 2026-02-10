# Optimization Pass & Best Practices

## Status: BACKLOG

Full audit of the codebase for performance issues, code quality, Godot best practices, and architectural debt. Issues are organized by priority tier with concrete file:line references.

---

## Tier 1: Performance (Immediate Impact)

### 1.1 Remove Debug Print Statements

60+ `print()` calls left in production code paths, many in `_process()`/`_physics_process()` hot loops with string concatenation overhead.

**Files with print statements:**

| File | Key Lines | Notes |
|------|-----------|-------|
| `scripts/ball.gd` | 78, 90-92, 162, 188, 194, 200, 204-232, 288, 293, 311, 332-337, 354-355, 385, 432, 465, 629, 638, 806, 810 | Heaviest offender; string building in physics path |
| `scripts/paddle.gd` | 39, 46 | Print with string concat in `_ready()` and physics |
| `scripts/brick.gd` | 162, 275, 293, 401 | On brick hit/break (frequent) |
| `scripts/power_up.gd` | 58, 158 | On spawn and collection |
| `scripts/game_manager.gd` | 68-70, 95, 155-167, 180, 188-189, 199, 204, 212, 233 | Score/state changes (frequent) |
| `scripts/power_up_manager.gd` | 74, 77, 84, 190 | Effect apply/remove |
| `scripts/main.gd` | 56, 68, 179-182, 216, 233, 237, 257, 271-298, 334 | Level load, brick events |
| `scripts/audio_manager.gd` | 46, 227-228, 258, 319 | Track changes |
| `scripts/level_loader.gd` | 31, 42, 91, 159 | Level loading |
| `scripts/set_loader.gd` | 14, 47 | Set loading |

**Recommendation:** Remove all `print()` calls, or gate behind a debug flag:
```gdscript
const DEBUG_LOG := false
func _log(msg: String) -> void:
    if DEBUG_LOG:
        print(msg)
```

### 1.2 Cache Node References (Stop Per-Frame Tree Lookups)

Several scripts call `get_tree().get_first_node_in_group()` every frame instead of caching in `_ready()`.

| File:Line | Call | Frequency |
|-----------|------|-----------|
| `scripts/power_up.gd:62` | `get_first_node_in_group("game_manager")` | Every `_physics_process()` frame |
| `scripts/hud.gd:363` | `get_first_node_in_group("game_manager")` | Every `_process()` frame |
| `scripts/hud.gd:777` | `get_first_node_in_group("ball")` | Every debug overlay update |
| `scripts/power_up_manager.gd:137-139, 147-148, 199-201, 237-240` | `get_first_node_in_group()` for paddle/ball | Per effect apply/remove |

**Fix:** Cache in `_ready()` or `@onready`, invalidate only on scene change.

### 1.3 Cache Group Queries (Avoid O(n) Tree Search on Collision)

`get_nodes_in_group()` called during collision events, iterating the full scene tree.

| File:Line | Group | Context |
|-----------|-------|---------|
| `scripts/ball.gd:783` | `"brick"` | `destroy_surrounding_bricks()` - on every bomb/explosion |
| `scripts/brick.gd:376` | `"brick"` | `explode_surrounding_bricks()` - on every bomb brick break |
| `scripts/power_up_manager.gd:94-118` | `"ball"` | Called 5 times per effect (GRAB, BRICK_THROUGH, BOMB_BALL, AIR_BALL, MAGNET) |
| `scripts/main.gd:266, 591` | `"ball"` | `_on_ball_lost()` and `try_spawn_additional_balls()` |
| `scripts/hud.gd:754, 777` | `"ball"` | Debug overlay (every frame when visible) |

**Fix:** Maintain a cached brick list in main.gd (invalidate on brick add/remove). Maintain a cached ball list (invalidate on spawn/destroy). Pass the lists to methods that need them.

### 1.4 Reduce Per-Frame Allocations

| File:Line | Issue |
|-----------|-------|
| `scripts/hud.gd:354` | `find_child()` every frame to locate timer label (O(n) tree search) |
| `scripts/hud.gd:348-356` | Iterates `powerup_container.get_children()` every frame |
| `scripts/hud.gd:770` | `"%.0f"` string formatting every frame in velocity display |
| `scripts/ball.gd:176-207` | String building for debug messages every frame when out of bounds |
| `scripts/ball.gd:156-157` | Vector2 creation for magnet pull every frame |
| `scripts/paddle.gd:88-89` | Vector2 clamp operation every frame for mouse control |

**Fix:** Cache child references, pre-allocate frequently used objects, only format strings when values change.

---

## Tier 2: Code Quality (High Priority)

### 2.1 Extract Magic Numbers to Constants

**ball.gd:**
- Line 8: `BASE_current_speed = 500.0` - inconsistent naming (should be `BASE_SPEED`)
- Lines 179, 184, 190, 196: Boundary values `1300`, `0`, `0`, `720` - some defined as constants, some not
- Lines 327-328: Escape zone thresholds `40.0`, `660.0` - hardcoded
- Lines 470, 482: Speed values `650.0`, `350.0` - unnamed
- Lines 509-512: Speed comparisons against `FAST_SPEED_MULTIPLIER` - mixed constant/literal

**brick.gd:**
- Line 101: `999` for unbreakable hit count - should be `UNBREAKABLE_HITS` constant
- Line 349: `0.20` power-up spawn chance - should be constant or export

**main.gd:**
- Line 241: `2.0`, `50.0`, `3.0`, `12.0` in shake intensity formula - all unnamed
- Line 246: `3`, `2`, `0.15` in combo multiplier calculation - unnamed
- Lines 679-701: Zones `100`, `150`, `570` for triple ball spawn - unnamed

**paddle.gd:**
- Line 103: `0.3` lerp speed - unnamed
- Line 178: `0.2` tween duration - unnamed

**power_up_manager.gd:**
- Lines 31-47: Duration values mixed with `0.0` for permanent effects - no clear distinction

### 2.2 Add Type Annotations

Missing or inconsistent type annotations on variables that should be typed:

| File:Line | Variable | Should Be |
|-----------|----------|-----------|
| `scripts/ball.gd:40` | `paddle_reference = null` | `var paddle_reference: Node2D = null` |
| `scripts/ball.gd:41` | `game_manager = null` | `var game_manager: Node = null` |
| `scripts/paddle.gd:28` | `game_manager = null` | `var game_manager: Node = null` |
| `scripts/power_up_manager.gd:27` | `active_effects: Dictionary = {}` | Document expected structure |
| `scripts/hud.gd:11-26` | Multiple UI references | Should be typed as `Label`, `Control`, etc. |
| `scripts/game_manager.gd:36-42` | `score_breakdown: Dictionary` | Could use class or typed dict |

### 2.3 Consolidate Duplicate Code

**PowerUpManager reset pattern (power_up_manager.gd:143-184):**
The same pattern repeats 5 times:
```gdscript
var balls = get_tree().get_nodes_in_group("ball")
for ball in balls:
    if ball.has_method("reset_XXX"):
        ball.reset_XXX()
```
Lines 154-157, 160-163, 170-172, 176-178, 182-184.

**Fix:** Create a helper:
```gdscript
func _reset_ball_effect(method_name: String) -> void:
    for ball in get_tree().get_nodes_in_group("ball"):
        if ball.has_method(method_name):
            ball.call(method_name)
```

**Power-up state duplication:**
Ball tracks its own flags (`grab_enabled`, `brick_through_enabled`, `bomb_ball_enabled`, `air_ball_enabled`, `magnet_enabled`) in ball.gd:626-684, while PowerUpManager independently tracks the same state in `active_effects` dictionary. If either system fails, they desync.

**Fix:** Single source of truth - either Ball queries PowerUpManager, or PowerUpManager is the only thing that sets Ball flags.

### 2.4 Standardize Signal Patterns

Current inconsistency:
- ball.gd:74-75 - emits custom signals (`ball_lost`, `brick_hit`)
- ball.gd:305-307 - calls `game_manager.start_playing()` directly
- power_up.gd:56 - uses `body_entered.connect()`
- Some systems use groups, others use direct references

**Fix:** Document a convention and apply consistently. Suggested pattern:
- Gameplay events (ball lost, brick broken, score change) -> signals
- System commands (start game, pause) -> direct method calls
- Cross-system queries (get ball count) -> group queries (cached)

---

## Tier 3: Architecture (Medium Priority)

### 3.1 Split Oversized Files

| File | Lines | Proposed Split |
|------|-------|---------------|
| `scripts/ball.gd` | 972 | Extract: AimIndicator, AirBallLogic, StuckDetection into separate scripts or helper classes |
| `scripts/save_manager.gd` | 865 | Extract: SettingsManager, AchievementsManager, StatisticsManager. Keep SaveDataManager for persistence core. |
| `scripts/hud.gd` | 843 | Extract: PauseMenu, DebugOverlay, LevelIntro, ComboDisplay, PowerUpTimers into child scene scripts |
| `scripts/main.gd` | 749 | Extract: BackgroundManager, PowerUpHandler. Keep Main as orchestrator. |
| `scripts/audio_manager.gd` | 609 | Extract: ToastUI (lines 568-597) into separate node |

### 3.2 Unify Power-Up State

Remove state duplication between Ball per-instance flags and PowerUpManager.active_effects dictionary.

- Ball currently has: `grab_enabled`, `brick_through_enabled`, `bomb_ball_enabled`, `air_ball_enabled`, `magnet_enabled`
- PowerUpManager has: `active_effects` dict with timers

**Approach:** Ball queries `PowerUpManager.is_effect_active(effect_type)` instead of maintaining its own flags. PowerUpManager remains the single source of truth.

### 3.3 Extract Toast UI from AudioManager

`audio_manager.gd:568-597` (`_init_toast_ui()`) creates a CanvasLayer with Label for track change notifications. This UI concern is mixed into the audio system.

**Fix:** Move to a standalone ToastNotification node/autoload, or integrate into HUD.

### 3.4 Disable Processing When Idle

| File | Issue |
|------|-------|
| `scripts/power_up.gd` | `_physics_process()` runs every frame even after power-up stops moving |
| `scripts/paddle.gd` | Processes input during pause (should check pause state or `set_physics_process(false)`) |
| `scripts/hud.gd` | `_process()` always enabled, even when not in gameplay |
| `scripts/ball.gd:103` | `set_process_unhandled_input(true)` for every ball, but only main ball needs aim input |

**Fix:** Use `set_physics_process(false)` / `set_process(false)` when the node is idle. Re-enable on relevant state changes.

---

## Tier 4: Minor Cleanup (Low Priority)

### 4.1 Variable Naming

- `ball.gd:8`: `BASE_current_speed` mixes constant and variable naming conventions. Should be `BASE_SPEED` (constant) or `base_speed` (variable).

### 4.2 Error Handling Gaps

| File:Line | Issue |
|-----------|-------|
| `scripts/ball.gd:345` | Checks `paddle_offset.x > 0` but doesn't validate `paddle_reference` exists |
| `scripts/paddle.gd:154` | Modifies collision shape without null check |
| `scripts/audio_manager.gd:209-221` | Loads SFX files but doesn't validate successful load |
| `scripts/level_loader.gd:63-92` | Returns empty dict on corrupted file with no error propagation |
| `scripts/save_manager.gd:177-182` | File access errors only printed to console |

### 4.3 Shared Materials

`power_up.gd:128-147` creates a new `CanvasItemMaterial` per power-up instance for the glow effect. Since power-ups share the same material settings, a single shared static material would reduce allocations.

### 4.4 Physics Query Optimization

`ball.gd:736-776` (`_resolve_air_ball_landing()`) creates `PhysicsShapeQueryParameters2D` and runs `intersect_shape()` up to 16 times per air ball landing to find a safe position. Results are not reused between iterations.

**Fix:** Run a single broader query and filter results, or cache the query parameters object.

---

## Implementation Notes

- **Tier 1 can be done independently** - performance fixes have no architectural dependencies
- **Tier 2 items are safe refactors** - constants, types, and deduplication don't change behavior
- **Tier 3 requires careful planning** - file splits need updated scene references and signal wiring
- **Tier 4 is opportunistic** - fix when touching nearby code

---

Last Updated: 2026-02-10
