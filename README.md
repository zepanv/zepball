# Zep Ball

A breakout-style game with a unique vertical paddle positioned on the right side of the screen. Inspired by z-ball (retro64).

## Current Status: 2026-01-31 (Fully Playable)

Highlights:

- ✅ Main menu, level select, settings, stats, game over, level complete
- ✅ 20 JSON-driven levels with vertically centered layouts and strategic bomb brick placement
- ✅ Difficulty modes (Easy/Normal/Hard) with multipliers
- ✅ Statistics + achievements tracking (12 achievements)
- ✅ Audio playback (music + expanded SFX coverage)

## Controls
- **W / Up Arrow**: Move paddle up
- **S / Down Arrow**: Move paddle down
- **Mouse**: Paddle follows mouse Y position
- **Space / Left Click**: Launch ball
- **Escape**: Pause/unpause game
- **R**: Restart current level
- **Right Click (hold)**: Aim mode for first shot per life (paddle locks)
- **- / =**: Music volume down/up
- **[ / ]**: Previous/next music track
- **\\**: Toggle music pause/play
- **Keybindings**: Rebindable in Settings (except Escape)

### Debug Controls (Debug Build Only)
- **C**: Clear all bricks

## Game Features

### Core Mechanics
- Paddle spin affects ball trajectory
- **14 brick types** (including bomb bricks that explode)
- Combo and no-miss streak multipliers
- Perfect clear bonus on level completion
- Ball escape logic prevents wedging in corners

### Progression
- Strategic bomb brick placement for tactical gameplay
- Unlocks next level on completion
- High scores per level

### Power-Ups (16 Types)
- **Paddle**: Expand, Contract
- **Ball Speed**: Speed Up, Slow Down
- **Ball Effects**: Triple Ball, Big Ball, Small Ball, Bomb Ball (explosive impacts), Air Ball (teleport to level center X on paddle hit)
- **Special**: Extra Life, Grab (stick to paddle), Brick Through (pass through bricks)
- **Control**: Magnet (paddle gravity pull)
- **Defense**: Block (temporary barrier bricks)
- **Score**: Double Score (2x multiplier)
- **Mystery**: Random effect
- Timed effects with HUD timers and visual indicators
- Ball glows orange-red during bomb ball effect

### Settings
- Screen shake intensity
- Particle effects toggle
- Ball trail toggle
- Visual toggles (combo flash, short/skip intro, FPS) default Off
- Paddle sensitivity
- Music/SFX volume (applies immediately)
- Music playback mode (Off / Loop One / Loop All / Shuffle)
- Music track selection (Loop One)
- Keybindings menu (rebind core input actions; Escape not rebindable)
- Reset Keybindings button restores defaults
- Reset Settings button restores defaults only
- Clear Save Data resets progress/scores without changing settings

## Asset Credits
- Graphics: Kenney Vleugels (kenney.nl)
- Backgrounds: AI-generated space/abstract backgrounds
- Audio: TBD (Freesound.org, Incompetech)
- Music: Suno
- SFX: ElevenLabs

## License

TBD - Personal project, not yet open source

---

**Last Updated**: 2026-01-31

**Ready to play with explosive action!** 🎮💥
