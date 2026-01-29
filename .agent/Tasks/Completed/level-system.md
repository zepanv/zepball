# Level System & Progression

## Status: ✅ COMPLETE

## Overview
Levels are fully data-driven via JSON files, loaded by the LevelLoader autoload, and wired into gameplay and menus. Progression, level select, and next-level flow are implemented.

## Goals (Achieved)
- Data-driven levels (JSON).
- Level selection UI with unlock/high score display.
- Progression and next-level flow.
- Level metadata for UI (name/description).

## Implementation Details

### LevelLoader Singleton ✅ IMPLEMENTED
- **Location**: `scripts/level_loader.gd`
- **Autoload**: Registered in `project.godot`
- **Levels Path**: `res://levels/`

### Key Methods
- `get_total_level_count()` - Count available level files
- `load_level_data(level_id)` - Load and cache level JSON
- `get_level_info(level_id)` - Get metadata (name, description)
- `instantiate_level(level_id, brick_container)` - Create level bricks in container
- `level_exists(level_id)` - Check if level file exists
- `get_next_level_id(current_level_id)` - Get next level or -1
- `has_next_level(current_level_id)` - Check if more levels exist

### Brick Type Support
Supports all brick types from `brick.gd`:
- NORMAL, STRONG, UNBREAKABLE
- GOLD, RED, BLUE, GREEN, PURPLE, ORANGE

## Current Level Data Schema
```json
{
  "level_id": 1,
  "name": "First Contact",
  "description": "Learn the basics - break all the bricks!",
  "grid": {
    "rows": 4,
    "cols": 6,
    "start_x": 200,
    "start_y": 200,
    "brick_size": 48,
    "spacing": 3
  },
  "bricks": [
    {"row": 0, "col": 0, "type": "NORMAL"}
  ]
}
```

## Implemented Flow
- `main.gd` uses `LevelLoader.instantiate_level()` to build gameplay bricks.
- Level select screen (`scripts/ui/level_select.gd`) lists all levels and respects unlock state.
- On level complete (`MenuController.show_level_complete()`):
  - Saves high score, unlocks next level, and marks completion.
  - Next level can be launched directly from `level_complete.tscn`.

## Related Docs
- `Tasks/Completed/tile-system.md`
- `Tasks/Completed/ui-system.md`
- `System/architecture.md`
