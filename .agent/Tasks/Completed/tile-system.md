# Tile & Brick System

## Status: 🔶 PARTIALLY IMPLEMENTED

## Overview
Core brick types and particle effects are implemented. Advanced tile mechanics (force zones, penetrating spin, data-driven special tiles) are still planned.

## Implemented
- Brick types: Normal, Strong, Unbreakable, Gold, Red, Blue, Green, Purple, Orange, Bomb.
- Advanced bricks: Diamond and Pentagon (glossy variants are 2-hit).
- Brick hit logic with multi-hit support.
- Particle effects on break with color matched to brick type.
- Sprite-based visuals (32x32 scaled to 48x48).
- Angled collision shapes for diamond/pentagon bricks.

## Not Implemented (Tracked in Backlog)
- Force Arrow / Force Field zones that redirect or repel the ball.
- Penetrating Spin interaction (ball passes through bricks at high spin).
- Data-driven placement for special tiles in level JSON.
- Level authoring workflow for special tiles.

## Related Docs
- `Tasks/Backlog/future-features.md`
- `Tasks/Completed/level-system.md`
