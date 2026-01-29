# UI System Implementation Plan

## Status: ✅ FULLY IMPLEMENTED

## Overview
The UI system manages all menus, HUDs, and on-screen displays. Complete menu flow with progression system implemented.

## Key Components

### 1. Main Menu ✅ IMPLEMENTED
The entry point of the game.
- **Title**: Large "ZEP BALL" logo.
- **Play Button**: Starts the game.
- **Difficulty Selection**:
  - **Easy**: Slower ball speed (e.g., x0.8).
  - **Normal**: Standard speed (x1.0).
  - **Hard**: Faster ball speed (x1.2).
- **Options**: Volume controls (Music, SFX).
- **Quit**: Exit game.

### 2. HUD (Implemented)
- **Score**: Current score.
- **Lives**: Remaining lives.
- **Power-up Status**: Active timed effects with countdown text.
- **Difficulty Indicator**: ✅ Shows current difficulty in top-right corner.
- **Combo Counter**: ✅ Shows combo multiplier (visible at 3+ combo).
- **Pause Indicator**: "PAUSED" label shown when game state is paused.
- **Game State Overlays**: ✅ Game Over and Level Complete text overlays.

### 3. Level Selection ✅ IMPLEMENTED
A grid or list of available levels.
- **Unlock System**: Levels unlock as you complete previous ones.
- **High Scores**: Show personal best for each level.

### 4. Game Over / Level Complete ✅ IMPLEMENTED
- **Game Over Screen**:
  - Final Score.
  - "Retry" button.
  - "Main Menu" button.
- **Level Complete Screen**:
  - Score summary (Accuracy, Time Bonus).
  - "Next Level" button.

## Visual Style (Planned)
- **Theme**: Robotic, Sci-Fi, Retro Arcade.
- **Colors**: Neon blues, pinks, and dark metals.
- **Animations**: Smooth transitions, button hover effects.

## Implementation Details

### Scenes (Planned)
- `scenes/ui/main_menu.tscn`
- `scenes/ui/level_select.tscn`
- `scenes/ui/game_over.tscn`
- `scenes/ui/settings.tscn`

### Scripts
- `scripts/ui/menu_controller.gd`: Handles navigation (Planned).
- `scripts/difficulty_manager.gd`: **✅ IMPLEMENTED** - Autoload singleton managing difficulty settings.

## Tasks
- [x] HUD shows power-up timers and pause indicator
- [x] **Add difficulty selection logic (Easy/Normal/Hard)** - DifficultyManager singleton implemented
- [x] **Add difficulty indicator to HUD** - Shows current difficulty in top-right corner
- [x] **Add combo counter to HUD** - Shows combo multiplier with visual feedback
- [x] **Add a restart flow (R key input)** - Players can press R to restart level
- [x] **Add game over/level complete overlays** - Simple text overlays with instructions
- [x] **Create Main Menu scene with Difficulty Selector UI** - ✅ DONE
- [x] **Persist difficulty selection across sessions** - ✅ DONE via SaveManager
- [x] **Upgrade Game Over / Level Complete to full scenes** - ✅ DONE
- [x] **Implement scene management for UI/gameplay transitions** - ✅ DONE via MenuController
- [x] **Create Level Selection screen** - ✅ DONE with unlock system
- [x] **Enhanced pause screen** - ✅ DONE - Full menu with Resume/Restart/Main Menu buttons
- [x] **FPS/Debug overlay** - ✅ DONE - Toggle with F3, shows FPS/velocity/speed/balls/combo
- [x] **Ball launch direction indicator** - ✅ DONE - Cyan arrow shows launch direction with spin
- [x] **Level name display** - ✅ DONE - Beautiful fade in/out intro when level starts
- [ ] Add audio volume controls (SFX/Music) once audio system exists

## Phase 4 Detailed Plan (UI and Game Flow)

### 1. Scene Architecture
- Create UI scenes under `scenes/ui/`:
  - `main_menu.tscn`
  - `game_over.tscn`
  - `level_complete.tscn`
  - `pause_menu.tscn` (optional if pause indicator is not enough)
- Use a single `MenuController` to load/unload UI scenes and route button actions.

### 2. Main Menu
- Title, Play, Difficulty selector (Easy/Normal/Hard), Options, Quit.
- **✅ BACKEND READY**: `DifficultyManager` singleton implemented with three levels:
  - Easy: 0.8x speed, 0.8x score
  - Normal: 1.0x speed, 1.0x score
  - Hard: 1.2x speed, 1.5x score
- **✅ DIFFICULTY LOCKING**: Difficulty is locked during gameplay, only changeable in main menu.
- **DEBUG CONTROLS**: E/N/H keys toggle difficulty (debug build only, temporary until main menu exists).
- TODO: Create UI scene for difficulty selection.
- Play should transition to the gameplay scene, lock difficulty, and set state to `READY`.

### 3. Game Over and Level Complete
- Game Over:
  - Final score
  - Retry (reload main scene)
  - Main Menu (return to menu scene)
- Level Complete:
  - Current score summary
  - Next Level (placeholder until level system exists)
  - Main Menu

### 4. Restart Flow (No F5) ✅ IMPLEMENTED
- **✅ DONE**: R key input action added to restart game (`main.gd:221`).
- **✅ DONE**: `restart_game` input action registered in `project.godot`.
- TODO: Add UI button to restart (for game over/level complete screens).

### 5. Pause Menu (Optional)
- Replace the simple PAUSED label with a minimal menu:
  - Resume
  - Restart
  - Main Menu

### 6. Audio Controls
- Add sliders to Settings menu for SFX/Music volume.
- Wire to `AudioManager` once implemented (see `Tasks/audio-system.md`).

### 7. Wiring and Signals
- `GameManager.game_over` -> show `game_over.tscn`.
- `GameManager.level_complete` -> show `level_complete.tscn`.
- `GameManager.state_changed` -> toggle pause menu or pause indicator.
- Menu buttons call `MenuController` methods for scene changes.

## Acceptance Criteria
- [ ] Player can start the game from a main menu.
- [x] **Player can restart without pressing F5** (R key implemented).
- [ ] Game over and level complete screens appear at the right time.
- [x] **Difficulty selection affects gameplay variables** (speed + score multipliers working).
- [ ] Difficulty persists across sessions.
- [ ] Audio sliders change SFX/Music volume once audio exists.

## Recent Progress (2026-01-29)
- ✅ Restart handler implemented (R key) - no F5 needed
- ✅ DifficultyManager singleton created with speed/score multipliers
- ✅ Debug controls for difficulty testing (E/N/H keys)

## Expanded TODOs from README
- No main menu -> Main Menu scene and routing (see tasks above).
- Game over screen needs UI -> Game Over screen with retry/main menu.
- Level complete screen needs UI -> Level Complete screen with next level.
- ~~No way to restart without F5~~ -> ✅ R key restart implemented.
- No audio yet -> See `Tasks/audio-system.md`.

## Related Docs
- `Tasks/audio-system.md`
