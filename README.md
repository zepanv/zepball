# Zep Ball

A breakout-style game with a unique vertical paddle positioned on the right side of the screen. Inspired by z-ball (retro64).

## Current Status: 2026-01-30 20:00 EST (Fully Playable)

The game is fully playable with extensive features:

- ✅ Main menu, level select, settings, stats, game over, level complete
- ✅ 10 JSON-driven levels with enhanced vertical coverage and strategic bomb brick placement
- ✅ Difficulty modes (Easy/Normal/Hard) with multipliers
- ✅ **13 Power-ups**: Expand, Contract, Speed Up, Slow Down, Triple Ball, Big/Small Ball, Extra Life, Grab, Brick Through, Double Score, Mystery, Bomb Ball
- ✅ **Special Bricks**: Bomb bricks that explode and destroy surrounding bricks
- ✅ Statistics + achievements tracking (12 achievements)
- ✅ Settings (shake, particles, trail, sensitivity, audio levels)
- ✅ HUD with combo + multiplier display + power-up timers

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
- **1**: Spawn bomb ball power-up (test explosive effects)

## Game Features

### Core Mechanics
- Paddle spin affects ball trajectory
- **10 brick types** including special bomb bricks that explode
- Combo and no-miss streak multipliers
- Perfect clear bonus on level completion
- Ball escape logic prevents wedging in corners

### Progression
- 10 enhanced levels with better vertical coverage
- Strategic bomb brick placement for tactical gameplay
- Unlocks next level on completion
- High scores per level

### Power-Ups (13 Types)
- **Paddle**: Expand, Contract
- **Ball Speed**: Speed Up, Slow Down
- **Ball Effects**: Triple Ball, Big Ball, Small Ball, Bomb Ball (explosive impacts)
- **Special**: Extra Life, Grab (stick to paddle), Brick Through (pass through bricks)
- **Score**: Double Score (2x multiplier)
- **Mystery**: Random effect
- Timed effects with HUD timers and visual indicators
- Ball glows orange-red during bomb ball effect

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

**Last Updated**: 2026-01-30 20:00 EST

**Ready to play with explosive action!** 🎮💥
