# Task: Player Profiles & Local High Scores

Implement a robust player profile system that allows multiple users to have their own settings, progression, and statistics on the same machine. Includes a new local leaderboard for comparing scores across profiles.

## Status
- **Priority**: High
- **Status**: Backlog (Plan Only)
- **Target Version**: Next

## Requirements

### 1. Profile Management (Architecture)
- **Storage Strategy**: Option B (Multiple Files).
  - `user://metadata.json`: Stores global data (last selected profile ID, profile list mapping).
  - `user://profiles/`: Directory containing individual profile JSON files (e.g., `p1.json`, `p2.json`).
- **Migration**: On first launch, detect legacy `save_data.json`.
  - Create `user://profiles/player_1.json` using the legacy data.
  - Create `user://metadata.json` with "Player 1" as the active profile.
  - Back up and remove/rename legacy `save_data.json`.
- **Sanitization**: Profile names must be sanitized for filenames and safe storage (alphanumeric + spaces only).
- **Default Naming**: New profiles should pre-fill with "Player N" (incrementing based on availability).

### 2. Main Menu UI
- **Profile Selector**: A dropdown menu above the "PLAY" button.
- **Add Button**: A "+" button next to the dropdown to create a new profile immediately.
- **Immediate Refresh**: Switching a profile must instantly update the menu's progression display (unlocked levels, stats).
- **Controller Support**: All new elements must be fully navigable via keyboard/gamepad (directional focus, `ui_accept` to select).

### 3. Settings UI
- **Profile Management Section**:
  - **Rename**: Allow changing the display name of the current profile.
  - **Delete**: Allow removing a profile (requires a "Hold to Confirm" or secondary confirmation dialog).
  - **Logic**: Deleting a profile wipes its file and removes its entries from the high scores leaderboard.

### 4. High Scores Menu
- **Entry Point**: A new "HIGH SCORES" button on the Main Menu (placed next to "STATS", sharing the width).
- **Comparison**: View top 10 scores overall across all profiles.
- **Filtering**: Ability to view high scores per level or per set.
- **UI**: Clear table showing Profile Name, Score, and Date achieved.

### 5. HUD Update
- **Display**: Show the active profile name on the HUD, positioned either under or next to the "ZEP BALL" logo.

---

## Technical Implementation Plan

### Phase 1: Save System Refactor (SaveManager)
- [ ] Implement `ProfileMetadata` structure to track `last_selected_id` and `profile_list`.
- [ ] Update `SaveManager` to support loading/saving from `user://profiles/[id].json`.
- [ ] Add migration logic for `save_data.json` -> `profiles/player_1.json`.
- [ ] Create a sanitization helper function for user-entered names.

### Phase 2: UI Overhaul
- [ ] **Main Menu**:
  - [ ] Add `OptionButton` (dropdown) and `Button` (+).
  - [ ] Implement name entry popup for new profiles.
  - [ ] Connect profile switching to a full UI refresh signal.
- [ ] **Settings**:
  - [ ] Add "Manage Profiles" sub-menu or section.
  - [ ] Implement rename/delete logic.
- [ ] **HUD**:
  - [ ] Update `hud.tscn` and `hud.gd` to display `SaveManager.current_profile_name`.

### Phase 3: Local Leaderboards
- [ ] Create `HighScoresManager` (or extend `SaveManager`) to maintain a global high scores index.
- [ ] Create `scenes/ui/high_scores.tscn`.
- [ ] Implement table view with sorting/filtering by level/set.
- [ ] Ensure score entries are linked to Profile IDs so they can be removed if a profile is deleted.

---

## Considerations & Risks
- **Controller Focus**: Ensuring the dropdown and "+" button play nice with Godot's focus system (especially when many profiles exist).
- **File IO**: Handling edge cases where a profile file might be missing but listed in metadata.
- **Active Data**: Ensuring `PowerUpManager`, `DifficultyManager`, etc., are correctly reset/notified when a profile swap occurs mid-session (though profiles should ideally only be swapped on the Main Menu).

## Verification Checklist
- [ ] Existing save data is correctly moved to "Player 1" on first run.
- [ ] Creating a new profile resets all progression and stats to default.
- [ ] Deleting a profile removes its file and clears its scores from the leaderboard.
- [ ] High scores correctly show names from different profiles.
- [ ] Profile name is visible on HUD during gameplay.
- [ ] All menu navigation works via D-Pad/Joystick.

# Outstanding issues
- Controller B button not cancelling new menus
