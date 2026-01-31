# UI Gaps - Remaining Missing Pieces

## Status: ✅ COMPLETE (2026-01-31)

## Summary
Implemented a new right-click aim mode for the main ball launch. The launch indicator is now active only on the first launch of each life, allows precise angle selection, locks paddle movement while aiming, and cancels cleanly on pause or right-click release.

## What Shipped
- Right-mouse hold enables aim mode and shows a launch indicator
- Paddle is locked while aiming; mouse movement rotates the indicator
- Left click / Space launches the ball in the indicator direction
- Releasing right mouse cancels aim mode without launching
- Aim mode is available only for the main ball’s first launch per life
- Aim mode cancels on pause (Esc)

## Implementation Notes
- Aim indicator is built dynamically in `scripts/ball.gd` using Line2D nodes
- Direction is clamped to safe leftward angles (120°–240°)
- Aim direction updates from mouse position; arrow handles near-paddle and behind-paddle cases
- Launch uses indicator direction and still triggers normal play state transition

## Related Docs
- `Tasks/Completed/ui-system.md`
- `System/architecture.md`
- `Tasks/Backlog/future-features.md`
