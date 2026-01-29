# Zep Ball - Documentation Index

This folder contains the canonical documentation for the Zep Ball codebase.

## Documentation Structure

### System/
Current system state, architecture, and technical foundation.
- `System/architecture.md` - Project architecture, scene graph, core systems, and gameplay flow.
- `System/tech-stack.md` - Engine, settings, input map, and runtime configuration.

### Tasks/
PRDs and implementation plans for individual features.
- `Tasks/core-mechanics.md` - Paddle, ball, and collision system design.
- `Tasks/tile-system.md` - Brick/tile system plan.
- `Tasks/level-system.md` - Level data, loader, and progression plan.
- `Tasks/power-ups.md` - Power-up system design and implementation plan.
- `Tasks/ui-system.md` - UI, menus, and HUD plans.
- `Tasks/audio-system.md` - Audio system plan (SFX, music, and volume controls).
- `Tasks/save-system.md` - Save data, high scores, and persistence plan.

### SOP/
Best practices and workflows for development.
- `SOP/godot-workflow.md` - Working with Godot scenes, nodes, and signals.

## Project Snapshot
- **Genre**: Breakout/arkanoid-style 2D game with a right-side paddle.
- **Current gameplay**: Paddle movement, ball physics with spin, brick breaking, score/lives, pause, power-ups, and HUD.
- **Level system**: A test grid is generated at runtime; no external level data yet.
- **Persistence**: No save system or database implemented.

## Tech Stack Snapshot
- **Engine**: Godot 4.6 (project config features include 4.6).
- **Language**: GDScript.
- **Main scene**: `res://scenes/main/main.tscn`.

## Quick Links
- `System/architecture.md`
- `System/tech-stack.md`
- `Tasks/core-mechanics.md`
- `SOP/godot-workflow.md`

## Roadmap Snapshot
- Phase 1: Core Mechanics ✅
- Phase 2: Visual Polish ✅
- Phase 3: Core Power-ups ✅
- Phase 4: UI System & Game Flow ⏳
- Phase 5: Level System & Content ⏳
- Phase 6: Audio System 📅
- Phase 7: Advanced Features 📅

---

Last Updated: 2026-01-29
