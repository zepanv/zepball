# Challenge Modes: Iron Ball & One Life

## Status: 📋 BACKLOG

Adds two hardcore challenge variants accessible from the Select Pack screen. Both modes are pack-run only, not stackable with each other, and maintain separate leaderboards from Normal play.

Last Updated: 2026-02-24

---

## Overview

| Mode | Description |
|------|-------------|
| **Normal** | Standard gameplay — all power-ups active. Default selection, current behavior unchanged. |
| **Iron Ball** | No power-ups of any kind. Pure skill-based gameplay. |
| **One Life** | One life for the entire pack run. No continues. |

**Shared constraints:**
- Pack-run only (the Challenge dropdown is exclusive to the Select Pack screen)
- Modes are not stackable
- Each mode has its own pack-level high score leaderboard
- HUD logo replaced with mode name during challenge play
- Mode is persisted in `last_played` so "Return to Last Level" resumes the correct mode

---

## Detailed Behavior

### Iron Ball Mode

**Power-up drops:** Skip the 20% drop chance in `main.gd → _on_brick_broken()`. No power-up pickups spawn from brick breaks.

**POWERUP_BRICK tiles:** On contact, destroy the brick (emit `brick_broken`, queue_free) without granting the power-up. Keep pass-through behavior — no collision shape changes needed. This is a single mode-flag check in the existing contact handler.

**MYSTERY power-up:** Moot — drops are suppressed at the source.

**High scores:** Separate namespace `iron_ball_set_high_scores` in save data, keyed by `pack_id`.

### One Life Mode

**Starting lives:** Override `game_manager.lives = 1` at game start instead of the default 3.

**EXTRA_LIFE power-up:** Drops can still spawn (power-ups are not suppressed). The grant is blocked in `main_power_up_handler.gd` — when EXTRA_LIFE is dispatched in One Life mode, skip the `add_life()` call silently (no visual/audio feedback, pickup still consumed).

**Continue Set:** The "Continue Set" button on the Game Over screen is hidden when the active challenge mode is One Life.

**High scores:** Separate namespace `one_life_set_high_scores` in save data, keyed by `pack_id`.

---

## Files to Change

### 1. `scripts/save_manager.gd` — Save Migration (REQUIRED FIRST)
- Bump save version: `1` → `2`
- Add migration logic to inject new fields with defaults for existing saves
- New fields:
  ```json
  "iron_ball_set_high_scores": {},
  "one_life_set_high_scores": {}
  ```
- Add `challenge_mode` field to `last_played` (default `"normal"`):
  ```json
  "last_played": {
    "level_id": 6,
    "set_id": -1,
    "mode": "individual",
    "challenge_mode": "normal",
    "in_progress": false
  }
  ```
- New helper methods:
  - `get_challenge_set_high_score(pack_id, challenge_mode) -> int`
  - `save_challenge_set_high_score(pack_id, challenge_mode, score)`
  - `get_last_challenge_mode() -> String`

### 2. `scripts/ui/menu_controller.gd` — Mode State
- Add `var current_challenge_mode: String = "normal"` (values: `"normal"`, `"iron_ball"`, `"one_life"`)
- `start_set(set_id)` → pass `current_challenge_mode` to gameplay scene
- On pack completion (`show_set_complete()`): call `SaveManager.save_challenge_set_high_score()` when mode is not normal
- Save `current_challenge_mode` to `last_played` via SaveManager
- Expose `get_challenge_mode() -> String` for consumption by HUD, GameManager, etc.

### 3. `scripts/game_manager.gd` — One Life Override
- Read `MenuController.get_challenge_mode()` in `start_game()` (or equivalent init)
- If mode is `"one_life"`: set `lives = 1` instead of default `3`
- No other GameManager changes needed

### 4. `scripts/main.gd` — Iron Ball Drop Suppression
- In `_on_brick_broken()`, wrap the 20% power-up spawn block:
  ```gdscript
  if MenuController.get_challenge_mode() != "iron_ball":
      # existing 20% drop logic
  ```

### 5. `scripts/brick.gd` — POWERUP_BRICK in Iron Ball
- In the POWERUP_BRICK contact handler (wherever power-up grant is called):
  ```gdscript
  if MenuController.get_challenge_mode() == "iron_ball":
      # skip grant, just break the brick
      emit_signal("brick_broken", 10)  # score like a normal brick
      queue_free()
      return
  ```

### 6. `scripts/main_power_up_handler.gd` — One Life EXTRA_LIFE Block
- In the dispatch for `EXTRA_LIFE`:
  ```gdscript
  if MenuController.get_challenge_mode() == "one_life":
      return  # silently block
  ```

### 7. `scripts/hud.gd` — Logo Replacement
- On game start, check `MenuController.get_challenge_mode()`
- Replace the center TopBar logo label text:
  - `"normal"` → `"ZEP BALL"` (unchanged)
  - `"iron_ball"` → `"IRON BALL"`
  - `"one_life"` → `"ONE LIFE"`
- Font color and size should remain the same as current logo

### 8. `scripts/ui/game_over.gd` — One Life Continue Button
- After scene loads, check `MenuController.get_challenge_mode()`
- If `"one_life"`: hide the "Continue Set" button entirely

### 9. `scenes/ui/set_select.tscn` + `scripts/ui/set_select.gd` — UI Restructure

**Layout change:** The current full-width pack list is split into a two-column layout.

```
┌──────────────────────────────────────────────────────────────────┐
│                        SELECT PACK                               │
│                                                                  │
│  FILTER: [ALL] [OFFICIAL] [CUSTOM]   SORT: [BY ORDER] [BY PROG] │
│                                                                  │
│  ┌─── Pack List (~75% width) ────┐  ┌── Challenge (~25%) ──┐   │
│  │ [pack cards + scrolling]      │  │ CHALLENGE MODE        │   │
│  │                               │  │ ┌──────────────────┐  │   │
│  │                               │  │ │ Normal         ▼ │  │   │
│  │                               │  │ └──────────────────┘  │   │
│  │                               │  │                        │   │
│  │                               │  │ Standard gameplay      │   │
│  │                               │  │ with all power-ups     │   │
│  │                               │  │ active.                │   │
│  └───────────────────────────────┘  └────────────────────────┘   │
│                                                                  │
│                      BACK TO MENU                                │
└──────────────────────────────────────────────────────────────────┘
```

**Challenge Mode panel contents:**
- Label: "CHALLENGE MODE" (same dim styling as filter labels)
- `OptionButton` with options: `Normal`, `Iron Ball`, `One Life`
- Description `Label` (word-wrapped) below the dropdown:
  - Normal: `"Standard gameplay with all power-ups active."`
  - Iron Ball: `"No power-ups spawn. Pure skill and precision only."`
  - One Life: `"One life. No continues. Complete the pack or start over."`

**LEVELS button disable:** When a non-Normal mode is selected, iterate all visible pack cards and disable their LEVELS buttons. Re-enable when Normal is reselected. Add a tooltip or small note: `"Challenge modes are pack-run only."` (can be a small italic label below the description).

**`set_select.gd` changes:**
- `@onready var challenge_dropdown` reference
- `@onready var challenge_description_label` reference
- `_on_challenge_dropdown_item_selected(index)`:
  - Map index → mode string
  - Update description label text
  - Enable/disable LEVELS buttons on all pack cards
  - Set `MenuController.current_challenge_mode`
- On `_ready()`: set dropdown to index matching `MenuController.current_challenge_mode` (preserves selection if returning from a run)

### 10. `scenes/ui/stats.tscn` + `scripts/ui/stats.gd` — Challenge Leaderboard Tabs

**Change:** Add a `TabBar` (or `TabContainer`) above the existing set high scores section with three tabs:
- `Normal` | `Iron Ball` | `One Life`

On tab switch, re-populate the high scores list from the corresponding save namespace:
- Normal: existing `set_high_scores`
- Iron Ball: `iron_ball_set_high_scores`
- One Life: `one_life_set_high_scores`

Iron Ball and One Life tabs show "No runs yet" placeholder if the namespace is empty.

---

## Save Migration Notes

Follow the save migration SOP in `.agent/SOP/critical-workflows.md`. Summary:
- Version guard: `if data.get("version", 0) < 2`
- Inject `iron_ball_set_high_scores: {}` and `one_life_set_high_scores: {}` if missing
- Inject `challenge_mode: "normal"` into `last_played` if missing
- After migration, write version `2`
- Existing player progress, scores, and settings are fully preserved

> **Coordination note:** `new-game-modes.md` (Time Attack + Survival) bumps save to version `3`. If both tasks are implemented together, a single migration from `1` → `3` is acceptable — consolidate all new fields into one migration block rather than chaining two separate guards.

---

## Implementation Order

Work in this order to avoid depending on unfinished pieces:

1. **SaveManager** — migration + new helpers (everything else reads from here)
2. **MenuController** — mode state + `get_challenge_mode()` (everything else reads from here)
3. **set_select** — UI restructure + dropdown wiring (sets the mode state)
4. **GameManager** — One Life lives override
5. **main.gd** — Iron Ball drop suppression
6. **brick.gd** — POWERUP_BRICK Iron Ball handling
7. **main_power_up_handler.gd** — One Life EXTRA_LIFE block
8. **game_over.gd** — One Life Continue Set hide
9. **hud.gd** — Logo replacement
10. **stats** — Leaderboard tabs

---

## Out of Scope (Future)

- Challenge mode per-level high scores (pack-level only for now)
- Challenge mode achievements/badges (e.g., "Complete a pack in One Life")
- Stacking Iron Ball + One Life simultaneously
- Challenge mode support for individual level play
- Additional challenge modes (Time Attack, Survival) → see `Tasks/Backlog/new-game-modes.md`

---

## Related Docs
- `future-features.md` — parent backlog (Iron Ball, One Life entries)
- `Tasks/Backlog/new-game-modes.md` — Time Attack & Survival spec; shares save migration chain (v2→3), Stats screen tabs, and `get_challenge_mode()` extension
- `System/architecture.md` — GameManager, main.gd, power-up system details
- `SOP/critical-workflows.md` — save migration SOP, commit format
