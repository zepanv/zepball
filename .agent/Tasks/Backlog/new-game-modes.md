# New Game Modes: Time Attack & Survival

## Status: 📋 BACKLOG

Adds **Time Attack** as a third challenge mode variant in the Set Select dropdown, and **Survival** as a standalone mode accessible from the Main Menu. Both modes share a single save migration (version 3) and new Stats screen tabs.

Last Updated: 2026-02-24

---

## Overview

| Mode | Entry Point | Description |
|------|------------|-------------|
| **Time Attack** | Set Select → Challenge dropdown | Complete a pack as fast as possible. Timer is the only ranked metric. |
| **Survival** | Main Menu → SURVIVAL button | Endless procedurally-generated waves with increasing difficulty. Play until all lives lost. |

---

## Time Attack Mode

### Behavior

**Challenge dropdown:** Adds a third option to the existing Challenge Mode dropdown on Set Select (after Normal, Iron Ball, One Life). Pack-run only — LEVELS buttons are disabled when selected, same as other challenge modes.

**Timer:**
- Starts on first ball launch of the pack run
- Pauses when the ball is in READY state (attached to paddle after a life loss)
- Pauses when the game is paused (ESC)
- Resumes when the ball is launched
- Stops when the final level of the pack is complete
- Discarded entirely if the run ends in Game Over (no partial-run recording)

**Format:** MM:SS displayed in HUD. Store as total elapsed seconds (integer) in save data.

**Scoring:**
- Normal score accumulates throughout the run and **can update the regular `set_high_scores` namespace** as usual — a Time Attack run is not excluded from the normal leaderboard
- The challenge leaderboard is time-based only (fastest pack completion time)
- Time is only recorded on full pack completion

**Lives:** Standard 3 lives — no override.

**HUD:**
- Logo area replaced on game start (same pattern as Iron Ball / One Life)
- > **TBD:** Exact logo area format. Options:
>   - `"TIME ATTACK"` static (time shown in a new TopBar label)
>   - `"TIME ATTACK\n01:23"` two-line (mode name + live timer in logo slot)
>   - `"01:23"` timer only (simplest, mode context from context)
>   Recommendation: two-line approach keeps all info in one zone without layout changes, but needs to fit the existing label size.

**Stats tab:** Time Attack tab is added to the set high scores section of the Stats screen. Sort order is **ascending** (lower = better), and the column header reads "Best Time" rather than "High Score". Tab order: Normal | Iron Ball | One Life | Time Attack.

**High scores:** Separate namespace `time_attack_set_high_scores` in save data, keyed by `pack_id`.

---

## Survival Mode

### Behavior Overview

Survival is a standalone mode — it does not use pack data or level JSON. The existing game scene (`main.tscn`) is reused with a **survival mode flag** that replaces the level loader with a `SurvivalGenerator` and replaces level progression with wave cycling. See [Scene Architecture](#scene-architecture) below.

### Waves

- **One wave = one screenful of bricks**
- When all breakable bricks in a wave are cleared, a countdown plays: **"WAVE [N+1] INCOMING"** at 3… 2… 1…, then the next wave spawns
- > **TBD:** Reuse the existing `LevelIntro` overlay in hud.gd for the countdown text, or add a dedicated wave transition label. LevelIntro is the natural fit (already handles fade + hold + fade out) but currently displays level name/description — needs a survival-mode branch.

- Wave number is tracked in GameManager (or a small survival state struct). There is no completion state — the run ends only when all lives are lost.

### Starting Configuration

| Parameter | Value |
|-----------|-------|
| Wave 1 brick count | ~10 bricks |
| Starting brick type | 1-hit only (NORMAL / RED / BLUE / GREEN) |
| Layout | Random sparse placement |
| Ball speed | Normal base (500 × difficulty multiplier) |
| Indestructibles | None until wave 5 |

### Brick Tier Progression

> **Needs work** — The wave thresholds (X values) and exact brick mix per tier are tuning constants. They should be defined as exported or config variables, not hardcoded, so they can be adjusted without code changes after playtesting.

Three candidate curves shown below. Tier transitions are cumulative (each tier adds to the previous pool).

| Tier | **Option A** (Gradual) | **Option B** (Fast Ramp) | **Option C** (Slow Burn) |
|------|------------------------|--------------------------|--------------------------|
| **0** Waves 1–? | NORMAL, RED, BLUE, GREEN — simple grid layouts | Same | Same |
| **1** | 2-hit bricks (STRONG, PURPLE) + diamond / polygon shapes + denser layouts | Waves 3–4 | Waves 6–9 |
| **2** | GOLD, ORANGE (high-value) + POWERUP_BRICKs + shaped formations | Waves 5–8 | Waves 10–14 |
| **3** | BOMB bricks + glossy diamond/polygon (DIAMOND_GLOSSY, POLYGON_GLOSSY = 2-hit shaped) | Waves 9–12 | Waves 15–19 |
| **4** | Full pool mix — all types in rotation | Wave 13+ | Wave 20+ |

**Indestructibles:** First appear at **wave 5** — 1 to 2 bricks only. Count can scale up every few tiers (exact cadence TBD).

**Formation patterns:** As tiers increase, the generator should move from pure-scatter toward structured shapes (clusters, L-shapes, hollow rings). Exact pattern templates are part of `SurvivalGenerator` design.

### Difficulty Scaling (Ball Speed)

- Ball speed increases by a fixed step every **Y waves** (Y = TBD tuning constant)
- Speed is capped at **3× the wave-1 starting speed**
- > **Design note:** Wave-1 speed is `500 × difficulty_multiplier`. On Hard that is 600; 3× = 1800, which may be physically unpleasant. Consider whether the survival speed cap should be **absolute** (e.g., always cap at 1500 regardless of difficulty) rather than relative. Flag for playtesting.

### HUD

- Logo area replaced at game start
- > **TBD:** Exact format for logo replacement:
>   - `"WAVE 3"` — updates each wave transition (clean, minimal)
>   - `"SURVIVAL • WAVE 3"` — more descriptive
>   - `"SURVIVAL"` static + wave number shown elsewhere
>   Recommendation: `"WAVE 3"` updating each wave, consistent with the LevelIntro countdown.

### Game Over Screen

When all lives are lost in Survival, the existing `game_over.tscn` is reused with survival-specific modifications:
- Wave reached displayed prominently (new label)
- Final score displayed as usual
- Top-run comparison shown (e.g., "Your best: Wave 15, 32,400 pts")
- **"Continue Set"** button hidden (nothing to continue)
- **"Retry"** button relabeled **"Play Again"** (restarts survival from wave 1)
- **"Main Menu"** button unchanged

### High Score / Leaderboard

- Top **10 runs** stored, sorted by score descending
- Each entry: `{ score, wave, date }`
- Shown in a dedicated **Survival tab** on the Stats screen
- If no runs yet: "No runs yet" placeholder

### Scene Architecture

**Reuse `main.tscn` with a survival mode flag.** Rationale: the existing scene already contains ball, paddle, physics, power-ups, scoring, lives, HUD, pause, and game over — duplicating all of this in a new scene is unnecessary.

The key divergence points from normal gameplay:

| Normal play | Survival |
|-------------|----------|
| `load_level_ref(pack_id, level_index)` loads JSON bricks | `SurvivalGenerator.generate_wave(wave_number)` populates `BrickContainer` |
| `remaining_breakable_bricks == 0` → level complete → load next level | `remaining_breakable_bricks == 0` → wave complete → countdown → generate next wave |
| `current_pack_id` / `current_level_index` identity | `current_wave` integer identity |
| Pack run: score/lives carry over | Same — lives and score persist across waves |

**New script: `scripts/survival_generator.gd`**
- Stateless utility (or autoload — TBD based on how main.gd calls it)
- `generate_wave(wave_number: int) -> Array[BrickData]` — returns brick placement data for the wave
- Reads tier config constants to determine brick type pool and layout rules
- Handles indestructible placement (wave 5+, separate from breakable count)
- Indestructibles must **not** be added to `remaining_breakable_bricks`

**`main.gd` additions:**
- `var is_survival_mode: bool` flag set by MenuController before scene load
- `var current_wave: int` replaces level identity in survival
- `_load_survival_wave()` called instead of `load_level_ref()` on wave start and wave transition
- `_on_survival_wave_complete()` called when `remaining_breakable_bricks == 0` in survival mode — triggers countdown then next wave instead of level complete screen
- `_apply_survival_speed_step()` — called on each wave transition when the speed step threshold is reached

---

## Shared Infrastructure

### Save Migration (Version 2 → 3)

Follow `.agent/SOP/critical-workflows.md`. Challenge modes handles 1 → 2. This migration handles 2 → 3.

**Version guard:** `if data.get("version", 0) < 3`

**New fields to inject with defaults:**
```json
"time_attack_set_high_scores": {},
"survival_top_runs": []
```

**New helper methods in `save_manager.gd`:**
- `get_time_attack_set_high_score(pack_id) -> int` — returns best time in seconds (0 = no run)
- `save_time_attack_set_high_score(pack_id, time_seconds: int)`
- `get_survival_top_runs() -> Array` — returns array of `{score, wave, date}`, max 10
- `save_survival_run(score: int, wave: int)` — inserts, sorts by score desc, trims to 10

### Stats Screen Tabs

**Set high scores section** gains a fourth tab: **Normal | Iron Ball | One Life | Time Attack**
- Time Attack tab: ascending sort, "Best Time" header, MM:SS display format
- Empty namespace → "No runs yet" placeholder (consistent with Iron Ball / One Life)

**Survival section** is a new independent section (not pack-keyed):
- Heading: "SURVIVAL"
- Lists top 10 runs: Wave | Score | Date columns
- Empty → "No runs yet" placeholder

---

## Files to Change

### New Files
- `scripts/survival_generator.gd` — Wave brick layout generator

### Modified Files

#### 1. `scripts/save_manager.gd` — Save Migration (REQUIRED FIRST)
- Bump save version: `2` → `3`
  - Note: challenge-modes.md handles `1` → `2`; if implementing both together, a single migration from `1` → `3` is acceptable
- Add migration logic for new fields (see above)
- New helper methods for time attack + survival (see above)

#### 2. `scripts/ui/menu_controller.gd` — Mode State + Survival Entry
- `start_survival()` — sets survival flag, loads main.tscn
- `show_survival_over(final_score, wave)` — calls SaveManager to record run, shows game over scene in survival context
- `show_set_complete()` — when Time Attack mode active, call `SaveManager.save_time_attack_set_high_score(pack_id, elapsed_time)` before showing set complete screen
- Expose `get_challenge_mode() -> String` already planned in challenge-modes.md; Time Attack adds `"time_attack"` as a fourth valid value

#### 3. `scripts/ui/main_menu.gd` + `scenes/ui/main_menu.tscn` — Survival Button
- Add **SURVIVAL** button to main menu
- > **TBD:** Exact placement in menu button order (currently: PLAY, STATS, SETTINGS, QUIT). Likely between PLAY and STATS.
- On press: `MenuController.start_survival()`

#### 4. `scripts/survival_generator.gd` — New Script
- `generate_wave(wave_number: int) -> Array` — returns brick layout for BrickContainer population
- Tier config constants (exported for tuning): wave thresholds, brick type pools, layout patterns, indestructible scale curve, speed step interval, speed cap multiplier

#### 5. `scripts/main.gd` — Survival Mode Branch
- `var is_survival_mode: bool`
- `var current_wave: int`
- `var survival_speed_multiplier: float = 1.0`
- Override level-load path when `is_survival_mode == true`
- Wave completion detection and transition logic
- Speed step application on wave transitions

#### 6. `scripts/game_manager.gd` — Time Attack Timer + Wave Tracking
- `var time_attack_elapsed: float` — accumulates seconds
- `var time_attack_running: bool` — controlled by ball launch/land/pause signals
- Timer runs in `_process()` when `time_attack_running == true`
- `start_time_attack_timer()` / `pause_time_attack_timer()` / `stop_time_attack_timer() -> int` (returns integer seconds)
- `var current_wave: int` (for survival, incremented by main.gd)

#### 7. `scripts/hud.gd` — Timer + Wave Display
- On game start, check `MenuController.get_challenge_mode()`
  - `"time_attack"` → replace logo with Time Attack display (format TBD, see above)
  - `"normal"` / `"iron_ball"` / `"one_life"` → existing behavior (challenge-modes.md)
- For survival: check `MenuController.is_survival_mode` → replace logo with wave display (format TBD)
- Connect to `GameManager` timer signal (or poll `time_attack_elapsed`) to update timer label each frame

#### 8. `scripts/ui/game_over.gd` — Survival Modifications
- If survival context:
  - Show wave reached label
  - Relabel Retry → "Play Again"
  - Hide "Continue Set" button
  - Show top-run comparison from SaveManager

#### 9. `scenes/ui/stats.tscn` + `scripts/ui/stats.gd` — New Tabs
- Add Time Attack tab to set high scores section (4th tab, ascending sort, MM:SS display)
- Add Survival section below set scores (independent, top 10 runs: wave + score + date)

#### 10. `scenes/ui/set_select.tscn` + `scripts/ui/set_select.gd` — Time Attack Dropdown
- Add `"Time Attack"` as 4th option in the Challenge Mode `OptionButton`
- Description: `"Complete the pack as fast as possible. Time is the only ranked metric."`
- On select, set `MenuController.current_challenge_mode = "time_attack"`
- LEVELS buttons disabled (same as Iron Ball / One Life)

---

## Implementation Order

Work in this order to avoid depending on unfinished pieces:

1. **SaveManager** — v3 migration + new helpers (everything reads from here)
2. **MenuController** — survival entry point + time attack score saving
3. **SurvivalGenerator** — brick layout logic (needed before main.gd survival branch)
4. **main.gd** — survival mode branch + wave management
5. **game_manager.gd** — time attack timer + wave tracking
6. **main_menu** — Survival button
7. **set_select** — Time Attack dropdown option
8. **hud.gd** — timer display + wave display
9. **game_over.gd** — survival summary modifications
10. **stats** — Time Attack tab + Survival section

---

## TBD / Needs Decision Before Implementation

| Item | Options | Notes |
|------|---------|-------|
| Time Attack HUD format | Two-line logo (`TIME ATTACK\n01:23`) vs separate label | Two-line keeps layout changes minimal |
| Survival HUD format | `WAVE 3` (updating) vs `SURVIVAL • WAVE 3` | `WAVE 3` updating is cleanest |
| Wave transition UI | Reuse LevelIntro overlay vs new label | LevelIntro already handles fade + hold + fade out |
| Survival speed cap | Relative (3× start speed) vs absolute ceiling | Relative may be too fast on Hard; flag for playtesting |
| Survival speed step interval (Y) | Tuning constant | Define in SurvivalGenerator config |
| Brick tier unlock waves (X) | Tuning constant (see tier table options A/B/C) | Option A (Gradual) is recommended starting point |
| Indestructible scale curve | 1–2 at wave 5, +1 per tier? | TBD, define in SurvivalGenerator config |
| Main menu button order | PLAY / SURVIVAL / STATS / SETTINGS / QUIT | TBD |
| Save migration single-step | 1→3 if implementing alongside challenge-modes | Coordinate with challenge-modes.md v2 migration |

---

## Out of Scope (Future)

- Time Attack per-level best times (pack-level only for now)
- Time Attack for individual level play
- Survival mid-run save/resume
- Survival seeded runs (reproducible layouts)
- Stacking Time Attack + other challenge modes
- Survival difficulty selector (always Normal-equivalent rules for now)
- Survival achievements (e.g., "Reach wave 20")

---

## Related Docs
- `challenge-modes.md` — Iron Ball & One Life (shares dropdown, leaderboard infrastructure, save migration chain)
- `future-features.md` — parent backlog (Time Attack, Survival entries)
- `System/architecture.md` — GameManager, main.gd, HUD, save system details
- `SOP/critical-workflows.md` — save migration SOP, commit format
