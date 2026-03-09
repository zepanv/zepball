# UI Overhaul

## Status: 📋 BACKLOG

Holistic pass over ZepBall's menus and HUD to reduce clutter, improve information hierarchy, and modernize the visual language. Some items overlap with other tasks (Blitz Mode needs High Scores tabs, Wave Objectives need HUD elements) — this task owns the design direction so those features slot in cleanly.

Created: 2026-03-09
Last Updated: 2026-03-09

---

## Goal

Make every menu and HUD feel polished rather than functional-but-flat. Prioritize readability, reduce visual noise, and establish a consistent design language across all screens.

---

## Screens

### 1. High Scores — Full Rework ⭐

**Current state**: `scenes/ui/high_scores.tscn` + `scripts/ui/high_scores.gd` (350 lines)

**Problems**:
- Entire layout is code-generated (`_add_score_entry` builds HBoxContainers with hardcoded sizes and colors) — brittle and hard to iterate on visually.
- Double tab bars (Overall / Sets / Levels / Survival + a second challenge sub-tab bar for Sets) are confusing. Sets tab surfaces Normal / Iron Ball / One Life / Time Attack as a nested row — easy to miss.
- Column widths are fixed magic numbers (`custom_minimum_size = Vector2(50, 0)`, `Vector2(120, 0)`, `Vector2(110, 0)`).
- No visual distinction between score entries — plain rows with no alternating color, no card treatment, no ranking badges.
- Back button floating at bottom-left outside the panel, easy to miss.
- Already flagged in `run-variety-expansion.md`: adding Blitz as yet another tab makes the problem worse.

**Direction**:
- Replace double tab bars with a **single redesigned tab bar**: `Overall | Levels | Sets ▾ | Survival | Blitz` — where Sets uses a dropdown/submenu for challenge variants (Normal / Iron Ball / One Life / Time Attack) instead of a second nested tab row.
- Move score entry layout to a scene-based template (PackedScene row) instead of pure code generation, so styling can be iterated in the editor.
- Add rank badges for top 3 (🥇🥈🥉 or colored highlights).
- Alternating row tint or card-style entries for scanability.
- Integrate Back action into the panel footer, not a floating orphan button.
- Plan for extensibility: adding a new mode tab should be trivial — data-driven tab list, not hardcoded match statements.
- **Controller focus**: tab bar must be navigable with shoulder buttons or d-pad. Sets dropdown must be openable/closable with gamepad.

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

**Current state**: `scenes/ui/level_complete.tscn` (205 lines) + `scripts/ui/level_complete.gd` (206 lines); `scenes/ui/set_complete.tscn` + `scripts/ui/set_complete.gd` (187 lines)

**Problems**:
- Level Complete shows 7 breakdown line items (Base, Difficulty, Combo, Streak, Power-Up, Perfect Clear, Total) plus Time, plus Set Total, plus High Score label, plus Perfect Clear banner — all displayed at once.
- Breakdown + buttons are in a side-by-side HBoxContainer that can feel cramped on smaller windows.
- Set Complete duplicates much of the breakdown logic (same bonus categories + Perfect Set Bonus), but the two scenes share no code — maintenance burden.
- 16+ `@onready` vars in level_complete.gd alone, tightly coupled to scene tree paths.

**Direction**:
- Keep all breakdown info visible — don't collapse or hide bonus lines. Instead, improve readability through **positioning and font treatment**: use size/weight/color to establish hierarchy between the big numbers (Total, Score) and supporting detail (individual bonuses).
- Stack layout vertically instead of side-by-side (breakdown left, buttons right). On these screens the player's focus is "what did I get?" then "what do I do next?" — vertical flow matches that better.
- Perfect Clear and Perfect Set bonuses should remain visually prominent — these are exciting moments.
- Extract shared bonus-formatting logic into a helper (both screens format bonuses and time identically).
- Reduce `@onready` count by grouping labels into a sub-scene or using a dictionary-driven approach.

---

### 3. Main Menu — Possible Refresh

**Current state**: `scenes/ui/main_menu.tscn` (283 lines) + `scripts/ui/main_menu.gd` (264 lines)

**Problems (minor)**:
- Long vertical button list can feel flat: Play, Return, Difficulty row, Survival, Editor, Stats/High Scores row, Settings, Quit — 8+ tappable items stacked with spacers.
- Difficulty selection (3 buttons + "Current: NORMAL" label) takes up significant vertical space for a setting that changes rarely.
- Profile dropdown + "+" button works but looks utilitarian.
- `SurvivalButton` will eventually be replaced by an "Endless Waves" hub entry (per `run-variety-expansion.md`).

**Direction**:
- Move Survival / Endless Waves up near the Play button so the primary gameplay actions are grouped together at the top.
- Keep Difficulty on the Main Menu (players use it often enough), but replace the 3-button row + label with a **dropdown selector** to save vertical space.
- Group secondary actions (Stats, High Scores, Settings, Editor) into a smaller row or icon strip to further elevate the primary actions.
- When Blitz / Endless Waves hub is implemented, replace the standalone Survival button with an "Endless Waves" button that opens the mode hub.
- Visual polish: subtle background animation (particles, gradient shift), title treatment, profile area styling.
- **Controller focus**: dropdown must support gamepad cycling (left/right or triggers to change selection). Ensure focus chains flow logically top-to-bottom through the revised layout.

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

**Cross-task notes**:
- `run-variety-expansion.md` § Wave Objectives → needs a persistent HUD element for objective display.
- `run-variety-expansion.md` § Blitz → needs a countdown timer for next row push.

---

### 5. Other Screens — Audit & Align

These don't need a full rework but should be updated to match whatever design language emerges from the above:

| Screen | File | Notes |
|--------|------|-------|
| Game Over | `scenes/ui/game_over.tscn` | Align styling with new Level/Set Complete treatment |
| Set Select | `scenes/ui/set_select.tscn` | Verify card styling is consistent |
| Level Select | `scenes/ui/level_select.tscn` | Check for consistency |
| Settings | `scenes/ui/settings.tscn` | May absorb Difficulty selection from Main Menu |
| Stats | `scenes/ui/stats.tscn` | Align with new High Scores design |
| Keybindings | `scenes/ui/keybindings.tscn` | Consistent panel styling |
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
- [ ] High Scores full rework
- [ ] Level Complete / Set Complete declutter

### Phase 2: Polish
- [ ] Main HUD improvements (scene-based overlays, multiplier badge, power-up icons)
- [ ] Main Menu refresh

### Phase 3: Consistency Pass
- [ ] Update remaining screens (Game Over, Set Select, Level Select, Settings, Stats, Keybindings) to match new design language

---

## Cross-Task Dependencies

| Other Task | UI Work Needed | Owned Here? |
|-----------|---------------|-------------|
| Blitz Mode (`run-variety-expansion.md`) | High Scores: new Blitz tab; HUD: row-push countdown timer; Main Menu: Endless Waves hub button | Design direction owned here; implementation may live in the Blitz task |
| Wave Objectives (`run-variety-expansion.md`) | HUD: persistent objective display element | Design direction owned here; implementation may live in the Wave Objectives task |
| Endless Waves Hub (`run-variety-expansion.md`) | New mode selection scene (card-based); replaces Survival button on Main Menu | New scene — could live in either task |

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
