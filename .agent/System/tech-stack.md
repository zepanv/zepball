# Zep Ball - Tech Stack and Settings

## Core Technologies
- **Engine**: Godot 4.6 (project config features include "4.6" and Forward Plus).
- **Language**: GDScript.
- **Version Control**: Git.

## Project Settings (project.godot)
- **Main scene**: `res://scenes/main/main.tscn`.
- **Window size**: 1600x900.
- **Stretch mode**: `canvas_items`.
- **2D gravity**: 0 (no gravity).
- **Texture filtering**: `default_texture_filter=0` (nearest).

## Input Actions
- `move_up`: Up Arrow, W.
- `move_down`: Down Arrow, S.
- `launch_ball`: Space, Left Mouse Button.
- `restart_game`: R key. ✅ NEW
- `ui_cancel`: Escape.

## Autoloads
- `PowerUpManager`: `res://scripts/power_up_manager.gd`.
- `DifficultyManager`: `res://scripts/difficulty_manager.gd`. ✅ NEW

## Asset Formats in Use
- **Sprites and textures**: PNG, JPG.
- **Vector icon**: SVG (`icon.svg`).
- **Level data**: JSON (5 files in `levels/` folder). ✅ NEW

## Not Implemented Yet
- Persistent save data or database.
- Audio system and assets.
- Menus and scene management beyond the main gameplay scene.

## Related Docs
- `System/architecture.md`
- `SOP/godot-workflow.md`
- `Tasks/ui-system.md`
