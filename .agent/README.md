# Zep Ball - Documentation Index

Welcome to the Zep Ball project documentation! This folder contains all technical documentation, implementation plans, and standard operating procedures for the project.

## 📁 Documentation Structure

### System/
Contains documentation about the current state of the system, architecture decisions, and technical foundation.

- **architecture.md** - Godot scene structure, node hierarchy, and system design
- **tech-stack.md** - Technology choices, rationale for using Godot 4.x, and key decisions

### Tasks/
Project Requirements Documents (PRDs) and implementation plans for specific features.

- **core-mechanics.md** - Paddle, ball, and collision system implementation
- **tile-system.md** - Brick/tile breaking mechanics and grid layout
- **power-ups.md** - Power-up system design and implementation plan
- **ui-system.md** - User interface, menus, and HUD elements
- **audio-system.md** - Sound effects and music integration
- **save-system.md** - Player profiles, high scores, and save data

### SOP/
Standard Operating Procedures - best practices for common development tasks.

- **godot-workflow.md** - Working with Godot: adding scenes, nodes, signals
- **adding-scenes.md** - How to create and integrate new scene files
- **git-workflow.md** - Commit practices and branch management
- **testing-workflow.md** - How to test and playtest changes

## 🎮 Project Overview

Zep Ball is a breakout/arkanoid-style game with a unique vertical paddle positioned on the right side of the screen. Key features:

- **Vertical right-side paddle** - Unique gameplay mechanic
- **Physics-based ball mechanics** - Paddle spin affects ball trajectory
- **Level-based progression** - Multiple levels with increasing difficulty
- **Power-up system** - Multi-ball, paddle modifications, special abilities
- **High score tracking** - Save player profiles and achievements
- **Cross-platform** - Mac, Linux, Windows support via Godot exports

## 🛠 Tech Stack

- **Engine**: Godot 4.3+
- **Language**: GDScript (Python-like scripting)
- **Version Control**: Git
- **Asset Sources**: Kenney.nl, OpenGameArt, Freesound.org

## 📋 Quick Links

- [Project Plan](/plan/brainstorm.md)
- [System Architecture](.agent/System/architecture.md)
- [Tech Stack Rationale](.agent/System/tech-stack.md)
- [Godot Workflow](.agent/SOP/godot-workflow.md)

## 🚀 Development Phases

1. **Setup & Infrastructure** ✓ (Current)
2. **Core Mechanics** - Paddle, ball, basic physics
3. **Tiles & Breaking** - Brick system and collision
4. **Polish & Game Feel** - Audio, particles, UI
5. **Features & Content** - Power-ups, levels, menus
6. **Export & Distribution** - Multi-platform builds

---

*Last Updated: 2026-01-27*
