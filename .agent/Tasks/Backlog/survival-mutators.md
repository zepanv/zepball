# Survival Mutators

## Status: 📋 BACKLOG

Pre-run rule modifier for Survival. A single dropdown in the Survival hub (default `None`) picks a mutator for the run. Mutators change *rules*, not *stats* — stats are the domain of the 16 existing power-ups.

Extracted from `future-features.md` on 2026-03-12 for implementation planning. This file is the single source of truth for the mutator feature.

Last Updated: 2026-08-23

---

## Overview

| Option | Rule change |
|--------|-------------|
| `None` | Standard Survival — behavior unchanged, normal Survival leaderboard |
| `Random` | Resolves to one concrete mutator at run start; the resolved mutator is surfaced in the HUD and run-end results |
| `No Walls` | Ball wraps top/bottom edges instead of bouncing (left wall still bounces, right edge still the loss edge) |
| `Ricochet Chaos` | Ball bounces off bricks at randomized angles (±15°) |
| `Countdown` | If the wave is not cleared within N seconds, destroyed bricks come back one by one until the board refills |
| `Speed Ramp` | Ball gains extra speed at the start of each wave (slow Blitz-style ramp), total capped at 3× base speed |

`Reverse Controls` is explicitly **out of scope for v1** — not fun enough to justify inclusion right now.

`Shrinking Playfield` is **sidelined from v1** (decided 2026-08-23) — see [Sidelined: Shrinking Playfield](#sidelined-shrinking-playfield) for the kept analysis. `Random` resolves only over the concrete mutators shipped in v1.

**Leaderboard policy:**
- `None` runs → normal Survival leaderboard (`survival_top_runs`), unchanged
- Any mutator run (`Random` or a named mutator) → new **Survival Mutators** leaderboard
- The Mutators board has a header filter/toggle: `All` (default), `Random`, and one per named mutator
- Default leaderboard filter: `All` — so players see their own runs regardless of how they started them (named-filter default would hide named-mutator runs)
- One shared board + filter for v1 — no per-mutator score storage

**Scope:** Survival only. Blitz and set/challenge modes are unaffected.

**Key risk:** Curate carefully — some combinations become unfun or unplayable.

---

## Decisions (resolved 2026-08-23)

Original open questions, resolved in discussion. Remaining tuning details are listed at the end.

1. **Selection persistence** — ✅ **Persist per profile, default `None`.** Mirror the `current_challenge_mode` handling (`SaveManager.set/get_last_survival_mutator`, restored when the menu opens), validating against the registry on restore (unknown id → `none`).
2. **Retry / Random re-roll** — ✅ **Re-roll.** Resolution happens in `start_survival()`, and Retry already calls exactly that (game_over.gd), so every "Play Again" is a fresh run — no extra state needed. Players who want a stable rule set to grind against just pick a named mutator.
3. **Countdown: N and "cleared"** — ✅ **Progressive refill, not full regeneration.** If the wave is not cleared within N seconds, destroyed breakable bricks come back **one by one** (same position/type, in destruction order, staggered a few seconds apart — see tuning details) until the board refills. Adds difficulty pressure without punishing a missed clear with a hard reset. "Cleared" = *all breakable bricks destroyed* (mandatory: waves 5+ generate UNBREAKABLE bricks that never die, per `INDESTRUCTIBLE_START_WAVE = 5`). N is fixed at 60 s for v1. Re-breaking a respawned brick scores again (proposal — keeps "keep up" rewarding).
4. **Speed Ramp: increment and cap** — ✅ **Slow per-wave ramp (Blitz-style), total capped at 3× base** (`SurvivalGenerator.SPEED_CAP_MULTIPLIER`). Per-hit accumulation rejected: at +3%/hit the 3× cap is reached in ~40 hits (~one wave) and the rest of the run is constant 3× speed. A per-wave ramp keeps pressure growing over the run (the wave speed curve itself only reaches its 3× ceiling around wave 61, so the cap stays meaningful). Two code constraints drive the implementation:
   - The per-wave speed application in `main_survival_helper` resets `base_speed`/`current_speed` from the external multiplier on **every wave load**, so the ramp must **not** accumulate into `base_speed`/`current_speed` directly. Keep a separate per-run `ramp_factor` and fold it into the external multiplier: `set_external_speed_multiplier(survival_speed_multiplier * ramp_factor)`. Bonus: spawned extra balls already inherit the helper's multiplier (main.gd), so they get the ramp for free.
   - Composes with the SPEED_UP power-up as pure speed stacking (power-up multiplies `current_speed` on top).
   - Starting increment: +5% per wave (tuning detail below).
5. **Shrinking Playfield: amount and cap** — ⏸️ **Sidelined from v1.** See [Sidelined: Shrinking Playfield](#sidelined-shrinking-playfield).
6. **No Walls: loss edge** — ✅ **Only top/bottom wrap.** Left wall stays a bounce wall; right edge stays the loss edge; paddle escape-zone logic untouched. Rationale: with the left wall gone, a ball wrapping from the left re-enters at x≈1295 — exactly the zone behind the paddle where the Block Barrier power-up spawns its shield bricks (`PLAY_AREA_RIGHT_X = 1270` in `main_block_barrier_helper.gd`). Balls materializing in the shield zone would be confusing and would undercut the power-up. Top/bottom wrapping avoids the problem entirely. Display name needs updating (tuning detail below) — "No Walls" is no longer accurate.
7. **Named filter semantics** — ✅ **Runs store the resolved concrete id *and* a `random` flag.** Named filters match resolved mutator (all sources); `Random` filter matches the flag. Plus: **`All` filter added as the default** (see leaderboard policy) so named-mutator players see their own runs without switching filters.
8. **Save migration shape** — ✅ **Follow the established pattern.** `survival_mutator_top_runs` default in `create_default_save()`, missing-key compatibility in `load_save()`, no `SAVE_VERSION` bump — purely additive key, same shape as `survival_top_runs` (verified in save_manager.gd).
9. **HUD wave intro** — ✅ **HUD badge only for v1** (badge shows for the whole run). One-line addition later if wanted.

### Remaining tuning details (resolve before implementation, or pick defaults in review)

- **Countdown refill pacing:** per-brick respawn interval after expiry (proposal: 1 brick every ~3 s, oldest destruction first), and whether pending respawns cancel when the remaining breakable count drops below a threshold (proposal: yes, at ≤5 — gives each wave a decisive end and caps the "keep up" grind).
- **Countdown scoring:** confirm re-breaking a respawned brick scores again.
- **Speed Ramp increment:** +5% per wave is a starting point — tune against the wave speed curve so the 3× total cap is reached around waves 15–20.
- **No Walls display name:** the rule no longer matches the name. Candidates: `No Ceiling, No Floor`, `Top & Bottom Wrap`, keep `No Walls`. Pick one for the registry display string.

---

## Sidelined: Shrinking Playfield

Deferred from v1 (decided 2026-08-23). Full analysis kept so this can be revived without re-deriving.

**Concept:** walls close in each wave, increasing spatial pressure.

**Geometry (verified in code):** brick grid spans roughly x 150–1170, y 120–627. Walls: `TopWall` inner face y=20, `BottomWall` y=700, `LeftWall` x=20 (`main.tscn`). Maximum travel before covering bricks: ~100 px (top), ~73 px (bottom), ~130 px (left).

**Saturation problem:** at 10 px/side/wave the walls saturate by waves 11 / 8 / 14. The survival speed curve only saturates around wave 61, so the design expects 15–30+ wave runs — the "pressure every wave" promise dies after ~10 waves. Even at 5 px/side/wave saturation lands around waves 15/15/27.

**Options from the original discussion:**
- **A:** fixed shrink per wave (5–10 px/side) capped so walls never intrude into the brick grid region — simple, no generator changes, but pressure stops once capped.
- **B:** parameterize `SurvivalGenerator` grid bounds and regenerate each wave inside the current bounds — sustained pressure, more work. Note the grid origin is already data-driven (`grid.start_x/start_y` in level data) and the generator already takes bounds params for Blitz, so B is mostly "pass current bounds into `generate_wave()` and clamp cluster/unbreakable placement."

**Implementation notes (either option):** `ball.gd` boundary handling is const-based (hardcoded 20/700 nudge values in `_handle_error_boundary_escape`) and would need runtime values; walls should move between waves (during the intro) or the ball needs clamping if it's near an edge when a wave loads.

---

## Implementation Plan (pending tuning details)

### 1. Mutator registry (single source of truth)

New `scripts/survival_mutator.gd` (`class_name SurvivalMutator`, `extends RefCounted`, static API):

- `MUTATOR_IDS = ["none", "random", "no_walls", "ricochet_chaos", "countdown", "speed_ramp"]` (v1 set; `shrinking_playfield` is sidelined — do not add until revived, see [Sidelined](#sidelined-shrinking-playfield))
- `MUTATORS: Dictionary` — id → `{ "display": String, "blurb": String }` (display strings used everywhere: dropdown, HUD badge, run-end label, leaderboard filter)
- `is_valid(id)`, `is_active(id)` (true for everything except `none`), `resolve_random(id, rng)` → concrete id (no-op for `none`), `get_display(id)`

All UI/score code references ids + this registry — no free-text mutator strings in save data or leaderboards.

### 2. Selection state + entry UI

- **`scenes/ui/endless_waves.tscn` / `scripts/ui/endless_waves.gd`** — add an `OptionButton` to `SurvivalCard` (between `SurvivalDescriptionLabel`/`SurvivalBestLabel` and `SurvivalStartButton`), populated from the registry, themed like `set_filter_dropdown`. Pass the selected id into start.
- **`scripts/ui/menu_controller.gd`** —
  - `var survival_mutator: String = "none"` (selected id; persisted per profile — decision 1, mirror `current_challenge_mode` handling)
  - `start_survival()` resolves `random` → concrete id using a fresh `RandomNumberGenerator`; stores run state: `active_survival_mutator` (concrete id) + `survival_mutator_random: bool` (whether it came from Random)
  - Reset in the same places `is_survival_mode` is reset
  - `show_survival_over(final_score, wave)` branches the score write (see §5)

### 3. Rule hooks (gameplay)

Run descriptor lives above gameplay scene setup, per the original spec — i.e. `main.gd` reads `MenuController.active_survival_mutator` during `_start_survival_run()` and applies the hook below before wave 1 loads.

| Mutator | Hook location | Mechanism |
|---------|---------------|-----------|
| `no_walls` | `main.gd` + `ball.gd` | Disable `TopWall`/`BottomWall` bodies (collision off + hidden visuals) at run start; `LeftWall` **stays** (decision 6); in `ball.gd` `_handle_out_of_bounds()`, wrap position across top/bottom instead of `_handle_error_boundary_escape` nudge; left nudge and right `ball_lost` unchanged |
| `ricochet_chaos` | `ball_collision_helper.gd` (brick branch) | After `velocity = velocity.bounce(normal)`, rotate velocity by `randf_range(-15, 15)` degrees |
| `countdown` | `main_survival_helper.gd` + brick respawn | Per-wave timer (N = 60 s) started at wave load; stopped/cancelled on wave clear (existing `remaining_breakable_bricks == 0` path in `main.gd`). On expiry: enter refill state — destroyed breakable bricks respawn one by one (same position/type, in destruction order, staggered ~3 s, see tuning details) until the board is full; wave still clears when all breakables are destroyed; brief "refilling" HUD state |
| `speed_ramp` | `main_survival_helper.gd` (+ `ball.gd` via external multiplier) | Per-run `ramp_factor` (starts 1.0); at each wave load multiply by `1.0 + RAMP_STEP` (start 0.05, see tuning details) and apply as `set_external_speed_multiplier(survival_speed_multiplier * ramp_factor)`; clamp final total speed to `wave_one_speed * SPEED_CAP_MULTIPLIER`. Do **not** mutate `base_speed`/`current_speed` directly — they are reset from the external multiplier on every wave load |

Notes:
- `ball.gd` keeps its const-based boundary handling (20/700/1300) — No Walls only changes the top/bottom branch, and Shrinking Playfield is sidelined.
- Only one mutator is active per run, so no mutator×mutator interactions to handle.
- Paddle-side logic (escape zone, grab, launch) stays untouched by all mutators.

### 4. HUD badge + run-end results

- **`scripts/hud.gd`** — small badge in the top bar `CenterBlock` (next to `ModeDetailLabel`) showing `MUTATOR: <display>` when the active mutator is not `none`. Visible for the whole run.
- **`scripts/ui/game_over.gd`** — survival branch of `_ready()`: append a mutator line to `survival_label` (e.g. `Mutator: No Walls`), plus the existing personal/machine comparison against the *mutators* board (see §5).

### 5. Save schema + leaderboards

Save data (per profile):
```
"survival_mutator_top_runs": [
    { "score": int, "wave": int, "mutator": "<concrete id>", "random": bool, "date": "<datetime string>" }
]
```

- **`scripts/save_manager.gd`** — new pass-throughs `get_survival_mutator_top_runs()`, `save_survival_mutator_run(score, wave, mutator, was_random)`; default in `create_default_save()` + missing-key compatibility in `load_save()` (decision 8).
- **`scripts/save_high_scores_helper.gd`** — storage/sanitize logic mirroring `save_survival_run`; `get_all_leaderboards()` gains `"survival_mutator_runs": []` aggregated across profiles.
- **`scripts/save_progression_helper.gd`** — `_sanitize_survival_mutator_runs()` — keeps `{score, wave, mutator, random, date}` (mutator validated against registry ids; unknown ids dropped), sorted by score desc then wave desc, capped at 10.
- **`scripts/ui/menu_controller.gd`** — `show_survival_over()`: `none` → `save_survival_run` (unchanged path); otherwise → `save_survival_mutator_run(final_score, wave, active_survival_mutator, survival_mutator_random)`.
- **`scripts/ui/high_scores.gd`** —
  - New `FILTER_TABS` entry: `{"id": "mutators", "title": "MUTATORS"}` (tab order: after `survival`)
  - New header dropdown (mirroring `SET_FILTERS` pattern, shown only on the mutators tab): `All` (default) + `Random` + one item per named mutator (registry order)
  - `_render_mutators_view()` — `All` shows everything; `Random` filters by `random == true`; named filters match `mutator == <id>` (all sources — decision 7); context column shows the resolved mutator display name; column headers `MUTATOR` / `SCORE`; empty states like the other views.

### 6. Docs + verification (per project guardrails)

- `.agent/System/architecture.md` — mutator flow: selection → run descriptor → rule hooks → score routing.
- `.agent/SOP/critical-workflows.md` — only if the migration pattern note needs updating (new array key; likely no doc change beyond the code).
- Run `scripts/check_agent_docs.sh` before commit.
- Manual verification matrix: each v1 mutator end-to-end (start → badge → rule active → run end → correct board → filter shows the run), `Countdown` refill pacing + wave still clearable under refill, `Speed Ramp` composing with the per-wave speed curve without being clobbered on wave load, `Random` surfacing the resolved name, `None` path byte-identical to today, old saves load with the new key defaulted.

---

## Related Docs

- `future-features.md` — original backlog entry (now points here)
- `../Completed/new-game-modes.md` — Survival mode (implemented)
- `../Completed/challenge-modes.md` — closest precedent: pre-run mode pick + separate leaderboards + tabbed High Scores UI
- `../../System/architecture.md` — runtime flow (update when implemented)
- `../../SOP/critical-workflows.md` — save migration procedure
