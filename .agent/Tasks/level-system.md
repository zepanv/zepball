# Level System & Progression Plan

## Status: ⏳ NOT STARTED

## Overview
Add external level data, a loader, progression rules, and a level select screen. Currently, levels are generated at runtime in `scripts/main.gd` for testing.

## Goals
- Move from hardcoded test grid to data-driven levels.
- Support progression (next level on completion).
- Provide a level select UI once multiple levels exist.

## Proposed Data Format
- **Option A: JSON**
  - Simple to edit and version.
  - Stored in `levels/` or `assets/levels/`.
- **Option B: Godot Resources (.tres)**
  - Stronger typing, editor integration.
  - Slightly heavier workflow.

## Loader Responsibilities
- Parse level data.
- Instantiate bricks and special elements (force fields later).
- Track breakable brick count for completion checks.

## Progression Rules (Draft)
- Start at level 1.
- On level complete:
  - Advance to next level if it exists.
  - If last level, show victory screen or loop.

## Tasks
- [ ] Choose a level data format (JSON vs Resource).
- [ ] Implement a `LevelLoader` (script or node) and replace `create_test_level()`.
- [ ] Create 5 unique starter levels.
- [ ] Implement level progression integration with `GameManager`.
- [ ] Build a level select UI (depends on `Tasks/ui-system.md`).
- [ ] Add hooks for future special elements (force fields, etc.).

## Related Docs
- `Tasks/tile-system.md`
- `Tasks/ui-system.md`
- `System/architecture.md`
