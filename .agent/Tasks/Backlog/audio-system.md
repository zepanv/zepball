# Audio System Implementation Plan

## Status: ⏳ NOT STARTED

## Overview
Add sound effects and background music to improve game feel. Audio playback and assets are not implemented; settings already include Music/SFX volume sliders and SaveManager fields.

## Goals
- Provide immediate feedback for gameplay actions (hits, breaks, power-ups).
- Add background music for ambience.
- Provide volume controls (SFX/Music) in UI (already present in Settings; needs real audio wiring).

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
- [ ] **Sound event placeholder system** (prep for audio):
  - [ ] Create `SoundManager` stub that prints event names.
  - [ ] Wire all gameplay events to sound placeholders.
  - [ ] Events: paddle_hit, brick_hit, brick_break, power_up_spawn, power_up_collect, life_lost, level_complete, game_over, combo_milestone.
  - [ ] Ready for drop-in audio implementation later.
- [ ] Create audio buses (SFX, Music) in Godot project settings.
- [ ] Implement `AudioManager` autoload with helpers:
  - `play_sfx(name)`
  - `play_music(name, loop=true)`
  - `set_sfx_volume(db)` / `set_music_volume(db)`
- [ ] Replace placeholder system with actual audio playback.
- [ ] Add audio assets:
  - Paddle hit
  - Brick hit / break
  - Power-up spawn / collect
  - Life lost
  - Level complete / game over
  - Combo milestone sounds
- [ ] Add background music track and loop configuration.
- [ ] Verify Settings UI volume sliders drive AudioManager/buses correctly (`Tasks/Completed/ui-system.md` already implements sliders).

## Related Docs
- `Tasks/Completed/ui-system.md`
- `System/architecture.md`
