# Audio System Implementation Plan

## Status: ⏳ NOT STARTED

## Overview
Add sound effects and background music to improve game feel. Audio is currently not implemented in the codebase.

## Goals
- Provide immediate feedback for gameplay actions (hits, breaks, power-ups).
- Add background music for ambience.
- Provide volume controls (SFX/Music) in UI.

## Proposed Architecture
- **AudioManager** (autoload) to centralize playback and volume state.
- **Audio bus layout** in Godot:
  - Master
  - SFX
  - Music

## Proposed Files
- `scripts/audio_manager.gd` (autoload singleton)
- `assets/audio/sfx/` (hit, break, power-up, lose-life)
- `assets/audio/music/` (looping tracks)

## Tasks
- [ ] Create audio buses (SFX, Music) in Godot project settings.
- [ ] Implement `AudioManager` autoload with helpers:
  - `play_sfx(name)`
  - `play_music(name, loop=true)`
  - `set_sfx_volume(db)` / `set_music_volume(db)`
- [ ] Wire gameplay events to SFX:
  - Paddle hit
  - Brick hit / break
  - Power-up spawn / collect
  - Life lost
  - Level complete / game over
- [ ] Add background music track and loop configuration.
- [ ] Add UI volume sliders (link to `Tasks/ui-system.md`).

## Related Docs
- `Tasks/ui-system.md`
- `System/architecture.md`
