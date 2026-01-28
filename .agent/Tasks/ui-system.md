# UI System Implementation Plan

## Overview
The UI system manages all menus, HUDs, and on-screen displays. It serves as the bridge between the player and the game mechanics.

## Key Components

### 1. Main Menu
The entry point of the game.
- **Title**: Large "ZEP BALL" logo.
- **Play Button**: Starts the game.
- **Difficulty Selection**:
  - **Easy**: Slower ball speed (e.g., x0.8).
  - **Normal**: Standard speed (x1.0).
  - **Hard**: Faster ball speed (x1.2).
- **Options**: Volume controls (Music, SFX).
- **Quit**: Exit game.

### 2. HUD (Heads-Up Display)
Already partially implemented. Needs to support new features.
- **Score**: Current score.
- **Lives**: Remaining lives.
- **Power-up Status**: Icons showing active power-ups and their remaining duration (progress bars or circular timers).
- **Level Info**: Current level number.

### 3. Level Selection
A grid or list of available levels.
- **Unlock System**: Levels unlock as you complete previous ones.
- **High Scores**: Show personal best for each level.

### 4. Game Over / Level Complete
- **Game Over Screen**:
  - Final Score.
  - "Retry" button.
  - "Main Menu" button.
- **Level Complete Screen**:
  - Score summary (Accuracy, Time Bonus).
  - "Next Level" button.

## Visual Style
- **Theme**: Robotic, Sci-Fi, Retro Arcade.
- **Colors**: Neon blues, pinks, and dark metals.
- **Animations**: Smooth transitions, button hover effects.

## Implementation Details

### Scenes
- `scenes/ui/main_menu.tscn`
- `scenes/ui/level_select.tscn`
- `scenes/ui/game_over.tscn`
- `scenes/ui/settings.tscn`

### Scripts
- `scripts/ui/menu_controller.gd`: Handles navigation.
- `scripts/ui/difficulty_manager.gd`: Stores selected difficulty.

## Tasks
- [ ] Create Main Menu scene with Difficulty Selector.
- [ ] Update HUD to show Power-up timers.
- [ ] Implement Game Over / Level Complete screens.
- [ ] Create Level Selection screen.
