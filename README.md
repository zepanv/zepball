# Zep Ball

A breakout-style game with a unique vertical paddle positioned on the right side of the screen. Inspired by z-ball (retro64).

## Current Status: 2026-01-30 16:10 EST (Playable)

The game is fully playable with menus, progression, and settings:

- ✅ Main menu, level select, settings, stats, game over, level complete
- ✅ 10 JSON-driven levels with progression and high scores
- ✅ Difficulty modes (Easy/Normal/Hard) with multipliers
- ✅ Power-ups (Expand, Contract, Speed Up, Triple Ball, Big Ball, Small Ball)
- ✅ Statistics + achievements tracking
- ✅ Settings (shake, particles, trail, sensitivity, audio levels)
- ✅ HUD with combo + multiplier display

Audio playback and assets are not implemented yet.

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

### Debug Controls (Debug Build Only)
- **E/N/H**: Set difficulty to Easy/Normal/Hard
- **C**: Clear all bricks
- **1**: Spawn triple ball power-up
- **2**: Spawn expand power-up
- **3**: Spawn contract power-up
- **4**: Spawn big ball power-up
- **5**: Spawn small ball power-up

## Game Features

### Core Mechanics
- Paddle spin affects ball trajectory
- 9 brick types with score values and hit counts
- Combo and no-miss streak multipliers
- Perfect clear bonus on level completion

### Progression
- 10 levels loaded from JSON
- Unlocks next level on completion
- High scores per level

### Power-Ups
- Expand, Contract, Speed Up, Triple Ball, Big Ball, Small Ball
- Timed effects managed by PowerUpManager
- HUD timers for active effects

### Settings
- Screen shake intensity
- Particle effects toggle
- Ball trail toggle
- Paddle sensitivity
- Music/SFX volume (UI + save, audio not yet wired)

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
├── levels/             # Level JSON files (10 levels)
├── assets/             # Graphics
└── project.godot       # Godot project configuration
```

## Documentation

All technical documentation is in the `.agent/` folder:

- **[.agent/README.md](.agent/README.md)** - Documentation index
- **[.agent/System/architecture.md](.agent/System/architecture.md)** - Scene hierarchy and design patterns
- **[.agent/System/tech-stack.md](.agent/System/tech-stack.md)** - Technology decisions and conventions
- **[.agent/SOP/godot-workflow.md](.agent/SOP/godot-workflow.md)** - Development workflows and best practices

## Known Gaps / Backlog

- **Audio system**: `.agent/Tasks/Backlog/audio-system.md`
- **Additional power-ups**: `.agent/Tasks/Backlog/power-up-expansion.md`
- **Advanced tile mechanics**: `.agent/Tasks/Backlog/tile-advanced-elements.md`
- **UI gaps (launch indicator + score breakdown)**: `.agent/Tasks/Backlog/ui-gaps.md`
- **Future features**: `.agent/Tasks/Backlog/future-features.md`

## Asset Credits
- Graphics: Kenney Vleugels (kenney.nl)
- Backgrounds: AI-generated space/abstract backgrounds
- Audio: TBD (Freesound.org, Incompetech)

## License

TBD - Personal project, not yet open source

---

**Last Updated**: 2026-01-30 16:10 EST

**Ready to play!** 🎮
