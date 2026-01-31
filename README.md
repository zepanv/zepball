# Zep Ball

A breakout-style game with a unique vertical paddle positioned on the right side of the screen. Inspired by z-ball (retro64).

## Current Status: 2026-01-31 (Fully Playable)

The game is fully playable with extensive features:

- ✅ Main menu, level select, settings, stats, game over, level complete
- ✅ 20 JSON-driven levels with vertically centered layouts and strategic bomb brick placement
- ✅ Difficulty modes (Easy/Normal/Hard) with multipliers
- ✅ **16 Power-ups**: Expand, Contract, Speed Up, Slow Down, Triple Ball, Big/Small Ball, Extra Life, Grab, Brick Through, Double Score, Mystery, Bomb Ball, Air Ball, Magnet, Block
- ✅ **Special Bricks**: Bomb bricks that explode and destroy surrounding bricks
- ✅ **Advanced Bricks**: Diamond + pentagon shapes (glossy variants are 2-hit)
- ✅ Statistics + achievements tracking (12 achievements)
- ✅ Settings (shake, particles, trail, sensitivity, audio levels, music mode/track)
- ✅ HUD with combo + multiplier display + power-up timers
- ✅ Launch aim indicator (right-click hold for main ball’s first shot)

Audio playback is implemented (music + expanded SFX coverage).

## Quick Start

### Requirements
- **Godot 4.6** (or later)

### Running the Game
1. Open Godot Engine
2. Click "Import" and select `zepball/project.godot`
3. Press **F5** to run

### Controls
- **W / Up Arrow**: Move paddle up
- **S / Down Arrow**: Move paddle down
- **Mouse**: Paddle follows mouse Y position
- **Space / Left Click**: Launch ball
- **Escape**: Pause/unpause game
- **R**: Restart current level
- **Backtick (`)**: Toggle debug overlay
- **Right Click (hold)**: Aim mode for first shot per life (paddle locks)
- **- / =**: Music volume down/up
- **[ / ]**: Previous/next music track
- **\\**: Toggle music pause/play

### Debug Controls (Debug Build Only)
- **E/N/H**: Set difficulty to Easy/Normal/Hard
- **C**: Clear all bricks
- **1**: Spawn bomb ball power-up (test explosive effects)
- **2**: Spawn air ball power-up
- **3**: Spawn magnet power-up
- **4**: Spawn block power-up

## Game Features

### Core Mechanics
- Paddle spin affects ball trajectory
- **14 brick types** including special bomb bricks that explode
- Combo and no-miss streak multipliers
- Perfect clear bonus on level completion
- Ball escape logic prevents wedging in corners

### Progression
- 20 enhanced levels with better vertical coverage
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
- Reset Settings button restores defaults only
- Clear Save Data resets progress/scores without changing settings

## Project Structure

```
zepball/
├── .agent/              # Project documentation
│   ├── README.md       # Documentation index
│   ├── System/         # Architecture and tech decisions
│   ├── SOP/            # Development procedures
│   └── Tasks/          # Completed + backlog feature docs
├── scenes/
│   ├── main/           # Gameplay scene
│   ├── gameplay/       # Paddle, ball, brick, power-up scenes
│   └── ui/             # Menus and screens
├── scripts/            # GDScript files
├── levels/             # Level JSON files (20 levels)
├── assets/             # Audio + graphics
└── project.godot       # Godot project configuration
```

## Documentation

All technical documentation is in the `.agent/` folder:

- **[.agent/README.md](.agent/README.md)** - Documentation index
- **[.agent/System/architecture.md](.agent/System/architecture.md)** - Scene hierarchy and design patterns
- **[.agent/System/tech-stack.md](.agent/System/tech-stack.md)** - Technology decisions and conventions
- **[.agent/SOP/godot-workflow.md](.agent/SOP/godot-workflow.md)** - Development workflows and best practices

## Known Gaps / Backlog

- **UI gaps (launch indicator)**: `.agent/Tasks/Backlog/ui-gaps.md`
- **Future features**: `.agent/Tasks/Backlog/future-features.md` (includes advanced tile elements)

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
