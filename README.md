# Zep Ball

A breakout-style game with a unique vertical paddle positioned on the right side of the screen. Inspired by z-ball (retro64).

## Current Features: 2026-02-13

Highlights:

- 30 built-in levels across 3 packs
- Difficulty modes (Easy/Normal/Hard) with multipliers
- Statistics + achievements tracking
- In-game level/pack editor with test, save, export, and delete flows
- Audio playback (music + SFX)

## Controls
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
- **Keybindings**: Rebindable in Settings (except Escape)

### Debug Controls (Debug Build Only)
- **C**: Clear all bricks

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
- Unlock progression, per-level high scores, per-pack run scores
- Star ratings per level (0-3 stars)

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

## Asset Credits
- Graphics: Kenney Vleugels (kenney.nl) Puzzle Packs + AI-Generated
- Backgrounds: AI-Generated space/abstract backgrounds
- Music: Suno
- SFX: ElevenLabs

## License

TBD - Personal project, not yet open source
