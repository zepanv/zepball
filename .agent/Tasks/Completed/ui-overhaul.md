# UI Overhaul

## Status: ✅ COMPLETE

Holistic pass over ZepBall's menus and HUD to reduce clutter, improve information hierarchy, and modernize the visual language. Some items overlap with other tasks (Blitz Mode needs High Scores tabs, Wave Objectives need HUD elements) — this task owns the design direction so those features slot in cleanly.

Created: 2026-03-09
Last Updated: 2026-03-10 (moved to Completed; remaining run-variety follow-up tracked in `.agent/Tasks/Backlog/run-variety-expansion.md`)

---

## Goal

Make every menu and HUD feel polished rather than functional-but-flat. Prioritize readability, reduce visual noise, and establish a consistent design language across all screens.

## Foundation Progress (2026-03-10)

- Shared theme foundation added via `scripts/ui/ui_theme.gd`. Main Menu, Settings, High Scores, Game Over, Level Complete, Set Complete, and HUD now consume the same theme tokens rather than each defining their own color/font language ad hoc.
- The shared menu theme has since been tightened toward a flatter, denser look: smaller corner radii, slimmer borders, reduced control padding, and less pill-heavy chrome so dense menus do not waste vertical space.
- In-play HUD standardized in `scenes/main/main.tscn` + `scripts/hud.gd` around fixed slots:
  - score
  - mode + detail
  - lives
  - difficulty
  - player
  - reserved objective slot
  - power-up indicator stack
  - multiplier card
  - center state/combo overlays
- This means future mode work (Wave Objectives, Blitz timer, Survival variants) should populate reserved HUD regions instead of introducing a new HUD arrangement per mode.
- Power-up indicators were restyled to match the shared theme, but they are still text-first. Icon/radial treatment remains future polish.
- Follow-up HUD tightening kept the top strip transparent, moved combo feedback into the bottom-center gutter, pushed debug/multiplier into opposite bottom corners, and reduced power-up timer footprint so the playfield border stays clear.
- Power-up timers now occupy a dedicated right-side lane that starts just below the top wall and grows downward instead of upward, preventing overlap with the top HUD when multiple timed effects are active.
- Debug overlay was compacted into a two-line bottom-right readout (`FPS / Balls / Combo` and `Velocity / Speed`) to fit the gameplay gutter without clipping.
- Screenshot capture now exists as a real input action (`take_screenshot`) with defaults for `F12`, `Cmd+Shift+S`, and `Ctrl+Shift+S`, so UI iteration can be reviewed from menus or in-run frames without OS-level capture timing.

---

## Current Status Summary

### Completed

- **Shared theme foundation** is in place and applied to all major screens.
- **In-play HUD** has a predictable slot contract, transparent gutter-based overlays, downward-growing power-up lane, screenshot capture (`F12`), and refreshed objective/multiplier presentation with pulse feedback while keeping those elements unboxed so they do not intrude on the playfield.
- **High Scores** full visual and structural rework: single tab bar, Sets dropdown filter, footer Back button, left-accent rank stripes, tighter flush panels. Stable Blitz tab placeholder added.
- **Level Complete & Set Complete declutter**: Switched from side-by-side to vertical flow, extracted shared breakdown formatting logic, hid zero-value bonus lines, reduced script @onready bloat, and applied `title_large` header treatments.
- **Stats screen** fully rebuilt: `ui_theme` integration, tighter layout, accent-row achievements.
- **Settings screen** updated with `title_large` and green profile label.
- **Set Select** themed with accent-row pack cards (cyan/gold) and proper theme colors.
- **Main Menu** no longer uses the old 3-button difficulty row: it now has the dropdown layout, grouped primary actions near the top, Endless Waves hub replacing the old Survival button, click-triggered update checks, and post-refactor sanity fixes for difficulty persistence plus button routing.
- **Main Menu secondary actions** are now tighter: `Editor` and `Settings` sit in a shared row instead of two extra full-width lines.
- **Main Menu finishing pass** landed: profile controls were tightened into a cleaner strip (no framed bubble), the background has subtle ambient color drift, and explicit controller focus neighbors were added across profile/actions/difficulty/footer rows (including return-button visibility cases).
- **Game Over** now uses a centered panel + constrained action column with shared-theme styling, fixing the oversized full-width button presentation.
- **Keybindings overlay** now consumes shared-theme styling and no longer runs verbose focus/controller debug logging during normal menu use.
- **Level Select** was compacted to match shared-theme density: narrower panel target, 3-column card grid, reduced card footprint, and trimmed action footer sizing.

### Completion Note

- **Main HUD improvements** are complete for this overhaul's structural/design scope. Remaining endless-mode follow-up work that grew out of this pass now lives under `.agent/Tasks/Backlog/run-variety-expansion.md`:
  - long-session Blitz pacing/readability tuning
  - mutator leaderboard/filter policy
  - optional HUD polish such as icon/radial power-up treatment and richer objective presentation

### Out Of Scope For What Is Already Done

- ~~Blitz leaderboard tab and row-push timer are not implemented here yet.~~ **Done** — implemented in `.agent/Tasks/Completed/phase1-wave-objectives-blitz.md`; `high_scores.gd` now renders live Blitz run data; `hud.gd` has `set_blitz_push_status()` with color-threshold countdown.
- ~~Wave Objective HUD element is not implemented yet.~~ **Done** — `hud.gd` has `set_objective_text()` / `_on_objective_assigned` / `_on_objective_completed` / `_on_objective_failed` wired to `GameManager` signals via `main_survival_helper.gd`.
- ~~Endless Waves hub/menu replacement is not implemented yet.~~ **Done** — `scenes/ui/endless_waves.tscn` exists; `main_menu.gd` routes `SurvivalButton → _on_endless_waves_pressed() → MenuController.show_endless_waves()`.

---

## Screens

### 1. High Scores — Full Rework ⭐

**Current state**: `scenes/ui/high_scores.tscn` + `scripts/ui/high_scores.gd` + `scenes/ui/components/high_score_row.tscn` + `scripts/ui/high_score_row.gd`

**Shipped in this pass**:
- Replaced the nested tab rows with a single tab bar: `Overall | Levels | Sets | Survival | Blitz`.
- Sets now uses an in-panel dropdown filter (`Normal / Iron Ball / One Life / Time Attack`) instead of a second tab row.
- Score entries now come from a reusable scene-based row template, with alternating card tint, top-3 rank badge colors, and current-profile highlighting.
- Back now lives in the panel footer instead of as a floating orphan button.
- Blitz now has a placeholder tab in the layout so future work can attach real data without another structural UI pass.

**Follow-up moved to run variety task**:
- Blitz tab data is now live via `.agent/Tasks/Completed/phase1-wave-objectives-blitz.md`.
- Optional mutator/filter controls remain deferred until mutator scoring rules are decided in `.agent/Tasks/Backlog/run-variety-expansion.md`.

**Mutator-proofing** (future consideration from `run-variety-expansion.md`):
- Mutators (No Walls, Ricochet Chaos, Speed Ramp, etc.) could affect scoring fairness. Options to consider when mutators ship:
  - **Tag approach**: mutator-enabled runs appear on the same leaderboard but are tagged/badged (e.g., a small icon next to the score). Simple, avoids fragmenting boards.
  - **Separate buckets**: mutator runs get their own leaderboard section. Clean separation but multiplies tabs/views.
  - **Exclude from leaderboard**: mutator runs are "for fun" and don't record to High Scores at all. Simplest but may feel unrewarding.
- The tab bar design should allow for *filtering* (e.g., a toggle like "Show mutator runs") without requiring a whole new tab per mutator. A filter icon or checkbox on the leaderboard view could work.
- **Decision deferred** — depends on how mutators affect difficulty. If mutators are random-only (no player selection), a tag approach is likely sufficient. If players choose mutators, separate scoring may be needed.

**Cross-task notes**:
- `run-variety-expansion.md` § Blitz → needs its own leaderboard tab here.
- Blitz tracked metrics: score + rows/time survived.
- `run-variety-expansion.md` § Mutators → open question about leaderboard separation (see above).

---

### 2. Level Complete / Set Complete — Declutter

**Current state**: `scenes/ui/level_complete.tscn` + `scripts/ui/level_complete.gd`; `scenes/ui/set_complete.tscn` + `scripts/ui/set_complete.gd`

**Shipped in this pass**:
- Result screens now use a vertical information flow instead of the older cramped side-by-side arrangement.
- Shared bonus/time formatting moved into helper code instead of duplicating that logic in both result scripts.
- Zero-value bonus lines are hidden to reduce visual noise while still keeping meaningful breakdown detail visible.
- Both screens were restyled around the shared theme with stronger hierarchy for headline totals, banners, and supporting breakdown rows.

**Follow-up status**:
- Any future result-screen work is polish only; the structural declutter goals for this task are complete.

---

### 3. Main Menu — Possible Refresh

**Current state**: `scenes/ui/main_menu.tscn` + `scripts/ui/main_menu.gd`

**Shipped in this pass**:
- The old difficulty button trio was replaced with a compact dropdown.
- Survival was replaced with an **Endless Waves** button that routes to the new hub scene (`endless_waves.tscn`), providing Survival and Blitz mode cards.
- Stats and High Scores were grouped into a shared row to reduce some vertical sprawl.
- Version/update behavior was corrected so network checks only happen when the player clicks the update button.
- Main-menu refactor bugs already found in implementation were fixed: difficulty restores from the active profile, quit/editor/survival keep using `MenuController`, and pause/settings/menu return flows stay coherent.
- Profile section was flattened by removing the extra framed panel treatment while preserving profile controls and controller flow.

**Follow-up status**:
- Controller-flow sanity work is now part of normal regression testing if later menu changes land; no standalone backlog item remains here.

---

### 4. Main HUD — Mode-Aware Improvements

**Current state**: `scripts/hud.gd` (486 lines) + 4 helper scripts (pause menu, debug overlay, level intro, power-up timers)

**Problems**:
- HUD reconfigures itself per mode (Set play, Survival, Time Attack, Iron Ball, One Life) via `_configure_topbar_mode()` and `_show_center_mode_with_detail()` — functional but the mode branching is spread across callbacks.
- Dynamic elements (game_over_label, level_complete_label, combo_label, multiplier_label) are all code-generated with hardcoded positions, sizes, and colors inside `_init_dynamic_elements()`.
- Multiplier display (bottom-left text list) is informational but visually bland — easy to miss during intense play.
- Power-up timer indicators are managed by `hud_power_up_timers_helper.gd` — works but could be more visually distinctive.

**Direction**:
- Move code-generated overlays (game over, level complete, combo) to scene-based sub-scenes for easier visual iteration.
- Improve multiplier display: consider an abbreviated badge or bar rather than a multi-line text label.
- Power-up timers: explore icon-based indicators with radial cooldown rings rather than plain text.
- Ensure HUD cleanly supports future Wave Objective display (per `run-variety-expansion.md` § Wave Objectives): persistent top element like `⭐ No ball loss | +500` with live progress for threshold objectives.
- Mode-specific styling: Survival could have a distinct HUD tint or accent, Blitz could show a row-push countdown timer.

**Carry-over follow-up**:
- Longer-term endless-mode HUD polish and Blitz readability tuning moved to `.agent/Tasks/Backlog/run-variety-expansion.md`.

---

### 5. Other Screens — Audit & Align

These don't need a full rework but should be updated to match whatever design language emerges from the above:

| Screen | File | Notes |
|--------|------|-------|
| Game Over | `scenes/ui/game_over.tscn` | **Done** for this task: shared-theme styling plus narrowed, centered action layout |
| Set Select | `scenes/ui/set_select.tscn` | **Done** for this task: accent-row cards and theme colors are in place |
| Level Select | `scenes/ui/level_select.tscn` | **Done** for this task: shared-theme pass plus compact 3-column panel/card layout |
| Settings | `scenes/ui/settings.tscn` | **Done** for this task |
| Stats | `scenes/ui/stats.tscn` | **Done** for this task |
| Keybindings | `scenes/ui/keybindings.tscn` | **Done** for this task: shared-theme pass applied and debug-heavy focus/input logging removed |
| Level Editor | `scenes/ui/level_editor.tscn` | Low priority — functional tool |

---

## Design Principles

1. **Controller-first** — **Hard requirement.** Every menu and HUD must be fully navigable with gamepad. Focus chains, button hints, and logical tab order are non-negotiable. Any new widget (dropdowns, sidebars, expandables) must be tested for controller flow before shipping.
2. **Information hierarchy** — Lead with the number the player cares about most (total score, wave reached, rank), detail second.
3. **Consistent color language** — Cyan for primary/interactive, gold for achievements/bonuses, grey for secondary info, green for success.
4. **Scene-based layouts** — Move away from code-generated UI where possible so designs can be iterated in the Godot editor.
5. **Extensibility** — Tab systems, mode displays, and leaderboard views should be data-driven so adding a new mode doesn't require structural refactoring.

---

## Suggested Phasing

### Phase 1: High Impact
- [x] High Scores full rework (structural + visual overhaul)
- [x] Level Complete / Set Complete declutter (vertical flow, shared breakdown logic)

### Phase 2: Polish
- [x] Main HUD improvements
  - Completed: fixed-slot HUD contract, shared-theme styling, transparent gutter-based overlays, player/lives top-bar cleanup, bottom-center combo placement, bottom-corner multiplier/debug placement, downward-growing power-up timer lane, screenshot capture input, improved objective/multiplier readability with pulse feedback while keeping them unboxed, Blitz countdown color states, and all-clear HUD callout feedback.
  - Carry-over moved to `.agent/Tasks/Backlog/run-variety-expansion.md`: icon/radial timer exploration, richer objective presentation polish, and long-session Blitz readability/pacing tuning.
- [x] Main Menu refresh
  - Completed: title/theme integration, difficulty dropdown, Survival button replaced with Endless Waves hub entry, Stats/High Scores row grouping, click-only update checks, save-flow sanity fixes, flattened profile strip, ambient background drift, and explicit controller focus-neighbor wiring across all layout variants.

### Phase 3: Consistency Pass
- [x] Stats — full theme integration from scratch
- [x] Settings — title_large, profile label styled
- [x] Set Select — accent-row cards with theme colors
- [x] Game Over — centered panel + constrained action column aligned with shared theme
- [x] Level Select — shared-theme pass + compact panel/card layout complete
- [x] Keybindings — consistent shared-theme styling with cleaned controller/focus logging behavior

---

## Cross-Task Dependencies

| Other Task | UI Work Needed | Status |
|-----------|---------------|-------------|
| Blitz Mode (`run-variety-expansion.md`) | High Scores: Blitz tab ✅; HUD: row-push countdown timer ✅; Main Menu: Endless Waves hub button ✅ | **Complete** — shipped via `.agent/Tasks/Completed/phase1-wave-objectives-blitz.md` |
| Wave Objectives (`run-variety-expansion.md`) | HUD: persistent objective display element ✅ | **Complete** — `set_objective_text()` wired end-to-end |
| Endless Waves Hub (`run-variety-expansion.md`) | New mode selection scene ✅; Survival button rewired ✅ | **Complete** — shipped via `.agent/Tasks/Completed/phase1-wave-objectives-blitz.md` |
| Phase 1 Wave Objectives + Blitz (`.agent/Tasks/Completed/phase1-wave-objectives-blitz.md`) | Post-ship pacing/readability tuning over multiple sessions | **Tracked elsewhere** — carried into `.agent/Tasks/Backlog/run-variety-expansion.md` as endless-mode follow-up |

---

## Open Questions

- ~~How much bonus breakdown detail do players actually want on Level Complete?~~ **Resolved: keep all info, improve with positioning/font treatment.**
- ~~Should difficulty live on Main Menu or move entirely to Settings?~~ **Resolved: stays on Main Menu, switch to dropdown.**
- ~~Where should Survival/Endless sit in menu order?~~ **Resolved: move up near Play button.**
- ~~High Scores rework design — sidebar vs. redesigned tab bar vs. other approach?~~ **Resolved: single redesigned tab bar with dropdown for Sets challenge variants.**
- How should mutator-enabled runs interact with leaderboards? (tag, separate, or exclude?) **Deferred until mutators are designed — see High Scores § Mutator-proofing.**

---

## Related Docs

- `Tasks/Backlog/run-variety-expansion.md` (Blitz, Wave Objectives, Endless Waves hub)
- `Tasks/Backlog/future-features.md`
