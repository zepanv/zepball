# Level System & Progression Plan

## Status: 🔶 PARTIALLY IMPLEMENTED

## Overview
Add external level data, a loader, progression rules, and a level select screen. LevelLoader singleton implemented, integration with main scene and UI pending.

## Goals
- Move from hardcoded test grid to data-driven levels.
- Support progression (next level on completion).
- Provide a level select UI once multiple levels exist.
- Ensure level design can explicitly place special tiles (e.g., bomb tiles) and tune their behaviors.

## Data Format (Planned)
- **Option A: JSON** (simple to edit and version)
- **Option B: Godot Resources (.tres)** (editor-friendly, typed)

## Loader Responsibilities
- Parse level data.
- Instantiate bricks and special elements (force fields, special bricks).
- Track breakable brick count for completion checks.

## Progression Rules (Draft)
- Start at level 1.
- On level complete:
  - Advance to next level if it exists.
  - If last level, show victory screen or loop.

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

## Tasks
- [x] **Choose a level data format** - JSON selected and documented
- [x] **Create 5 unique starter levels** - Completed in `levels/` folder
- [x] **Implement JSON level loader** - Parse JSON files and instantiate bricks:
  - [x] Create `LevelLoader` script (autoload)
  - [x] Load level JSON data from `levels/` folder
  - [x] Parse grid configuration and brick definitions
  - [x] Instantiate bricks at calculated positions
  - [x] Track breakable brick count for completion
  - [ ] Replace `create_test_level()` with level loading in main.gd
- [ ] **Implement basic level progression** - Auto-advance to next level:
  - [ ] Load next level on completion
  - [ ] Handle end of all levels (victory/loop)
  - [ ] Integrate with `GameManager.current_level`
  - [ ] Add level transition effects (optional)
- [ ] Define schema for special tiles (bomb, etc.) and ensure the loader supports them
- [ ] Build a level select UI (depends on `Tasks/ui-system.md`)
- [ ] Add hooks for future special elements (force fields, etc.)

## Level Data Schema (Draft)
```json
{
  "level_id": 1,
  "name": "Level Name",
  "description": "Description",
  "grid": {
    "rows": 5, "cols": 8,
    "start_x": 150, "start_y": 150,
    "brick_size": 48, "spacing": 3
  },
  "bricks": [
    {"row": 0, "col": 0, "type": "NORMAL"},
    {"row": 0, "col": 1, "type": "STRONG"}
  ]
}
```

## Related Docs
- `Tasks/tile-system.md`
- `Tasks/ui-system.md`
- `System/architecture.md`
