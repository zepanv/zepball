## ZepBall v0.6.5

Endless modes expansion, full UI overhaul, and a wave of gameplay and controller fixes.

## v0.6.5 Highlights

- **Endless Waves & Blitz mode** — Blitz is now a fully playable endless mode with wave objectives, all-clear bonuses, difficulty-scaled push timers, and a live HUD callout. Survival waves now have assignment, progress tracking, completion/failure states, and bonus scoring.
- **UI overhaul** — Main menu, HUD, leaderboards, result screens, settings, and selection menus unified under shared theme tokens for consistent density and readability across the whole game.
- **Per-run stats on endless game over** — Run time, best combo, and bricks broken now shown on the endless mode game over screen. Blitz leaderboard shows rows alongside score.
- **Wall color customization** — 16 Minecraft-style colors (Pink default) added to settings, persisted across sessions, and applicable live from the pause menu.
- **New backgrounds** — Abyssal Deep, Cosmic Dust, Cyber Void, and CGASE added to the rotation.
- **Controller support improvements** — Stats/high scores screens now scroll with D-pad; set select auto-scrolls to focused card; paddle controller movement fixed when ball is grabbed near top.
- **Gameplay bug fixes** — Triple ball spawn timing, block barrier passthrough, ball boundary recovery, paddle right-boundary escape, and audio bus routing all corrected.
- **Gameplay screenshot capture** — Press F12 during play to capture a screenshot.

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
