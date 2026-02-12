# Post-Overhaul Fixes

## Status: COMPLETED (2026-02-12)

Issues discovered and fixed during the post-optimization-pass / post-level-overhaul review.

---

## 1. BUG FIX: Perfect Clear Flag Reset on Ball Relaunch

**File**: `scripts/game_manager.gd`

`start_playing()` was unconditionally setting `is_perfect_clear = true` on every ball launch. After losing a life, relaunching the ball reset the flag, so the 2x perfect clear bonus was always awarded regardless of lives lost.

**Fix**: Removed the `is_perfect_clear = true` line from `start_playing()`. The flag is already initialized to `true` on fresh scene load and `_restore_set_state()` handles set-mode continuity.

---

## 2. Removed Unreachable Condition in `is_level_key_unlocked`

**File**: `scripts/save_manager.gd`

Removed a dead branch that checked `level_index == 0` with an additional `MenuController.current_set_pack_id` guard, which was unreachable because the preceding unconditional `level_index == 0` check already returned `true`.

---

## 3. DRY: Deduplicated Brick Color Constants

**File**: `scripts/ui/level_editor.gd`

Replaced the inline `BRICK_COLORS` dictionary (14 entries duplicating `PackLoader.BRICK_PREVIEW_COLOR_MAP`) with a getter property that delegates to `PackLoader.BRICK_PREVIEW_COLOR_MAP`.

---

## 4. Fixed Stale Documentation Reference

**File**: `.agent/Tasks/Backlog/future-features.md`

Updated "Advanced Tile Elements" section to reference `scripts/pack_loader.gd` instead of the removed `scripts/level_loader.gd`.

---

## 5. Removed Unused `reset_game()`

**File**: `scripts/game_manager.gd`

Removed the `reset_game()` function which was never called. Game state resets happen via fresh scene instantiation, and set-mode state is restored via `_restore_set_state()`.

---

Last Updated: 2026-02-12
