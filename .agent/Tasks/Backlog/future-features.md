# Future Features - Pending Implementation

## Status: 📋 BACKLOG

Features that have been designed but not yet implemented.

Last Updated: 2026-02-12

---

## Game Modes

### Time Attack Mode & Survival Mode
> **Extracted to dedicated task**: See `Tasks/Backlog/new-game-modes.md` for full design spec and implementation plan.
> Covers: Time Attack as a fourth challenge dropdown variant (pack-run only, MM:SS timer, time-keyed leaderboard), Survival as a standalone main menu mode (procedural wave generation, brick tier progression, speed scaling, top-10 run leaderboard), shared save migration v3, and Stats screen additions.

### Iron Ball Mode & One Life Mode
> **Extracted to dedicated task**: See `Tasks/Backlog/challenge-modes.md` for full design spec and implementation plan.
> Covers: Set Select UI restructure, challenge mode dropdown, Iron Ball power-up suppression, One Life lives override, separate leaderboards, HUD logo replacement, stats screen tabs, and save migration.

## Advanced Gameplay Features

### Advanced Tile Elements
> **Extracted to dedicated task**: See `Tasks/Backlog/advanced-tile-elements.md` for full PRD and implementation plan.
> Covers: Force Arrow tiles, Power-up Bricks, Enhanced Spin (dramatic curve), Penetrating Spin.

### Ball Speed Zones
- **Description**: Special bricks that affect ball speed temporarily
- **Features**:
  - **Slow Zone Brick** (Blue): Slows ball to 60% speed for 3 seconds
  - **Fast Zone Brick** (Red): Speeds ball to 140% speed for 3 seconds
  - Visual indicator on ball (glow effect)
  - Stack with power-ups
  - Adds strategic layer to brick breaking
- **Implementation**:
  - New brick types: SLOW_ZONE, FAST_ZONE
  - Temporary speed modifiers in ball.gd
  - Visual effects for zones

### Brick Chains
- **Description**: Connected bricks that break in sequence
- **Features**:
  - Chain reaction effect
  - Bonus points for chain length
  - Special brick type to trigger
- **Implementation**:
  - Add chain metadata in level JSON
  - Propagate break events
  - Add chain score bonus in GameManager

### Paddle Abilities
- **Description**: Skill-based paddle actions with cooldowns
- **Features**:
  - **Pulse**: Send shockwave to knock nearby balls upward
  - **Shield**: Temporary block on right edge to prevent ball loss
  - Visual indicators for charge/cooldown state
- **Implementation**:
  - Add ability system to paddle.gd
  - Cooldown timers in PowerUpManager
  - Visual feedback for charge levels
  - HUD indicators for ability status

---

---

## Implementation Priority

**High Priority:**
1. Advanced Tile Elements → see `Tasks/Backlog/advanced-tile-elements.md`
2. Time Attack Mode + Survival Mode → see `Tasks/Backlog/new-game-modes.md`

**Medium Priority:**
3. Ball Speed Zones (simple mechanic, strategic depth)

**Low Priority:**
5. Paddle Abilities (complex, needs careful balancing)
6. Brick Chains (nice to have, not essential)
7. Challenge Modes (Iron Ball, One Life) → see `Tasks/Backlog/challenge-modes.md`
8. New Game Modes (Time Attack, Survival) → see `Tasks/Backlog/new-game-modes.md`

---

## Notes
- All features designed to work without additional art assets
- Features use existing sprites, colors, and Godot built-ins
- Most features integrate with existing SaveManager system
- Consider user feedback before implementing complex features
