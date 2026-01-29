# Tile & Level System Implementation Plan

## Status: 🔶 PARTIALLY IMPLEMENTED

## Overview
This document covers the current brick system and the future level/force-field design. Only bricks and a runtime test grid are implemented today.

## 1. Brick System (Implemented)
- **Normal Brick**: 1 hit, 10 points.
- **Strong Brick**: 2 hits, 20 points.
- **Unbreakable Block**: Never breaks.
- **Themed Variants**: Gold/Red/Blue/Green/Purple/Orange (1-2 hits, 15-50 points).

## 2. Force Fields / Arrows (Planned)
A key feature from z-ball, "Arrows" are zones that apply a strong force to the ball, often making gameplay difficult ("anxiety inducing").

### Mechanics
- **Visuals**: Arrows pointing in a direction (Up, Down, Left, Right, Diagonal).
- **Behavior**: When the ball enters the zone (Area2D), its velocity is modified.
  - **Repel/Reverse**: Some arrows push the ball back towards the paddle at high speed.
  - **Redirect**: Force the ball into specific paths (e.g., towards hard-to-reach bricks).
  - **Bouncy**: Act like bumpers that impart extra velocity.

### Implementation (Proposed)
- **Scene**: `scenes/level_elements/force_arrow.tscn`
- **Properties**:
  - `force_vector`: Vector2 (direction and magnitude).
  - `is_instant`: Boolean (if true, sets velocity; if false, adds acceleration).

## 3. Advanced Brick Mechanics (Planned)
- **Penetrating Spin Interaction**:
  - Normal collisions bounce the ball.
  - If ball has "Penetrating Spin" (high RPM), it destroys the brick *without* bouncing, effectively passing through it.
  - This requires the Ball script to check its spin vs brick resistance before calculating collision physics.

## 4. Level Layout (Current vs Planned)

**Current**:
- A test grid is generated at runtime in `scripts/main.gd` (`create_test_level()`).
- No external level data format yet.

**Planned**:
- **Grid System**: 1280x720 play area.
- **Data Format**: JSON or Custom Resource defining:
  - Brick positions and types.
  - Force Field positions and directions.
  - Power-up drop tables.

## Tasks
- [ ] Implement `ForceArrow` scene (Area2D).
- [ ] Add physics override logic to `Ball.gd` to handle force zones.
- [ ] Implement Penetrating Spin logic in `Ball.gd` and `Brick.gd`.
- [ ] Define a future level editor workflow (tooling TBD).

## Level System
Level data, loader, and progression tasks live in `Tasks/level-system.md` to avoid overlap.
