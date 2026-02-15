# Critical Workflows - Zep Ball

**⚠️ MANDATORY PROCEDURES - Read before making any code changes**

These workflows MUST be followed for all development work on this project.

---

## Table of Contents

1. [Save System Compatibility](#save-system-compatibility) - CRITICAL
2. [Asset Documentation Requirements](#asset-documentation-requirements) - CRITICAL
3. [Commit Message Format](#commit-message-format) - Required
4. [Release Versioning (SemVer) and Git Tags](#release-versioning-semver-and-git-tags) - Required for releases

---

## Save System Compatibility

### ⚠️ CRITICAL: Always Check Save Format When Adding Features

When adding new features that modify the save data structure, you **MUST** add migration logic to handle existing save files. Failure to do this will cause crashes for users with existing saves.

### When to Add Migration Logic

Add migration code whenever you:
- ✅ Add new keys to the save_data dictionary
- ✅ Add new statistics or achievement tracking
- ✅ Add new settings or preferences
- ✅ Change the structure of existing save data
- ✅ Rename or remove save data keys

### Migration Pattern

**Location:** `scripts/save_manager.gd` in the `load_save()` function

**Template:**
```gdscript
func load_save() -> void:
	# ... existing load code ...

	save_data = loaded_data

	# MIGRATION: Add new section if it doesn't exist
	if not save_data.has("new_section"):
		print("Adding new_section to save data...")
		save_data["new_section"] = {
			"new_field_1": default_value,
			"new_field_2": default_value
		}
		save_to_disk()  # Save the migrated data immediately

	# ... rest of load code ...
```

### Example: Adding Statistics Section (2026-01-29)

**Problem:** Added statistics tracking, but old saves don't have "statistics" key.
**Result:** Game crashes with "Invalid access to property 'statistics'" when viewing stats.

**Solution:**
```gdscript
# Migrate old saves that don't have statistics
if not save_data.has("statistics"):
	print("Adding statistics section to save data...")
	save_data["statistics"] = {
		"total_bricks_broken": 0,
		"total_power_ups_collected": 0,
		"total_levels_completed": 0,
		"total_playtime": 0.0,
		"highest_combo": 0,
		"highest_score": 0,
		"total_games_played": 0,
		"perfect_clears": 0
	}
	save_to_disk()
```

### Migration Checklist

Before committing changes that modify save data:
- [ ] Added migration code in `load_save()` to handle old saves
- [ ] Updated `create_default_save()` with new structure
- [ ] Tested with both new save (delete user://save_data.json) and old save
- [ ] Verified migration preserves existing player progress
- [ ] Checked that new features work with migrated data
- [ ] Added print statement for debugging migration

### Testing Save Migrations

**Test with old save:**
1. Run game with existing save file
2. Check console for migration messages
3. Verify new feature doesn't crash
4. Check that old data (levels, scores) still works

**Test with new save:**
1. Delete `user://save_data.json` (see SaveManager.get_save_file_location())
2. Run game to create fresh save
3. Verify all features work with new structure

**Finding save file:**
```gdscript
# Run this in game or debug console
print(SaveManager.get_save_file_location())

# Typical locations:
# macOS: ~/Library/Application Support/Godot/app_userdata/[ProjectName]/
# Linux: ~/.local/share/godot/app_userdata/[ProjectName]/
# Windows: %APPDATA%/Godot/app_userdata/[ProjectName]/
```

### Save Version System

The save file includes a `"version"` field for major migrations:

```gdscript
const SAVE_VERSION = 1  # Increment for breaking changes

# Check version and perform major migration if needed
if loaded_data.get("version", 0) < SAVE_VERSION:
	print("Performing major save migration from v", loaded_data.get("version"), " to v", SAVE_VERSION)
	# Perform migration...
	save_data["version"] = SAVE_VERSION
	save_to_disk()
```

**When to increment SAVE_VERSION:**
- Major restructuring that can't be handled by simple key checks
- Removing old data that's no longer needed
- Changing data types (e.g., String to int)
- Multiple related changes that should happen atomically

**For simple additions:** Use `if not save_data.has("key")` checks (no version bump needed)

---

## Asset Documentation Requirements

### ⚠️ CRITICAL: Always Update Asset Documentation

When you add a new asset to the project or remove one from use, you **MUST** update the corresponding documentation files. Failure to do this will cause the documentation to become out of sync with the actual asset usage.

### When to Update Documentation

Update the docs when you:
- ✅ Add a new graphic asset (sprites, backgrounds, powerups, particles)
- ✅ Add a new audio asset (SFX, music)
- ✅ Remove an asset from use (stop referencing it in code)
- ✅ Change which assets are used (e.g., switching paddle sprite)
- ✅ Add new powerup types that need icons
- ✅ Add new brick types with new textures

### Documentation Files

| File | Purpose | Update When |
|------|---------|-------------|
| `.agent/System/used-assets.md` | Lists all actively used assets | Add new assets, update references |
| `.agent/System/unused-assets.md` | Lists assets not currently in use | Remove assets from use, clean up unused |

### Update Process

**Adding a New Asset:**
1. Import the asset into the appropriate `assets/` folder
2. Reference it in your code/scene
3. Add entry to `used-assets.md` with:
   - Asset path and filename
   - Usage description
   - Line reference (file:line)
4. If replacing an existing asset, move old asset to `unused-assets.md`

**Removing an Asset from Use:**
1. Remove references from code/scenes
2. Move entry from `used-assets.md` to `unused-assets.md`
3. Add reason for removal in unused-assets.md
4. Recommendation: Keep or Delete

**Example - Adding a New Powerup:**
```
In used-assets.md:
| `freeze_time.png` | Freeze time power-up | power_up.gd:50 |

In power_up.gd:
# Add to texture dictionary
POWERUP_TEXTURES[PowerUpType.FREEZE_TIME] = preload("res://assets/graphics/powerups/freeze_time.png")
```

**Example - Removing an Asset:**
```
In unused-assets.md:
| `old_sprite.png` | assets/graphics/ | Removed - Replaced with new_sprite.png |
```

### Asset Documentation Checklist

Before committing changes involving assets:
- [ ] New assets added to `used-assets.md`
- [ ] Line references updated for code changes
- [ ] Removed assets moved to `unused-assets.md`
- [ ] Unused folder assets documented (if applicable)
- [ ] File paths are correct and relative to project root
- [ ] Usage descriptions are clear and accurate

---

## Commit Message Format

### Required Format

All commits must follow this format:

```
<type>: <short summary>

Major Features:
- Feature area
  - Subdetail
  - Subdetail

Quality of Life:
- Improvement
  - Subdetail

Level System:
- Content changes
  - Subdetail

Code Improvements:
- Technical changes
  - Subdetail

Documentation:
- Doc updates

Co-Authored-By: <Your Agent Name/Model> <email>
```

**Note:** Replace `<Your Agent Name/Model>` with your actual model/agent identifier (e.g., "Claude Sonnet 4.5", "GPT-4", "Gemini Pro", etc.)

For Codex commits in this repository, use:
`Co-Authored-By: Codex <codex@openai.com>`

### Commit Types

- `feat` - New feature
- `fix` - Bug fix
- `refactor` - Code restructuring
- `docs` - Documentation changes
- `chore` - Maintenance tasks

### Rules

- Omit sections that don't apply
- Keep headings for major changes
- Always include Co-Authored-By line
- Short summary should be clear and concise

### Example Commit

```
feat: Implement paddle vertical movement

Major Features:
- Paddle Movement System
  - Keyboard controls (W/S, arrows)
  - Mouse following (optional toggle)
  - Constrained to screen bounds (40-680 Y)
  - Velocity tracking for spin mechanics

Code Improvements:
- Added CharacterBody2D with collision shape
- Cached movement bounds for performance

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

**Note:** This example shows Claude Sonnet 4.5. Use your actual agent name/model when committing.

---

## Release Versioning (SemVer) and Git Tags

### Versioning Policy

- Public versioning uses **Semantic Versioning**: `MAJOR.MINOR.PATCH`.
- Current baseline version is **`0.5.0`**.
- The in-game public version is shown **only** on the main menu (`VersionLabel`).
- Do **not** auto-increment the version unless the user explicitly requests a bump.

### When a Version Bump Is Requested

Update all of the following in the same change:
1. Main menu version display source:
   - `scripts/ui/main_menu.gd` (`PUBLIC_VERSION`)
   - `scenes/ui/main_menu.tscn` (`VersionLabel.text`, fallback/default)
2. Documentation references:
   - `README.md` (player-facing version mention if present)
   - `.agent/CHANGELOG.md` (release entry)
   - Any `.agent` docs that reference the current public version

### Git Tag at Release Time

Yes, create a Git tag when the version is incremented.

Recommended commands:
```bash
git tag -a vX.Y.Z -m "Release vX.Y.Z"
git push origin vX.Y.Z
```

Tag format: `vMAJOR.MINOR.PATCH` (for example `v0.5.0`).

### Release Integrity (Minisign)

Use checksum signing for release integrity:
1. Generate `SHA256SUMS.txt` for release zips.
2. Sign `SHA256SUMS.txt` with Minisign.
3. Publish these files with release assets:
   - `*.zip`
   - `SHA256SUMS.txt`
   - `SHA256SUMS.txt.minisig`
   - `minisign.pub` (public verification key)

Script support:
- `scripts/export_release_bundle.sh` can sign automatically when these env vars are provided:
  - `MINISIGN_SECRET_KEY=/path/to/minisign.key`
  - `MINISIGN_PUBLIC_KEY=/path/to/minisign.pub` (optional but recommended for distribution)

Verification example for users:
```bash
minisign -Vm SHA256SUMS.txt -P "<public-key>"
sha256sum -c SHA256SUMS.txt
```

### One-Command GitHub Release Publish

After building/singing release assets, publish with:
```bash
scripts/publish_github_release.sh X.Y.Z
```

What it does:
- Creates/pushes tag `vX.Y.Z` (if missing)
- Creates GitHub Release (or updates existing release assets)
- Uploads:
  - `dist/releases/zepball.zip` (Windows build)
  - `dist/releases/zepball.x86_64.zip` (Linux x86_64 build)
  - `dist/releases/SHA256SUMS.txt` (archive checksums)
  - `dist/releases/SHA256SUMS.txt.minisig` (signature for checksum file)
  - `dist/releases/minisign.pub` (public key for checksum signature verification)

---

## Quick Pre-Commit Checklist

Before committing ANY changes:

### Save Data Changes?
- [ ] Added migration logic in `SaveManager.load_save()`
- [ ] Updated `create_default_save()`
- [ ] Tested with old save file
- [ ] Tested with fresh save file

### Asset Changes?
- [ ] Updated `System/used-assets.md` (if adding)
- [ ] Updated `System/unused-assets.md` (if removing)
- [ ] Asset paths are correct

### Commit Ready?
- [ ] Commit message follows format
- [ ] Includes Co-Authored-By line
- [ ] Type is correct (feat/fix/refactor/docs/chore)
- [ ] Sections only include relevant changes

### If This Is a Version Bump
- [ ] Version bump was explicitly requested by user
- [ ] `PUBLIC_VERSION` updated in `scripts/ui/main_menu.gd`
- [ ] `VersionLabel.text` updated in `scenes/ui/main_menu.tscn`
- [ ] Release docs/changelog updated
- [ ] Git tag planned/created using `vMAJOR.MINOR.PATCH`

---

## When in Doubt

- **Save changes?** → Add migration code. Better safe than sorry.
- **Asset changes?** → Update the docs. Takes 30 seconds.
- **Commit format?** → Copy the template above.
- **Still unsure?** → Ask the user.

---

**Last Updated:** 2026-02-15

**See also:**
- `SOP/godot-workflow.md` - General Godot development workflows
- `System/architecture.md` - Project architecture
- `README.md` - Project overview
