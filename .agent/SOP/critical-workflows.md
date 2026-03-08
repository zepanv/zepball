# Critical Workflows - ZepBall

This is the canonical procedures doc for save migrations, asset docs, commits, and release/version bumps.

## Non-Negotiables
1. Save schema changes require migration logic.
2. Asset usage changes require asset documentation updates.
3. Commits must follow the required commit format.
4. Version bumps happen only when explicitly requested.

## 1) Save System Compatibility (Required)

### When Migration Logic Is Required
Add migration handling in `scripts/save_manager.gd` whenever you:
- Add, rename, remove, or restructure save keys.
- Add new settings, statistics, or progression fields.
- Change a stored type (for example `String` -> `int`).

### Required Pattern
- Update default save shape in `create_default_save()`.
- Add compatibility handling in `load_save()`.
- Persist migrated data with `save_to_disk()`.

```gdscript
# In load_save(), after loading existing data
if not save_data.has("new_section"):
	save_data["new_section"] = {
		"new_field": 0
	}
	save_to_disk()
```

### Validation Checklist
- [ ] Existing saves load without crash.
- [ ] Existing progression/settings are preserved.
- [ ] Fresh saves include the new schema.
- [ ] Migration is idempotent (safe if load runs again).

## 2) Asset Documentation Sync (Required)

### When Updates Are Required
Update docs whenever assets are added, removed, or usage changes.

### Files To Update
- Active assets: `.agent/System/used-assets.md`
- Unused/deprecated assets: `.agent/System/unused-assets.md`

### Required Steps
- Add new actively used assets to `used-assets.md` with path and usage reference.
- Move removed/replaced assets to `unused-assets.md` with reason.
- Keep paths accurate (`res://assets/...` and project-relative references in docs).

### Validation Checklist
- [ ] Every new referenced asset is documented as used.
- [ ] Every no-longer-used asset is documented as unused.
- [ ] Paths and file names match repository reality.

## 3) Commit Message Format (Required)

Use this structure and include Codex as co-author.

```text
<type>: <short summary>

Major Features:
- Feature area
  - Subdetail

Minor Features:
- Improvement
  - Subdetail

Code Improvements:
- Technical changes
  - Subdetail

Documentation:
- Doc updates

Co-Authored-By: Codex <codex@openai.com>
```

Rules:
- Valid `<type>`: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`.
- Include only relevant sections; omit empty sections.
- Keep summary short and specific.

## 4) Version Bump + Release (On Request Only)

Public versioning uses SemVer: `MAJOR.MINOR.PATCH`.

Follow these steps **in order**. Do not skip ahead — build and publish only after all code/doc changes are committed and approved.

### Step 1 — Pre-Release Gate
- [ ] All feature/fix branches merged to `main`.
- [ ] Working tree is clean (`git status` shows nothing uncommitted).
- [ ] Game runs and no regressions observed.

### Step 2 — Draft Release Notes (Requires Approval Before Continuing)
Create `temp/release-vX.Y.Z-notes.md` using this format:

```markdown
## ZepBall vX.Y.Z

One-line summary of the release theme.

## vX.Y.Z Highlights
- **Feature or fix** — brief description.
- ...

## Release Assets
- `zepball.zip` (Windows x86_64)
- `zepball.x86_64.zip` (Linux x86_64)
- `SHA256SUMS.txt`
- `SHA256SUMS.txt.minisig`
- `minisign.pub`

## Verify Downloads
\`\`\`bash
minisign -Vm SHA256SUMS.txt -p minisign.pub
sha256sum -c SHA256SUMS.txt
\`\`\`
```

**Stop here and get the release notes approved before continuing.**

### Step 3 — Version Bump
Update the version string in all of these locations in the same commit:
1. `scripts/ui/main_menu.gd` — `PUBLIC_VERSION` constant
2. `scenes/ui/main_menu.tscn` — `VersionLabel.text` fallback string
3. `README.md` — "Current version:" line and "Current Features:" date
4. `.agent/CHANGELOG.md` — add a new dated entry at the top

Commit message format:
```
chore: prepare vX.Y.Z release metadata
```

### Step 4 — Build Release Bundles
Run the export script (requires Godot in PATH and Minisign keys for signing):

```bash
# Unsigned build (CI/testing):
scripts/export_release_bundle.sh

# Signed build (required for publishing):
MINISIGN_SECRET_KEY=/path/to/minisign.key \
MINISIGN_PUBLIC_KEY=/path/to/minisign.pub \
scripts/export_release_bundle.sh
```

This produces in `dist/releases/`:
- `zepball.zip` (Windows)
- `zepball.x86_64.zip` (Linux)
- `SHA256SUMS.txt`
- `SHA256SUMS.txt.minisig` (if signed)
- `minisign.pub` (if signed)

Note: `README.md` and `LICENSE` are automatically copied into each platform's staging folder by the script — no manual copy needed.

Verify the zips open correctly and the game launches before continuing.

### Step 5 — Tag and Publish
```bash
scripts/publish_github_release.sh X.Y.Z --notes-file temp/release-vX.Y.Z-notes.md
```

This script will:
1. Create and push the `vX.Y.Z` git tag
2. Create the GitHub release with the approved notes
3. Upload all assets from `dist/releases/`

### Step 6 — Post-Release Cleanup
- [ ] Confirm the GitHub release page looks correct (assets, notes, tag).
- [ ] Delete or archive `temp/release-vX.Y.Z-notes.md` (already published).

## Quick Pre-Commit Gate
- [ ] Save schema touched? Migration and default-save updates added.
- [ ] Asset usage touched? Used/unused asset docs updated.
- [ ] `.agent` docs touched? Run `scripts/check_agent_docs.sh`.
- [ ] Commit message matches required format and includes co-author.
- [ ] Version changed only if explicitly requested.

**Last Updated:** 2026-03-08

**Related Docs:**
- `.agent/System/architecture.md`
- `.agent/System/tech-stack.md`
- `.agent/SOP/godot-workflow.md`
