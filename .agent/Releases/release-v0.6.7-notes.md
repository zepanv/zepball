## ZepBall v0.6.7

Physics and reliability fixes for paddle collision, grab power-up, screen shake, and wave transitions.

## v0.6.7 Highlights

- **Grab power-up reliability** — Ball is now reliably grabbed near the top and bottom walls; previously the wall-escape path ran before the grab check and swallowed the hit.
- **Ball pinch behind paddle fixed** — Escape-zone check now fires before the ghost-hit pass-through, preventing the ball from slipping behind the paddle near walls.
- **Screen shake intensity setting** — Changing the intensity (Off / Low / Medium / High) now takes effect immediately without requiring a game restart.
- **Wave-start ball position** — Ball no longer spawns at a stale grab-contact offset at the start of a new survival wave; `reset_ball()` now restores the default front-of-paddle position.
- **Airball teleport at wall boundaries** — Airball teleport is now triggered even when the paddle is hit inside the escape zone (previously skipped).
- **Comma separators on score displays** — All score and stat counters now use locale-formatted numbers.

## Release Assets
- `zepball.zip` (Windows x86_64)
- `zepball.x86_64.zip` (Linux x86_64)
- `SHA256SUMS.txt`
- `SHA256SUMS.txt.minisig`
- `minisign.pub`

## Verify Downloads
```bash
minisign -Vm SHA256SUMS.txt -p minisign.pub
sha256sum -c SHA256SUMS.txt
```
