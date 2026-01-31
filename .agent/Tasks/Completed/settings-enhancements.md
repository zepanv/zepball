# Settings Enhancements

## Goal
Expand the Settings menu with additional gameplay, display, and UX options.

## Scope
- Gameplay toggles: combo flash, short level intro, skip level intro.
- Display toggle: show FPS.
- UX: apply settings live from pause overlay for supported options.
- Controls: key rebinding handled separately (see keybinding-menu.md).

## Implementation Summary
- Added settings toggles for combo flash, intro variants, and FPS.
- Settings persist via SaveManager with migration.
- Pause overlay applies compatible settings live (HUD, trail, sensitivity, intros).

## Files
- `scenes/ui/settings.tscn`
- `scripts/ui/settings.gd`
- `scripts/save_manager.gd`
- `scripts/hud.gd`

## Notes
- Audio settings still apply immediately via AudioServer/AudioManager.
- Gameplay settings apply on next load unless opened from pause overlay.
