# Optimization Pass & Best Practices

## Status: COMPLETED

## Progress Update (2026-02-11)

Initial Tier 1 optimization pass has started and landed in core gameplay scripts.

### Completed in this pass

- Removed runtime `print()` logging from hot gameplay paths:
  - `scripts/ball.gd`
  - `scripts/main.gd`
  - `scripts/brick.gd`
  - `scripts/game_manager.gd`
  - `scripts/paddle.gd`
  - `scripts/power_up.gd`
  - `scripts/power_up_manager.gd`
  - `scripts/hud.gd`
  - `scripts/level_loader.gd`
  - `scripts/set_loader.gd`
- Removed remaining runtime `print()` logging from non-hot-path systems:
  - `scripts/difficulty_manager.gd`
  - `scripts/save_manager.gd`
  - `scripts/ui/settings.gd`
  - `scripts/ui/game_over.gd`
  - `scripts/ui/set_complete.gd`
  - `scripts/ui/menu_controller.gd`
  - `scripts/ui/main_menu.gd`
  - `scripts/ui/level_complete.gd`
- Replaced critical error/warning logs with `push_error()` / `push_warning()` where needed.
- Reduced per-instance allocation in power-up visuals:
  - `power_up.gd`: shared static glow `CanvasItemMaterial` for all power-up instances.
- Reduced per-frame debug overlay string formatting and label churn:
  - `hud.gd`: debug labels now update only when FPS/ball-count/velocity/speed/combo values change.
- Reduced power-up timer UI update frequency:
  - `hud.gd`: timer labels are refreshed on a short interval (`0.1s`) instead of every frame.
- Reduced idle processing overhead:
  - `power_up_manager.gd`: `_process` now disables automatically when no active effects exist.
  - `ball.gd`: unhandled input processing now runs only on the main ball (`set_is_main_ball` helper used by `main.gd`).
- Reduced per-frame scene-tree lookups:
  - `power_up.gd`: caches `game_manager` instead of querying group each physics tick.
  - `hud.gd`: caches `game_manager`, pause/intro/debug label references, and timer label references.
  - `hud.gd`: throttles debug ball group query updates (`0.1s`) instead of every frame.
- Reduced full-tree group scans in collision-heavy paths:
  - `brick.gd`: bomb explosion now iterates parent container children instead of `get_nodes_in_group("brick")`.
  - `ball.gd`: bomb-ball explosion prefers local `BrickContainer` children, with group-query fallback.
  - `main.gd`: active ball queries now use local `PlayArea` children helper instead of global ball group scans.
- Added shared active-ball registry to reduce cross-system group scans:
  - `power_up_manager.gd`: tracks live balls via `register_ball`/`unregister_ball` and serves `get_active_balls()`.
  - `ball.gd`: balls now self-register on `_ready()` and unregister on `_exit_tree()`.
  - `hud.gd` and `ui/settings.gd`: debug/trail updates now consume `PowerUpManager.get_active_balls()` instead of global `"ball"` group scans.
- Consolidated repetitive ball effect loops in `power_up_manager.gd` with `_for_each_ball()` helper and added cached fallback paddle/ball references.
- Addressed a Tier 2 cleanup item:
  - `ball.gd`: renamed `BASE_current_speed` to `BASE_SPEED` and extracted key boundary/speed literals into named constants.
- Addressed additional Tier 2 cleanup in gameplay orchestration/control scripts:
  - `main.gd`: extracted shake and triple-ball safety/timing literals into named constants.
  - `main.gd`: deduplicated repeated brick-hit shake math into `_apply_brick_hit_shake()`.
  - `paddle.gd`: extracted paddle resize heights and mouse/tween tuning literals into named constants.
- Clarified power-up timer semantics in `power_up_manager.gd`:
  - `EFFECT_DURATIONS` now includes timed effects only (no `0.0` placeholders for instant/non-timed effects).
  - `active_effects` tracks only timed effects, reducing ambiguous state entries.
- Hardened debug overlay against multiball cleanup races:
  - `hud.gd`: `update_debug_overlay()` now filters invalid/freed ball references before property access.
  - `hud.gd`: FPS display now explicitly rounds/casts to `int` to avoid narrowing-conversion warnings.
- Magnet behavior correction in `ball.gd`:
  - Magnet pull now applies only while ball X-velocity is moving toward the paddle, preventing immediate post-hit pullback.
- Optimized air-ball landing query path in `ball.gd`:
  - Level landing metrics (center/step) now compute in one level-data load instead of separate loads.
  - Reused `CircleShape2D` and `PhysicsShapeQueryParameters2D` for landing overlap checks to reduce per-landing allocations.
- Reduced avoidable per-frame work in core loops:
  - `ball.gd`: reuses `delta_move` in collision checks and movement path; visual rotation gate now uses `length_squared()`.
  - `paddle.gd`: switched to scalar `input_velocity_y` flow and reused per-tick viewport reads to reduce temporary `Vector2` churn.
  - `hud.gd`: power-up timer refresh loop now runs only when indicators are present.
  - `power_up_manager.gd`: `_process` iterates a stable effect-key snapshot with existence guards before mutation/removal.
- Hardened loader/runtime error paths:
  - `audio_manager.gd`: validates SFX/music asset loads and skips missing streams with warnings.
  - `save_manager.gd`: persists and emits loaded-state when recovering from unreadable/invalid save files.
  - `level_loader.gd`: caches failed level reads/parses as empty results to avoid repeated file IO/parsing attempts.
  - `hud.gd`: replaced per-frame `meta` debug-key state with a typed boolean field.
  - `ball.gd`: extracted slow-trail speed threshold into named constant (`SLOW_SPEED_MULTIPLIER`).
- Added typed data structures in core systems:
  - `power_up_manager.gd`: introduced typed `ActiveEffect` payload class and typed `active_effects` dictionary.
  - `game_manager.gd`: typed score-breakdown dictionary with shared key constants to reduce string-key drift.
  - `paddle.gd`: added defensive null-shape guard before resize mutation in collision-shape update path.
- Further hot-path lookup reductions in ball runtime:
  - `ball.gd`: cached `Trail`/`Visual`/`CollisionShape2D` refs and reused cached viewport for aim/input reads.
  - `ball.gd`: added paddle-reference recovery from collision object when paddle signal path is hit without a cached reference.
- HUD per-frame allocation reductions and typing cleanup:
  - `hud.gd`: replaced power-up timer `get_children()` scans with tracked `powerup_indicators` list.
  - `hud.gd`: reused preallocated debug-ball and multiplier line buffers to reduce temporary allocations.
  - `hud.gd`: added explicit type annotations to key handlers/process methods and power-up callbacks.
- Additional aim-path micro-optimization:
  - `ball.gd`: aim head line points now update in-place via `set_point_position()` (no per-frame points-array replacement).
- Additional micro-optimizations in input/aim paths:
  - `paddle.gd`: cached viewport/visual/collision-shape refs to avoid repeated node lookups per tick.
  - `ball.gd`: aim head now updates Line2D points in-place (no per-frame array allocation); air-ball fallback uses cached viewport.
- Additional hot-path math/cache reductions:
  - `ball.gd`: bomb-radius and stuck checks now use squared-distance comparisons to avoid per-frame/per-brick sqrt calls.
  - `ball.gd`: air-ball landing center/step metrics are cached per level to avoid repeated per-jump layout scans.
- Additional manager-loop allocation reductions:
  - `power_up_manager.gd`: timer updates now iterate the dictionary directly with a reusable `expired_effect_types` buffer.
  - `power_up_manager.gd`: tracked-ball compaction now removes invalid entries in-place (no temporary array copy).
- Additional process-state gating for idle systems:
  - `power_up.gd`: game-manager lookup is now throttled/retried and bound via `state_changed` signal instead of per-frame group scans.
  - `hud.gd`: `_process` now auto-disables when FPS/debug is off, no power-up timers are active, and game is not paused.
  - `audio_manager.gd`: `_process` runs only when loop-all/shuffle crossfade monitoring is actually needed.
  - `camera_shake.gd`: `_process` now runs only during active shake windows.
- Additional cached-resource and loop-path reductions:
  - `brick.gd`: power-up scene is now preloaded and power-up type selection reuses a shared constant list.
  - `main.gd`: triple-ball spawn now reuses a preloaded ball scene instead of loading per activation.
  - `brick.gd`: bomb-brick AoE checks now use squared-distance comparisons.
  - `paddle.gd`: movement bounds are cached and reused; non-gameplay states now early-return from `_physics_process`.
  - `ball.gd`: paddle-reference refresh now runs only when the cached reference is missing/invalid.
- Additional ball-effect query reductions:
  - `ball.gd`: grab/brick-through/bomb-ball/air-ball/magnet active states are now cached once per physics frame and reused across launch/collision paths.
- Additional explosion/query path reductions:
  - `main.gd`: maintains a compacted cached level-brick list (`get_cached_level_bricks`) for shared gameplay queries.
  - `ball.gd` and `brick.gd`: bomb explosion scans now consume the cached brick list instead of repeatedly rebuilding child/group lists.
  - `ball.gd`: air-ball landing now uses cached unbreakable-row candidates to prune search checks, with a single physics confirmation on candidate slots.
- Additional section-closeout optimizations:
  - `ball.gd`: magnet pull now uses a scalar math path and out-of-bounds handling uses dedicated handlers to avoid unnecessary per-frame message setup.
  - `paddle.gd`: final bounds clamp is now conditional instead of unconditional each tick.
  - `brick.gd`: default power-up spawn chance now uses named constant (`DEFAULT_POWER_UP_SPAWN_CHANCE`).
- Tier 1 completion cleanup:
  - `main.gd`: `main_controller` group registration moved to `_enter_tree()` for earlier availability to child scripts.
  - `ball.gd`/`brick.gd`: cached `main_controller` references now back bomb/landing brick-list access without repeated group lookup churn.
- Tier 3 architecture cleanup:
  - `audio_manager.gd`: toast UI creation moved into dedicated `scripts/ui/audio_toast.gd`; AudioManager now delegates toast rendering instead of building UI controls inline.
- Tier 3 idle-processing closeout:
  - `power_up.gd`: physics processing is now state-driven and auto-disables when movement is inactive (terminal game state or zero-speed), with throttled manager retry while unresolved.
- Tier 4 landing-query optimization:
  - `ball.gd`: air-ball landing now resolves blocked slots primarily from cached unbreakable-row candidates, avoiding repeated per-candidate physics `intersect_shape()` calls on the common path.
- Tier 3 modularization progress:
  - `main.gd`: extracted background setup/viewport-fit logic into `scripts/main_background_manager.gd`; main controller now delegates to this helper.
- Tier 3 modularization continuation:
  - `main.gd`: extracted collected power-up effect dispatch into `scripts/main_power_up_handler.gd`; main now delegates effect application logic to helper methods.
- Ball script cleanup:
  - `ball.gd`: removed unused legacy launch-direction-indicator path (`create_direction_indicator` / `update_direction_indicator`) now that aim-indicator flow is canonical.
- Tier 3 ball modularization:
  - `ball.gd`: extracted air-ball landing helpers/cache/query scaffolding into `scripts/ball_air_ball_helper.gd`; ball script now delegates landing data/slot checks.
- Tier 3.1 file splits completed:
  - `ball.gd` (977 → 820): extracted `scripts/ball_aim_indicator_helper.gd` (aim indicator subsystem) and `scripts/ball_stuck_detection_helper.gd` (stuck detection).
  - `hud.gd` (960 → 354): extracted `scripts/hud_pause_menu_helper.gd`, `scripts/hud_debug_overlay_helper.gd`, `scripts/hud_level_intro_helper.gd`, `scripts/hud_power_up_timers_helper.gd`.
  - `save_manager.gd` (850 → 483): facade pattern with `scripts/save_settings_helper.gd`, `scripts/save_achievements_helper.gd`, `scripts/save_statistics_helper.gd`.

Full audit of the codebase for performance issues, code quality, Godot best practices, and architectural debt. Issues are organized by priority tier with concrete file:line references.

---

## Tier 1: Performance (Immediate Impact)

### 1.1 Remove Debug Print Statements

Status: ✅ Completed (2026-02-11)

- `scripts/` now has zero `print()` calls in runtime code.
- High-signal failures/warnings use `push_error()` and `push_warning()` instead.

### 1.2 Cache Node References (Stop Per-Frame Tree Lookups)

Status: ✅ Completed (2026-02-11)

Several scripts call `get_tree().get_first_node_in_group()` every frame instead of caching in `_ready()`.

| File:Line | Call | Frequency |
|-----------|------|-----------|
| ✅ `scripts/power_up.gd` | game-manager ref is cached/bound via signal with throttled retry instead of per-frame group lookup |
| ✅ `scripts/hud.gd` | game-manager and debug ball queries are cached/throttled; hot path now uses cached refs/registries |
| ✅ `scripts/power_up_manager.gd` | paddle/ball targets use cached refs and tracked-ball registry for effect apply/remove paths |
| ✅ `scripts/ball.gd` + `scripts/brick.gd` | main-controller lookups for cached brick access now use cached references |

**Fix:** Cache in `_ready()` or `@onready`, invalidate only on scene change.

### 1.3 Cache Group Queries (Avoid O(n) Tree Search on Collision)

Status: ✅ Completed (2026-02-11)

`get_nodes_in_group()` called during collision events, iterating the full scene tree.

| File:Line | Group | Context |
|-----------|-------|---------|
| ✅ `scripts/ball.gd` | `"brick"` | Bomb-ball explosion now uses cached level brick list from `main.gd` |
| ✅ `scripts/brick.gd` | `"brick"` | Bomb-brick explosion now uses cached level brick list from `main.gd` |
| ✅ `scripts/power_up_manager.gd` | `"ball"` | Effect application uses tracked active-ball registry |
| ✅ `scripts/main.gd` | `"ball"` | Active-ball queries use local `PlayArea` child scans (no full-tree group scan) |
| ✅ `scripts/hud.gd` | `"ball"` | Debug overlay uses `PowerUpManager.get_active_balls()` cache path |

**Fix:** Maintain a cached brick list in main.gd (invalidate on brick add/remove). Maintain a cached ball list (invalidate on spawn/destroy). Pass the lists to methods that need them.

### 1.4 Reduce Per-Frame Allocations

Status: ✅ Completed (2026-02-11)

| File:Line | Issue |
|-----------|-------|
| ✅ `scripts/hud.gd` | timer label lookups are cached and refreshed on interval, not per-frame `find_child()` |
| ✅ `scripts/hud.gd` | power-up timer label updates are throttled (0.1s), no longer every frame |
| ✅ `scripts/hud.gd` | Debug FPS/ball/velocity/speed/combo label text now updates only when values change |
| ✅ `scripts/ball.gd` | out-of-bounds diagnostics now build strings only on boundary-escape events via dedicated handlers |
| ✅ `scripts/ball.gd` | magnet pull uses scalar math path to reduce temporary vector churn in per-frame pull updates |
| ✅ `scripts/paddle.gd` | per-frame clamp is now conditional (applied only when outside bounds) |

**Fix:** Cache child references, pre-allocate frequently used objects, only format strings when values change.

---

## Tier 2: Code Quality (High Priority)

### 2.1 Extract Magic Numbers to Constants

Status: ✅ Completed (2026-02-11)

**ball.gd:**
- ✅ Resolved: base speed renamed to `BASE_SPEED`; boundary and speed literals extracted to named constants.
- ✅ Resolved: trail speed thresholds use named multipliers (`FAST_SPEED_MULTIPLIER`, `SLOW_SPEED_MULTIPLIER`) consistently.

**brick.gd:**
- ✅ Resolved: unbreakable hit count uses `UNBREAKABLE_HITS`.
- ✅ Resolved: default power-up spawn chance extracted to `DEFAULT_POWER_UP_SPAWN_CHANCE`.

**main.gd:**
- ✅ Resolved: extracted shake intensity/combo tuning literals and triple-ball spawn zone/safety literals into named constants.

**paddle.gd:**
- ✅ Resolved: extracted lerp/tween tuning and expand/contract height values into named constants.

**power_up_manager.gd:**
- ✅ Resolved: timed effects are now the only entries in `EFFECT_DURATIONS`; non-timed effects are no longer represented with `0.0` durations.

### 2.2 Add Type Annotations

Missing or inconsistent type annotations on variables that should be typed:

| File:Line | Variable | Should Be |
|-----------|----------|-----------|
| ✅ `scripts/ball.gd` | `paddle_reference`, `game_manager` | Typed (`Node2D`/`Node`) |
| ✅ `scripts/paddle.gd` | `game_manager` | Typed (`Node`) |
| ✅ `scripts/power_up_manager.gd` | `active_effects` payload structure | Typed via `ActiveEffect` class + typed dictionary |
| ✅ `scripts/hud.gd` | Multiple UI references and key handlers | Typed references + typed function signatures added |
| ✅ `scripts/game_manager.gd` | `score_breakdown` | Typed dictionary with centralized key constants |

### 2.3 Consolidate Duplicate Code

Status: ✅ Completed (2026-02-11)

**PowerUpManager reset pattern**
- ✅ Resolved: consolidated repeated ball effect apply/reset loops using `_for_each_ball(method_name: String)`.

**Power-up state duplication:**
- ✅ Resolved: ball runtime behavior flags are now sourced from `PowerUpManager` (`is_grab_active`, `is_brick_through_active`, `is_bomb_ball_active`, `is_air_ball_active`, `is_magnet_active`) instead of duplicated per-ball state booleans.
- ✅ Resolved: `ball.gd` compatibility hooks (`enable_*` / `reset_*`) remain for manager calls but no longer act as parallel effect-state truth; bomb-ball visual state is synchronized from manager-active status.

### 2.4 Standardize Signal Patterns

Status: ✅ Completed (2026-02-11)

Current inconsistency:
- ball.gd:74-75 - emits custom signals (`ball_lost`, `brick_hit`)
- ball.gd:305-307 - calls `game_manager.start_playing()` directly
- power_up.gd:56 - uses `body_entered.connect()`
- Some systems use groups, others use direct references

**Resolved convention (documented in `.agent/System/architecture.md`):**
- Gameplay events (ball lost, brick broken, score change) -> signals
- System commands (start game, pause) -> direct method calls
- Cross-system queries (get ball count) -> cached references/registries (group-backed only as fallback)

---

## Tier 3: Architecture (Medium Priority)

### 3.1 Split Oversized Files

Status: ✅ Completed (2026-02-11)

| File | Lines | Result |
|------|-------|--------|
| ✅ `scripts/ball.gd` | 977 → 820 | Air-ball helper + aim indicator + stuck detection extracted to `scripts/ball_air_ball_helper.gd`, `scripts/ball_aim_indicator_helper.gd`, `scripts/ball_stuck_detection_helper.gd` |
| ✅ `scripts/save_manager.gd` | 850 → 483 | Facade pattern: `scripts/save_settings_helper.gd`, `scripts/save_achievements_helper.gd`, `scripts/save_statistics_helper.gd` |
| ✅ `scripts/hud.gd` | 960 → 354 | `scripts/hud_pause_menu_helper.gd`, `scripts/hud_debug_overlay_helper.gd`, `scripts/hud_level_intro_helper.gd`, `scripts/hud_power_up_timers_helper.gd` |
| ✅ `scripts/main.gd` | 629 | Background + power-up-effect dispatch extracted to `scripts/main_background_manager.gd` and `scripts/main_power_up_handler.gd` |
| ✅ `scripts/audio_manager.gd` | 600 | Toast UI extracted to `scripts/ui/audio_toast.gd` helper node |

#### Extraction Pattern

All helpers follow the established project convention: `extends RefCounted` with `class_name`, preloaded as `const` scripts, instantiated lazily, using direct method calls with the parent/controller passed as a parameter. See `main_power_up_handler.gd` and `main_background_manager.gd` for the canonical pattern.

---

#### 3.1a ball.gd Extractions (Low Risk, ~977 → ~840 lines)

**`scripts/ball_aim_indicator_helper.gd`** (~120 lines, `class_name BallAimIndicatorHelper`)

Extracts the aim indicator subsystem. The helper receives the ball node for tree/viewport operations.

| What | Details |
|------|---------|
| Constants | `AIM_MIN_ANGLE`, `AIM_MAX_ANGLE`, `AIM_LENGTH`, `AIM_HEAD_LENGTH`, `AIM_HEAD_ANGLE` |
| State | `aim_available`, `aim_active`, `aim_direction`, `aim_indicator_root`, `aim_shaft`, `aim_head`, `virtual_mouse_pos`, `was_mouse_captured` |
| Methods | `create_indicator(ball)`, `update_direction(ball, viewport)`, `set_mode(enabled, paddle)`, `can_use(is_attached, game_manager)`, `handle_input(event, ball, viewport)`, `reset(is_main_ball)` |
| ball.gd delegates from | `_ready()`, `_unhandled_input()`, `_physics_process()`, `launch_ball()`, `reset_ball()`, `set_is_main_ball()` |

**`scripts/ball_stuck_detection_helper.gd`** (~65 lines, `class_name BallStuckDetectionHelper`)

Extracts stuck detection logic. Self-contained state tracking with the ball node passed for position/velocity reads.

| What | Details |
|------|---------|
| State | `stuck_check_timer`, `last_position`, `stuck_threshold`, `last_collision_normal`, `last_collision_collider`, `last_collision_age` |
| Methods | `check(ball, delta, current_speed, ball_radius, is_attached)`, `record_collision(normal, collider)`, `tick_collision_age(delta)` |
| ball.gd delegates from | `_physics_process()` (tick + check), `handle_collision()` (record) |

**Verification:** Launch ball normally, with aim (right-click), and in multiball. Let ball get stuck in unbreakable corner and confirm escape after ~2s. Confirm ball_lost signal fires on ball loss.

---

#### 3.1b hud.gd Extractions (Low Risk, ~959 → ~450 lines)

Four subsystems extracted. Combo (~50 lines) and Multiplier (~60 lines) stay inline — too small and too coupled to shared signals to justify separate files.

**`scripts/hud_pause_menu_helper.gd`** (~215 lines, `class_name HudPauseMenuHelper`)

| What | Details |
|------|---------|
| State | `pause_menu`, `settings_overlay`, `level_select_confirm`, `pause_level_info_label`, `pause_score_info_label`, `pause_lives_info_label` |
| Methods | `create(hud)`, `update_info(game_manager)`, `on_resume(game_manager)`, `on_restart(game_manager)`, `on_main_menu(game_manager)`, `on_level_select()`, `on_confirm_level_select(game_manager)`, `on_settings(hud)`, `on_settings_closed()` |
| hud.gd delegates from | `_ready()`, `_on_game_state_changed()`, `_process()`, `apply_settings_from_save()` |

**`scripts/hud_debug_overlay_helper.gd`** (~135 lines, `class_name HudDebugOverlayHelper`)

| What | Details |
|------|---------|
| State | `debug_overlay`, `debug_visible`, 5 debug labels, refresh timer/interval, cached ball arrays, 7 last-value tracking vars, `debug_key_handled` |
| Methods | `create()`, `update(delta, game_manager)`, `toggle_visibility()`, `is_active()` |
| hud.gd delegates from | `_ready()`, `_process()` (key toggle + update call), `_refresh_processing_state()`, `apply_settings_from_save()` |

**`scripts/hud_level_intro_helper.gd`** (~90 lines, `class_name HudLevelIntroHelper`)

| What | Details |
|------|---------|
| State | `level_intro`, `level_intro_num_label`, `level_intro_name_label`, `level_intro_desc_label`, `short_level_intro`, `skip_level_intro` |
| Methods | `create()`, `show(hud, level_id, level_name, level_description)`, `apply_settings(short, skip)` |
| hud.gd delegates from | `_ready()`, `show_level_intro()`, `apply_settings_from_save()` |

**`scripts/hud_power_up_timers_helper.gd`** (~130 lines, `class_name HudPowerUpTimersHelper`)

| What | Details |
|------|---------|
| State | `powerup_indicators`, `powerup_timer_refresh_time`, `POWERUP_TIMER_REFRESH_INTERVAL` |
| Methods | `on_effect_applied(type, container)`, `on_effect_expired(type, container)`, `create_indicator(type)`, `update_timer_labels()`, `has_active_indicators()` |
| hud.gd delegates from | `_ready()` (signal connections), `_process()` (timer refresh), `_refresh_processing_state()` |

**Verification:** Score/lives display, pause menu buttons (resume, restart, settings, level select, main menu), power-up timer indicators, debug overlay toggle (backtick), FPS display, level intro animation, combo label + screen flash.

---

#### 3.1c save_manager.gd Extractions (Medium Risk, ~849 → ~365 lines)

**Facade pattern:** SaveManager remains the single autoload. All 18 files / 113+ call sites referencing `SaveManager.method()` continue to work unchanged. Sub-managers are internal RefCounted helpers; SaveManager keeps all public methods as thin one-line wrappers that delegate.

Sub-managers receive `save_data` dictionary reference + `save_to_disk` callable on init. Signals remain on SaveManager (helpers return data, SaveManager emits).

**`scripts/save_settings_helper.gd`** (~300 lines, `class_name SaveSettingsHelper`)

| What | Details |
|------|---------|
| Constants | `DEFAULT_SETTINGS`, `REBIND_ACTIONS` |
| State | `default_keybindings` |
| Methods | ~30 functions: all get/save for audio (volume, playback mode, track), gameplay (difficulty, shake, particles, trail, combo flash, intro, FPS, sensitivity), keybindings (capture, save, apply, reset, serialize/deserialize), `reset_settings_to_default()` |
| Data | Operates on `save_data["settings"]` |

**`scripts/save_achievements_helper.gd`** (~110 lines, `class_name SaveAchievementsHelper`)

| What | Details |
|------|---------|
| Constants | `ACHIEVEMENTS` dictionary (~70 lines of definitions) |
| Methods | `check_achievements(get_stat_callable)`, `unlock_achievement(id)`, `is_achievement_unlocked(id)`, `get_unlocked_achievements()`, `get_achievement_progress(id, get_stat_callable)` |
| Data | Operates on `save_data["achievements"]` |
| Dependencies | Receives `get_stat` callable from SaveManager for condition checking |

**`scripts/save_statistics_helper.gd`** (~45 lines, `class_name SaveStatisticsHelper`)

| What | Details |
|------|---------|
| Methods | `increment_stat(name, amount)`, `get_stat(name)`, `update_stat_if_higher(name, value)`, `get_all_statistics()` |
| Data | Operates on `save_data["statistics"]` |

**SaveManager core retains (~365 lines):**
- File I/O: `load_save()`, `save_to_disk()`, `create_default_save()` + migration logic
- Progression: level unlock/complete/high-score functions
- Set system: set high-score/complete/unlock functions
- Last played tracking
- Reset operations: `reset_save_data()`, `reset_progress_data()`
- Facade wrappers (~60 lines of one-liner delegations)
- Preload consts, helper instantiation, signals

**Verification:** Settings round-trip (change every setting, reopen, verify). Stats increment during gameplay. Achievement unlock signal fires. Level progression + high scores persist. Save/load cycle with fresh save file. Reset settings vs reset progress.

### 3.2 Unify Power-Up State

Status: ✅ Completed (2026-02-11)

- Ball runtime behavior now queries `PowerUpManager` for effect activity (`is_grab_active`, `is_brick_through_active`, `is_bomb_ball_active`, `is_air_ball_active`, `is_magnet_active`) instead of maintaining duplicate state booleans.
- `enable_*` / `reset_*` methods remain as compatibility hooks for manager-driven apply/reset paths, but no longer act as separate sources of truth.

PowerUpManager is the canonical source of timed effect truth.

### 3.3 Extract Toast UI from AudioManager

Status: ✅ Completed (2026-02-11)

- Added `scripts/ui/audio_toast.gd` to own toast UI node creation and fade behavior.
- `scripts/audio_manager.gd` now instantiates this helper and delegates toast display through `show_toast()`.
- Result: Audio playback logic and transient UI concerns are now separated.

### 3.4 Disable Processing When Idle

Status: ✅ Completed (2026-02-11)

Completed:
- `power_up_manager.gd`: processing toggles on/off based on whether `active_effects` is empty.
- `ball.gd`: only main ball receives `_unhandled_input` processing; extra balls skip input handling.
- `power_up.gd`: physics processing disables when game reaches LEVEL_COMPLETE/GAME_OVER.
- `power_up.gd`: movement processing now also disables automatically when movement is inactive (e.g., zero speed), instead of continuing per-frame updates.
- `hud.gd`: `_process` now disables in idle gameplay (not paused, no debug/FPS overlay, no active power-up indicators).
- `audio_manager.gd`: `_process` now disables unless loop-all/shuffle track-boundary monitoring is needed.
- `camera_shake.gd`: `_process` now enables only while shake is active.

| File | Issue |
|------|-------|
| ✅ `scripts/power_up.gd` | `_physics_process()` now toggles off when movement is inactive; state changes and manager retry logic re-enable only when needed |
| ✅ `scripts/paddle.gd` | `_physics_process()` now early-returns outside READY/PLAYING and skips input/velocity work in non-gameplay states |
| ✅ `scripts/hud.gd` | `_process()` now toggles via `_refresh_processing_state()` and is disabled during idle gameplay |
| ✅ `scripts/audio_manager.gd` | `_process()` now runs only while music crossfade timing needs monitoring |
| ✅ `scripts/camera_shake.gd` | `_process()` now runs only while shake is active |
| ✅ `scripts/ball.gd` | unhandled input now enabled only for main ball |

---

## Tier 4: Minor Cleanup (Low Priority)

### 4.1 Variable Naming

Status: ✅ Completed (2026-02-11)

- `ball.gd` now uses `BASE_SPEED` for the base-speed constant naming convention.

### 4.2 Error Handling Gaps

Status: ✅ Completed (2026-02-11)

Completed:
- `audio_manager.gd`: SFX/music stream loads now validate and warn on missing assets.
- `save_manager.gd`: load-failure fallback now saves default data to disk and emits `save_loaded`.
- `level_loader.gd`: failed file/open/parse loads now cache empty results to reduce repeated failed IO/parsing.

| File:Line | Issue |
|-----------|-------|
| ✅ `scripts/ball.gd` | Grab offset correction path now guards on valid `paddle_reference` before using `paddle_offset` |
| ✅ `scripts/paddle.gd` | Collision-shape resize path now guards null/shape type before mutation |
| ✅ `scripts/audio_manager.gd` | SFX/music loads validate missing streams and skip invalid entries with warnings |
| ✅ `scripts/level_loader.gd` | Failed level loads are cached as empty results to avoid repeated failed parses |
| ✅ `scripts/save_manager.gd` | File-open/parse/version recovery now persists default save and emits load signal |

### 4.3 Shared Materials

Status: ✅ Completed (2026-02-11)

- `power_up.gd` now uses a shared static glow `CanvasItemMaterial` instead of allocating a new one per power-up instance.

### 4.4 Physics Query Optimization

Status: ✅ Completed (2026-02-11)

Completed:
- `ball.gd` air-ball landing now reuses shape/query objects rather than allocating new query objects every landing.
- `ball.gd` combines level center/step lookup into a single level-data read per air-ball jump.
- `ball.gd` now uses cached unbreakable-row slot checks for candidate landing positions, with the physics query loop retained only as fallback when row cache data is unavailable.

---

## Implementation Notes

- **Tier 1 can be done independently** - performance fixes have no architectural dependencies
- **Tier 2 items are safe refactors** - constants, types, and deduplication don't change behavior
- **Tier 3 requires careful planning** - file splits need updated scene references and signal wiring
- **Tier 4 is opportunistic** - fix when touching nearby code

---

Last Updated: 2026-02-11
