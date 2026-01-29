# Save System & High Scores Plan

## Status: ⏳ NOT STARTED

## Overview
Add persistent player data: high scores, unlocked levels, and player preferences. No persistence exists in the current codebase.

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

## Tasks
- [ ] Decide on storage format (ConfigFile vs JSON).
- [ ] Implement a `SaveManager` singleton for load/save.
- [ ] Integrate save hooks:
  - On game over (save best score).
  - On level complete (unlock next level, save score).
  - On settings change (audio/difficulty).
- [ ] Add schema versioning and default migration behavior.
- [ ] Document save file location and reset procedure.

## Related Docs
- `Tasks/ui-system.md`
- `Tasks/tile-system.md`
- `Tasks/audio-system.md`
- `System/architecture.md`
