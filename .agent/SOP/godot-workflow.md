# Godot Workflow (Supplemental)

This document is supplemental guidance for day-to-day Godot work.

Canonical project procedures are in `.agent/SOP/critical-workflows.md`.
Do not use this file as the source of truth for save migrations, asset doc requirements, commit format, or release/version policy.

## Scope
Use this doc for:
- Practical editor/runtime workflow reminders.
- Project-specific implementation conventions.
- Debugging and export workflow references.

## Daily Workflow
1. Open project and confirm active task context (`.agent/Tasks/Backlog/*` when relevant).
2. Read only the needed canonical docs for the change.
3. Implement in small increments and run focused tests.
4. Update canonical docs only when behavior/procedure facts change.
5. If `.agent` docs changed, run `scripts/check_agent_docs.sh`.

## Scene and Script Conventions
- Keep one clear purpose per scene/script pair.
- Prefer signals for gameplay events and direct calls for explicit commands.
- Avoid deep `get_tree()` scans in hot gameplay paths; cache references.
- Use descriptive node names (avoid defaults like `Node2D` or `Sprite2D`).

## Input and Settings
- Input actions are defined in `project.godot`.
- Remappable bindings persist through `SaveManager`.
- Settings that affect runtime behavior should be reflected in:
  - `scripts/save_manager.gd` (persistence)
  - the consuming runtime system (`paddle.gd`, `ball.gd`, HUD/settings scripts, etc.)

## Assets Workflow (Implementation Side)
- Graphics assets live under `assets/graphics/`.
- Audio assets live under `assets/audio/music/` and `assets/audio/sfx/`.
- After wiring assets in scene/script code, update asset docs per critical workflow.

## Debugging Workflow
1. Reproduce with the smallest deterministic case.
2. Check Godot Output and debugger stack traces.
3. Add scoped logging around the failing path.
4. Verify root cause before implementing fixes.
5. Re-test adjacent systems for regressions.

## Headless and CLI Helpers
From project root:

```bash
# Load project config and exit (basic sanity check).
# Use a temporary HOME so Godot user:// paths (logs/config) do not crash in restricted environments.
mkdir -p /tmp/zepball-godot-home
HOME=/tmp/zepball-godot-home godot --headless --path . --quit

# Export configured release presets and build release zips
./scripts/export_release_bundle.sh
```

If `godot` is not on PATH, run:

```bash
mkdir -p /tmp/zepball-godot-home
HOME=/tmp/zepball-godot-home GODOT_BIN=/path/to/godot4 "$GODOT_BIN" --headless --path . --quit
```

Use `GODOT_BIN=/path/to/godot4` (or `godot4`) for scripts that support binary override.

## Export Notes
- Export presets are configured in `export_presets.cfg`.
- Include non-resource pack files in export filters when needed (`packs/*.zeppack`).
- Validate artifacts in `dist/releases/` after running export scripts.

## External References
- Godot docs: https://docs.godotengine.org/en/stable/
- Godot community Q&A: https://ask.godotengine.org/

**Last Updated:** 2026-02-24
