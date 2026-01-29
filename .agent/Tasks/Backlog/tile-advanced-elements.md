# Tile System - Advanced Elements

## Status: 📋 BACKLOG

## Why
`Tasks/Completed/tile-system.md` includes several planned brick/level mechanics that are not implemented in code. This backlog item captures those missing features.

## Missing Features
- Force Arrow / Force Field zones that redirect or repel the ball.
- Penetrating Spin interaction (ball passes through bricks when spin threshold is met).
- Special bricks (e.g., Bomb tile with splash damage).
- Data-driven placement for special tiles in level JSON.
- Level authoring workflow for special tiles (tooling TBD).

## Implementation Notes
- Add new scene(s) for force zones (e.g., `scenes/level_elements/force_arrow.tscn`).
- Extend level JSON schema and `scripts/level_loader.gd` to spawn special elements.
- Update `scripts/ball.gd` to apply force zones and penetrating spin logic.
- Update `scripts/brick.gd` to support special behaviors (bomb splash, pass-through).
- Add visual feedback for force zones and special brick states.

## Acceptance Criteria
- Special elements can be defined in level JSON and instantiated by LevelLoader.
- Force zones reliably redirect ball velocity without physics errors.
- Bomb bricks affect adjacent bricks per design.
- Penetrating spin can be toggled/tested without breaking standard collisions.

## Related Docs
- `Tasks/Completed/tile-system.md`
- `Tasks/Completed/level-system.md`
- `System/architecture.md`
