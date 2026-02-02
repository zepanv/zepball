# Audio System Implementation Plan

## Status: ✅ COMPLETE

## Overview
Add sound effects and background music to improve game feel. Core playback is now in place; remaining SFX coverage still needed.

## Goals
- Provide immediate feedback for gameplay actions (hits, breaks, power-ups).
- Add background music for ambience.  Multiple tracks, ability to loop single track or play all in order or shuffle.
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
- `assets/audio/music/` (looping tracks, OGG)

## Tasks
- [x] Implement `AudioManager` autoload with helpers and crossfade music playback.
- [x] Create audio buses (SFX, Music) at runtime if missing.
- [x] Wire SFX for paddle hit, brick hit, wall hit.
- [x] Add background music playlist with loop-all, loop-one, shuffle, off modes.
- [x] Add Settings UI for music playback mode and loop-one track selection.
- [x] Verify Settings UI volume sliders drive AudioManager/buses correctly.
- [x] Add hotkeys for music volume, track skip, and pause toggle with on-screen toast.
- [x] Finish SFX coverage for remaining events:
  - power_up_collect (good vs bad)
  - life_lost
  - level_complete / game_over
  - combo_milestone
- [x] Export-safe music track discovery (ResourceLoader list + DirAccess fallback).

## Related Docs
- `Tasks/Completed/ui-system.md`
- `System/architecture.md`
