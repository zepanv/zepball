# Zep Ball - Documentation Index

This folder contains the canonical documentation for the Zep Ball codebase.

## Documentation Structure

### System/
Current system state, architecture, and technical foundation.
- `System/architecture.md` - Project architecture, scene graph, core systems, and gameplay flow.
- `System/tech-stack.md` - Engine, settings, input map, and runtime configuration.

### Tasks/
PRDs and implementation plans for individual features.
- `Tasks/core-mechanics.md` - Paddle, ball, and collision system design.
- `Tasks/tile-system.md` - Brick/tile system plan.
- `Tasks/level-system.md` - Level data, loader, and progression plan.
- `Tasks/power-ups.md` - Power-up system design and implementation plan.
- `Tasks/ui-system.md` - UI, menus, and HUD plans.
- `Tasks/audio-system.md` - Audio system plan (SFX, music, and volume controls).
- `Tasks/save-system.md` - Save data, high scores, and persistence plan.

### SOP/
Best practices and workflows for development.
- `SOP/godot-workflow.md` - Working with Godot scenes, nodes, and signals.

## Project Snapshot
- **Genre**: Breakout/arkanoid-style 2D game with a right-side paddle.
- **Current gameplay**: Paddle movement, ball physics with spin, brick breaking, score/lives, pause, power-ups, and HUD.
- **Difficulty system**: ✅ Easy/Normal/Hard modes with speed and score multipliers (DifficultyManager autoload).
- **Combo system**: ✅ Consecutive brick hits build combo multiplier with bonus points.
- **HUD elements**: Score, lives, power-up timers, difficulty indicator, combo counter, pause/game over/level complete overlays.
- **Restart**: ✅ R key to restart game without F5.
- **Level system**: A test grid is generated at runtime. ✅ 5 JSON level files created (not yet loaded).
- **Persistence**: No save system or database implemented.

## Tech Stack Snapshot
- **Engine**: Godot 4.6 (project config features include 4.6).
- **Language**: GDScript.
- **Main scene**: `res://scenes/main/main.tscn`.

## Quick Links
- `System/architecture.md`
- `System/tech-stack.md`
- `Tasks/core-mechanics.md`
- `SOP/godot-workflow.md`

## Roadmap Snapshot
- Phase 1: Core Mechanics ✅
- Phase 2: Visual Polish ✅
- Phase 3: Core Power-ups ✅
- Phase 4: UI System & Game Flow ⏳ (Restart + Difficulty backend done, UI scenes pending)
- Phase 5: Level System & Content ⏳ (5 level files created, loader pending)
- Phase 6: Audio System 📅
- Phase 7: Advanced Features 📅

## Recent Updates (2026-01-29)
- ✅ **Restart handler** - R key to restart game (no F5 needed)
- ✅ **Difficulty system** - DifficultyManager singleton with Easy/Normal/Hard modes
- ✅ **Difficulty indicator** - HUD shows current difficulty in top-right corner
- ✅ **Game state overlays** - Game Over and Level Complete messages with instructions
- ✅ **Combo system** - Consecutive hits build multiplier (10% bonus per hit after 3x)
- ✅ **Level data files** - 5 unique JSON levels created in `levels/` folder
- ✅ **Code quality** - Named constants, input actions, improved documentation

## Quick Wins Implemented
These simple tasks were completed to improve the game without requiring major system changes:

### Session 1 (2026-01-29 Morning)
1. **Restart handler (R key)** - Added `restart_game` input action for instant restarts
2. **Difficulty system** - Backend fully implemented with speed/score multipliers
3. **Level data files** - 5 JSON level layouts created and documented
4. **Code quality** - Constants, better comments, cleaner input handling

### Session 2 (2026-01-29 Afternoon)
5. **Difficulty indicator** - HUD shows current difficulty in top-right corner
6. **Game state overlays** - Game Over and Level Complete text with instructions
7. **Combo system** - Consecutive hits build multiplier (10% bonus per hit after 3x)

## Pending Quick Wins (Integrated into Task Files)
The following quick wins have been identified and integrated into the appropriate task files for future implementation:
- Enhanced pause screen with control hints → `Tasks/ui-system.md`
- FPS/debug overlay → `Tasks/ui-system.md`
- Ball launch direction indicator → `Tasks/ui-system.md`
- Level name display on start → `Tasks/ui-system.md`
- Slow Down, Extra Life, Big/Small Ball power-ups → `Tasks/power-ups.md`
- JSON level loader → `Tasks/level-system.md`
- Basic level progression → `Tasks/level-system.md`
- Particle color matching → `Tasks/tile-system.md`
- Sound event placeholder system → `Tasks/audio-system.md`

---

Last Updated: 2026-01-29 (Restart, Difficulty, Level Files)
