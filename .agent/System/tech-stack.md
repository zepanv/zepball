# Zep Ball - Tech Stack and Settings

## Core Technologies
- **Engine**: Godot 4.6 (project config features include "4.6" and Forward Plus).
- **Language**: GDScript.
- **Version Control**: Git.

## Project Settings (project.godot)
- **Run main scene**: `res://scenes/ui/main_menu.tscn`.
- **Gameplay scene**: `res://scenes/main/main.tscn`.
- **Window size**: 1600x900.
- **Stretch mode**: `canvas_items`.
- **2D gravity**: 0 (no gravity).
- **Texture filtering**: `default_texture_filter=0` (nearest).

## Input Actions
- `move_up`: Up Arrow, W.
- `move_down`: Down Arrow, S.
- `launch_ball`: Space, Left Mouse Button.
- `restart_game`: R key.
- `ui_cancel`: Escape.
- `audio_volume_down`: - key.
- `audio_volume_up`: = key.
- `audio_prev_track`: [ key.
- `audio_next_track`: ] key.
- `audio_toggle_pause`: \ key.
- Keybindings (except `ui_cancel`) can be remapped and persist in save data.

## Autoloads
- `PowerUpManager`: `res://scripts/power_up_manager.gd`.
- `DifficultyManager`: `res://scripts/difficulty_manager.gd`.
- `SaveManager`: `res://scripts/save_manager.gd`.
- `AudioManager`: `res://scripts/audio_manager.gd`.
- `PackLoader`: `res://scripts/pack_loader.gd`.
- `MenuController`: `res://scripts/ui/menu_controller.gd`.

## Asset Formats in Use
- **Sprites and textures**: PNG, JPG.
- **Vector icon**: SVG (`icon.svg`).
- **Level data**: JSON (10 files in `levels/`).
- **Set data**: JSON (`data/level_sets.json`).

## Audio Status
- **Audio playback system**: Implemented via `AudioManager` (music playlists + SFX).
- **Audio buses**: "Music" and "SFX" are created at runtime if missing.
- **Settings**: Music/SFX volume sliders persist via SaveManager and apply via AudioServer.

## Related Docs
- `System/architecture.md`
- `SOP/godot-workflow.md`
- `Tasks/Completed/ui-system.md`
