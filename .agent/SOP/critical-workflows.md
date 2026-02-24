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

## 4) Version Bump + Release Tag (On Request Only)

Public versioning uses SemVer: `MAJOR.MINOR.PATCH`.

When a version bump is explicitly requested, update in the same change:
1. `scripts/ui/main_menu.gd` (`PUBLIC_VERSION`)
2. `scenes/ui/main_menu.tscn` (`VersionLabel.text` fallback)
3. `.agent/CHANGELOG.md` release entry
4. Any other docs that mention the old current version

Then tag release:
```bash
git tag -a vX.Y.Z -m "Release vX.Y.Z"
git push origin vX.Y.Z
```

If publishing GitHub release assets, use:
```bash
scripts/publish_github_release.sh X.Y.Z
```

## Quick Pre-Commit Gate
- [ ] Save schema touched? Migration and default-save updates added.
- [ ] Asset usage touched? Used/unused asset docs updated.
- [ ] `.agent` docs touched? Run `scripts/check_agent_docs.sh`.
- [ ] Commit message matches required format and includes co-author.
- [ ] Version changed only if explicitly requested.

**Last Updated:** 2026-02-24

**Related Docs:**
- `.agent/System/architecture.md`
- `.agent/System/tech-stack.md`
- `.agent/SOP/godot-workflow.md`
