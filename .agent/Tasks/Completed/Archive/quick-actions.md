# Quick Actions

## Goal
Add convenience actions in menus and gameplay flow to reduce friction.

## Scope
- Play Again on level complete.
- Next Level default focus.
- Return to Last Level on main menu.
- Return to Level Select from pause (with confirmation).

## Implementation Summary
- Buttons and default focus wired in level complete UI.
- Main menu shows Return to Last Level when a session is in progress.
- Pause menu includes Level Select with confirmation dialog.

## Files
- `scripts/ui/level_complete.gd`
- `scripts/ui/main_menu.gd`
- `scripts/hud.gd`
- `scripts/save_manager.gd`
- Related UI scenes in `scenes/ui/`

## Notes
- SaveManager tracks last played session metadata for resume.
