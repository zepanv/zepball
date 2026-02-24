# Task: Bugfixes & Pack Select UI Enhancements

Address reported bugs regarding combo persistence and paddle displacement, and enhance the Pack Select screen with filtering and sorting capabilities.

## Status
- **Priority**: Medium-High
- **Status**: ✅ Completed
- **Completed Date**: 2026-02-15
- **Target Version**: Next

## Requirements

### 1. Bugfix: Level-Specific Combo & Streak (Set Mode)
- **Issue**: In Set Mode, the combo multiplier and no-miss streak currently carry over between levels, leading to unintended high scores.
- **Requirement**: 
  - Reset `combo` and `no_miss_hits` (streak) at the start of every level.
  - **Exception**: The `is_perfect_clear` status (Perfect Set eligibility) **must continue to carry over** until a life is lost, ensuring the 3x Perfect Set bonus remains achievable only for flawless runs.
- **Fix**:
  - Update `MenuController.gd` to stop saving/restoring `set_saved_combo` and `set_saved_no_miss`.
  - Ensure `set_saved_perfect` remains in the state preservation logic.
  - Update `main.gd`'s `_restore_set_state` to remove combo/streak restoration.

### 2. Bugfix: Paddle Horizontal Displacement
- **Issue**: The ball can occasionally push the paddle horizontally out of the play area when hitting its top/bottom at an angle.
- **Requirement**: Ensure the paddle is strictly locked to its X-axis position.
- **Fix**:
  - Update `paddle.gd` to explicitly clamp/set `position.x` to its initial value during `_physics_process`.

### 3. UI Enhancement: Pack Select Filters & Sorts
- **Feature**: Add a toolbar to the Pack Select screen (`set_select.tscn`) similar to the Level Select screen.
- **Filter Options**:
  - **ALL**: Show everything.
  - **OFFICIAL**: Show only built-in/official packs.
  - **CUSTOM**: Show only user-created packs.
- **Sort Options**:
  - **BY ORDER**: 
    1. Custom packs first (A-Z or creation date).
    2. Official packs second (in their defined legacy order: Classic -> Prism -> Nebula).
  - **BY PROGRESSION**: Sort by completion percentage (descending).
- **Navigation**: Ensure all new UI elements are controller-accessible.

---

## Technical Implementation Plan

### Phase 1: Bugfixes
- [x] **Combo Reset**:
  - [x] Modify `scripts/ui/menu_controller.gd`: Remove `set_saved_combo` and `set_saved_no_miss` from the state preservation logic in `show_level_complete`.
  - [x] Modify `scripts/main.gd`: Update `_restore_set_state` and its call site to stop restoring these values.
- [x] **Paddle Lock**:
  - [x] Modify `scripts/paddle.gd`:
    - [x] Store `initial_x` in `_ready()`.
    - [x] Set `position.x = initial_x` at the end of `_physics_process`.

### Phase 2: Pack Select UI
- [x] **UI Scaffolding**:
  - [x] Modify `scenes/ui/set_select.tscn`: Add a toolbar container for filters and sorts.
  - [x] Update `scripts/ui/set_select.gd` to include `filter_mode` and `sort_mode` variables.
- [x] **Filtering/Sorting Logic**:
  - [x] Implement `_apply_filter` and `_apply_sort` helpers in `set_select.gd`.
  - [x] Use `PackLoader.LEGACY_PACK_ORDER` for official pack ordering.
  - [x] Calculate progression via `SaveManager.get_pack_completed_count(pack_id) / PackLoader.get_level_count(pack_id)`.
- [x] **Controller Support**:
  - [x] Ensure toolbar buttons are in the focus order.
  - [x] Verify `_grab_first_button_focus` works with the new layout.

---

## Verification Checklist
- [x] Starting a new level in a set starts with 0x combo and 0 streak.
- [x] The paddle cannot be moved horizontally, even when hit by a high-speed ball at an angle.
- [x] Pack Select screen shows Filter/Sort buttons.
- [x] Filtering "CUSTOM" shows only user packs.
- [x] Sorting "BY ORDER" places Custom packs at the top and preserves Official pack sequence.
- [x] Sorting "BY PROGRESSION" puts 100% completed packs at the top.
- [x] All UI is navigable via Gamepad.

## Implementation Summary

### Files Modified
1. **scripts/ui/menu_controller.gd**
   - Lines 484-490: Removed saving of `set_saved_combo` and `set_saved_no_miss`
   - Preserved `set_saved_perfect` for Perfect Set bonus eligibility

2. **scripts/main.gd**
   - Lines 119-124: Updated `_restore_set_state` call to remove combo/streak parameters
   - Lines 129-141: Updated `_restore_set_state` function signature and implementation

3. **scripts/paddle.gd**
   - Line 30: Added `initial_x` variable declaration
   - Line 48: Store initial X position in `_ready()`
   - Line 133: Lock paddle to initial X position in `_physics_process()`

4. **scripts/ui/set_select.gd**
   - Added FilterMode and SortMode enums
   - Added filter/sort state variables
   - Implemented `_create_toolbar()` method with UI controls
   - Implemented `_apply_filter()` and `_apply_sort()` methods
   - Updated `populate_packs()` to apply filtering and sorting

5. **scenes/ui/set_select.tscn**
   - Added ToolbarContainer MarginContainer node for filter/sort UI

6. **scenes/ui/main_menu.tscn**
   - Line 203: Updated VersionLabel text from "2026-02-14" to "2026-02-15"
