# Tile & Level System Implementation Plan

## Overview
This document outlines the design for the level elements, including bricks, unbreakable obstacles, and the new dynamic force fields.

## 1. Brick System (Existing)
- **Normal Brick**: 1 hit, breaks.
- **Strong Brick**: 2 hits, breaks.
- **Unbreakable Block**: Impervious to normal balls.

## 2. Force Fields / Arrows (New)
A key feature from z-ball, "Arrows" are zones that apply a strong force to the ball, often making gameplay difficult ("anxiety inducing").

### Mechanics
- **Visuals**: Arrows pointing in a direction (Up, Down, Left, Right, Diagonal).
- **Behavior**: When the ball enters the zone (Area2D), its velocity is modified.
  - **Repel/Reverse**: Some arrows push the ball back towards the paddle at high speed.
  - **Redirect**: Force the ball into specific paths (e.g., towards hard-to-reach bricks).
  - **Bouncy**: Act like bumpers that impart extra velocity.

### Implementation
- **Scene**: `scenes/level_elements/force_arrow.tscn`
- **Properties**:
  - `force_vector`: Vector2 (direction and magnitude).
  - `is_instant`: Boolean (if true, sets velocity; if false, adds acceleration).

## 3. Advanced Brick Mechanics (New)
- **Penetrating Spin Interaction**:
  - Normal collisions bounce the ball.
  - If ball has "Penetrating Spin" (high RPM), it destroys the brick *without* bouncing, effectively passing through it.
  - This requires the Ball script to check its spin vs brick resistance before calculating collision physics.

## 4. Level Layout
- **Grid System**: 1280x720 play area.
- **Data Format**: JSON or Custom Resource defining:
  - Brick positions and types.
  - Force Field positions and directions.
  - Power-up drop tables.

## Tasks
- [ ] Implement `ForceArrow` scene (Area2D).
- [ ] Add physics override logic to `Ball.gd` to handle force zones.
- [ ] Implement Penetrating Spin logic in `Ball.gd` and `Brick.gd`.
- [ ] Create test level with Arrows.
