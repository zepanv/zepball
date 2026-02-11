# Future Features - Pending Implementation

## Status: 📋 BACKLOG (Verified Against Code)

These are features that have been designed but not yet implemented (or are only partially implemented). Notes below reflect what is actually in code as of 2026-01-31.

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

---

## Quality of Life Improvements

### Level System Overhaul
- **Status**: Tracked in `Tasks/Backlog/level-overhaul.md`
- **Scope moved**: Pack format (`.zeppack`), in-game level editor, pack select rework, enhanced level select (thumbnails/stars/filter/sort), and third built-in pack.

### Settings Enhancements
- **Description**: Add advanced options beyond the current settings screen
- **Status**: ✅ Completed (see `Tasks/Completed/settings-enhancements.md`)

### Quick Actions
- **Description**: Convenience features
- **Status**: ✅ Completed (see `Tasks/Completed/quick-actions.md`)

### Skip Options
- **Description**: Let players skip animations
- **Features**:
  - Skip level intro (Space/Click to skip) ❌
  - Disable level intros entirely (setting) ✅
  - Fast forward level complete screen ❌
  - Quick restart (skip menus) ❌
- **Implementation**:
  - Input-based skip for intro (pending)
  - Fast-forward/skip on level complete screen (pending)
  - Keyboard shortcuts for quick actions (pending)

---

## Advanced Gameplay Features

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

## Implementation Priority

**High Priority:**
1. Time Attack Mode (easiest mode to add)

**Medium Priority:**
2. Survival Mode (good for replayability)
3. Skip Options (easy wins)
4. Advanced Tile Elements (force zones + data-driven placement)

**Low Priority:**
5. Advanced abilities (complex, can wait)
6. Brick Chains (nice to have)
7. Hardcore modes (for skilled players only)

---

## Notes
- All features designed to work without additional art assets
- Features use existing sprites, colors, and Godot built-ins
- Most features integrate with existing SaveManager system
- Consider user feedback before implementing complex features

---

Last Updated: 2026-02-11
### Advanced Tile Elements (from tile-advanced backlog)
- **Description**: Special brick/zone mechanics beyond standard bricks
- **Features**:
  - Force Arrow / Force Field zones that redirect or repel the ball
  - Penetrating Spin interaction (ball passes through bricks when spin threshold is met)
  - Data-driven placement for special tiles in level JSON
  - Level authoring workflow for special tiles (tooling TBD)
- **Implementation**:
  - Add new scene(s) for force zones
  - Extend level JSON schema and `scripts/level_loader.gd`
  - Update `scripts/ball.gd` to apply force zones and penetrating spin logic
  - Update `scripts/brick.gd` to support special behaviors
