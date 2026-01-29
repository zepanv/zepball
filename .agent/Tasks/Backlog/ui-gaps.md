# UI Gaps - Remaining Missing Pieces

## Status: 📋 BACKLOG

## Why
`Tasks/Completed/ui-system.md` reflects the overall UI system as implemented, but a couple of UI-related items called out there are still missing or disabled.

## Missing Pieces
1. **Ball launch direction indicator**
   - Present in `scripts/ball.gd` but currently disabled (indicator creation/update is commented out).
2. **Level complete score breakdown**
   - Current screen shows score, high score, and perfect clear only.
   - No accuracy/time bonus/multiplier breakdown yet.

## Implementation Notes
- Re-enable and validate the launch direction indicator for the main ball only.
- Track level duration and compute bonus breakdown on the level complete screen.
- Update `scenes/ui/level_complete.tscn` and `scripts/ui/level_complete.gd`.

## Acceptance Criteria
- Indicator appears before launch, updates with paddle velocity, and hides on launch.
- Level complete screen shows a clear breakdown (score + bonuses/multipliers).
- No regressions in pause, restart, or scene transitions.

## Related Docs
- `Tasks/Completed/ui-system.md`
- `System/architecture.md`
- `Tasks/Backlog/future-features.md`
