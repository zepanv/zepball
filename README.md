# Zep Ball

A breakout-style game with a unique vertical paddle positioned on the right side of the screen. Inspired by z-ball (retro64).

## Current Status: Phase 1 Complete! 🎮

The game is now in a **playable state** with core mechanics implemented:

- ✅ Paddle movement (keyboard + mouse)
- ✅ Ball physics with collision detection
- ✅ Paddle spin mechanics (paddle movement affects ball trajectory)
- ✅ Brick breaking system with particle effects
- ✅ Score tracking and lives system
- ✅ HUD display (score, lives, logo)
- ✅ Test level (5x8 brick grid)
- ✅ Level completion detection
- ✅ Game over on life loss

## Quick Start

### Requirements
- **Godot 4.6** (or later)
- Download from: https://godotengine.org/download

### Running the Game
1. Open Godot Engine
2. Click "Import" and select `zepball/project.godot`
3. Press **F5** to run the game

### Controls
- **W / Up Arrow**: Move paddle up
- **S / Down Arrow**: Move paddle down
- **Mouse**: Paddle follows mouse Y position
- **Space / Left Click**: Launch ball
- **Escape**: Pause/unpause game

## How to Play

1. Move the paddle (right side of screen) to keep the ball in play
2. Launch the ball with Space or Left Click
3. Break all the bricks to complete the level
4. Don't let the ball pass the right edge or you'll lose a life
5. Game over when you run out of lives (starts with 3)

## Game Mechanics

### Unique Feature: Paddle Spin
- Moving the paddle while hitting the ball adds **vertical spin**
- Moving up while hitting: ball curves upward
- Moving down while hitting: ball curves downward
- Creates dynamic gameplay unlike traditional Breakout

### Brick Types
- **Normal (Teal)**: 1 hit to break, 10 points
- **Strong (Pink)**: 2 hits to break, 20 points
- **Unbreakable (Gray)**: Cannot be destroyed (not in test level)

## Project Structure

```
zepball/
├── .agent/              # Project documentation
│   ├── README.md       # Documentation index
│   ├── System/         # Architecture and tech decisions
│   └── SOP/            # Development procedures
├── scenes/
│   ├── main/           # Main game scene
│   └── gameplay/       # Paddle, ball, brick scenes
├── scripts/            # GDScript files
├── assets/             # Graphics, audio, fonts (to be added)
├── levels/             # Level data files (future)
└── project.godot       # Godot project configuration
```

## Development Phases

### ✅ Phase 1: Core Mechanics (COMPLETE)
- [x] Project setup and structure
- [x] Paddle movement (keyboard + mouse)
- [x] Ball physics and collision
- [x] Brick system
- [x] Game state management
- [x] HUD and scoring
- [x] Test level

### ✅ Phase 2: Visual Polish (COMPLETE)
- [x] Random background images from asset pack
- [x] Screen shake on brick impacts
- [x] Ball trail effect
- [x] Paddle sprite graphics (Kenney assets)
- [x] Brick sprite graphics with variety
- [x] Particle effects on brick break
- [x] Power-up visual indicators
- [x] Improved pause system with UI indicator

### 🚧 Phase 3: Audio & Power-ups (Next)
- [ ] Sound effects (paddle hit, brick break, wall bounce, ball lost)
- [ ] Background music
- [ ] **[NEW] Penetrating Spin**: High spin allows ball to break through multiple bricks

### 📋 Phase 4: Features & Content
- [x] Power-ups system (Expand, Contract, Speed Up, Triple Ball)
- [ ] **[NEW] Force Fields / Arrows**: Level elements that push/pull the ball (Gravity zones)
- [ ] **[NEW] Difficulty Modes**: Easy (slow), Normal, Hard (fast)
- [ ] **[NEW] Expanded Power-ups**: More types including Warp, Repel, Guns, Big/Small Ball
- [ ] Multiple levels (5-10 unique layouts)
- [ ] Level selection menu
- [ ] Main menu
- [ ] Game over screen with retry option
- [ ] High score persistence

### 📦 Phase 5: Distribution
- [ ] Export templates setup
- [ ] Mac, Linux, Windows builds
- [ ] Icon and metadata

## Tech Stack

- **Engine**: Godot 4.6
- **Language**: GDScript
- **Target Platforms**: macOS, Linux, Windows
- **Resolution**: 1600x900 (16:9), scalable with canvas_items stretch mode

See `.agent/System/tech-stack.md` for detailed rationale.

## Documentation

All technical documentation is in the `.agent/` folder:

- **[.agent/README.md](.agent/README.md)** - Documentation index
- **[.agent/System/architecture.md](.agent/System/architecture.md)** - Scene hierarchy and design patterns
- **[.agent/System/tech-stack.md](.agent/System/tech-stack.md)** - Technology decisions and conventions
- **[.agent/SOP/godot-workflow.md](.agent/SOP/godot-workflow.md)** - Development workflows and best practices

## Testing Checklist

Current working features:
- [x] Paddle moves with W/S keys
- [x] Paddle follows mouse Y position
- [x] Paddle stays within screen bounds
- [x] Ball attaches to paddle on start
- [x] Ball launches on Space/Click
- [x] Ball bounces off walls correctly
- [x] Ball bounces off paddle
- [x] Paddle spin affects ball trajectory
- [x] Ball breaks bricks on collision
- [x] Bricks show particle effect when broken
- [x] Score increases when bricks break
- [x] Lives decrease when ball is lost
- [x] Ball resets to paddle after life lost
- [x] Game over when lives reach 0
- [x] Level completes when all bricks broken

## Known Issues / TODOs

- [ ] No audio yet
- [ ] Game over screen needs UI
- [ ] Level complete screen needs UI
- [ ] No way to restart without F5
- [ ] No main menu

## Contributing

This is a learning/exploration project. The codebase prioritizes:
- **Clarity** over cleverness
- **Simplicity** over premature optimization
- **Working features** over theoretical perfection

## Asset Credits
- Graphics: Kenney Vleugels (kenney.nl)
- Backgrounds: AI-generated space/abstract backgrounds
- Audio: TBD (Freesound.org, Incompetech)

## License

TBD - Personal project, not yet open source

---

**Version**: 0.2.0 (Polished Prototype)
**Last Updated**: 2026-01-29
**Godot Version**: 4.6+

**Ready to play! Press F5 in Godot!** 🎮✨
