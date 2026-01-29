# Tile & Brick System

## Status: 🔶 PARTIALLY IMPLEMENTED

## Overview
Core brick types and particle effects are implemented. Advanced tile mechanics (force zones, special bricks, penetrating spin) are planned and tracked separately.

## Implemented
- Brick types: Normal, Strong, Unbreakable, Gold, Red, Blue, Green, Purple, Orange.
- Brick hit logic with multi-hit support.
- Particle effects on break with color matched to brick type.
- Sprite-based visuals (32x32 scaled to 48x48).

## Not Implemented (Tracked in Backlog)
- Force Arrow / Force Field zones that redirect or repel the ball.
- Penetrating Spin interaction (ball passes through bricks at high spin).
- Special bricks (e.g., Bomb tile with splash damage).
- Data-driven placement for special tiles in level JSON.
- Level authoring workflow for special tiles.

## Related Docs
- `Tasks/Backlog/tile-advanced-elements.md`
- `Tasks/Completed/level-system.md`
