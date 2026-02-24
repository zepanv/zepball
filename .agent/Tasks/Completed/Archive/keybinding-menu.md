# Keybinding Menu + Persistence

## Goal
Add a keybinding menu accessible from Settings that allows players to rebind core gameplay/audio keys and persist those bindings across sessions.

## Scope
- Settings menu button to open keybinding overlay.
- Rebind supported actions (movement, launch, restart, audio hotkeys).
- Persist input map overrides in save data.
- Exclude pause/back (Esc) from rebinding.
- Esc cancels an in-progress rebind and closes the menu when not editing.

## Implementation Summary
- **SaveManager** stores serialized input events under `settings.keybindings` and re-applies them at startup.
- **Keybindings Menu** (overlay) lists rebindable actions with current bindings and supports reset to defaults.
- **Settings Menu** includes a Keybindings button and handles Esc back navigation.
- Debug hotkeys cleaned up: only `C` remains for debug/editor builds.

## Files
- `scripts/save_manager.gd`
- `scripts/ui/settings.gd`
- `scripts/ui/keybindings.gd`
- `scenes/ui/settings.tscn`
- `scenes/ui/keybindings.tscn`

## Notes
- Defaults are captured from `InputMap` on startup and used for reset.
- Mouse button bindings are preserved when rebinding a key (and vice versa).
