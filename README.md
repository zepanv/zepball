# Zep Ball

A breakout-style game with a unique vertical paddle positioned on the right side of the screen. Inspired by z-ball (retro64).

## Current Features: 2026-02-15

Highlights:

- Current version: **v0.5.0**
- 40 built-in levels across 4 official packs
- Player profiles with local high score tracking
- Difficulty modes (Easy/Normal/Hard) with multipliers
- Statistics + achievements tracking
- Pack Select with filtering (ALL/OFFICIAL/CUSTOM) and sorting (BY ORDER/BY PROGRESSION)
- In-game level/pack editor with test, save, export, and delete flows
- Audio playback (music + SFX)

## Releases and Verification

### Release Assets
- GitHub Releases include prebuilt binaries for:
  - Windows (`zepball.zip`)
  - Linux (`zepball.x86_64.zip`)
- macOS binaries are not currently published.

### macOS Status
- For now, macOS users should download source and build locally with Godot 4.6.

### Verify Download Integrity
Each release includes:
- `SHA256SUMS.txt`
- `SHA256SUMS.txt.minisig`
- `minisign.pub`

Verify signature:
```bash
minisign -Vm SHA256SUMS.txt -p minisign.pub
```

Verify file checksums:
```bash
sha256sum -c SHA256SUMS.txt
```

## Controls

### Keyboard & Mouse
- **W / Up Arrow**: Move paddle up
- **S / Down Arrow**: Move paddle down
- **Mouse**: Paddle follows mouse Y position
- **Space / Left Click**: Launch ball
- **Space (during intro)**: Skip level intro
- **Enter (level complete/game over)**: Quick advance/retry
- **Escape**: Pause/unpause game
- **R**: Restart current level (also works on game over)
- **Right Click (hold)**: Aim mode for first shot per life (paddle locks)
- **- / =**: Music volume down/up
- **[ / ]**: Previous/next music track
- **\\**: Toggle music pause/play
- **Keybindings**: All actions rebindable in Settings (separate keyboard/controller columns)

### Controller (Gamepad)
- **Left Stick / D-Pad**: Move paddle up/down, navigate menus
- **A Button (Xbox) / Cross (PlayStation)**: Launch ball, select/confirm in menus
- **B Button (Xbox) / Circle (PlayStation)**: Pause/back in menus
- **Y Button (Xbox) / Triangle (PlayStation)**: Restart level
- **LB/L1 & RB/R1**: Previous/next music track
- **L3/R3**: Music volume down/up
- **Back/Select**: Toggle music pause/play
- **Controller Support**: Full menu navigation, gameplay, and keybinding customization

## Game Features

### Core Mechanics
- **Enhanced Spin System**: Paddle spin creates persistent ball curve with visual trail effects. High-spin balls pass through breakable bricks (penetrating spin)
- **16 brick types** including:
  - Standard bricks (normal, strong, colored variants, diamond, polygon shapes)
  - Bomb bricks (explode on hit)
  - Force Arrow tiles (non-collidable directional force fields with charge-up mechanic and audio feedback)
  - Power-up bricks (instant power-up grant on contact, all 16 types)
- Combo and no-miss streak multipliers
- Perfect clear bonus on level completion
- Ball escape logic prevents wedging in corners

### Progression
- Built-in packs:
  - **Classic Challenge** (levels 1-10)
  - **Prism Showcase** (levels 11-20)
  - **Nebula Ascend** (levels 21-30)
  - **Advanced Elements** (levels 31-40)
- Player profiles with individual progression tracking
- Unlock progression, per-level high scores, per-pack run scores
- Star ratings per level (0-3 stars)
- Set Mode: Score and lives carry across levels; combo/streak reset each level; Perfect Set bonus (3x) for flawless runs

### Power-Ups (16 Types)
- **Paddle**: Expand, Contract
- **Ball Speed**: Speed Up, Slow Down
- **Ball Effects**: Triple Ball, Big Ball, Small Ball, Bomb Ball (explosive impacts), Air Ball (teleport to level center X on paddle hit)
- **Special**: Extra Life, Grab (stick to paddle), Brick Through (pass through bricks)
- **Control**: Magnet (paddle gravity pull)
- **Defense**: Block (temporary barrier bricks)
- **Score**: Double Score (2x multiplier)
- **Mystery**: Random effect
- Timed effects with HUD timers and visual indicators (duplicate pickups add full duration)
- Air Ball avoids unbreakable slots on teleport landings
- Ball glows orange-red during bomb ball effect

### Settings
- Screen shake intensity
- Particle effects toggle
- Ball trail toggle
- Visual toggles (combo flash, skip intro, FPS) default Off
- Paddle sensitivity (0.5x - 2.0x)
- Music/SFX volume (applies immediately)
- Music playback mode (Off / Loop One / Loop All / Shuffle)
- Music track selection (Loop One)
- Keybindings menu (rebind core input actions; Escape not rebindable)
- Reset Keybindings button restores defaults
- Reset Settings button restores defaults only
- Clear Save Data resets progress/scores without changing settings

### Level Editor + Packs
- Create and edit custom `.zeppack` files in-game (supports v1 and v2 formats)
- Paint levels with all 16 brick types including special tiles:
  - Force Arrows: 8 directional options (Up, Down, Left, Right, and diagonals)
  - Power-up Bricks: All 16 power-up type options
- Add/remove/duplicate/reorder levels
- Undo/redo support (`Ctrl/Cmd+Z`, `Ctrl/Cmd+Y`, `Ctrl/Cmd+Shift+Z`)
- Test current draft level without affecting progression/stats
- Save packs to `user://packs/`
- Export timestamped pack files to `user://exports/`
- Open export folder directly (Finder/Explorer/file manager)
- Delete saved custom packs with confirmation
- Backward compatible (v1 packs load seamlessly)

## Credits & Licensing

### Software
The source code for Zep Ball is licensed under the **MIT License**. See [LICENSE](LICENSE) for details.

### Audio
- **Music**: Generated with Suno AI (Basic Plan). Music provided by [Suno.com](https://suno.com).
  - *License*: Non-commercial use only. Suno AI retains ownership.
- **Sound Effects**: Generated with [ElevenLabs](https://elevenlabs.io).
  - *License*: Royalty-free and can be used for commercial or non-commercial purposes.

### Graphics
- **Kenney Assets**: Bricks and UI elements from [Kenney.nl](https://kenney.nl) are licensed under Creative Commons CC0 (Public Domain).
- **Backgrounds & Primary Art**: Generated with Nano Banana.
- **Other Art Assets**: Generated with OpenAI (ChatGPT).
- **Note on AI Art**: To the extent permitted by law, the AI-generated graphical assets in this project are provided without copyright.

### Legal Considerations
- **AI-Generated Content**: Users should be aware that AI-generated assets may not be eligible for copyright protection under current laws in various jurisdictions.
- **Suno Music**: The music files are restricted to **non-commercial use only** per Suno AI's Basic Plan terms. If you intend to use this project for commercial purposes, you must replace the music or ensure you have a valid commercial license.
