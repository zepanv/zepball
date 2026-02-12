# Future Features - Pending Implementation

## Status: 📋 BACKLOG

Features that have been designed but not yet implemented.

Last Updated: 2026-02-12

---

## Game Modes

### Time Attack Mode
- **Description**: Complete levels as fast as possible
- **Features**:
  - Timer starts when ball launches
  - Stops when level completes
  - Track best times per level
  - Leaderboard showing fastest clears
  - Time bonus points for fast completion
- **Implementation**:
  - Add timer to GameManager
  - Show timer in HUD
  - Save best times in SaveManager
  - Add mode selector to main menu

### Survival Mode
- **Description**: Endless gameplay with increasing difficulty
- **Features**:
  - Randomly generated brick patterns
  - Difficulty increases over time (speed, brick toughness)
  - Track highest wave/score reached
  - No level completion - play until all lives lost
- **Implementation**:
  - Create endless level generator
  - Add difficulty scaling system
  - New game mode state in GameManager

### Iron Ball Mode
- **Description**: No power-ups challenge
- **Features**:
  - Power-ups don't spawn
  - Pure skill-based gameplay
  - Separate high scores for Iron Ball mode
  - Unlockable after completing all 10 levels
- **Implementation**:
  - Add mode flag to disable power-up spawning
  - Separate leaderboard in stats

### One Life Mode
- **Description**: Single life hardcore challenge
- **Features**:
  - Start with only 1 life
  - No extra life power-ups
  - Track highest level reached
  - Ultimate challenge for skilled players
- **Implementation**:
  - Override starting lives in GameManager
  - Disable extra life mechanics
  - Special badge for completing game in One Life mode

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
2. Time Attack Mode (easy to add, good replayability)

**Medium Priority:**
3. Survival Mode (endless gameplay mode)
4. Ball Speed Zones (simple mechanic, strategic depth)

**Low Priority:**
5. Paddle Abilities (complex, needs careful balancing)
6. Brick Chains (nice to have, not essential)
7. Hardcore modes (Iron Ball, One Life - for skilled players only)

---

## Notes
- All features designed to work without additional art assets
- Features use existing sprites, colors, and Godot built-ins
- Most features integrate with existing SaveManager system
- Consider user feedback before implementing complex features
