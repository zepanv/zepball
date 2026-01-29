# Zep Ball - Documentation Index

This folder contains the canonical documentation for the Zep Ball codebase. All documentation is kept up-to-date to reflect the current state of the game.

## Documentation Structure

### System/
Current system state, architecture, and technical foundation.
- **`System/architecture.md`** - Complete project architecture, autoload systems, core gameplay systems, scene graph, scoring mechanics, menu flow, and all implemented features. **Read this first for full context.**
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
  - `Tasks/Backlog/power-up-expansion.md` - Additional power-ups beyond the current four
  - `Tasks/Backlog/tile-advanced-elements.md` - Force zones, special bricks, and advanced tile behaviors
  - `Tasks/Backlog/ui-gaps.md` - Launch indicator + level complete breakdown

### SOP/
Best practices and workflows for development.
- **`SOP/godot-workflow.md`** - Working with Godot scenes, nodes, signals, and **CRITICAL: Save System Compatibility** section for handling save data migrations.

## Current Game State (2026-01-29 15:27 EST)

### Core Features ✅ COMPLETE
- **Gameplay**: Paddle movement (keyboard + mouse), ball physics with spin, 9 brick types, collision detection, score tracking
- **Power-Ups**: 4 types (Expand, Contract, Speed Up, Triple Ball) with visual timers
- **Difficulty**: 3 modes (Easy/Normal/Hard) with speed and score multipliers
- **Levels**: 10 unique levels with creative patterns and increasing difficulty
- **Menu System**: Complete flow (Main Menu, Level Select, Game Over, Level Complete, Stats, Settings)
- **Progression**: Level unlocking - complete one to unlock the next
- **Save System**: Persistent data for progress, high scores, statistics, achievements, and settings

### Statistics & Achievements ✅ COMPLETE
- **8 Tracked Stats**: Bricks broken, power-ups collected, levels completed, playtime, highest combo, highest score, games played, perfect clears
- **12 Achievements**: Ranging from "First Blood" (1 brick) to "Champion" (all 10 levels) with progress tracking
- **Stats Screen**: Full statistics display with achievement list and progress bars
- **Note**: `total_playtime` and `total_games_played` are displayed but not currently incremented in gameplay code.

### Settings System ✅ COMPLETE
- **Gameplay Settings (6)**:
  - Screen shake intensity (Off/Low/Medium/High)
  - Particle effects toggle
  - Ball trail toggle
  - Paddle sensitivity (0.5x - 2.0x)
  - Music volume (-40dB to 0dB)
  - SFX volume (-40dB to 0dB)
- **Difficulty** is selected in the main menu and persisted in SaveManager.
- **All settings persist** via SaveManager with automatic migration

### Score Multipliers ✅ COMPLETE
- **Difficulty Multiplier**: 0.8x (Easy), 1.0x (Normal), 1.5x (Hard)
- **Combo Multiplier**: 10% bonus per hit after 3x combo (e.g., 12x combo = 2.0x multiplier)
- **No-Miss Streak**: 10% bonus per 5 consecutive hits without losing ball (e.g., 15 hits = 1.3x multiplier)
- **Perfect Clear**: 2x final score bonus for completing level with all 3 lives intact
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
- **Autoloads**: PowerUpManager, DifficultyManager, SaveManager, LevelLoader, MenuController

## Autoload Singletons (Global Systems)
These are always accessible and control key game systems:
1. **PowerUpManager** - Timed power-up effects
2. **DifficultyManager** - Difficulty modes with multipliers
3. **SaveManager** - Save data, statistics, achievements, settings
4. **LevelLoader** - Level JSON loading
5. **MenuController** - Scene transitions and game flow

## Quick Start for New Developers
1. **Read** `System/architecture.md` - Complete system overview with all features documented
2. **Check** `SOP/godot-workflow.md` - Development workflows and **save migration best practices**
3. **Explore** `Tasks/Backlog/future-features.md` - See what's planned for future development
4. **Note**: Save system has automatic migration - see SOP for how to add new fields safely

## Development Roadmap

### ✅ Phase 1-5: Core Game (COMPLETE)
- Phase 1: Core Mechanics (Paddle, Ball, Bricks, Collision)
- Phase 2: Visual Polish (Particles, Camera Shake, Backgrounds)
- Phase 3: Power-Ups (4 types with timers)
- Phase 4: UI System & Game Flow (Complete menu system)
- Phase 5: Level System & Content (10 levels with progression)

### ✅ Phase 6: Progression Systems (COMPLETE)
- Save system with JSON persistence
- Statistics tracking (8 stats)
- Achievement system (12 achievements)
- Settings system (6 UI controls + difficulty persistence)
- Score multipliers (Difficulty, Combo, Streak, Perfect Clear)

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

### 2026-01-29 (Latest) - Settings & Score Multipliers
- ✅ **Settings Menu**: 6 customizable options (shake, particles, trail, sensitivity, audio)
- ✅ **Score Multipliers**: No-miss streak (+10%/5 hits), Perfect Clear (2x final score)
- ✅ **Multiplier HUD**: Real-time display of active bonuses with color coding
- ✅ **Bug Fixes**: Ball stuck detection, integer division warnings, HUD overlap

### 2026-01-29 - Statistics & Achievements
- ✅ **Statistics System**: 8 tracked stats (bricks, power-ups, combos, score, etc.)
- ✅ **Achievement System**: 12 achievements with progress tracking
- ✅ **Stats Screen**: Full UI for viewing statistics and achievements
- ✅ **Save Migration**: Automatic save file updates for old saves

### 2026-01-29 - Content Expansion
- ✅ **5 New Levels (6-10)**: Diamond Formation, Fortress, Pyramid, Corridors, The Gauntlet
- ✅ **10 Total Levels**: Doubled content with creative patterns
- ✅ **Enhanced UI**: Pause menu with level info, level intro animations, debug overlay

### 2026-01-29 - Core Systems
- ✅ **Complete Menu System**: Main Menu, Level Select, Game Over, Level Complete screens
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
│   └── ui/                    # Menu screens (6 screens)
├── scripts/                   # All game logic (GDScript)
│   ├── main.gd                # Main gameplay controller
│   ├── [autoload singletons]  # 5 global systems
│   ├── [gameplay scripts]     # Ball, paddle, brick, power-up, camera shake, hud
│   └── ui/                    # Menu screen scripts
├── levels/                    # 10 level JSON files
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
Settings are loaded on scene `_ready()`. To apply setting changes, users must:
1. Exit to main menu
2. Return to gameplay

This affects: screen shake, particles, trail, paddle sensitivity.

### Complex Areas to Review
1. **Triple Ball Spawn** (`main.gd:279-347`) - Retry system with angle validation
2. **Ball Stuck Detection** (`ball.gd:287-325`) - Dynamic threshold per-frame monitoring
3. **Save Migration** (`save_manager.gd:160-180`) - Automatic field addition
4. **Scene Transitions** (`brick.gd:190`) - Check `is_inside_tree()` before await
5. **Physics Callbacks** (`main.gd:276`) - Use `call_deferred()` for spawns

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

**Last Updated**: 2026-01-29 15:27 EST (Docs refresh and tasks reorg)
**Total Levels**: 10
**Total Achievements**: 12
**Documentation Status**: ✅ Up-to-date with all implemented features
