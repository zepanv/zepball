# Zep Ball - Documentation Index

This folder contains the canonical documentation for the Zep Ball codebase. All documentation is kept up-to-date to reflect the current state of the game.

## Documentation Structure

### ⚠️ CRITICAL: Always Follow the SOP
**The Standard Operating Procedures (SOP) in `SOP/godot-workflow.md` must be followed at all times.** This document contains mandatory workflows, best practices, and critical procedures that ensure consistency, prevent bugs, and maintain documentation accuracy. Key SOP requirements include:
- **Save System Compatibility** - Always add migration logic when modifying save data
- **Asset Documentation** - Update `used-assets.md` and `unused-assets.md` when adding/removing assets
- **Commit Message Format** - Follow the required format for all commits
- **Testing Checklists** - Complete all checklists before committing

**When in doubt, refer to the SOP. It is the single source of truth for development workflows.**

### Project README
High-level, less technical overview for players and general readers.
- **`../README.md`** - Main project README; keep updated when appropriate.

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
  - `Tasks/Completed/power-up-expansion.md` - Additional power-ups beyond the current 16 ✅ IMPLEMENTED
  - `Tasks/Completed/ui-system.md` - UI, menus, and HUD plans ✅ IMPLEMENTED
  - `Tasks/Completed/save-system.md` - Save data, high scores, and persistence plan ✅ IMPLEMENTED
  - `Tasks/Completed/audio-system.md` - Audio system plan (SFX, music) ✅ IMPLEMENTED
  - `Tasks/Completed/keybinding-menu.md` - Keybinding menu and input map persistence ✅ IMPLEMENTED
  - `Tasks/Completed/settings-enhancements.md` - Settings QoL expansions ✅ IMPLEMENTED
  - `Tasks/Completed/quick-actions.md` - Menu/gameplay convenience actions ✅ IMPLEMENTED
  - `Tasks/Completed/optimization-pass.md` - Performance and architecture optimization audit ✅ IMPLEMENTED
  - `Tasks/Completed/ui-gaps.md` - Launch indicator (aim mode) ✅ IMPLEMENTED
  - `Tasks/Completed/level-overhaul.md` - Pack-format migration, in-game editor, pack/level UX overhaul, third built-in pack ✅ IMPLEMENTED
  - `Tasks/Completed/skip-options.md` - Input-based intro skip, fast-forward level complete, quick restart ✅ IMPLEMENTED
  - `Tasks/Completed/advanced-tile-elements.md` - Force arrows, power-up bricks, persistent spin, penetrating spin ✅ IMPLEMENTED
  - `Tasks/Completed/player-profiles.md` - Player profile system and local high scores comparison ✅ IMPLEMENTED
  - `Tasks/Completed/bugfixes-and-pack-ui.md` - Combo/streak reset fix, paddle X-lock, Pack Select filters/sorts ✅ IMPLEMENTED
- **`Tasks/Backlog/`** - Not yet implemented or future work.
  - **`Tasks/Backlog/future-features.md`** - Remaining planned features (Time Attack, Survival, Ball Speed Zones, Brick Chains, Paddle Abilities, hardcore modes)

### SOP/
Best practices and workflows for development. **These procedures are mandatory and must be followed for all development work.**
- **`SOP/godot-workflow.md`** - **MANDATORY** workflows including: Godot scenes/nodes/signals, **Asset Documentation** (update docs when adding/removing assets), **CRITICAL: Save System Compatibility** (migration requirements), and commit message formats.

## Current Game State (2026-02-15)

### Core Features ✅ COMPLETE
- **Gameplay**: Paddle movement (keyboard + mouse), ball physics with persistent/decaying spin, enhanced spin system with visual curve effects and penetrating spin, 16 brick types, collision detection, score tracking
- **Power-Ups**: 16 types with visual timers and effects (Expand, Contract, Speed Up, Slow Down, Triple Ball, Big/Small Ball, Extra Life, Grab, Brick Through, Double Score, Mystery, Bomb Ball, Air Ball, Magnet, Block)
- **Special Bricks/Tiles**:
  - Bomb bricks (AoE break)
  - Force Arrow tiles (non-collidable directional force fields with charge-up mechanic, pulsing visuals, and audio feedback)
  - Power-up Bricks (instant power-up grant on pass-through contact, all 16 types available)
- **Difficulty**: 3 modes (Easy/Normal/Hard) with speed and score multipliers
- **Levels**: 30 built-in levels with varied brick mixes (bomb bricks appear across all sets)
- **Menu System**: Complete flow (Main Menu, Set Select, Level Select, Game Over, Level Complete, Set Complete, Stats, Settings)
- **Progression**: Level unlocking and high scores saved per level

### Set Mode ✅ COMPLETE
- **Set Data**: Built-in sets are defined by `.zeppack` metadata in `packs/` (no `level_sets.json` runtime dependency)
- **Pack Foundation**: Set and level flows are fully pack-native via `PackLoader`
- **Current Sets**: 3 sets
  - **Classic Challenge** (levels 1–10)
  - **Prism Showcase** (levels 11–20)
  - **Nebula Ascend** (levels 21–30)
- **Set Select**: Play set or view its levels; filter by ALL/OFFICIAL/CUSTOM; sort by ORDER or PROGRESSION
- **Set Progression**: Score/lives carry across set levels; combo/streak reset each level; perfect status tracked for 3x bonus
- **Set Completion Bonus**: 3x score if all lives intact and no continues
- **Set High Scores**: Saved separately from individual level scores

### Statistics & Achievements ✅ COMPLETE
- **10 Tracked Stats**: Bricks broken, power-ups collected, levels completed, individual levels completed, set runs completed, playtime, highest combo, highest score, games played, perfect clears
- **12 Achievements**: Ranging from "First Blood" (1 brick) to "Champion" (30 level completions) with progress tracking
- **Stats Screen**: Full statistics display with achievement list and progress bars
- **Tracking**: `total_playtime` increments during READY/PLAYING (flushed every 5s), and `total_games_played` increments per level start

### Settings System ✅ COMPLETE
- **Gameplay Settings (12)**:
  - Screen shake intensity (Off/Low/Medium/High)
  - Particle effects toggle
  - Ball trail toggle
  - Combo flash toggle
  - Skip level intro toggle
  - Show FPS toggle
  - Paddle sensitivity (0.5x - 2.0x)
  - Music volume (-40dB to 0dB)
  - SFX volume (-40dB to 0dB)
  - Music playback mode (Off / Loop One / Loop All / Shuffle)
  - Music loop-one track selection
  - Difficulty (Easy/Normal/Hard) saved from Main Menu
- **All settings persist** via SaveManager with automatic migration
- **Audio settings apply immediately**; gameplay settings apply on next scene load unless changed via pause overlay (live apply)

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
- **Enhanced Pause Menu**: Level info, Resume, Restart, Settings, Level Select, Main Menu buttons
- **Level Intro**: Fade in/out animation with level name and description (2.0s total: 0.5s fade in + 1.0s hold + 0.5s fade out)
- **Debug Overlay**: FPS, ball stats, combo (toggle with backtick ` key when enabled)
- **HUD Elements**: Score, lives, difficulty label, combo counter (with elastic bounce at milestones), multiplier display, power-up timers
- **Launch Aim Indicator**: Right-mouse hold locks paddle and aims first shot per life
- **Quick Actions**: Play Again button on level complete, Return to Last Level on main menu
- **Skip Options**: Space during intro skips it, Enter on level complete/game over advances/retries (0.5s guard delay)

## Tech Stack
- **Engine**: Godot 4.6
- **Language**: GDScript
- **Run Main Scene**: `res://scenes/ui/main_menu.tscn`
- **Gameplay Scene**: `res://scenes/main/main.tscn`
- **Autoloads**: PowerUpManager, DifficultyManager, SaveManager, AudioManager, PackLoader, MenuController

## Autoload Singletons (Global Systems)
These are always accessible and control key game systems:
1. **PowerUpManager** - Timed power-up effects
2. **DifficultyManager** - Difficulty modes with multipliers
3. **SaveManager** - Save data, statistics, achievements, settings
4. **AudioManager** - Music/SFX playback and audio bus setup
5. **PackLoader** - `.zeppack` discovery/loading/instantiation (foundation stage)
6. **MenuController** - Scene transitions and game flow

## Quick Start for New Developers
1. **Read** `System/architecture.md` - Complete system overview with all features documented
2. **Read and Follow** `SOP/godot-workflow.md` - **Mandatory development workflows** including save migration, asset documentation, and commit procedures
3. **Explore** `Tasks/Backlog/future-features.md` - Planned future development
4. **Note**: Save system has automatic migration - see SOP for how to add new fields safely

## Development Roadmap

### ✅ Phase 1-5: Core Game (COMPLETE)
- Phase 1: Core Mechanics (Paddle, Ball, Bricks, Collision)
- Phase 2: Visual Polish (Particles, Camera Shake, Backgrounds)
- Phase 3: Power-Ups (16 types with timers)
- Phase 4: UI System & Game Flow (Complete menu system)
- Phase 5: Level System & Content (30 built-in levels with progression)

### ✅ Phase 6: Progression Systems (COMPLETE)
- Save system with JSON persistence
- Statistics tracking (10 stats)
- Achievement system (12 achievements)
- Settings system (9 UI controls + difficulty persistence)
- Score multipliers (Difficulty, Combo, Streak, Double Score, Perfect Clear)
- Set mode with cumulative scoring and set high scores

### ✅ Phase 7: Audio System (COMPLETE)
- AudioManager autoload (music playback + SFX helpers)
- Music modes: Off, Loop One, Loop All, Shuffle
- Crossfades between tracks (Loop All / Shuffle)
- Settings UI for music mode + loop-one track selection
- SFX: paddle hit, brick hit, wall hit, power-up good/bad, life lost, combo milestone, level complete, game over

### ✅ Phase 8: Advanced Tile Elements (COMPLETE)
- ✅ Enhanced Spin - Persistent spin state with visual curve effects, decay, and trail color changes
- ✅ Penetrating Spin - High-spin balls pass through breakable bricks
- ✅ Force Arrow Tiles - Non-collidable directional force fields with charge-up, pulsing visuals, and audio
- ✅ Power-up Bricks - Pass-through instant power-up tiles (all 16 types)
- ✅ Schema v2 - Backward-compatible pack format with new brick metadata
- ✅ Editor Support - Full palette, direction/power-up pickers, save/load

### 📅 Phase 9: Future Features (PLANNED)
- Remaining roadmap in `Tasks/Backlog/future-features.md`:
- Game Modes: Time Attack, Survival, Iron Ball, One Life
- Advanced Gameplay: Ball speed zones, brick chains, paddle abilities

## Recent Updates

**Latest:** 2026-02-15 - Bugfixes & Pack Select UI Enhancements (combo/streak reset fix, paddle X-lock, pack filters/sorting)

For complete update history, see `CHANGELOG.md`.

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
│   ├── main_background_manager.gd # Gameplay background helper
│   ├── main_power_up_handler.gd # Gameplay power-up effect helper
│   ├── ball_air_ball_helper.gd # Air-ball runtime helper
│   ├── [autoload singletons]  # 7 global systems
│   ├── [gameplay scripts]     # Ball, paddle, brick, power-up, camera shake, hud
│   └── ui/                    # Menu screen scripts
├── levels/                    # 10 level JSON files
├── data/                      # Set data JSON
├── assets/
│   ├── audio/                 # Music + SFX
│   └── graphics/              # Sprites, backgrounds, power-ups
```

## Important Notes for Developers

### ⚠️ Critical Workflows
**ALWAYS follow these procedures** - See `SOP/critical-workflows.md`:
- **Save System Compatibility**: Add migration logic when modifying save data
- **Asset Documentation**: Update docs when adding/removing assets
- **Commit Message Format**: Follow the required format

### Settings Apply Limitation
Gameplay settings are loaded on scene `_ready()` (ball, paddle, camera). To apply these changes, users must:
1. Exit to main menu
2. Return to gameplay

Audio settings (volume + music mode/track) apply immediately via AudioServer/AudioManager.
Pause overlay settings apply live for paddle sensitivity, ball trail, combo flash, level intro toggles, and FPS display.

### Known Issues
- Set unlocking is stubbed; `highest_unlocked_set` is always 1 and all sets are effectively unlocked.

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

**Last Updated**: 2026-02-15
**Total Levels**: 30
**Total Sets**: 3
**Total Achievements**: 12
**Documentation Status**: ✅ Up-to-date with current codebase
