# Skip Options

## Status: COMPLETED (2026-02-12)

## What Was Done

### 1. Removed "Short Level Intro" setting
- Removed `short_level_intro` from save settings, SaveManager, HUD, and settings UI
- Removed `ShortIntroCheck` node from settings.tscn
- Changed default intro hold duration from 2.5s to 1.0s (total intro: 0.5s fade in + 1.0s hold + 0.5s fade out = 2.0s)

### 2. Input-based intro skip (Space/Click)
- Added `skip_intro()`, `is_showing()`, and tween tracking to `HudLevelIntroHelper`
- Added `_unhandled_input()` in `hud.gd` to detect `launch_ball` action during intro
- Pressing Space/Click immediately hides the intro overlay

### 3. Fast-forward level complete screen (Space/Enter)
- Added `_unhandled_input()` in `level_complete.gd`
- Handles `launch_ball` or `ui_accept` actions
- 0.5s guard delay prevents accidental skip
- Triggers next level (or play again if next level unavailable)

### 4. Quick restart from game over (R/Space)
- Added `_unhandled_input()` in `game_over.gd`
- Handles `restart_game` (R) or `launch_ball` (Space/Click) actions
- 0.5s guard delay prevents accidental skip
- Triggers retry (same as clicking RETRY button)

## Files Modified
- `scripts/hud_level_intro_helper.gd` - intro timing, skip support
- `scripts/hud.gd` - removed short_level_intro, added input skip
- `scripts/ui/settings.gd` - removed short intro checkbox
- `scenes/ui/settings.tscn` - removed ShortIntroCheck node
- `scripts/save_settings_helper.gd` - removed short_level_intro setting
- `scripts/save_manager.gd` - removed short_level_intro wrapper functions
- `scripts/ui/level_complete.gd` - quick advance with guard delay
- `scripts/ui/game_over.gd` - quick retry with guard delay
- `.agent/Tasks/Backlog/future-features.md` - marked completed
