# Level System Overhaul - Pack Format, Editor, and Level Select

## Status: COMPLETED

This document covers four interconnected features that modernize the level system: a shareable pack format, an in-game level editor, enhanced level select UX, and a third content set.  The current built in levels should also be converted to the new pack format.

## Progress Update (2026-02-11)

### Stage 1 Completed: Pack Format Foundation (Compatibility Mode)
- ✅ Added `scripts/pack_loader.gd` autoload with discovery, validation, level access, and level instantiation APIs.
- ✅ Added built-in packs:
  - `packs/classic-challenge.zeppack` (levels 1-10 converted)
  - `packs/prism-showcase.zeppack` (levels 11-20 converted)
- ✅ Added `PackLoader` autoload registration in `project.godot`.
- ✅ Added startup creation for `user://packs/`.
- ✅ Kept existing gameplay/menu flow stable by converting legacy integer level/set compatibility into `PackLoader` helper APIs.
- ✅ Phase 2 loader migration is now complete for core runtime systems.

### Stage 2 Completed: Loader Migration (Core Runtime)
- ✅ `MenuController` now tracks and runs levels with `pack_id + level_index` internally (legacy `level_id` still exposed for compatibility).
- ✅ `main.gd` now loads gameplay levels via `PackLoader.instantiate_level(pack_id, level_index, ...)`.
- ✅ `GameManager` now stores `current_pack_id`, `current_level_index`, and `current_level_key` alongside legacy `current_level`.
- ✅ `SaveManager` upgraded to save version 2 with pack-native progression/high-score structures and migration from legacy level/set IDs.
- ✅ High-score/completion/unlock flow now supports level keys (`pack_id:level_index`) and set pack IDs.
- ✅ Last-played tracking now persists pack-native references (`pack_id`, `level_index`, `level_key`, `set_pack_id`) with legacy fallback fields.
- ✅ Removed `LevelLoader` autoload and `scripts/level_loader.gd` after migrating all direct runtime calls to `PackLoader`.
- ✅ Removed `SetLoader` autoload and `scripts/set_loader.gd` after migrating set compatibility lookups to `PackLoader`.
- ✅ Removed legacy data files no longer used at runtime:
  - `data/level_sets.json`
  - `levels/level_01.json` - `levels/level_20.json`

### Stage 3 Completed: Enhanced Pack/Level Select UX
- ✅ Reworked `set_select.gd` to pack-driven cards using `PackLoader` (official/custom badge, author, progress, star summary, best score).
- ✅ Added pack-level play flow with `MenuController.start_pack(pack_id)` and browse-pack context (`current_browse_pack_id`).
- ✅ Reworked `level_select.gd` with:
  - Preview thumbnails generated from pack level data (`PackLoader.generate_level_preview`).
  - Star display per level and save-backed star tracking (`SaveManager` level-key stars).
  - Filter controls: All / Completed / Locked.
  - Sort controls: By Order / By Score.
- ✅ Fixed incorrect `NEW` label behavior:
  - `NEW` now appears only for unlocked levels with no completion and no high score.
  - Completed/high-score levels now show `COMPLETED`.
  - Locked levels show `LOCKED`.

### Stage 4 Completed: Level Editor (Scaffolding + Navigation)
- ✅ Added `scenes/ui/level_editor.tscn` and `scripts/ui/level_editor.gd` with:
  - Pack metadata editing (pack_id, name, author, description)
  - Level list add/remove/select
  - Grid size controls (rows/cols)
  - Brush selection (eraser + all current brick types)
  - Click paint / right-click erase grid editing
  - Save to `user://packs/{pack_id}.zeppack` via `PackLoader.save_user_pack()`
- ✅ Added editor entry points:
  - Main menu `EDITOR` button
  - Pack select `EDIT` button on custom packs
  - Pack select `CREATE NEW PACK` action
  - `MenuController.show_editor()` / `show_editor_for_pack(pack_id)`
- ✅ Added editor return routing:
  - Back returns to Main Menu when editor was opened from Main Menu
  - Back returns to Pack Select when editor was opened from Pack Select
- ✅ Added level metadata editing UI:
  - Per-level `name` and `description` fields in editor
- ✅ Added level list management upgrades:
  - Duplicate level
  - Move level up/down reordering
- ✅ Added undo/redo history:
  - Snapshot-based undo/redo buttons
  - Ctrl/Cmd+Z undo
  - Ctrl/Cmd+Y and Ctrl/Cmd+Shift+Z redo
- ✅ Added editor test mode flow:
  - `TEST LEVEL` launches gameplay from current in-editor draft (no save required)
  - Test runs avoid progression/high-score/stat side effects
  - Game Over / Level Complete routes return to editor
  - Draft pack and selected level are restored when returning from test
  - Pause menu in test mode now includes `RETURN TO EDITOR`
- ✅ Added saved-pack reload shortcut:
  - Editor now includes `OPEN SAVED PACKS (EDIT)` button to jump directly to pack list for reopening via `EDIT`
- ✅ Added export UX polish:
  - Editor now includes `EXPORT PACK` button
  - Exports write timestamped `.zeppack` files to `user://exports/`
  - Status bar shows full exported file path for quick retrieval
  - Added `OPEN EXPORT FOLDER` button to open `user://exports/` in Finder/Explorer/file manager
- ✅ Added pack deletion flow in editor:
  - `DELETE PACK` action is available for saved custom packs
  - Confirmation prompt is shown before deletion
  - Successful delete returns to pack select

### UX/Runtime Fixes (2026-02-11)
- ✅ Level select title clipping fixed by expanding top-level layout bounds.
- ✅ Level select filter/sort controls consolidated to a single toolbar row.
- ✅ Gameplay level intro now shows actual level descriptions (fixed missing intro desc label binding).
- ✅ Stats screen now supports `Esc` (`ui_cancel`) to go back.
- ✅ Removed warning-as-error from `stats.gd` by marking intentionally unused achievement parameter.

### Stage 5 Completed: Third Set Content
- ✅ Added third built-in pack: `packs/nebula-ascend.zeppack` with 10 authored levels.
- ✅ Wired legacy compatibility mappings for the third set:
  - `PackLoader.LEGACY_PACK_ORDER` now includes `nebula-ascend`.
  - `PackLoader` legacy set mapping includes set 3 -> `nebula-ascend`.
  - `SaveManager` legacy fallback mappings now support levels `21-30` and set `3`.
- ✅ Updated Champion achievement requirement from 10 to 30 level completions.

### Stage 6 Completed: Polish and Documentation
- ✅ Updated `levels/README.md` to document `.zeppack` as the source-of-truth format and clarify that `levels/*.json` is legacy compatibility only.
- ✅ Removed direct `LevelLoader` runtime dependencies from:
  - `scripts/ball.gd` (air-ball landing data now uses `PackLoader` + level-key cache)
  - `scripts/hud_pause_menu_helper.gd` (pause level info now uses `PackLoader.get_level_info`)
- ✅ Removed remaining temporary migration wrappers/data:
  - `scripts/set_loader.gd`
  - `data/level_sets.json`
  - `levels/level_01.json`-`levels/level_20.json`
- ✅ Editor play-area bounds enforcement:
  - Rows/cols are now dynamically clamped so bricks cannot be placed outside playable bounds.
  - Existing oversized levels are normalized on load/test/save.
- ✅ Editor bounds stability fix:
  - Hard-capped editor grid limits to `12 rows` and `19 cols` (play-area safe bounds) to prevent return-from-test column resets.

---

## 1. Shareable Pack Format (`.zeppack`)

### Description
Replace individual level JSON files and `level_sets.json` with a single-file pack format (`.zeppack`) that users can create, share, and drop into a directory the game discovers on load.

### Pack File Schema
```json
{
  "zeppack_version": 1,
  "pack_id": "classic-challenge",
  "name": "Classic Challenge",
  "author": "Zep Ball Team",
  "description": "Master the basics across 10 progressive levels",
  "created_at": "2026-02-10T12:00:00Z",
  "updated_at": "2026-02-10T12:00:00Z",
  "source": "builtin",
  "tags": ["official", "beginner"],
  "levels": [
    {
      "level_index": 0,
      "name": "First Contact",
      "description": "Learn the basics - break all the bricks!",
      "grid": {
        "rows": 10,
        "cols": 6,
        "start_x": 200,
        "start_y": 106,
        "brick_size": 48,
        "spacing": 3
      },
      "bricks": [
        {"row": 0, "col": 0, "type": "NORMAL"}
      ]
    }
  ]
}
```

### Key Design Decisions
- **Single JSON file** - The codebase is fully JSON-based; no need for ZIP/binary at this data size (<100KB per pack). Human-readable and trivially shareable.
- **`.zeppack` extension** - Distinct from plain `.json` for easy identification and file association.
- **`pack_id`** - String slug used as the key in save data. Built-in: `"classic-challenge"`, `"prism-showcase"`. User packs: generated from author + name.
- **`source` field** - Either `"builtin"` or `"user"`. The loader enforces this based on where the file was found, not what the file claims.
- **`level_index`** - 0-based index within the pack. Replaces the global integer `level_id`.
- **Compound level key** - `"pack_id:level_index"` (e.g., `"classic-challenge:3"`) used throughout the game for level addressing.
- **Levels per pack** - Variable, support packs with as few as 1 level up to 30?

### Discovery and Loading
- **Built-in packs**: `res://packs/` (read-only in exports)
- **User packs**: `user://packs/` (created on first launch if missing)
  - Linux: `~/.local/share/godot/app_userdata/Zep Ball/packs/`
  - macOS: `~/Library/Application Support/Godot/app_userdata/Zep Ball/packs/`
  - Windows: `%APPDATA%/Godot/app_userdata/Zep Ball/packs/`
- **Load order**: Built-in first, then user packs alphabetically by name
- **Duplicate `pack_id`**: User pack skipped if it collides with a built-in pack

### Validation on Load
- Check `zeppack_version` is supported (currently only 1)
- Verify `pack_id`, `name`, and `levels` array exist and are non-empty
- Validate each level has `grid` and `bricks` with correct structure
- Validate all brick `type` strings against the known brick type map
- Skip invalid bricks with a warning; still load the level

### New Autoload: `PackLoader`
Replaces both `LevelLoader` and `SetLoader` with a unified API:

```gdscript
# Pack discovery
func get_all_packs() -> Array[Dictionary]
func get_builtin_packs() -> Array[Dictionary]
func get_user_packs() -> Array[Dictionary]
func get_pack(pack_id: String) -> Dictionary
func pack_exists(pack_id: String) -> bool

# Level access
func get_level_count(pack_id: String) -> int
func get_level_data(pack_id: String, level_index: int) -> Dictionary
func get_level_info(pack_id: String, level_index: int) -> Dictionary
func instantiate_level(pack_id: String, level_index: int, brick_container: Node2D) -> Dictionary
func get_level_key(pack_id: String, level_index: int) -> String

# Validation
func validate_pack(data: Dictionary) -> Array[String]

# User pack management
func save_user_pack(pack_data: Dictionary) -> bool
func delete_user_pack(pack_id: String) -> bool
func ensure_packs_directory() -> void
```

### Save Data Migration (v1 -> v2)
- Map integer level IDs to compound keys: `1` -> `"classic-challenge:0"`, `11` -> `"prism-showcase:0"`
- New `pack_progression` dict per pack replaces flat `progression` + `set_progression`
- Map old `high_scores` keys, `set_high_scores`, `last_played` to new format
- Migration runs once on load when save version < 2

### Migration: Existing Level Files
- Combine `levels/level_01.json` through `level_10.json` + set metadata into `packs/classic-challenge.zeppack`
- Combine `levels/level_11.json` through `level_20.json` + set metadata into `packs/prism-showcase.zeppack`
- Delete individual level files, `data/level_sets.json`, `scripts/level_loader.gd`, `scripts/set_loader.gd` after migration confirmed

---

## 2. In-Game Level Editor

### Description
A visual editor built into the game for creating and editing level packs. Accessible from the main menu and from user pack cards in pack select.

### Scene Architecture
```
LevelEditor (Control)
  Background (ColorRect)
  HSplitContainer
    LeftPanel (VBoxContainer)
      PackInfoSection         -- Pack name, author, description fields
      LevelListSection        -- ItemList of levels + add/remove/reorder buttons
      LevelPropertiesSection  -- Level name, description, rows/cols SpinBoxes
      BrickPalette            -- 14 brick type buttons + eraser
      ActionButtons           -- Test Level, Save Pack, Export Pack
    RightPanel (VBoxContainer)
      Toolbar                 -- Undo, Redo, Clear Grid, Fill Grid, Auto-Center
      GridViewport (SubViewportContainer)
        SubViewport
          EditorGrid (Node2D) -- Interactive grid with brick previews
      StatusBar               -- "Row: 3, Col: 5 | Bricks: 24/120"
  BackButton
```

### Features
- **Grid rendering**: Same coordinate system as gameplay (`brick_size = 48`, `spacing = 3`). Cells rendered as colored rects matching brick type colors.
- **Painting**: Click to place selected brick type, drag to paint, right-click to erase. Hovering highlights the target cell.
- **Grid resize**: Rows/cols SpinBoxes auto-recalculate `start_x`/`start_y` using the vertical centering formula.
- **Undo/Redo**: Snapshot stacks of the bricks array (cap at 50). Ctrl+Z / Ctrl+Y.
- **Level list**: Add, remove, duplicate, reorder levels within the current pack.
- **Test mode**: Launches gameplay scene with current level data. MenuController gets `is_editor_test_mode` flag to return to editor on exit.
- **Save**: Writes to `user://packs/{pack_id}.zeppack`. Built-in packs require "Save As" with new pack_id.
- **Access points**: "EDITOR" button on main menu (new pack), "EDIT" button on user pack cards in pack select.

### Implementation
- Create `scenes/ui/level_editor.tscn` and `scripts/ui/level_editor.gd`
- Add `show_editor()` and `show_editor_for_pack(pack_id)` to MenuController
- Add editor test mode flow to MenuController (flag + return path)
- Add editor input actions to `project.godot` (Ctrl+Z, Ctrl+Y)

---

## 3. Enhanced Level Select UX

### Description
Improve level browsing with previews, star ratings, and filtering. Rework Set Select into a Pack Select that shows both built-in and user packs.

### Level Preview Thumbnails
- Procedurally generated from level brick data
- Small canvas (e.g., 120x80), each brick drawn as a small colored rectangle
- Colors match brick type colors from `brick.gd`
- Cached in memory (fast to generate, no disk writes)

### Star Rating System
- **Bronze**: Completed the level (any score)
- **Silver**: Score >= 50% of max possible base score
- **Gold**: Score >= 80% of max possible base score OR achieved a perfect clear
- Max possible base score = sum of all brick `score_value` in the level
- Stored in save data: `pack_progression.{pack_id}.stars.{level_index}: int` (0-3)

### Filter and Sort Controls
- Filter bar above level grid: All / Completed / Locked
- Sort: By Order / By Score
- Default: All + By Order

### Pack Select (Reworked Set Select)
- Rename "SET SELECT" to "SELECT PACK"
- Built-in packs shown first with "OFFICIAL" badge
- User packs below with "CUSTOM" badge
- Each pack card: name, author, description, level count, completion progress, star summary
- Buttons per card: "PLAY PACK" (set mode), "VIEW LEVELS" (level select)
- User pack cards also get "EDIT" button
- "CREATE NEW PACK" button at bottom of list (opens editor)

### Level Card Enhancements
```
LevelCard (PanelContainer)
  HBoxContainer
    PreviewTexture (TextureRect)   -- 120x80 thumbnail
    VBoxContainer
      TitleLabel                   -- "LEVEL 1: First Contact"
      DescriptionLabel
      HBoxContainer
        StarsContainer             -- 1-3 star icons
        ScoreLabel                 -- "Best: 5,420"
        StatusLabel                -- "NEW" / "LOCKED"
```

### Bugfix Requirement: Incorrect `NEW` Label
- Current issue: previously completed levels can still display `NEW` in Level Select.
- Required behavior:
  - `NEW` only shows for unlocked levels with no completion/high-score record.
  - Completed levels must never show `NEW`; show stars/high-score state instead.
  - Locked levels continue to show `LOCKED`.
- Include this in the Level Select refactor acceptance criteria and migration validation.

### Implementation
- Add thumbnail utility function to PackLoader (or standalone helper)
- Rework `scripts/ui/set_select.gd` -> pack select with badges and user pack controls
- Rework `scripts/ui/level_select.gd` with thumbnails, stars, filter/sort
- Update `SaveManager` with star rating calculation and storage
- Update level complete flow to calculate and store star ratings

---

## 4. New Content: Third Set

### Description
10 new levels as a third built-in pack, authored using the editor.

### Requirements
- Ship as `res://packs/{pack-name}.zeppack`
- Uses existing brick types
- Theme TBD (e.g., bomb-focused, mixed advanced shapes, or a new creative theme)
- Can be created once the editor is functional

---

## Implementation Phases

### Phase 1: Pack Format Foundation
- ✅ Create `scripts/pack_loader.gd` with pack discovery, loading, validation, caching
- ✅ Convert 20 existing levels into 2 `.zeppack` files under `packs/`
- ✅ Register `PackLoader` as autoload (alongside existing loaders initially)
- ✅ Create `user://packs/` directory on startup

### Phase 2: Loader Migration
- ✅ Refactor `MenuController` to use `pack_id` + `level_index` (string-based addressing)
- ✅ Refactor `GameManager` for string-based current level
- ✅ Update `main.gd` to use `PackLoader.instantiate_level()`
- ✅ Add save data v2 migration to `SaveManager`
- ✅ Remove old `SetLoader`, individual level files, `level_sets.json`

### Phase 3: Enhanced Level Select
- ✅ Create thumbnail generation utility
- ✅ Rework set select into pack select with official/custom badges
- ✅ Enhance level cards with thumbnails, stars, filters, sort
- ✅ Add star rating calculation to level complete flow

### Phase 4: Level Editor
- ✅ Create `level_editor.tscn` and `level_editor.gd`
- ✅ Implement grid rendering, brick palette, painting, undo/redo
- ✅ Implement level list management, pack metadata editing
- ✅ Implement test mode flow
- ✅ Implement save/export
- ✅ Add editor access to main menu and pack select

### Phase 5: Third Set Content
- ✅ Author 10 new levels using the editor
- ✅ Move from `user://packs/` to `res://packs/` for shipping (`packs/nebula-ascend.zeppack`)
- ✅ Update achievements (Champion now requires 30 level completions)

### Phase 6: Polish and Documentation
- Update `.agent/System/architecture.md` and `.agent/README.md`
- Edge case testing: empty packs, corrupted files, duplicate pack_ids
- Remove debug print statements
- Update `levels/README.md` to document `.zeppack` format

---

## Files Impact Summary

### Create
| File | Purpose |
|------|---------|
| `scripts/pack_loader.gd` | New autoload: pack discovery, loading, validation |
| `scripts/ui/level_editor.gd` | Level editor logic |
| `scenes/ui/level_editor.tscn` | Level editor scene |
| `packs/classic-challenge.zeppack` | Built-in pack (converted from levels 1-10) |
| `packs/prism-showcase.zeppack` | Built-in pack (converted from levels 11-20) |
| `packs/{third-set}.zeppack` | Third built-in pack (10 new levels) |

### Modify
| File | Changes |
|------|---------|
| `project.godot` | Migrate autoloads toward PackLoader-centric runtime; add editor input actions |
| `scripts/save_manager.gd` | v2 migration, pack_progression, star ratings |
| `scripts/ui/menu_controller.gd` | String-based level keys, pack_id, editor flow |
| `scripts/game_manager.gd` | String-based current_level |
| `scripts/main.gd` | Use PackLoader instead of LevelLoader |
| `scripts/ui/set_select.gd` | Rework into pack select |
| `scripts/ui/level_select.gd` | Thumbnails, stars, filter/sort |
| `scripts/ui/main_menu.gd` | Add EDITOR button |
| `scenes/ui/main_menu.tscn` | Add EDITOR button node |
| `scenes/ui/set_select.tscn` | Layout changes for pack select |
| `scenes/ui/level_select.tscn` | Layout changes for enhanced level cards |

### Delete (After Migration)
| File | Reason |
|------|--------|
| `levels/level_01.json` - `level_20.json` | Replaced by .zeppack files |
| `data/level_sets.json` | Replaced by pack metadata |
| `scripts/level_loader.gd` | Replaced by pack_loader.gd |
| `scripts/set_loader.gd` | Replaced by pack_loader.gd |

---

## Notes
- All features use existing Godot APIs (FileAccess, DirAccess, JSON) with no external dependencies
- Pack files are small enough that ZIP compression provides negligible benefit
- The `source` field is enforced by the loader, preventing users from spoofing official status
- Star rating thresholds may need tuning after playtesting
- The editor should enforce vertical centering automatically

---

Last Updated: 2026-02-11
