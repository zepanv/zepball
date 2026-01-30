# UI System

## Status: ✅ IMPLEMENTED (core UI, minor gaps)

## Overview
The UI system manages menus, HUD, and overlays. Scene transitions are handled by MenuController, and gameplay UI reacts to GameManager signals.

## Implemented Screens
- **Main Menu** (`scenes/ui/main_menu.tscn`): Play, difficulty selection, stats, settings, quit.
- **Level Select** (`scenes/ui/level_select.tscn`): Unlock status + high scores.
- **Game Over** (`scenes/ui/game_over.tscn`).
- **Level Complete** (`scenes/ui/level_complete.tscn`): Score breakdown (base + bonuses + time).
- **Stats** (`scenes/ui/stats.tscn`).
- **Settings** (`scenes/ui/settings.tscn`): screen shake, particles, trail, sensitivity, music/SFX volumes.

## Implemented HUD Elements
- Score and lives top bar.
- Difficulty label (top-left).
- Combo counter with milestone bounce.
- Multiplier display (difficulty/combo/streak).
- Power-up timers (top-right).
- Pause menu overlay.
- Level intro fade in/out.
- Debug overlay (toggle with backtick `).

## Scene Management
- `scripts/ui/menu_controller.gd` controls transitions and flow.
- Difficulty locking/unlocking is handled when entering/leaving gameplay.

## Known Gaps (Tracked in Backlog)
- Launch direction indicator is currently disabled in `scripts/ball.gd`.

See `Tasks/Backlog/ui-gaps.md`.

## Related Docs
- `Tasks/Backlog/audio-system.md`
- `Tasks/Backlog/ui-gaps.md`
- `System/architecture.md`
