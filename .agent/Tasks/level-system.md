# Level System & Progression Plan

## Status: ⏳ NOT STARTED

## Overview
Add external level data, a loader, progression rules, and a level select screen. Currently, levels are generated at runtime in `scripts/main.gd` for testing.

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

## Tasks
- [x] **Choose a level data format** - JSON selected and documented.
- [x] **Create 5 unique starter levels** - Completed in `levels/` folder.
- [ ] **Implement JSON level loader** - Parse JSON files and instantiate bricks:
  - [ ] Create `LevelLoader` script (autoload or node).
  - [ ] Load level JSON data from `levels/` folder.
  - [ ] Parse grid configuration and brick definitions.
  - [ ] Instantiate bricks at calculated positions.
  - [ ] Replace `create_test_level()` with level loading.
  - [ ] Track breakable brick count for completion.
- [ ] **Implement basic level progression** - Auto-advance to next level:
  - [ ] Load next level on completion.
  - [ ] Handle end of all levels (victory/loop).
  - [ ] Integrate with `GameManager.current_level`.
  - [ ] Add level transition effects (optional).
- [ ] Define schema for special tiles (bomb, etc.) and ensure the loader supports them.
- [ ] Build a level select UI (depends on `Tasks/ui-system.md`).
- [ ] Add hooks for future special elements (force fields, etc.).

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
