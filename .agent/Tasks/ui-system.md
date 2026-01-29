# UI System Implementation Plan

## Status: 🔶 PARTIALLY IMPLEMENTED

## Overview
The UI system manages all menus, HUDs, and on-screen displays. The in-game HUD is implemented; menus and flow screens are still pending.

## Key Components

### 1. Main Menu (Planned)
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
- **Pause Indicator**: "PAUSED" label shown when game state is paused.

### 3. Level Selection (Planned)
A grid or list of available levels.
- **Unlock System**: Levels unlock as you complete previous ones.
- **High Scores**: Show personal best for each level.

### 4. Game Over / Level Complete (Planned)
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

### Scripts (Planned)
- `scripts/ui/menu_controller.gd`: Handles navigation.
- `scripts/ui/difficulty_manager.gd`: Stores selected difficulty.

## Tasks
- [x] HUD shows power-up timers and pause indicator.
- [ ] Create Main Menu scene with Difficulty Selector.
- [ ] Add difficulty selection logic (Easy/Normal/Hard) and persist selection.
- [ ] Implement pause menu (resume/restart/main menu) or expand pause overlay.
- [ ] Implement Game Over / Level Complete screens.
- [ ] Implement scene management for UI/gameplay transitions.
- [ ] Create Level Selection screen.
- [ ] Add a restart flow (Retry button or input) so players don't need to press F5.
- [ ] Add audio volume controls (SFX/Music) once audio system exists.

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
- Difficulty choice should write to a shared setting node (e.g., `DifficultyManager` singleton).
- Play should transition to the gameplay scene and set state to `READY`.

### 3. Game Over and Level Complete
- Game Over:
  - Final score
  - Retry (reload main scene)
  - Main Menu (return to menu scene)
- Level Complete:
  - Current score summary
  - Next Level (placeholder until level system exists)
  - Main Menu

### 4. Restart Flow (No F5)
- Add retry input (e.g., R key) and/or a UI button to restart.
- Implement in `MenuController` or in `main.gd` (but keep flow consistent).

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
- Player can start the game from a main menu.
- Player can restart without pressing F5.
- Game over and level complete screens appear at the right time.
- Difficulty selection affects gameplay variables (ball speed multiplier).
- Audio sliders change SFX/Music volume once audio exists.

## Expanded TODOs from README
- No main menu -> Main Menu scene and routing (see tasks above).
- Game over screen needs UI -> Game Over screen with retry/main menu.
- Level complete screen needs UI -> Level Complete screen with next level.
- No way to restart without F5 -> Add retry button and/or input handler.
- No audio yet -> See `Tasks/audio-system.md`.

## Related Docs
- `Tasks/audio-system.md`
