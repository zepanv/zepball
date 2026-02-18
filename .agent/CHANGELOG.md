# Zep Ball - Changelog

**Recent development history and feature updates.**

For current game state, see `README.md`. For full system architecture, see `System/architecture.md`.

---

## 2026-02-18 (Latest) - v0.5.1 Release Prep + Stability Fixes
- ✅ **Dev Builtin Pack Editing**: Added debug-only `EDIT [DEV]` entry on official packs and save path support for builtin pack edits in debug builds.
- ✅ **Editor Save Intent Fix**: Preserved builtin-edit intent through test round-trips and corrected save status text to reflect actual save target.
- ✅ **Shutdown Leak Fix**: Added graceful audio teardown during quit flow, removing persistent ObjectDB/resource leak warnings at exit.
- ✅ **Public Version Bump**: Updated public version display to `v0.5.1` for release.
- ✅ **Release Notes Standardized**: Added canonical GitHub release notes format guidance to release SOP for consistent future release pages.

## 2026-02-15 - Bugfixes & Pack Select UI Enhancements
- ✅ **Set Mode Combo/Streak Fix**: Combo multiplier and no-miss streak now reset at the start of each level in Set Mode (Perfect Set eligibility preserved)
- ✅ **Paddle X-Lock Fix**: Paddle is now strictly locked to its X-axis position, preventing horizontal displacement from ball collisions
- ✅ **Pack Select Filters Added**: Filter packs by ALL / OFFICIAL / CUSTOM
- ✅ **Pack Select Sorting Added**: Sort by ORDER (custom A-Z, then official legacy order) or PROGRESSION (completion percentage)
- ✅ **Pack Select Toolbar UI**: Added controller-accessible filter/sort controls to Pack Select screen
- ✅ **SemVer Adoption**: Switched public versioning to Semantic Versioning; main menu now displays `v0.5.0` (single in-game location)
- ✅ **Official First Public Release**: Published `v0.5.0` on GitHub Releases with signed assets (`zepball.zip`, `zepball.x86_64.zip`, `SHA256SUMS.txt`, `SHA256SUMS.txt.minisig`, `minisign.pub`)

## 2026-02-13 - Launch & Spin Fixes
- ✅ **Built-In Pack Export Fix**: `PackLoader` now discovers built-in `.zeppack` files with `ResourceLoader.list_directory()` and a `DirAccess` fallback, fixing missing built-in pack cards in exported builds.
- ✅ **Export Preset Include Fix**: Added `packs/*.zeppack` to export preset include filters so built-in packs are bundled in exported binaries.
- ✅ **Release Export Automation**: Added `scripts/export_release_bundle.sh` to export all release presets, copy `README.md`, and generate per-preset zips in `dist/releases/` (`zepball.x86_64.zip` for Linux, `zepball.zip` for Windows).
- ✅ **Launch Angle Fix**: Fixed ball launching toward paddle when paddle was moving. Now uses correct leftward angles (180° straight, 135° up-left when moving down, 225° down-left when moving up) instead of incorrectly using -45°.
- ✅ **Brick-Through Powerup Fix**: Fixed powerup bricks not being collected when ball has brick-through active or penetrating spin - now properly calls collect_powerup() in pass-through path.
- ✅ **Spin Safety on Launch**: Reduced max spin on launch to 50% of normal, with additional reduction near vertical boundaries.
- ✅ **Return-to-Paddle Protection**: Added spin curve reduction (70%) when ball is heading right (back toward paddle) to prevent going behind paddle.
- ✅ **Spin Delay Removed**: Removed the 450ms spin delay that was previously added to try to fix launch issues - no longer needed with correct launch angles.
- ✅ **Powerup Brick Bomb Fix**: Bomb explosions now properly grant powerup effects when destroying powerup bricks (previously only broke them without granting effect).
- ✅ **Enhanced Spin**: Persistent spin state with per-frame curve, exponential decay, visual trail effects (color/size change at high spin), and ball rotation scaling
- ✅ **Penetrating Spin**: High-spin balls (≥400 spin threshold) pass through and break regular bricks, does NOT penetrate unbreakable/block/force arrow tiles
- ✅ **Force Arrow Tiles**: Non-collidable directional force fields (8 directions) with proximity-based strength, charge-up mechanic (1.0× to 2.5× over 0.8s), pulsing visual effect (size + opacity), and audio feedback (bzzrt.mp3 with volume scaling)
- ✅ **Power-up Bricks**: Pass-through tiles that grant instant power-ups (all 16 types), disappear on collection, do not count toward level completion
- ✅ **Schema Extension v2**: Backward-compatible pack format supporting direction and powerup_type metadata fields
- ✅ **Editor Integration**: Force Arrow direction picker (8 options), Power-up type picker (16 options), grid cell display, v2 save logic
- ✅ **Blocking Issues Resolved**: Force arrows made non-collidable (field forces only), spin stabilized with angle limiting and boundary protection
- ✅ **File Organization**: Moved unused powerup assets to main directory, updated documentation

## 2026-02-12 - Skip Options Complete
- ✅ **Removed Short Intro Setting**: Deleted `short_level_intro` from settings/save/HUD; default intro hold is now 1.0s (total 2.0s with fades).
- ✅ **Input-Based Intro Skip**: Space/Click during intro immediately hides it.
- ✅ **Fast-Forward Level Complete**: Enter on level complete screen advances after 0.5s guard delay.
- ✅ **Quick Restart from Game Over**: R or Enter on game over retries after 0.5s guard delay.

## 2026-02-11 - Legacy Loader Cleanup Complete
- ✅ **Legacy Loaders Removed**: Deleted `scripts/level_loader.gd` and `scripts/set_loader.gd`; removed both autoloads from `project.godot`.
- ✅ **Runtime Calls Migrated**: Gameplay/UI/save flows now use `PackLoader` directly for level and set compatibility lookups.
- ✅ **Legacy Data Removed**: Deleted `data/level_sets.json` and `levels/level_01.json`-`level_20.json`.

## 2026-02-11 - Editor Pack Delete Flow
- ✅ **Delete Custom Pack Added**: Added `DELETE PACK` action in level editor for saved user packs.
- ✅ **Safety Confirmation**: Delete now requires explicit confirmation before removing the pack file.
- ✅ **Post-Delete Navigation**: Successful deletes return directly to Pack Select.

## 2026-02-11 - Level Overhaul Stage 5 Complete
- ✅ **Third Built-In Pack Added**: Added `packs/nebula-ascend.zeppack` with 10 new authored levels.
- ✅ **Legacy Compatibility Expanded**: Added set/level legacy mapping for set 3 and levels 21-30 in `PackLoader` and `SaveManager`.
- ✅ **Champion Achievement Updated**: Requirement increased from 10 to 30 level completions.

## 2026-02-11 - Level Editor Export UX Polish
- ✅ **Export Button Added**: Added `EXPORT PACK` action in editor to create shareable `.zeppack` files.
- ✅ **Export Destination**: Exports now save to `user://exports/` with timestamped filenames.
- ✅ **Path Feedback**: Editor status now shows full exported file path after successful export.
- ✅ **Open Folder Shortcut**: Added `OPEN EXPORT FOLDER` button to open the exports directory in Finder/Explorer/file manager.

## 2026-02-11 - Editor Test UX Follow-Up
- ✅ **Pause Return Link**: Added `RETURN TO EDITOR` button to pause menu during editor test runs.
- ✅ **Saved Pack Reload Shortcut**: Added `OPEN SAVED PACKS (EDIT)` button in editor to jump to Pack Select and reopen saved packs via `EDIT`.

## 2026-02-11 - Level Editor Stage 4 Slice 3 (Test Mode)
- ✅ **Editor Test Run Added**: Added `TEST LEVEL` action in editor to launch gameplay from current in-memory draft without requiring a save.
- ✅ **Safe Test Flow**: Added dedicated editor-test runtime path in `MenuController` and `main.gd` so test runs do not update progression, high scores, or gameplay statistics.
- ✅ **Return-to-Editor Loop**: Game Over / Level Complete now route back to editor during test mode and restore the editor draft + selected level.

## 2026-02-11 - Level Editor Stage 4 Slice 2
- ✅ **Level Metadata Editing**: Added per-level name/description fields in editor UI and wired updates into in-memory pack state.
- ✅ **Level Management Controls**: Added duplicate and move up/down actions for level ordering in editor list.
- ✅ **Undo/Redo Added**: Implemented snapshot-based undo/redo with buttons and keyboard shortcuts (`Ctrl/Cmd+Z`, `Ctrl/Cmd+Y`, `Ctrl/Cmd+Shift+Z`).

## 2026-02-11 - Level Overhaul UI/Flow Fixes
- ✅ **Level Select Layout Fix**: Expanded layout bounds to prevent title clipping and consolidated filter/sort controls into one toolbar row.
- ✅ **Level Intro Description Fix**: Bound intro description label correctly so gameplay intro shows the level's actual description text.
- ✅ **Editor Back Navigation Fix**: Editor now returns to Main Menu when opened from Main Menu, and to Pack Select when opened from pack cards.
- ✅ **Stats UX + Warning Fixes**: ESC now returns from Stats to Main Menu; unused achievement parameter warning resolved in `stats.gd`.

## 2026-02-11 - Level Select/Editor Follow-Up Fixes
- ✅ **Editor Return Source Fix**: Added separate editor entry points for Main Menu vs Pack Select create flow, so return route is accurate for both.
- ✅ **Editor Back Label Fix**: Editor back button text now dynamically shows `BACK TO MENU` or `BACK TO PACKS` based on launch source.
- ✅ **Level Select Title Hardening**: Added explicit top margins/min-height and long-title font fallback/ellipsis behavior to avoid top clipping/overflow.

## 2026-02-11 - Level Select Top Spacing Tighten
- ✅ **Top Stack Tightened**: Reduced title-to-toolbar vertical spacing in `scenes/ui/level_select.tscn` (`VBox` separation, title minimum height, and spacer height) to keep filters tight under the title.

## 2026-02-11 - Level Overhaul Stage 4 Slice 1 + Compile Hardening
- ✅ **PackLoader Strict-Typing Hardening**: Removed Variant-inference `:=` usage in `scripts/pack_loader.gd` to satisfy warning-as-error parse settings.
- ✅ **Editor Scaffolding Added**: New `scenes/ui/level_editor.tscn` + `scripts/ui/level_editor.gd` for pack metadata editing, level list add/remove/select, grid painting, and user pack save flow.
- ✅ **Editor Navigation Wired**: Added `MenuController.show_editor()` / `show_editor_for_pack(pack_id)`, Main Menu `EDITOR` button, Pack Select `EDIT` (custom packs), and `CREATE NEW PACK`.

## 2026-02-11 - Optimization Pass Completed
- ✅ **Achievement Unlock Warning Fix**: Renamed local variable in `save_manager.gd` unlock flow to avoid shadowing `Node.name` (`SHADOWED_VARIABLE_BASE_CLASS`)
- ✅ **Triple-Ball Spawn Crash Fix**: Hardened `ball.gd` `set_is_main_ball()` to initialize/guard aim helper when called pre-`_ready`, preventing null `aim_available` assignment during extra-ball spawn
- ✅ **Performance Logging Cleanup**: Removed `print()` calls from core gameplay hot paths (`ball`, `main`, `brick`, `game_manager`, `power_up_manager`, `hud`, loaders)
- ✅ **Project-Wide Logging Cleanup**: Removed remaining runtime `print()` calls from save/difficulty/UI scripts; moved critical cases to warnings/errors
- ✅ **Cached Lookups**: HUD/game-manager and power-up/game-manager references cached to avoid repeated per-frame group lookups
- ✅ **Group Query Reduction**: Bomb explosion lookups now prefer local containers over full-scene group scans
- ✅ **Power-Up Manager Refactor**: Consolidated repeated ball-effect loops via helper methods
- ✅ **Magic Number Cleanup**: `main.gd` and `paddle.gd` now use named constants for shake tuning, triple-ball safety bounds, mouse lerp, and resize tween timings
- ✅ **Shake Logic Dedup**: Brick and block-brick hit shake math unified via a shared helper in `main.gd`
- ✅ **Power-Up Timer Semantics**: `power_up_manager.gd` now tracks timed effects only; instant/non-timed effects are no longer represented as `0.0` duration entries
- ✅ **Debug Overlay Stability**: `hud.gd` debug ball cache now filters freed references during multiball transitions; FPS value casting avoids narrowing warnings
- ✅ **Magnet Direction Fix**: Magnet attraction in `ball.gd` now applies only when the ball is moving toward the paddle on the X axis, preventing post-hit pullback
- ✅ **Air-Ball Query Optimization**: `ball.gd` now reuses landing query objects and computes center/step landing metrics in one level-data load
- ✅ **Loop Micro-Optimizations**: Reduced per-frame churn in `ball.gd`/`paddle.gd`, gated HUD timer refresh work by active indicators, and made `power_up_manager.gd` timer iteration mutation-safe
- ✅ **Error-Path Hardening**: Added asset-load validation in `audio_manager.gd`, persistent fallback recovery in `save_manager.gd`, failed-load caching in `level_loader.gd`, and minor HUD/ball cleanup constants
- ✅ **Typed Core Data**: Added typed active-effect payloads in `power_up_manager.gd` and typed score-breakdown keys/structure in `game_manager.gd`; added defensive paddle shape null guard
- ✅ **Ball Hot-Path Caching**: `ball.gd` now caches visual/trail/collision refs and reuses cached viewport access in aim/input logic; paddle-reference fallback added on paddle collision
- ✅ **HUD Allocation Cleanup**: `hud.gd` now tracks power-up indicators directly, reuses debug/multiplier buffers, and adds typed callback/process signatures
- ✅ **Active Ball Registry**: `power_up_manager.gd` now tracks live balls and provides `get_active_balls()`; HUD/settings now use it instead of global ball-group scans
- ✅ **Ball Math + Cache Optimizations**: `ball.gd` now uses squared-distance checks in bomb/stuck paths and caches air-ball landing center/step metrics per level
- ✅ **Manager Loop Optimization**: `power_up_manager.gd` now iterates active effects without per-frame key-array allocation and compacts tracked balls in-place
- ✅ **Idle Processing Gating**: `hud.gd`, `audio_manager.gd`, and `camera_shake.gd` now disable `_process` when idle; `power_up.gd` game-manager lookup no longer runs every frame
- ✅ **Scene Load Path Optimization**: `brick.gd` power-up spawning and `main.gd` triple-ball spawning now use preloaded scenes instead of runtime `load()` calls
- ✅ **Gameplay Loop Micro-Optimizations**: `paddle.gd` caches movement bounds and skips work outside READY/PLAYING; `brick.gd` bomb AoE uses squared-distance checks
- ✅ **Ball Effect Query Optimization**: `ball.gd` now caches effect-active flags once per physics frame to reduce repeated autoload checks in launch/collision logic
- ✅ **Explosion + Landing Query Optimization**: `main.gd` now serves a compacted cached level-brick list for shared bomb queries, and `ball.gd` air-ball landing prunes slot checks using cached unbreakable-row candidates
- ✅ **Section 1.4/2.1 Closeout**: `ball.gd` magnet/out-of-bounds paths reduce per-frame temp work, `paddle.gd` uses conditional bounds clamp, and `brick.gd` power-up spawn default now uses a named constant
- ✅ **Tier 1 Finalization**: Completed remaining section 1 items by finishing node/group cache cleanup, including cached `main_controller` refs in `ball.gd`/`brick.gd` and earlier group registration in `main.gd`
- ✅ **Section 2 Finalization**: Completed remaining section 2 items by removing duplicated ball effect-state truth (PowerUpManager is now canonical) and documenting the event/command/query convention in system architecture
- ✅ **Audio Toast Extraction**: Moved audio hotkey/status toast UI from `audio_manager.gd` into dedicated `scripts/ui/audio_toast.gd` helper and left AudioManager as a playback-focused system
- ✅ **Power-Up Idle Gating**: `power_up.gd` now toggles physics processing based on active movement/state, avoiding unnecessary idle `_physics_process` work
- ✅ **Air-Ball Query Reduction**: `ball.gd` now resolves most air-ball landing slots from cached unbreakable-row candidates, using physics shape queries only as fallback
- ✅ **Main Background Split**: Background setup/viewport-fit responsibilities moved from `main.gd` into new `scripts/main_background_manager.gd` helper
- ✅ **Main Power-Up Handler Split**: Collected power-up effect dispatch moved from `main.gd` into new `scripts/main_power_up_handler.gd` helper
- ✅ **Ball Legacy Cleanup**: Removed unused legacy launch-direction indicator path from `ball.gd` (aim-indicator flow remains canonical)
- ✅ **Ball Air-Ball Helper Split**: Air-ball landing cache/query helper logic moved from `ball.gd` into `scripts/ball_air_ball_helper.gd`
- ✅ **Task Tracking**: `Tasks/Completed/optimization-pass.md` finalized and moved out of backlog

## 2026-02-11 - Level Overhaul Stage 1 (Pack Foundation)
- ✅ **PackLoader Added**: New `scripts/pack_loader.gd` autoload for `.zeppack` discovery/loading/validation and level instantiation
- ✅ **Built-In Packs Added**: Converted existing content into `packs/classic-challenge.zeppack` and `packs/prism-showcase.zeppack`
- ✅ **Compatibility Layer**: `LevelLoader`/`SetLoader` now read via PackLoader while preserving current integer level/set flows

## 2026-02-11 - Level Overhaul Stage 2 (Core Migration)
- ✅ **Menu Runtime Migration**: `MenuController` now runs with `pack_id + level_index` as internal level identity (legacy `level_id` maintained for compatibility/UI)
- ✅ **Gameplay Load Migration**: `main.gd` now loads levels via `PackLoader.instantiate_level(pack_id, level_index, ...)`
- ✅ **Save v2 Migration**: `SaveManager` now stores pack-native progression/high scores/last-played references and migrates legacy save data
- ✅ **GameManager Identity Fields**: Added `current_pack_id`, `current_level_index`, `current_level_key`

## 2026-02-11 - Level Overhaul Stage 3 (Pack/Level Select UX)
- ✅ **Pack Select Refactor**: `set_select.gd` now renders pack cards from `PackLoader` with official/custom badges, author metadata, progress, stars, and pack high score
- ✅ **Level Select Refactor**: `level_select.gd` now supports pack browsing, level thumbnails, stars, filter/sort controls, and pack-level start flow
- ✅ **Star Ratings Added**: `SaveManager` now calculates and stores per-level stars keyed by `pack_id:level_index`
- ✅ **NEW Label Bugfix**: `NEW` is shown only when unlocked level has no completion and no high score

## 2026-01-31 - Documentation Refresh
- ✅ **System Docs**: Updated architecture + tech stack (keybindings, audio, debug notes)
- ✅ **Tasks**: Added completed docs for Settings Enhancements and Quick Actions

## 2026-01-31 - Keybinding Menu + Debug Cleanup
- ✅ **Keybindings**: Added keybinding menu in Settings with input map persistence
- ✅ **Debug Keys**: Removed debug hotkeys except C (debug/editor only)

## 2026-01-31 - Prism Showcase Polish + Physics Fixes
- ✅ **Level Layouts**: Prism Showcase levels re-centered vertically for better balance
- ✅ **Level Layouts**: All levels re-centered vertically based on PlayArea height (720) and occupied rows
- ✅ **Level 6 Theme**: Replaced duplicate Diamond Formation with Sun Gate layout
- ✅ **Perfect Clear**: Extra lives no longer disqualify perfect clears
- ✅ **Air Ball + Grab**: Air ball jump now triggers on grab release
- ✅ **Block Barrier**: Spawn deferred to avoid physics flush errors; barrier placed behind paddle
- ✅ **Brick Collisions**: Deferred collision polygon toggles to avoid query flush errors

## 2026-02-02 - Audio Export Fixes + Power-Up QoL
- ✅ **Music Exports**: Export-safe music discovery + OGG music assets
- ✅ **Power-Ups**: Duplicate timed power-ups add full duration
- ✅ **Bomb Bricks**: Bomb and bomb-ball explosions reliably break nearby bricks (block/unbreakable ignored)
- ✅ **Physics**: Square-brick bounce uses axis-resolved normals for more consistent reflections
- ✅ **Version Label**: Main menu uses date-based version string
- ✅ **Air Ball**: Landing avoids unbreakable brick slots

## 2026-01-31 - Advanced Bricks + Prism Showcase
- ✅ **Advanced Bricks**: Diamond + pentagon bricks with angled collision normals and glossy 2-hit variants
- ✅ **Brick Assets**: Diamond/pentagon textures wired with random color selection
- ✅ **Prism Showcase**: Added 10 creative levels highlighting new brick shapes

## 2026-01-31 - QoL Settings + Quick Actions
- ✅ **Settings QoL**: Visual Effects checkboxes (combo flash, short/skip intro, show FPS) + 3-column layout
- ✅ **Pause Settings**: Settings overlay from pause with live apply for key gameplay options
- ✅ **Quick Actions**: Play Again on level complete, Return to Last Level on main menu
- ✅ **Pause Menu**: Added Level Select with confirmation
- ✅ **Level Select**: 3-column layout + set context button moved up
- ✅ **Pause Menu Fix**: Pause can be opened in READY state before the first ball launch
- ✅ **Pause Menu Layout**: Centered pause menu vertically via CenterContainer
- ✅ **Mouse Capture**: Mouse is captured during READY/PLAYING and released in menus/overlays
- ✅ **Mouse Capture Input**: Paddle uses relative mouse motion while cursor is captured
- ✅ **Settings Defaults**: Visual toggles default off (combo flash/intro/FPS), particles+trail on, shake medium
- ✅ **Settings Tools**: Added Reset Settings (defaults) and Clear Save Data preserves settings
- ✅ **Audio SFX Coverage**: Power-up good/bad, life lost, combo milestone, level complete, game over
- ✅ **Aim Mode Fix**: Aim indicator uses relative mouse motion when cursor is captured
- ✅ **HUD Init Fix**: Restored combo/multiplier/score overlays initialization

## 2026-01-31 - Audio System Core + Aim Indicator
- ✅ **AudioManager** autoload with music playlist + crossfade support
- ✅ **Music Modes**: Off / Loop One / Loop All / Shuffle (Settings UI)
- ✅ **SFX Wiring**: Paddle hit, brick hit, wall hit
- ✅ **Audio Assets**: Moved to `assets/audio/` (music + sfx)
- ✅ **Audio Hotkeys**: Volume -, = ; track prev/next [ ] ; pause toggle \
- ✅ **Aim Mode**: Right-click hold to aim the main ball's first shot per life

## 2026-01-30 - Set Mode & Bomb Bricks
- ✅ **Set Mode**: Set Select + Set Complete screens, set-level flow
- ✅ **Set Data**: `data/level_sets.json` defines set(s)
- ✅ **Set Scoring**: Perfect set bonus (3x) and set high scores
- ✅ **Bomb Bricks**: Explosive bricks and bomb ball power-up (75px radius)
- ✅ **Expanded Power-Ups**: 16 types total, with HUD timers

## 2026-01-30 - Playtime Tracking + Game Over Fix
- ✅ **Playtime Tracking**: `total_playtime` now accumulates during READY/PLAYING and flushes every 5s
- ✅ **Games Played Tracking**: `total_games_played` increments per level start
- ✅ **Game Over Screen**: Fixed malformed `@onready` line for `high_score_label`

## 2026-01-30 - Set System Integration
- ✅ **Set System**: Set Select + Set Complete screens, PlayMode enum, state persistence across set levels
- ✅ **Set Progression**: Set high scores and completion tracking
- ✅ **Perfect Set Bonus**: 3x multiplier when all lives intact and no continues
- ✅ **Continue Set**: Game Over allows resuming current set level (resets score/lives)
- ✅ **Settings**: Clear Save Data button with confirmation dialog
- ✅ **UI Fixes**: Combo label z-index below pause menu; set context UI in Level Select
- ✅ **Data Fixes**: SetLoader int conversion for set_id; `set_display_name` rename in set select
- ✅ **Gameplay Fix**: Paddle height bounds correctly update after expand/contract

## 2026-01-30 - Settings & Score Multipliers
- ✅ **Settings Menu**: 7 customizable options (shake, particles, trail, sensitivity, audio, difficulty)
- ✅ **Score Multipliers**: No-miss streak (+10%/5 hits), Perfect Clear (2x final score)
- ✅ **Multiplier HUD**: Real-time display of active bonuses with color coding

## 2026-01-29 - Statistics & Achievements
- ✅ **Statistics System**: 10 tracked stats (bricks, power-ups, combos, score, etc.)
- ✅ **Achievement System**: 12 achievements with progress tracking
- ✅ **Stats Screen**: Full UI for viewing statistics and achievements
- ✅ **Save Migration**: Automatic save file updates for old saves

## 2026-01-29 - Content Expansion
- ✅ **5 New Levels (6-10)**: Diamond Formation, Fortress, Pyramid of Power, Corridors, The Gauntlet
- ✅ **10 Total Levels**: Expanded content with special bricks
- ✅ **Enhanced UI**: Pause menu with level info, level intro animations, debug overlay

## 2026-01-29 - Core Systems
- ✅ **Complete Menu System**: Main Menu, Set Select, Level Select, Game Over, Level Complete screens
- ✅ **Level Progression**: Unlock system with high score tracking
- ✅ **SaveManager**: Persistent save data with JSON format
- ✅ **PackLoader**: Dynamic level loading from `.zeppack` packs
- ✅ **Combo System**: Consecutive hits with score bonuses
- ✅ **Difficulty System**: Easy/Normal/Hard with speed/score multipliers

---

**Last Updated**: 2026-02-18
