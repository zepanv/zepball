# New Game Modes: Time Attack & Survival

## Status: 📋 BACKLOG

Adds **Time Attack** as a fourth challenge mode variant in the Set Select dropdown, and **Survival** as a standalone mode accessible from the Main Menu. Both modes share migration/leaderboard infrastructure and new High Scores tabs.

Last Updated: 2026-02-24

---

## Overview

| Mode | Entry Point | Description |
|------|------------|-------------|
| **Time Attack** | Set Select → Challenge dropdown | Complete a pack as fast as possible. Timer is the only ranked metric. |
| **Survival** | Main Menu → SURVIVAL button | Endless procedurally-generated waves with increasing difficulty. Play until all lives lost. |

---

## Resolved Clarifications (2026-02-24)

- Time Attack and other challenge runs still update normal pack high scores
- Time Attack keeps existing perfect set bonus behavior
- Survival uses normal difficulty multipliers (speed/score behavior remains difficulty-aware)
- Survival wave transitions freeze gameplay and reattach the ball to the paddle before countdown/spawn
- Survival is one-shot: no `last_played` resume, and main-menu "RETURN TO LAST LEVEL" is hidden when last run was Survival
- Leaderboards for challenge/survival are surfaced in the High Scores screen via tabs
- Survival Game Over shows both personal-best and machine-best comparisons
- Tie handling is deterministic with reasonable fallback ordering (score/time primary, then date)
- Applies to official and custom packs
- Brand text standardized to `ZepBall` everywhere

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
- Perfect set bonus rules remain unchanged and still apply to normal score flow

**Lives:** Standard 3 lives — no override.

**HUD:**
- **Resolved:** TopBar shows a three-section layout for Time Attack — the center logo label remains `"ZepBall"` (unchanged), a left label reads `"TIME ATTACK"`, and a right label shows the live timer in `MM:SS` format. This means `hud.gd` must add/show left and right supplementary labels in the TopBar when in Time Attack mode (they are hidden in Normal / Iron Ball / One Life).

**High Scores tab:** Time Attack tab is added to the set high scores section of the High Scores screen. Sort order is **ascending** (lower = better), and the column header reads "Best Time" rather than "High Score". Tab order: Normal | Iron Ball | One Life | Time Attack.

**High scores:** Separate namespace `time_attack_set_high_scores` in save data, keyed by `pack_id`.

---

## Survival Mode

### Behavior Overview

Survival is a standalone mode — it does not use pack data or level JSON. The existing game scene (`main.tscn`) is reused with a **survival mode flag** that replaces the level loader with a `SurvivalGenerator` and replaces level progression with wave cycling. See [Scene Architecture](#scene-architecture) below.

### Waves

- **One wave = one screenful of bricks**
- When all breakable bricks in a wave are cleared, a countdown plays: **"WAVE [N+1] INCOMING"** at 3… 2… 1…, then the next wave spawns
- **Resolved:** Reuse the existing `LevelIntro` overlay in `hud.gd` for the wave transition countdown. Add a survival-mode branch so it displays `"WAVE [N+1] INCOMING"` / `"3… 2… 1…"` instead of level name/description.
- During wave transitions, gameplay is frozen and the ball is reattached to the paddle before the countdown starts, then relaunched by player input for the next wave.

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

Wave thresholds and exact brick mix are tuning constants. Define as exported variables in `SurvivalGenerator` so they can be adjusted without code changes after playtesting.

**Selected curve: Option B (Fast Ramp).** Tier transitions are cumulative (each tier adds to the previous pool).

| Tier | Waves (Option B) | Brick types introduced |
|------|-----------------|------------------------|
| **0** | Waves 1–2 | NORMAL, RED, BLUE, GREEN — simple sparse layouts |
| **1** | Waves 3–4 | 2-hit bricks (STRONG, PURPLE) + diamond/polygon shapes + denser layouts |
| **2** | Waves 5–8 | GOLD, ORANGE (high-value) + POWERUP_BRICKs + shaped formations |
| **3** | Waves 9–12 | BOMB bricks + glossy shapes (DIAMOND_GLOSSY, POLYGON_GLOSSY = 2-hit) |
| **4** | Wave 13+ | Full pool mix — all types in rotation |

**Indestructibles:** First appear at **wave 5** — 1 to 2 bricks only. Count can scale up every few tiers (exact cadence TBD).

**Formation patterns:** As tiers increase, the generator should move from pure-scatter toward structured shapes (clusters, L-shapes, hollow rings). Exact pattern templates are part of `SurvivalGenerator` design.

### Difficulty Scaling (Ball Speed)

- Ball speed increases by a fixed step every **Y waves** (Y = tuning constant, define as exported var in `SurvivalGenerator`)
- Speed is capped at **3× the wave-1 starting speed** (relative cap — intentional; flag for playtesting if Hard feels too fast at 1800)

### HUD

- **Resolved:** Same three-section layout as Time Attack — center logo label remains `"ZepBall"`, left label reads `"SURVIVAL"`, right label shows `"WAVE N"` (updated on each wave transition). Reuses the same TopBar supplementary label mechanism introduced for Time Attack.

### Game Over Screen

When all lives are lost in Survival, the existing `game_over.tscn` is reused with survival-specific modifications:
- Wave reached displayed prominently (new label)
- Final score displayed as usual
- Top-run comparison shown for both personal and machine bests (e.g., "Your best: Wave 15, 32,400 pts" + machine best line)
- **"Continue Set"** button hidden (nothing to continue)
- **"Retry"** button relabeled **"Play Again"** (restarts survival from wave 1)
- **"Main Menu"** button unchanged

### High Score / Leaderboard

- Top **10 runs** stored, sorted by score descending
- Each entry: `{ score, wave, date }`
- Shown in a dedicated **Survival tab** on the High Scores screen
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

### Save Migration Versioning

Follow `.agent/SOP/critical-workflows.md`. Since challenge modes are already implemented, this phase should handle save migration `3 → 4`.

**Version guard (standalone phase):** `if data.get("version", 0) < 4`

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

### High Scores Screen Tabs

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
- Bump save version:
  - Standalone phase: `3` → `4`
  - Combined delivery with challenge modes: single `2` → `4`
- Add migration logic for new fields (see above)
- New helper methods for time attack + survival (see above)

#### 2. `scripts/ui/menu_controller.gd` — Mode State + Survival Entry
- `start_survival()` — sets survival flag, loads main.tscn
- `show_survival_over(final_score, wave)` — calls SaveManager to record run, shows game over scene in survival context
- `show_set_complete()` — when Time Attack mode active, call `SaveManager.save_time_attack_set_high_score(pack_id, elapsed_time)` before showing set complete screen
- Expose `get_challenge_mode() -> String` already implemented in `Tasks/Completed/challenge-modes.md`; Time Attack adds `"time_attack"` as a fourth valid value
- Ensure `last_played` in-progress resume is disabled for Survival and main-menu return button is hidden for Survival runs

#### 3. `scripts/ui/main_menu.gd` + `scenes/ui/main_menu.tscn` — Survival Button
- Add **SURVIVAL** button to main menu, positioned **above the EDITOR button**
- On press: `MenuController.start_survival()`

#### 4. `scripts/survival_generator.gd` — New Script
- `generate_wave(wave_number: int) -> Array` — returns brick layout for BrickContainer population
- Tier config constants (exported for tuning): wave thresholds, brick type pools, layout patterns, indestructible scale curve, speed step interval, speed cap multiplier

#### 5. `scripts/main.gd` — Survival Mode Branch
- `var is_survival_mode: bool`
- `var current_wave: int`
- `var survival_speed_multiplier: float = 1.0`
- Override level-load path when `is_survival_mode == true`
- Wave completion detection and transition logic (freeze + reattach ball during inter-wave countdown)
- Speed step application on wave transitions

#### 6. `scripts/game_manager.gd` — Time Attack Timer + Wave Tracking
- `var time_attack_elapsed: float` — accumulates seconds
- `var time_attack_running: bool` — controlled by ball launch/land/pause signals
- Timer runs in `_process()` when `time_attack_running == true`
- `start_time_attack_timer()` / `pause_time_attack_timer()` / `stop_time_attack_timer() -> int` (returns integer seconds)
- `var current_wave: int` (for survival, incremented by main.gd)

#### 7. `scripts/hud.gd` — Timer + Wave Display
- Add two supplementary labels to the TopBar: `TopBarLeft` and `TopBarRight` (hidden by default)
- On game start, check `MenuController.get_challenge_mode()` and `MenuController.is_survival_mode`:
  - `"normal"` / `"iron_ball"` / `"one_life"` → existing behavior (`Tasks/Completed/challenge-modes.md`); supplementary labels stay hidden
  - `"time_attack"` → show `TopBarLeft = "TIME ATTACK"`, center logo = `"ZepBall"` (unchanged), `TopBarRight = "MM:SS"` (live timer)
  - survival → show `TopBarLeft = "SURVIVAL"`, center logo = `"ZepBall"` (unchanged), `TopBarRight = "WAVE N"` (updated on each wave transition)
- Connect to `GameManager` timer signal (or poll `time_attack_elapsed`) to update `TopBarRight` each frame in Time Attack
- Update `TopBarRight` on each wave transition signal in Survival

#### 8. `scripts/ui/game_over.gd` — Survival Modifications
- If survival context:
  - Show wave reached label
  - Relabel Retry → "Play Again"
  - Hide "Continue Set" button
  - Show top-run comparison from SaveManager

#### 9. `scenes/ui/high_scores.tscn` + `scripts/ui/high_scores.gd` — New Tabs
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
10. **high_scores** — Time Attack tab + Survival section

---

## Remaining Tuning Constants (Pre-Playtesting)

These are implementation-ready as exported vars in `SurvivalGenerator` — exact values to be tuned after first playtest:

| Constant | Starting value | Notes |
|----------|---------------|-------|
| Speed step interval (Y) | Every 3 waves | Increase ball speed by fixed step |
| Indestructible scale curve | 1 at wave 5, +1 per 4 waves | Cap suggested at ~6 |
| Speed step size | 50 units/step | Relative to wave-1 base; cap at 3× |

**`SurvivalGenerator`:** Implemented as a stateless `class_name` utility (no autoload). `main.gd` calls `SurvivalGenerator.generate_wave(wave_number)` directly.

---

## Out of Scope (Future)

- Survival difficulty selector (always Normal-equivalent rules for now)
- Survival achievements (e.g., "Reach wave 20")

---

## Related Docs
- `Tasks/Completed/challenge-modes.md` — Iron Ball & One Life (shares dropdown, leaderboard infrastructure, save migration chain)
- `future-features.md` — parent backlog (Time Attack, Survival entries)
- `System/architecture.md` — GameManager, main.gd, HUD, save system details
- `SOP/critical-workflows.md` — save migration SOP, commit format
