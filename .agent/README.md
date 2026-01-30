# Zep Ball - Documentation Index

This folder contains the canonical documentation for the Zep Ball codebase. All documentation is kept up-to-date to reflect the current state of the game.

## Documentation Structure

### System/
Current system state, architecture, and technical foundation.
- **`System/architecture.md`** - Complete project architecture, autoload systems, core gameplay systems, set mode, scene graph, scoring mechanics, menu flow, and all implemented features. **Read this first for full context.**
- **`System/tech-stack.md`** - Engine version, project settings, input map, and runtime configuration.

### Tasks/
PRDs and implementation plans for features (both implemented and future).
- **`Tasks/Completed/`** - Implemented feature plans and final notes.
  - `Tasks/Completed/core-mechanics.md` - Paddle, ball, and collision system design ✅ IMPLEMENTED
  - `Tasks/Completed/tile-system.md` - Brick/tile system plan ✅ IMPLEMENTED
  - `Tasks/Completed/level-system.md` - Level data, loader, and progression plan ✅ IMPLEMENTED
- `Tasks/Completed/power-ups.md` - Power-up system design and implementation plan ✅ IMPLEMENTED
  - `Tasks/Completed/ui-system.md` - UI, menus, and HUD plans ✅ IMPLEMENTED
  - `Tasks/Completed/save-system.md` - Save data, high scores, and persistence plan ✅ IMPLEMENTED
- **`Tasks/Backlog/`** - Not yet implemented or future work.
  - `Tasks/Backlog/audio-system.md` - Audio system plan (SFX, music) 📅 NOT YET IMPLEMENTED
  - **`Tasks/Backlog/future-features.md`** - Planned features for future development (Time Attack, Survival, settings enhancements, advanced gameplay)
  - `Tasks/Backlog/power-up-expansion.md` - Additional power-ups beyond the current 15
  - `Tasks/Backlog/tile-advanced-elements.md` - Force zones, special bricks, and advanced tile behaviors
  - `Tasks/Backlog/ui-gaps.md` - Launch indicator + level complete breakdown

### SOP/
Best practices and workflows for development.
- **`SOP/godot-workflow.md`** - Working with Godot scenes, nodes, signals, and **CRITICAL: Save System Compatibility** section for handling save data migrations.

## Current Game State (2026-01-30)

### Core Features ✅ COMPLETE
- **Gameplay**: Paddle movement (keyboard + mouse), ball physics with spin, 10 brick types (including bomb bricks), collision detection, score tracking
- **Power-Ups**: 15 types with visual timers and effects (Expand, Contract, Speed Up, Slow Down, Triple Ball, Big/Small Ball, Extra Life, Grab, Brick Through, Double Score, Mystery, Bomb Ball, Air Ball, Magnet)
- **Special Bricks**: Bomb bricks that explode and destroy surrounding bricks (75px radius)
- **Difficulty**: 3 modes (Easy/Normal/Hard) with speed and score multipliers
- **Levels**: 10 unique levels with varied brick mixes (bomb bricks appear in multiple levels)
- **Menu System**: Complete flow (Main Menu, Set Select, Level Select, Game Over, Level Complete, Set Complete, Stats, Settings)
- **Progression**: Level unlocking and high scores saved per level

### Set Mode ✅ COMPLETE
- **Set Data**: `data/level_sets.json` defines available sets
- **Current Set**: 1 set, **Classic Challenge** (levels 1–10)
- **Set Select**: Play set or view its levels
- **Set Progression**: Score/lives/combo/streak carry across set levels
- **Set Completion Bonus**: 3x score if all lives intact and no continues
- **Set High Scores**: Saved separately from individual level scores

### Statistics & Achievements ✅ COMPLETE
- **10 Tracked Stats**: Bricks broken, power-ups collected, levels completed, individual levels completed, set runs completed, playtime, highest combo, highest score, games played, perfect clears
- **12 Achievements**: Ranging from "First Blood" (1 brick) to "Champion" (all 10 levels) with progress tracking
- **Stats Screen**: Full statistics display with achievement list and progress bars
- **Tracking**: `total_playtime` increments during READY/PLAYING (flushed every 5s), and `total_games_played` increments per level start

### Settings System ✅ COMPLETE
- **Gameplay Settings (7)**:
  - Screen shake intensity (Off/Low/Medium/High)
  - Particle effects toggle
  - Ball trail toggle
  - Paddle sensitivity (0.5x - 2.0x)
  - Music volume (-40dB to 0dB)
  - SFX volume (-40dB to 0dB)
  - Difficulty (Easy/Normal/Hard) saved from Main Menu
- **All settings persist** via SaveManager with automatic migration
- **Audio sliders apply immediately**; other gameplay settings apply on next scene load

### Score Multipliers ✅ COMPLETE
- **Difficulty Multiplier**: 0.8x (Easy), 1.0x (Normal), 1.5x (Hard)
- **Combo Multiplier**: 10% bonus per hit after 3x combo (e.g., 12x combo = 2.0x multiplier)
- **No-Miss Streak**: 10% bonus per 5 consecutive hits without losing ball (e.g., 15 hits = 1.3x multiplier)
- **Double Score Power-Up**: 2x multiplier while active
- **Perfect Clear**: 2x final score bonus for completing level with all 3 lives intact
- **Perfect Set**: 3x final score bonus for set completion with all lives intact and no continues
- **All multipliers stack multiplicatively**
- **Real-time HUD display** showing active bonuses with color coding

### UI Features ✅ COMPLETE
- **Enhanced Pause Menu**: Level info, Resume, Restart, Main Menu buttons
- **Level Intro**: Fade in/out animation with level name and description
- **Debug Overlay**: FPS, ball stats, combo (toggle with backtick ` key)
- **HUD Elements**: Score, lives, difficulty label, combo counter (with elastic bounce at milestones), multiplier display, power-up timers

## Tech Stack
- **Engine**: Godot 4.6
- **Language**: GDScript
- **Run Main Scene**: `res://scenes/ui/main_menu.tscn`
- **Gameplay Scene**: `res://scenes/main/main.tscn`
- **Autoloads**: PowerUpManager, DifficultyManager, SaveManager, LevelLoader, SetLoader, MenuController

## Autoload Singletons (Global Systems)
These are always accessible and control key game systems:
1. **PowerUpManager** - Timed power-up effects
2. **DifficultyManager** - Difficulty modes with multipliers
3. **SaveManager** - Save data, statistics, achievements, settings
4. **LevelLoader** - Level JSON loading
5. **SetLoader** - Set JSON loading
6. **MenuController** - Scene transitions and game flow

## Quick Start for New Developers
1. **Read** `System/architecture.md` - Complete system overview with all features documented
2. **Check** `SOP/godot-workflow.md` - Development workflows and **save migration best practices**
3. **Explore** `Tasks/Backlog/future-features.md` - Planned future development
4. **Note**: Save system has automatic migration - see SOP for how to add new fields safely

## Development Roadmap

### ✅ Phase 1-5: Core Game (COMPLETE)
- Phase 1: Core Mechanics (Paddle, Ball, Bricks, Collision)
- Phase 2: Visual Polish (Particles, Camera Shake, Backgrounds)
- Phase 3: Power-Ups (15 types with timers)
- Phase 4: UI System & Game Flow (Complete menu system)
- Phase 5: Level System & Content (10 levels with progression)

### ✅ Phase 6: Progression Systems (COMPLETE)
- Save system with JSON persistence
- Statistics tracking (10 stats)
- Achievement system (12 achievements)
- Settings system (7 UI controls + difficulty persistence)
- Score multipliers (Difficulty, Combo, Streak, Double Score, Perfect Clear)
- Set mode with cumulative scoring and set high scores

### 📅 Phase 7: Audio System (FUTURE)
- Music tracks
- Sound effects (brick break, power-up, paddle hit, etc.)
- Audio buses and assets not yet implemented

### 📅 Phase 8: Advanced Features (FUTURE)
See `Tasks/Backlog/future-features.md` for detailed plans:
- Game Modes: Time Attack, Survival, Iron Ball, One Life
- QoL: Enhanced level select with star ratings, quick actions, skip options
- Advanced Gameplay: Ball speed zones, brick chains, paddle abilities

## Recent Update History

### 2026-01-30 (Latest) - Set Mode & Bomb Bricks
- ✅ **Set Mode**: Set Select + Set Complete screens, set-level flow
- ✅ **Set Data**: `data/level_sets.json` defines set(s)
- ✅ **Set Scoring**: Perfect set bonus (3x) and set high scores
- ✅ **Bomb Bricks**: Explosive bricks and bomb ball power-up (75px radius)
- ✅ **Expanded Power-Ups**: 15 types total, with HUD timers

### 2026-01-30 - Playtime Tracking + Game Over Fix
- ✅ **Playtime Tracking**: `total_playtime` now accumulates during READY/PLAYING and flushes every 5s
- ✅ **Games Played Tracking**: `total_games_played` increments per level start
- ✅ **Game Over Screen**: Fixed malformed `@onready` line for `high_score_label`

### 2026-01-30 - Set System Integration (from `temp/changelog.md`)
- ✅ **Set System**: Set Select + Set Complete screens, PlayMode enum, state persistence across set levels
- ✅ **Set Progression**: Set high scores and completion tracking
- ✅ **Perfect Set Bonus**: 3x multiplier when all lives intact and no continues
- ✅ **Continue Set**: Game Over allows resuming current set level (resets score/lives)
- ✅ **Settings**: Clear Save Data button with confirmation dialog
- ✅ **UI Fixes**: Combo label z-index below pause menu; set context UI in Level Select
- ✅ **Data Fixes**: SetLoader int conversion for set_id; `set_display_name` rename in set select
- ✅ **Gameplay Fix**: Paddle height bounds correctly update after expand/contract

### 2026-01-30 - Settings & Score Multipliers
- ✅ **Settings Menu**: 7 customizable options (shake, particles, trail, sensitivity, audio, difficulty)
- ✅ **Score Multipliers**: No-miss streak (+10%/5 hits), Perfect Clear (2x final score)
- ✅ **Multiplier HUD**: Real-time display of active bonuses with color coding

### 2026-01-29 - Statistics & Achievements
- ✅ **Statistics System**: 10 tracked stats (bricks, power-ups, combos, score, etc.)
- ✅ **Achievement System**: 12 achievements with progress tracking
- ✅ **Stats Screen**: Full UI for viewing statistics and achievements
- ✅ **Save Migration**: Automatic save file updates for old saves

### 2026-01-29 - Content Expansion
- ✅ **5 New Levels (6-10)**: Diamond Formation, Fortress, Pyramid of Power, Corridors, The Gauntlet
- ✅ **10 Total Levels**: Expanded content with special bricks
- ✅ **Enhanced UI**: Pause menu with level info, level intro animations, debug overlay

### 2026-01-29 - Core Systems
- ✅ **Complete Menu System**: Main Menu, Set Select, Level Select, Game Over, Level Complete screens
- ✅ **Level Progression**: Unlock system with high score tracking
- ✅ **SaveManager**: Persistent save data with JSON format
- ✅ **LevelLoader**: Dynamic level loading from JSON files
- ✅ **Combo System**: Consecutive hits with score bonuses
- ✅ **Difficulty System**: Easy/Normal/Hard with speed/score multipliers

## File Structure Overview
```
zepball/
├── .agent/                    # Documentation (this folder)
│   ├── README.md              # This file - documentation index
│   ├── System/
│   │   ├── architecture.md    # Complete system architecture ⭐ START HERE
│   │   └── tech-stack.md      # Technical configuration
│   ├── Tasks/
│   │   ├── Completed/         # Implemented feature plans
│   │   └── Backlog/           # Future work
│   └── SOP/
│       └── godot-workflow.md  # Development workflows + save migration ⚠️ IMPORTANT
├── project.godot              # Project config with autoloads
├── scenes/
│   ├── main/main.tscn         # Gameplay scene
│   ├── gameplay/              # Reusable components (ball, paddle, brick, power-up)
│   └── ui/                    # Menu screens (8 screens)
├── scripts/                   # All game logic (GDScript)
│   ├── main.gd                # Main gameplay controller
│   ├── [autoload singletons]  # 6 global systems
│   ├── [gameplay scripts]     # Ball, paddle, brick, power-up, camera shake, hud
│   └── ui/                    # Menu screen scripts
├── levels/                    # 10 level JSON files
├── data/                      # Set data JSON
└── assets/graphics/           # Sprites, backgrounds, power-ups
```

## Important Notes for Developers

### ⚠️ Save System Compatibility (CRITICAL)
**Always** add migration logic when modifying save data structure. See `SOP/godot-workflow.md` "Save System Compatibility" section for:
- When to add migration code
- Migration pattern template
- Testing checklist
- Real examples

**Example Migration**:
```gdscript
# In SaveManager.load_save()
if not save_data.has("new_field"):
    save_data["new_field"] = default_value
    save_to_disk()
```

### Settings Apply Limitation
Gameplay settings are loaded on scene `_ready()` (ball, paddle, camera). To apply these changes, users must:
1. Exit to main menu
2. Return to gameplay

Audio volume changes apply immediately via AudioServer.

### Known Issues
- Set unlocking is stubbed; `highest_unlocked_set` is always 1 and all sets are effectively unlocked.
- Debug logging is still verbose in multiple scripts.

### Complex Areas to Review
1. **Triple Ball Spawn** (`main.gd`) - Retry system with angle validation (120°-240°)
2. **Ball Stuck Detection** (`ball.gd`) - Dynamic threshold per-frame monitoring
3. **Save Migration** (`save_manager.gd`) - Automatic field addition
4. **Scene Transitions** (`brick.gd`) - Check `is_inside_tree()` before await
5. **Physics Callbacks** (`main.gd`) - Use `call_deferred()` for spawns

## Doc Status Summary
- **System Docs**: `System/architecture.md`, `System/tech-stack.md` (current)
- **Completed Tasks**: Implemented features documented in `Tasks/Completed/`
- **Backlog**: Open items tracked in `Tasks/Backlog/`
- **SOP**: `SOP/godot-workflow.md` for workflows and save migration

## Getting Help
- **Architecture Questions**: See `System/architecture.md`
- **Development Workflow**: See `SOP/godot-workflow.md`
- **Future Features**: See `Tasks/Backlog/future-features.md`
- **Godot Help**: https://docs.godotengine.org/en/stable/

---

**Last Updated**: 2026-01-30
**Total Levels**: 10
**Total Sets**: 1
**Total Achievements**: 12
**Documentation Status**: ✅ Up-to-date with current codebase
