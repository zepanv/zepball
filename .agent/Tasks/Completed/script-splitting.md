# Script Splitting Refactor

## Status: 📋 BACKLOG

Several core scripts have grown too large for comfortable navigation and maintenance. The project already uses a proven `extends RefCounted` helper pattern (ball helpers, HUD helpers, save helpers). This task applies that same pattern to the remaining oversized files.

Last Updated: 2026-02-25

---

## Convention

All helpers follow the existing project pattern:
- `extends RefCounted` with a `class_name`
- Stored as sibling `.gd` files in `scripts/` (or `scripts/ui/` if the parent lives there)
- Preloaded via `const HELPER_SCRIPT = preload(...)` in the parent
- Instantiated in `_ready()` and stored as a `var helper: RefCounted` on the parent
- Naming: `{Parent}{Responsibility}Helper` (e.g. `SaveProgressionHelper`)
- When a helper needs parent state, pass `self` as a parameter to each method

Helpers that need node references (scene tree access) should receive them as arguments — helpers are plain objects, not nodes.

---

## Split 1: `scripts/save_manager.gd` (1768 lines)

**Existing helpers:** `SaveSettingsHelper`, `SaveAchievementsHelper`, `SaveStatisticsHelper`

Despite 3 existing helpers, the core file still owns 4 distinct responsibilities:

### Extract: `SaveProgressionHelper` (~400 lines)

Level and pack progression tracking, unlock/completion state, stars, and all save version migrations.

**Functions to move:**
- `is_level_unlocked`, `is_level_completed`, `unlock_level`, `mark_level_completed`
- `get_high_score`, `update_high_score`
- `is_level_key_unlocked`, `is_level_key_completed`, `unlock_level_key`, `mark_level_key_completed`
- `get_level_key_stars`, `update_level_key_stars`, `calculate_level_stars`
- `get_unlocked_level_count`, `get_completed_level_count`
- `get_pack_completed_count`, `get_pack_total_stars`
- `is_set_pack_unlocked`, `is_set_pack_completed`
- `mark_set_pack_completed`
- `_ensure_pack_progression_defaults`
- `_perform_migrations`, `_migrate_to_v2_pack_data`, `_migrate_to_v3_challenge_data`, `_migrate_to_v4_new_game_modes`
- `_parse_level_key`, `_legacy_ref_for_level`, `_legacy_level_id_for`, `_legacy_set_pack_id`, `_legacy_set_id_for_pack`
- `_normalize_challenge_mode`, `_sanitize_survival_runs`

**Parent retains:** Facade pass-through methods calling `progression_helper.*`

---

### Extract: `SaveHighScoresHelper` (~350 lines)

All high score tracking (levels, sets, packs, challenges, survival) plus leaderboard cache and cross-profile global lookups.

**Functions to move:**
- `get_level_key_high_score`, `update_level_key_high_score`
- `get_set_high_score`, `update_set_high_score`, `mark_set_completed`, `is_set_unlocked`, `is_set_completed`
- `get_set_pack_high_score`, `update_set_pack_high_score`
- `get_challenge_set_high_score`, `save_challenge_set_high_score`
- `_get_challenge_set_scores_key`, `_get_challenge_set_timestamps_key`
- `get_time_attack_set_high_score`, `save_time_attack_set_high_score`
- `get_survival_top_runs`, `save_survival_run`
- `get_all_leaderboards`, `_invalidate_leaderboard_cache` (+ `_leaderboard_cache` / `_leaderboard_cache_dirty` vars)
- `get_global_high_score`, `get_global_set_high_score`, `get_global_challenge_set_high_score`, `get_global_time_attack_set_best_time`

**Parent retains:** Facade pass-through methods calling `high_scores_helper.*`

---

### Extract: `SaveProfileHelper` (~150 lines)

Profile CRUD, metadata I/O, and legacy migration from the pre-profile save format.

**Functions to move:**
- `create_profile`, `load_profile`, `delete_profile`, `rename_current_profile`, `switch_profile`
- `load_metadata`, `save_metadata`
- `_migrate_legacy_save`
- `get_profile_list`, `get_current_profile_id`, `get_current_profile_name`
- `sanitize_name`, `_profile_name_exists`, `_get_profile_path`
- `_apply_profile_settings`, `get_next_default_name`
- `_ensure_dir_exists`

**Parent retains:** `_ready`, `load_save`, `save_to_disk`, `create_default_save`, `reset_save_data`, `reset_progress_data`, `get_save_file_location`, and all facade delegates

**Estimated parent reduction:** ~900 lines removed → parent down to ~500-600 lines

---

## Split 2: `scripts/ball.gd` (1020 lines)

**Existing helpers:** `BallAirBallHelper`, `BallAimIndicatorHelper`, `BallStuckDetectionHelper`

### Extract: `BallCollisionHelper` (~150 lines)

All collision response logic. Currently embedded in `handle_collision` with deeply nested paddle/brick/wall branches.

**Functions to move:**
- `handle_collision` (full method — paddle branch, brick branch, wall branch)
- `destroy_surrounding_bricks`

**Access needed from parent (pass as args):** `position`, `velocity`, `spin_amount`, `current_speed`, `ball_radius`, `frame_*_active` flags, `paddle_reference`, `stuck_helper`, `game_manager`, `main_controller_ref`, `last_physics_delta`, `grab_immunity_timer`, `block_pass_timer`

**Parent retains:** `_physics_process` calls `collision_helper.handle_collision(collision, self)`

---

### Extract: `BallVisualHelper` (~100 lines)

Trail appearance updates and ball visual state (bomb coloring, size changes).

**Functions to move:**
- `_update_trail_appearance`, `_get_trail_color`
- `_apply_bomb_ball_visual`
- `apply_big_ball_effect`, `apply_small_ball_effect`, `reset_ball_size`
- `get_ball_radius`, `set_ball_radius`, `get_base_radius`, `set_ball_size_multiplier`, `_set_ball_radius`
- `refresh_trail_state`

**Access needed from parent (pass as args):** `trail_node`, `visual_node`, `collision_shape_node`, `spin_amount`, `current_speed`, `base_speed`, `bomb_visual_active`

**Estimated parent reduction:** ~250 lines removed → parent down to ~750 lines

---

## Split 3: `scripts/ui/menu_controller.gd` (949 lines)

**Existing helpers:** None

### Extract: `MenuSetModeHelper` (~250 lines)

Set/pack run progression state and transitions.

**Functions to move:**
- `start_set`, `start_pack`
- `continue_set_from_level`, `continue_set_from_ref`
- `show_set_complete`
- `_find_set_id_by_pack_id`, `_get_starting_lives_for_challenge`, `_get_next_level_ref`

**State vars to move to helper** (or keep in parent and pass by reference):
- `set_current_index`, `set_level_ids`, `set_level_refs`
- `set_saved_score`, `set_saved_lives`, `set_saved_combo`, `set_saved_no_miss`, `set_saved_perfect`

---

### Extract: `MenuScoreBreakdownHelper` (~100 lines)

Score breakdown capture and accumulation across levels in a set.

**Functions to move:**
- `_capture_level_breakdown`, `_accumulate_set_breakdown`, `_reset_set_breakdown`
- `_create_empty_breakdown`, `_sum_breakdown`
- `get_last_level_breakdown`, `get_last_level_time_seconds`, `get_last_level_score_raw`, `get_last_level_score_final`
- `get_set_breakdown`, `get_set_total_time_seconds`, `get_set_score_before_bonus`, `get_set_perfect_bonus`

**State vars to move:** `last_level_breakdown`, `last_level_time_seconds`, `last_level_score_raw`, `last_level_score_final`, `set_breakdown`, `set_total_time_seconds`, `set_score_before_bonus`, `set_perfect_bonus`

---

### Extract: `MenuEditorTestHelper` (~100 lines)

Editor test mode flow: launching, storing draft data, and returning to editor.

**Functions to move:**
- `start_editor_test`
- `has_editor_test_data`, `get_editor_test_level_data`, `get_editor_test_level_name`, `get_editor_test_level_description`
- `get_editor_draft_pack`, `get_editor_draft_level_index`, `get_editor_draft_is_builtin_edit`
- `clear_editor_test_state`, `return_to_editor_from_test`

**State vars to move:** `is_editor_test_mode`, `editor_test_pack_data`, `editor_test_level_index`, `editor_draft_pack_data`, `editor_draft_level_index`, `editor_draft_is_builtin_edit`

**Estimated parent reduction:** ~450 lines removed → parent down to ~500 lines

---

## Split 4: `scripts/ui/level_editor.gd` (945 lines)

**Existing helpers:** None

### Extract: `EditorUndoHelper` (~80 lines)

Self-contained undo/redo system using snapshot dictionaries.

**Functions to move:**
- `_snapshot_state`, `_push_undo_state`, `_restore_snapshot`
- `_on_undo_button_pressed`, `_on_redo_button_pressed`

**State vars to move:** `undo_stack`, `redo_stack`, `MAX_UNDO_STATES`

**Interface:** `push_state(snapshot)`, `undo() -> snapshot | null`, `redo() -> snapshot | null`

---

### Extract: `EditorGridHelper` (~180 lines)

Grid rendering, coordinate-to-data mapping, and brick manipulation within a level.

**Functions to move:**
- `_refresh_grid`, `_get_brick_count`
- `_get_cell_short_text`, `_get_cell_color`, `_get_brick_type_at`, `_get_brick_data_at`, `_set_brick_type_at`
- `_update_grid_size`
- `_normalize_level_to_play_area`, `_get_grid_limits_for_play_area`
- `_reindex_levels`
- `_get_direction_label`, `_get_direction_marker`, `_get_powerup_abbreviation`

**Access needed from parent (pass as args):** `grid_container`, `selected_brick_type`, `selected_direction`, `selected_powerup_type`, `DEFAULT_ROWS`, `DEFAULT_COLS`

---

### Extract: `EditorPackIOHelper` (~180 lines)

All save/export/delete operations and the pack payload builder.

**Functions to move:**
- `_build_pack_payload`, `_requires_pack_v2`
- `_sanitize_pack_id`
- `_can_delete_current_pack`, `_update_delete_button_state`
- `_on_save_button_pressed`, `_on_export_button_pressed`
- `_on_delete_button_pressed`, `_on_delete_confirm_dialog_confirmed`
- `_on_test_button_pressed`
- `_on_open_exports_folder_button_pressed`

**Access needed from parent (pass as args):** `current_pack`, `selected_level_index`, `pack_id_input`, `pack_name_input`, `author_input`, `description_input`, `status_label`, `delete_button`, `delete_confirm_dialog`

**Estimated parent reduction:** ~440 lines removed → parent down to ~500 lines

---

## Split 5: `scripts/main.gd` (851 lines)

**Existing helpers:** `MainBackgroundManager`, `MainPowerUpHandler`, `SurvivalGenerator`

### Extract: `MainSurvivalHelper` (~100 lines)

Survival mode orchestration — wave loading, transitions, speed scaling, cleanup between waves.

**Functions to move:**
- `_start_survival_run`, `_load_survival_wave`, `_on_survival_wave_complete`
- `_apply_survival_speed_step`
- `_clear_non_main_balls`, `_clear_active_powerups`

**State vars to move:** `current_wave`, `survival_speed_multiplier`, `survival_transition_in_progress`

**Access needed from parent (pass as args):** `ball`, `play_area`, `hud`, `game_manager`, `brick_container`, `is_survival_mode`

---

### Extract: `MainBlockBarrierHelper` (~120 lines)

Block barrier spawning, visual configuration, color cycling, and cleanup.

**Functions to move:**
- `_spawn_block_barrier`, `_configure_block_brick`
- `_on_block_brick_broken`, `_on_block_barrier_timeout`, `_update_block_barrier_color`
- `_get_paddle_height`, `_get_paddle_width`

**Access needed from parent (pass as args):** `paddle`, `play_area`, `game_manager`, `BRICK_SCENE`

**Estimated parent reduction:** ~220 lines removed → parent down to ~630 lines

---

## Split 6: `scripts/pack_loader.gd` (634 lines)

**Existing helpers:** None

### Extract: `PackLegacyHelper` (~100 lines)

All legacy integer-based level and set ID mapping (compatibility layer for pre-pack-native code).

**Functions to move:**
- `get_legacy_level_ref`, `get_legacy_level_id`, `get_legacy_total_level_count`
- `get_all_legacy_sets`, `get_legacy_set_data`, `legacy_set_exists`
- `get_legacy_set_pack_id`, `get_legacy_set_level_ids`, `get_legacy_set_name`
- `get_legacy_set_description`, `get_legacy_set_id_for_pack`

**Access needed from parent (pass as args):** `LEGACY_PACK_ORDER` const and `get_level_count` / `pack_exists` methods

---

### Extract: `PackPreviewHelper` (~40 lines)

Level thumbnail/preview image generation. Isolated, no side effects.

**Functions to move:**
- `generate_level_preview`

**Access needed from parent (pass as args):** `BRICK_PREVIEW_COLOR_MAP` const

**Estimated parent reduction:** ~140 lines removed → parent down to ~500 lines

---

## Implementation Notes

- Each split should be its own commit: `refactor: extract {HelperName} from {parent_file}`
- Follow existing pattern exactly: preload script → instantiate in `_ready()` → store as `var helper: RefCounted`
- Do not change public API surface of parent autoloads — only move implementation
- When moving methods that reference `self` / internal state: convert to explicit parameter passing
- `save_manager.gd` splits must be done together in one pass (migrations call progression which calls high scores)
- `level_editor.gd` splits: `EditorUndoHelper` is the safest first extraction (fully self-contained)
- Test each split by running through affected gameplay paths in Godot before committing
