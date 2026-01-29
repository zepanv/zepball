# Save System & High Scores Plan

## Status: 🔶 PARTIALLY IMPLEMENTED

## Overview
Add persistent player data: high scores, unlocked levels, and player preferences. SaveManager singleton implemented, integration with game flow pending.

## Goals
- Save high scores (global or per level).
- Save unlocked levels and progression.
- Save player settings (difficulty, audio volumes).

## Proposed Approach
- Use Godot's `user://` path for cross-platform persistence.
- Store data via `ConfigFile` or JSON.
- Keep data schema versioned for future migrations.

## Data Model (Draft)
- `profile`:
  - `player_name` (string, optional)
  - `best_score` (int)
- `levels`:
  - `unlocked` (int)
  - `best_scores` (dictionary: level_id -> int)
- `settings`:
  - `difficulty` (string)
  - `music_volume_db` (float)
  - `sfx_volume_db` (float)

## Implementation Details

### SaveManager Singleton ✅ IMPLEMENTED
- **Location**: `scripts/save_manager.gd`
- **Autoload**: Registered in `project.godot`
- **Storage**: JSON format at `user://save_data.json`
- **Version**: v1 with migration support

### Key Methods
- `is_level_unlocked(level_id)` - Check if level is accessible
- `is_level_completed(level_id)` - Check if level was beaten
- `unlock_level(level_id)` - Unlock next level
- `mark_level_completed(level_id)` - Mark level as completed
- `get_high_score(level_id)` - Get high score for a level
- `update_high_score(level_id, score)` - Update if score is higher
- `save_difficulty(difficulty_name)` - Save difficulty preference
- `get_saved_difficulty()` - Load difficulty preference
- `reset_save_data()` - Reset all progress (for testing)

### Save Data Structure
```json
{
  "version": 1,
  "profile": {
    "player_name": "Player",
    "total_score": 0
  },
  "progression": {
    "highest_unlocked_level": 1,
    "levels_completed": []
  },
  "high_scores": {
    "1": 5000,
    "2": 8200
  },
  "settings": {
    "difficulty": "Normal",
    "music_volume_db": 0.0,
    "sfx_volume_db": 0.0
  }
}
```

## Tasks
- [x] Decide on storage format (ConfigFile vs JSON) - **JSON chosen**
- [x] Implement a `SaveManager` singleton for load/save - **DONE**
- [x] Add schema versioning and default migration behavior - **DONE**
- [x] Document save file location and reset procedure - **DONE**
- [ ] Integrate save hooks:
  - On game over (save best score if applicable)
  - On level complete (unlock next level, save score)
  - On settings change (audio/difficulty)

## Save File Location
- **Development**: Check console for exact path via `SaveManager.get_save_file_location()`
- **Typical paths**:
  - Windows: `%APPDATA%\Godot\app_userdata\Zep Ball\save_data.json`
  - macOS: `~/Library/Application Support/Godot/app_userdata/Zep Ball/save_data.json`
  - Linux: `~/.local/share/godot/app_userdata/Zep Ball/save_data.json`

## Reset Procedure
Call `SaveManager.reset_save_data()` from code or delete the save file manually.

## Related Docs
- `Tasks/ui-system.md`
- `Tasks/tile-system.md`
- `Tasks/audio-system.md`
- `System/architecture.md`
