# Future Features - Pending Implementation

## Status: 📋 BACKLOG

These are features that have been designed but not yet implemented. All features below can be implemented without requiring new assets.

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

### Settings Menu
- **Description**: Customizable game settings
- **Features**:
  - **Gameplay**:
    - Screen shake intensity (Off, Low, Medium, High)
    - Particle effects (On/Off)
    - Ball trail (On/Off)
    - Combo flash intensity
  - **Controls**:
    - Paddle sensitivity slider
    - Key rebinding
  - **Display**:
    - Show FPS toggle
    - Level intro duration
  - Save all settings in SaveManager
- **Implementation**:
  - Create settings.tscn scene
  - Add settings dictionary to SaveManager
  - Apply settings on game load

### Enhanced Level Select
- **Description**: Better level browsing experience
- **Features**:
  - Level preview/thumbnail (procedurally generated from brick layout)
  - Completion percentage (X/Y bricks)
  - Star rating system (bronze/silver/gold based on score)
  - Filter buttons: All/Completed/Locked
  - Sort options: By level/By score/By completion
  - "Replay Tutorial" button for level 1
- **Implementation**:
  - Enhance level_select.gd
  - Add preview generation
  - Add filters and sorting logic

### Quick Actions
- **Description**: Convenience features
- **Features**:
  - "Play Again" button on level complete (restart same level)
  - "Next Level" as default button (auto-select)
  - Level complete auto-advance option (3 second countdown)
  - "Return to Last Level" on main menu (if mid-game)
  - ESC from gameplay returns to level select (with confirmation)
- **Implementation**:
  - Add quick action buttons to UI scenes
  - Store last played level in SaveManager
  - Add confirmation dialogs

### Skip Options
- **Description**: Let players skip animations
- **Features**:
  - Skip level intro (Space/Click to skip)
  - Disable level intros entirely (setting)
  - Fast forward level complete screen
  - Quick restart (skip menus)
- **Implementation**:
  - Add skip detection to level intro
  - Setting toggle in settings menu
  - Keyboard shortcuts for quick actions

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
- **Description**: Chain reactions for strategic gameplay
- **Features**:
  - Breaking a brick can trigger nearby bricks of same type
  - Chain breaks award bonus points (50 per chained brick)
  - Maximum chain distance: 2 bricks away
  - Visual effect showing chain propagation
  - Encourages strategic aiming
- **Implementation**:
  - Add chain detection in brick.gd
  - Recursive chain breaking
  - Chain visual effects (lightning between bricks)
  - Chain bonus scoring

### Paddle Abilities
- **Description**: Active abilities for the paddle
- **Features**:
  - **Charge Shot**: Hold Space to charge, release for power shot (breaks STRONG bricks in one hit)
  - **Temporary Shield**: Press S for 2-second shield (ball can't be lost)
  - **Cooldown System**: Abilities have cooldown timers
  - Visual indicators for charge/cooldown state
- **Implementation**:
  - Add ability system to paddle.gd
  - Cooldown timers in PowerUpManager
  - Visual feedback for charge levels
  - HUD indicators for ability status

### Score Multipliers
- **Description**: Persistent multipliers for skilled play
- **Features**:
  - **No-Miss Streak**: +10% score per 5 consecutive non-miss hits
  - **Perfect Clear**: 2x score if level completed without missing ball
  - **Speed Bonus**: +50% score if level completed under par time
  - Multiplier UI indicator showing current bonuses
  - Encourages careful, skilled play
- **Implementation**:
  - Track hit streaks in GameManager
  - Calculate multipliers on score addition
  - Show multiplier breakdown on level complete

---

## Implementation Priority

**High Priority:**
1. Settings Menu (most requested QoL feature)
2. Enhanced Level Select (better UX)
3. Time Attack Mode (easiest mode to add)

**Medium Priority:**
4. Quick Actions (small improvements, big impact)
5. Survival Mode (good for replayability)
6. Score Multipliers (enhances core gameplay)

**Low Priority:**
7. Advanced abilities (complex, can wait)
8. Brick Chains (nice to have)
9. Hardcore modes (for skilled players only)

---

## Notes
- All features designed to work without additional art assets
- Features use existing sprites, colors, and Godot built-ins
- Most features integrate with existing SaveManager system
- Consider user feedback before implementing complex features

---

Last Updated: 2026-01-29
