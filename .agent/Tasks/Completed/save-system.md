# Save System & High Scores

## Status: ✅ COMPLETE

## Overview
SaveManager handles persistent player data: progression, per-level high scores, statistics, achievements, and settings (including audio levels). Integration is wired into menu flow and settings UI.

## Implemented Features
- JSON save file at `user://save_data.json` with schema versioning.
- Level progression tracking (unlock/completion).
- Per-level high scores.
- Statistics tracking and achievements (12 total).
- Settings persistence (difficulty, audio, effects, sensitivity).
- Migration for newly added fields.

## Save Data Structure (Current)
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
  "statistics": {
    "total_bricks_broken": 0,
    "total_power_ups_collected": 0,
    "total_levels_completed": 0,
    "total_playtime": 0.0,
    "highest_combo": 0,
    "highest_score": 0,
    "total_games_played": 0,
    "perfect_clears": 0
  },
  "achievements": [],
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

## Integration Points
- **MenuController**: updates high scores, unlocks levels, records completions, checks achievements.
- **Settings UI**: saves and applies audio/effects/sensitivity changes.
- **Gameplay**: increments brick and power-up statistics; updates combo/high score stats.

## Notes
- `total_playtime` increments during READY/PLAYING (flushed every 5s) and on scene exit.
- `total_games_played` increments per level start.

## Related Docs
- `Tasks/Completed/ui-system.md`
- `Tasks/Completed/tile-system.md`
- `Tasks/Backlog/audio-system.md`
- `System/architecture.md`
