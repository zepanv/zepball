## Zep Ball v0.6.0

Major gameplay expansion release introducing new challenge styles and an endless mode.

## v0.6.0 Highlights
- Added **Time Attack** challenge mode with timer-based set runs and dedicated leaderboard support.
- Added **Survival Mode** from Main Menu with endless wave progression and survival-specific game over context.
- Expanded challenge system with **Iron Ball** and **One Life** set-run modes and challenge-aware UI flow.
- Added save migration updates for new leaderboards and survival records (existing profiles migrate automatically).
- Updated High Scores and completion messaging to support challenge-specific rankings and record checks.
- Included stability fixes for survival wave signal wiring, survival HUD/paused context, and speed-effect stacking.

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
