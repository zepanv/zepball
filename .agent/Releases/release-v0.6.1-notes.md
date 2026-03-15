## ZepBall v0.6.1

Stability and progression patch.

## v0.6.1 Highlights
- **Ball physics fix** — Ball no longer gets nearly stuck bouncing vertically between top/bottom walls (minimum horizontal velocity now enforced every frame)
- **Triple ball power-up fixes** — Extra balls now correctly inherit big/small ball size and bomb ball visual, and reset to normal size when effects expire
- **Power-up crash fix** — Fixed a crash when clearing power-up effects during level transitions (freed node assigned to typed variable)
- **Set score restored on resume** — Returning to last level in a set now correctly restores the accumulated score from completed levels
- **Advanced Elements pack** — Added missing pack to progression order; completing Nebula Ascend now correctly unlocks Advanced Elements as the next pack
- **Save compatibility** — All existing saves migrate automatically; no data loss

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
