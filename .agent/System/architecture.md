# Zep Ball - System Architecture

## Overview
Zep Ball is a 2D breakout/arkanoid-style game built with Godot 4.6. The paddle sits on the right side of the playfield, and the ball travels leftward to break bricks. The game features a complete menu system, 10 levels with progression, difficulty modes, combo multipliers, statistics tracking, achievements, and customizable settings.

## Project Structure
```
zepball/
├── project.godot              # Project configuration (window size, input map, autoloads)
├── scenes/
│   ├── main/main.tscn         # Main gameplay scene
│   ├── gameplay/              # Reusable gameplay components
│   │   ├── ball.tscn          # Ball with physics and trail
│   │   ├── paddle.tscn        # Vertical paddle with power-up effects
│   │   ├── brick.tscn         # Breakable bricks with particles
│   │   └── power_up.tscn      # Collectible power-ups
│   └── ui/                    # Menu screens
│       ├── main_menu.tscn     # Start screen with difficulty selection
│       ├── level_select.tscn  # Level browser with unlock status
│       ├── game_over.tscn     # Game over screen
│       ├── level_complete.tscn # Level victory screen
│       ├── stats.tscn         # Statistics and achievements viewer
│       └── settings.tscn      # Game settings configuration
├── scripts/
│   ├── main.gd                # Main gameplay controller
│   ├── game_manager.gd        # Game state and scoring (autoload)
│   ├── ball.gd                # Ball physics and collision
│   ├── paddle.gd              # Paddle movement and input
│   ├── brick.gd               # Brick types and breaking logic
│   ├── power_up.gd            # Power-up movement and collection
│   ├── camera_shake.gd        # Screen shake effects
│   ├── hud.gd                 # In-game UI overlay
│   ├── power_up_manager.gd    # Power-up timer system (autoload)
│   ├── difficulty_manager.gd  # Difficulty modes (autoload)
│   ├── save_manager.gd        # Save data and persistence (autoload)
│   ├── level_loader.gd        # Level loading from JSON (autoload)
│   └── ui/
│       ├── menu_controller.gd # Scene transitions and flow (autoload)
│       ├── main_menu.gd       # Main menu logic
│       ├── level_select.gd    # Level selection grid
│       ├── game_over.gd       # Game over screen logic
│       ├── level_complete.gd  # Level complete screen logic
│       ├── stats.gd           # Statistics display
│       └── settings.gd        # Settings screen logic
├── levels/                    # Level definitions (JSON)
│   ├── level_01.json through level_10.json
├── assets/
│   └── graphics/
│       ├── backgrounds/       # 7 background images
│       ├── bricks/            # Brick sprite textures
│       └── powerups/          # Power-up sprite atlas
└── .agent/                    # Documentation (this file)
```

## Autoload Singletons (Global Systems)
These nodes are always loaded and accessible throughout the game:
1. **PowerUpManager** - `scripts/power_up_manager.gd` - Manages timed power-up effects
2. **DifficultyManager** - `scripts/difficulty_manager.gd` - Difficulty settings and multipliers
3. **SaveManager** - `scripts/save_manager.gd` - Save data, high scores, statistics, achievements
4. **LevelLoader** - `scripts/level_loader.gd` - Loads levels from JSON files
5. **MenuController** - `scripts/ui/menu_controller.gd` - Scene transitions and game flow

## Runtime Scene Graph (Gameplay - main.tscn)
```
Main (Node2D) [scripts/main.gd]
├── GameManager (Node) [scripts/game_manager.gd] (group: game_manager)
├── Camera2D [scripts/camera_shake.gd]
├── Background (ColorRect) [runtime: replaced by TextureRect in CanvasLayer]
├── PlayArea (Node2D)
│   ├── Walls (Node2D)
│   │   ├── TopWall (StaticBody2D + CollisionShape2D)
│   │   ├── BottomWall (StaticBody2D + CollisionShape2D)
│   │   └── LeftWall (StaticBody2D + CollisionShape2D)
│   ├── Paddle (CharacterBody2D) [instance: paddle.tscn] (group: paddle)
│   ├── Ball (CharacterBody2D) [instance: ball.tscn] (group: ball)
│   └── BrickContainer (Node2D) [dynamically populated from level JSON]
└── UI (CanvasLayer)
    └── HUD (Control) [scripts/hud.gd]
        ├── TopBar (Score/Logo/Lives labels)
        ├── PowerUpIndicators (VBoxContainer, top-right)
        ├── MultiplierLabel (Label, top-left) - Shows active score bonuses
        ├── ComboLabel (Label, center) - Shows combo counter
        ├── PauseMenu (Control) - Enhanced pause screen
        ├── LevelIntro (Control) - Level name fade-in/out
        └── DebugOverlay (PanelContainer) - FPS and ball stats (backtick key)
```

## Core Systems and Responsibilities

### 1. Main Gameplay Controller (`scripts/main.gd`)
**Purpose**: Orchestrates gameplay scene, level loading, and game loop.

**Responsibilities**:
- Loads level data from LevelLoader and instantiates bricks
- Connects signals between ball, GameManager, HUD, and bricks
- Tracks `remaining_breakable_bricks` for level completion detection
- Handles ball loss logic (life loss only if last ball in play)
- Spawns and manages power-ups with 20% drop chance
- Manages multi-ball behavior from TRIPLE_BALL power-up
- Loads random background image at startup with dimming
- Triggers camera shake on brick breaks (intensity scales with combo)
- Handles stuck ball detection and auto-escape boost
- Shows level intro display with fade animation

**Key Methods**:
- `create_level()` - Loads level from JSON and spawns bricks
- `_on_ball_lost(ball)` - Checks if main ball, handles life loss
- `_on_brick_broken(score_value)` - Awards points, tracks progress, checks completion
- `spawn_additional_balls_with_retry()` - Creates extra balls with retry logic

### 2. Game State Manager (`scripts/game_manager.gd`)
**Purpose**: Central game state machine and scoring system.

**State Machine**:
- `MAIN_MENU` - Not in gameplay
- `READY` - Ball attached to paddle, waiting for launch
- `PLAYING` - Active gameplay
- `PAUSED` - Game paused (ESC key)
- `LEVEL_COMPLETE` - All bricks destroyed
- `GAME_OVER` - No lives remaining

**Player Stats**:
- `score` - Current score with multipliers applied
- `lives` - Remaining lives (starts at 3)
- `combo` - Consecutive brick hits (combo multiplier)
- `no_miss_hits` - Streak without losing ball (streak multiplier)
- `is_perfect_clear` - True if no lives lost this level (2x bonus)

**Scoring System**:
```gdscript
// Score calculation order:
1. Base points (from brick type)
2. × Difficulty multiplier (0.8x Easy, 1.0x Normal, 1.5x Hard)
3. × Combo multiplier (1.0 + (combo - 3 + 1) * 0.1, if combo >= 3)
4. × Streak multiplier (1.0 + floor(no_miss_hits / 5) * 0.1, if hits >= 5)
5. Perfect Clear: Final score × 2 (if completed with all lives)
```

**Signals**:
- `score_changed(new_score)`
- `lives_changed(new_lives)`
- `combo_changed(new_combo)`
- `combo_milestone(combo_value)` - Every 5 hits (5, 10, 15...)
- `no_miss_streak_changed(hits)` - Updated on every hit
- `level_complete()` / `game_over()` / `state_changed(new_state)`

### 3. Paddle System (`scripts/paddle.gd` + `scenes/gameplay/paddle.tscn`)
**Purpose**: Player-controlled vertical paddle with power-up effects.

**Input Modes**:
- **Keyboard**: W/S or Arrow keys (speed × sensitivity multiplier)
- **Mouse**: Direct position following (lerped by sensitivity)

**Features**:
- Velocity tracking for ball spin mechanics
- Configurable sensitivity multiplier (0.5x - 2.0x from settings)
- Dynamic boundary clamping based on current height
- Power-up size changes with smooth tweening

**Power-Up Effects**:
- `apply_expand_effect()` - 130 → 180 height (15s)
- `apply_contract_effect()` - 130 → 80 height (10s)
- `reset_paddle_height()` - Back to 130 (base)

### 4. Ball Physics (`scripts/ball.gd` + `scenes/gameplay/ball.tscn`)
**Purpose**: Ball movement, collision, and spin mechanics.

**Physics**:
- Constant speed movement (BASE_SPEED = 500, adjusted by difficulty)
- Spin factor (0.3) - paddle velocity influences ball trajectory
- Max vertical angle (0.8) - prevents pure horizontal/vertical bounces
- Ball-to-ball collisions explicitly ignored (no physics conflicts)

**Collision Handling**:
- **Paddle**: Bounce + add spin from paddle velocity
- **Bricks**: Bounce + notify brick with impact direction
- **Walls**: Simple reflection
- **Out of bounds**: Right edge = lost, others = error (auto-correct)

**Special Features**:
- Stuck detection: Monitors movement over 2 seconds, applies escape boost if needed
- Trail particles: Cyan (normal speed), Yellow (SPEED_UP active)
- Trail toggling based on settings

**Power-Up Effects**:
- `apply_speed_up_effect()` - 500 → 650 speed (12s)
- `reset_ball_speed()` - Back to base × difficulty

### 5. Brick System (`scripts/brick.gd` + `scenes/gameplay/brick.tscn`)
**Purpose**: Breakable obstacles with varied types and scoring.

**Brick Types**:
| Type | Hits | Points | Color/Texture | Special |
|------|------|--------|---------------|---------|
| NORMAL | 1 | 10 | Cyan/Green | Standard brick |
| STRONG | 2 | 20 | Pink/Red glossy | Requires 2 hits |
| UNBREAKABLE | ∞ | 0 | Grey | Cannot be destroyed |
| GOLD | 1 | 50 | Gold glossy | High value |
| RED | 1 | 15 | Red | Themed brick |
| BLUE | 1 | 15 | Blue | Themed brick |
| GREEN | 1 | 15 | Green | Themed brick |
| PURPLE | 2 | 25 | Purple | High value, 2 hits |
| ORANGE | 1 | 20 | Orange | Mid-value |

**On Break**:
1. Emits `brick_broken(score_value)` signal
2. 20% chance to spawn random power-up
3. Plays particle burst (color-matched to brick) if particles enabled
4. Disables collision immediately
5. Waits 0.6s for particles, then removes from scene

### 6. Power-Up System (`scripts/power_up.gd` + `scripts/power_up_manager.gd`)
**Power-Up Types**:
| Type | Effect | Duration | Icon |
|------|--------|----------|------|
| EXPAND | Paddle height 130 → 180 | 15s | Green icon |
| CONTRACT | Paddle height 130 → 80 | 10s | Red icon |
| SPEED_UP | Ball speed 500 → 650 | 12s | Yellow icon |
| TRIPLE_BALL | Spawns 2 extra balls | Instant | Blue icon |

**Power-Up Manager** (Autoload):
- Tracks active timed effects and remaining time
- Automatically resets paddle/ball when effects expire
- Emits `effect_applied(type)` and `effect_expired(type)` signals
- Powers HUD timer display in top-right corner

### 7. Menu System (`scripts/ui/menu_controller.gd` + menu scenes)
**Purpose**: Scene transitions and game flow orchestration.

**Menu Screens**:
1. **Main Menu** (`scenes/ui/main_menu.tscn`)
   - Play button → Level Select
   - Difficulty selector (Easy/Normal/Hard)
   - Stats button → Statistics screen
   - Settings button → Settings screen
   - Quit button

2. **Level Select** (`scenes/ui/level_select.tscn`)
   - Grid of 10 level buttons
   - Shows unlock status and high scores
   - Only unlocked levels are clickable
   - Back to Main Menu button

3. **Game Over** (`scenes/ui/game_over.tscn`)
   - Final score display
   - High score comparison
   - Retry level button
   - Back to Level Select button

4. **Level Complete** (`scenes/ui/level_complete.tscn`)
   - Final score display
   - High score notification if beaten
   - "PERFECT CLEAR!" bonus message (2x score)
   - Next Level button (continues progression)
   - Level Select button

5. **Statistics** (`scenes/ui/stats.tscn`)
   - Global statistics display (bricks broken, power-ups, combos, etc.)
   - Achievement list with progress bars
   - 12 achievements total with unlock status
   - Back to Main Menu button

6. **Settings** (`scenes/ui/settings.tscn`)
   - Screen shake intensity (Off/Low/Medium/High)
   - Particle effects toggle
   - Ball trail toggle
   - Paddle sensitivity slider (0.5x - 2.0x)
   - Music volume slider (-40dB to 0dB)
   - SFX volume slider (-40dB to 0dB)
   - All settings persist via SaveManager

**MenuController Functions**:
- `show_main_menu()` / `show_level_select()` / `show_stats()` / `show_settings()`
- `start_level(level_id)` - Loads gameplay scene with specified level
- `show_game_over(final_score)` - Shows game over screen, saves high score
- `show_level_complete(final_score)` - Shows level complete, unlocks next level, checks perfect clear
- `restart_current_level()` - Reloads current level
- Difficulty locking: Unlocked in menus, locked during gameplay

### 8. Save System (`scripts/save_manager.gd`)
**Purpose**: Persistent player data, statistics, and achievements.

**Save Data Structure** (`user://save_data.json`):
```json
{
  "version": 1,
  "profile": {
    "player_name": "Player",
    "total_score": 0
  },
  "progression": {
    "highest_unlocked_level": 1,
    "levels_completed": [1, 2, 3]
  },
  "high_scores": {
    "1": 5420,
    "2": 3210
  },
  "statistics": {
    "total_bricks_broken": 1523,
    "total_power_ups_collected": 245,
    "total_levels_completed": 8,
    "total_playtime": 3725.5,
    "highest_combo": 27,
    "highest_score": 8940,
    "total_games_played": 42,
    "perfect_clears": 3
  },
  "achievements": ["first_blood", "combo_starter"],
  "settings": {
    "difficulty": "Normal",
    "music_volume_db": 0.0,
    "sfx_volume_db": 0.0,
    "screen_shake_intensity": "Medium",
    "particle_effects_enabled": true,
    "ball_trail_enabled": true,
    "paddle_sensitivity": 1.0
  }
}
```

**Achievement System** (12 Total):
- `first_blood` - Break your first brick (1 brick)
- `destroyer` - Break 1000 bricks
- `brick_master` - Break 5000 bricks
- `combo_starter` - Reach 5x combo
- `combo_master` - Reach 20x combo
- `combo_god` - Reach 50x combo
- `power_collector` - Collect 100 power-ups
- `champion` - Complete all 10 levels
- `perfectionist` - Complete a level without missing the ball (1 perfect clear)
- `flawless` - Get 10 perfect clears
- `high_roller` - Score 10,000 points in a single game
- `dedicated` - Play for 1 hour total

**Migration System**:
- Automatically detects old save formats
- Adds missing fields with defaults
- Preserves existing player progress
- See `SOP/godot-workflow.md` for save migration best practices

### 9. Level System (`scripts/level_loader.gd` + JSON files)
**Purpose**: Load and manage level definitions from JSON.

**Level Structure** (JSON):
```json
{
  "id": 1,
  "name": "Getting Started",
  "description": "Learn the basics and break some bricks!",
  "difficulty": "easy",
  "grid": {
    "columns": 8,
    "rows": 5,
    "brick_size": 48,
    "spacing": 4,
    "offset_x": 40,
    "offset_y": 100
  },
  "bricks": [
    {"row": 0, "col": 0, "type": "NORMAL"},
    {"row": 0, "col": 1, "type": "STRONG"}
  ]
}
```

**10 Levels**:
1. Getting Started (Tutorial - easy pattern)
2. The Wall (Stacked rows)
3. Checkerboard (Alternating pattern)
4. The Corridor (Narrow gaps)
5. Mixed Bag (All brick types)
6. Diamond Formation (Diamond shape)
7. Fortress (Unbreakable walls)
8. The Pyramid (Triangle pattern)
9. The Corridors (Multiple narrow paths)
10. The Gauntlet (Dense, hard pattern)

**LevelLoader Functions**:
- `level_exists(level_id)` - Check if level JSON exists
- `instantiate_level(level_id, brick_container)` - Spawn bricks in scene
- `get_level_info(level_id)` - Get name, description, metadata
- `get_next_level_id(current_id)` - Returns -1 if no more levels
- Automatically tracks total level count for progression

### 10. Difficulty System (`scripts/difficulty_manager.gd`)
**Purpose**: Game difficulty modes with multipliers.

**Difficulty Modes**:
| Mode | Ball Speed | Score Multiplier | Description |
|------|------------|------------------|-------------|
| Easy | 0.8x (400) | 0.8x | Slower, lower rewards |
| Normal | 1.0x (500) | 1.0x | Standard gameplay |
| Hard | 1.2x (600) | 1.5x | Faster, higher rewards |

**Features**:
- Difficulty locking: Prevents changes during active gameplay
- Auto-applies to ball speed on spawn and reset
- Score multiplier applied in `GameManager.add_score()`
- Difficulty selection saved to SaveManager
- Can be changed in Main Menu or via Settings

### 11. HUD System (`scripts/hud.gd`)
**Purpose**: In-game UI overlay with dynamic elements.

**HUD Elements**:
- **TopBar**: Score, Logo, Lives (always visible)
- **Difficulty Label**: "DIFFICULTY: NORMAL" (top-left, below score)
- **Multiplier Display**: Shows active score bonuses (top-left, below difficulty)
  - Example: "MULTIPLIERS:\nHard: 1.5x\nCombo: 1.4x\nStreak: 1.2x"
  - Color-coded: White (base), Yellow (1.1x-1.5x), Orange (1.5x+)
- **Combo Counter**: "COMBO x12!" (center, visible when combo >= 3)
  - Elastic bounce animation at milestones (5, 10, 15...)
- **Power-Up Timers**: Active effects with countdown (top-right)
- **Pause Menu**: Enhanced pause screen with level info, resume, restart, main menu
- **Level Intro**: Fade in/out display of level name and description
- **Debug Overlay**: FPS, ball count, velocity, speed, combo (backtick ` key)

**Signal Connections**:
- `GameManager.score_changed` → Update score label
- `GameManager.lives_changed` → Update lives label
- `GameManager.combo_changed` → Update combo display and multipliers
- `GameManager.no_miss_streak_changed` → Update multiplier display
- `GameManager.combo_milestone` → Trigger elastic bounce animation
- `GameManager.state_changed` → Show/hide pause/game over/level complete overlays
- `DifficultyManager.difficulty_changed` → Update difficulty label and multipliers
- `PowerUpManager.effect_applied/expired` → Add/remove power-up timers

### 12. Camera Shake (`scripts/camera_shake.gd`)
**Purpose**: Screen shake effects for game feel.

**Features**:
- `shake(intensity, duration)` - Trigger shake effect
- Intensity scales with combo multiplier in gameplay
- Settings-based multiplier: Off (0x), Low (0.5x), Medium (1.0x), High (1.5x)
- Gradual intensity reduction over duration
- Applied on brick breaks and special events

## Input Map (project.godot)
- `move_up`: Up Arrow, W - Paddle up
- `move_down`: Down Arrow, S - Paddle down
- `launch_ball`: Space, Left Mouse Button - Launch ball from paddle
- `restart_game`: R key - Restart current level
- `ui_cancel`: Escape - Toggle pause during gameplay

## Complete Gameplay Flow

### Menu Flow
```
Main Menu
  ├─→ PLAY → Level Select
  │            ├─→ Select Level → Gameplay (main.tscn)
  │            └─→ BACK → Main Menu
  ├─→ STATS → Statistics Screen → BACK → Main Menu
  ├─→ SETTINGS → Settings Screen → BACK → Main Menu
  └─→ QUIT → Exit game

Gameplay (main.tscn)
  ├─→ Level Complete → Level Complete Screen
  │                      ├─→ NEXT LEVEL → Next level gameplay
  │                      ├─→ LEVEL SELECT → Level Select
  │                      └─→ MAIN MENU → Main Menu
  └─→ Game Over → Game Over Screen
                   ├─→ RETRY → Restart current level
                   ├─→ LEVEL SELECT → Level Select
                   └─→ MAIN MENU → Main Menu
```

### Gameplay Loop
1. **Level Start**: Load level from JSON, spawn bricks, show level intro
2. **READY State**: Ball attached to paddle, press Space/Click to launch
3. **PLAYING State**: Ball in motion, paddle controls active
   - Hit bricks → Award points, build combo, spawn power-ups
   - Collect power-ups → Apply timed effects
   - Combo/Streak bonuses multiply score
   - ESC to pause → PAUSED State (pause menu shows)
4. **Lose Ball**: Falls off right edge
   - If last ball → Lose life, reset combo/streak, return to READY
   - If extra balls remain → Remove ball, continue playing
5. **Level Complete**: All breakable bricks destroyed
   - Check perfect clear (all lives intact → 2x score bonus)
   - Save high score, mark level completed
   - Unlock next level
   - Check and unlock achievements
   - Show Level Complete screen
6. **Game Over**: Lives reach 0
   - Save final score if high score
   - Show Game Over screen

### Score Multiplier Stacking Example
```
Base brick = 10 points
Difficulty = Hard (1.5x)
Combo = 12x (1.0 + 10 * 0.1 = 2.0x)
Streak = 15 hits (1.0 + 3 * 0.1 = 1.3x)

Calculation:
10 × 1.5 × 2.0 × 1.3 = 39 points per brick

If Perfect Clear at end:
Final score × 2
```

## Visual Polish and Assets

### Graphics
- **Brick Sprites**: Square textures (32x32) scaled to 48x48
  - 9 brick types with color-coded textures
  - Glossy variants for high-value bricks
- **Ball Trail**: CPUParticles2D with color changes
  - Cyan (normal speed)
  - Yellow (SPEED_UP active)
  - Toggleable in settings
- **Brick Particles**: 40 particles per break
  - Color-matched to brick type
  - Emits opposite to impact direction
  - Toggleable in settings
- **Backgrounds**: 7 random images with 0.85 alpha dimming
- **Power-Up Icons**: 5x5 sprite atlas (`powerups.jpg`)

### Audio System (Not Yet Implemented)
- Music volume control in settings (saved)
- SFX volume control in settings (saved)
- Audio buses ready: "Music" and "SFX"

## Data Persistence

### Save File Location
- **Path**: `user://save_data.json`
- **Format**: JSON with version number for migration
- **macOS**: `~/Library/Application Support/Godot/app_userdata/[ProjectName]/`
- **Linux**: `~/.local/share/godot/app_userdata/[ProjectName]/`
- **Windows**: `%APPDATA%/Godot/app_userdata/[ProjectName]/`

### Statistics Tracked
1. `total_bricks_broken` - Cumulative bricks destroyed
2. `total_power_ups_collected` - Cumulative power-ups picked up
3. `total_levels_completed` - Cumulative level clears
4. `total_playtime` - Total seconds played (not yet implemented)
5. `highest_combo` - Best combo multiplier achieved
6. `highest_score` - Best score in any single level
7. `total_games_played` - Total gameplay sessions (not yet implemented)
8. `perfect_clears` - Levels completed with all lives intact

### Settings Persistence
All 7 settings auto-save and load:
1. Difficulty (Easy/Normal/Hard)
2. Music volume (dB)
3. SFX volume (dB)
4. Screen shake intensity (Off/Low/Medium/High)
5. Particle effects (On/Off)
6. Ball trail (On/Off)
7. Paddle sensitivity (0.5x - 2.0x)

## Complex or Risky Areas

### 1. Triple Ball Spawn Logic (`scripts/main.gd:279-347`)
**Risk**: Extra balls can escape through walls if spawned at bad angles.
**Mitigation**:
- Retry system with 3 attempts and 0.5s delays
- Position validation before spawning (checks Y position)
- Safe angle ranges (45°-135° and 225°-315°)
- Failure message if all retries exhausted

### 2. Ball Stuck Detection (`scripts/ball.gd:287-325`)
**Risk**: Ball can get stuck in unbreakable brick formations.
**Mitigation**:
- Per-frame movement monitoring with dynamic threshold
- Threshold based on `current_speed * delta * 0.5`
- 2-second timer before applying escape boost
- Random escape angle in left hemisphere (135° - 225°)
- Always updates `last_position` for accurate comparison

### 3. Save Data Migration (`scripts/save_manager.gd:160-180`)
**Risk**: Old save files crash when accessing new fields.
**Mitigation**:
- Version number in save data
- Automatic migration on load
- Adds missing fields with defaults
- Preserves existing player progress
- See `SOP/godot-workflow.md` for best practices

### 4. Ball Collision During Scene Transition (`scripts/brick.gd:190`)
**Risk**: Brick tries to create timer during scene unload, causing crash.
**Mitigation**:
- Check `is_inside_tree()` before `await get_tree().create_timer()`
- Prevents crash when level completes during particle animation

### 5. Physics Callback Conflicts (`scripts/main.gd:276`)
**Risk**: Spawning objects during collision callback causes "flushing queries" error.
**Mitigation**:
- Use `call_deferred()` when spawning balls from collision events
- Delays spawn until after physics step completes

### 6. Settings Apply Without Restart
**Risk**: Changing settings doesn't affect current gameplay.
**Solution**: Settings are read on scene load (ball, paddle, camera on `_ready()`)
**Limitation**: Must return to main menu and reload level for changes to apply

## Related Docs
- `System/tech-stack.md` - Engine version, project settings, input configuration
- `Tasks/future-features.md` - Planned features (Time Attack, Survival mode, etc.)
- `SOP/godot-workflow.md` - Development workflows, save migration, debugging
- `Tasks/save-system.md` - Save system implementation details
- `Tasks/level-system.md` - Level JSON format and design guidelines
- `Tasks/ui-system.md` - Menu system architecture and flow

---

**Last Updated**: 2026-01-29 (Settings Menu, Score Multipliers, Statistics, Achievements)
**Godot Version**: 4.6
**Total Levels**: 10
**Total Achievements**: 12
