# New Game Modes: Time Attack & Survival

## Status: ✅ COMPLETED

Adds **Time Attack** as a fourth challenge mode in Set Select and **Survival** as a standalone mode from Main Menu.

Completed Date: 2026-02-24
Last Updated: 2026-02-24

---

## Implementation Summary

- Save migration bumped to **v4** with new namespaces:
  - `time_attack_set_high_scores`
  - `time_attack_set_high_score_timestamps`
  - `survival_top_runs`
- Added Survival run helpers in `save_manager.gd`:
  - `get_survival_top_runs()`
  - `save_survival_run(score, wave)`
  - plus deterministic sort/trim (top 10)
- Added Time Attack save helpers in `save_manager.gd`:
  - `get_time_attack_set_high_score(pack_id)`
  - `save_time_attack_set_high_score(pack_id, time_seconds)`
- `MenuController` now supports:
  - `start_survival()`
  - `show_survival_over(final_score, wave)`
  - time-attack elapsed carry-over between pack levels
  - save-safe no-resume survival behavior (`last_played.mode = "survival"`, `in_progress = false`)
- `main.gd` now branches into Survival flow with:
  - procedural wave loading (`survival_generator.gd`)
  - wave-complete countdown transitions via HUD intro overlay reuse
  - wave-based speed scaling (`+50` every 3 waves, capped at 3x wave-1 speed)
- `game_manager.gd` now tracks and signals:
  - Time Attack timer state (`time_attack_elapsed`, `time_attack_running`)
  - survival wave state (`current_wave`)
  - new signals: `time_attack_timer_updated`, `survival_wave_changed`
- HUD (`hud.gd` + `main.tscn`) now supports supplementary top-bar labels:
  - Time Attack: `TIME ATTACK` + live `MM:SS`
  - Survival: `SURVIVAL` + `WAVE N`
  - center logo remains `ZepBall`
- Completion screens (`level_complete.gd`, `set_complete.gd`) now render challenge-context labels for all challenge modes:
  - mode-specific breakdown titles for Iron Ball / One Life / Time Attack
  - Time Attack run time is shown on both level-complete and set-complete flows
  - challenge-set personal/machine best messaging now resolves against challenge-specific leaderboards
- Survival HUD + pause context follow-up:
  - Survival top bar now uses center mode/detail text (`SURVIVAL` + `WAVE N`) so score/lives remain visible
  - Pause menu now shows survival-specific run context (`SURVIVAL: WAVE N`) instead of pack level metadata
- Main Menu now includes a **SURVIVAL** button above **EDITOR**.
- Set Select challenge dropdown now includes **Time Attack** (pack-run only, LEVELS disabled like other challenge modes).
- Game Over now has Survival context behavior:
  - Retry -> **PLAY AGAIN**
  - shows `Wave Reached`
  - shows personal best and machine best survival comparisons
  - never shows `CONTINUE SET`
- High Scores now includes:
  - Primary tabs: `OVERALL | SETS | LEVELS | SURVIVAL`
  - Set challenge tabs: `NORMAL | IRON BALL | ONE LIFE | TIME ATTACK`
  - Time Attack set ranking sorted ascending with `BEST TIME` column
  - Survival top-runs section (`Wave`, `Score`, `Date`) in dedicated Survival tab
- Strict warning cleanup:
  - fixed `high_scores.gd` time formatter integer division warning under warnings-as-errors builds
  - fixed `level_complete.gd`/`set_complete.gd` strict typing on Time Attack timer values (no Variant inference under warnings-as-errors)
- Survival wave stability follow-up:
  - fixed duplicate brick signal connection errors during wave transitions by removing queued bricks from the container before respawn and guarding signal connects with `is_connected()`
- Survival speed + power-up stacking follow-up:
  - speed up / slow down now use percentage multipliers (+30% / -30%) relative to each ball's current base speed
  - active speed effects now persist correctly through Survival wave speed-step updates
  - expiring one speed effect now reapplies the remaining active speed effect (if any) instead of resetting incorrectly

---

## Validation Notes

- Headless load/compile check passed:
  - `HOME=/tmp/zepball-godot-home godot --headless --quit --path .`
- Existing macOS certificate warning from Godot runtime remains non-blocking.

---

## Files Added

- `scripts/survival_generator.gd`

## Files Updated

- `scripts/save_manager.gd`
- `scripts/ui/menu_controller.gd`
- `scripts/main.gd`
- `scripts/game_manager.gd`
- `scripts/hud.gd`
- `scripts/ball.gd`
- `scripts/ui/main_menu.gd`
- `scripts/ui/set_select.gd`
- `scripts/ui/high_scores.gd`
- `scripts/ui/game_over.gd`
- `scripts/ui/level_complete.gd`
- `scripts/ui/set_complete.gd`
- `scenes/ui/main_menu.tscn`
- `scenes/ui/set_select.tscn`
- `scenes/ui/high_scores.tscn`
- `scenes/ui/game_over.tscn`
- `scenes/main/main.tscn`

---

## Related Docs

- `Tasks/Completed/challenge-modes.md`
- `System/architecture.md`
- `SOP/critical-workflows.md`
