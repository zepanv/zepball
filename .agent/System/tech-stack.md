# ZepBall - Tech Stack and Runtime Config Notes

Use this document for non-obvious config conventions.
For raw config inventories, read `project.godot` directly.

## Stack
- Engine: Godot 4.6
- Language: GDScript
- Version control: Git

## Config Sources of Truth
- Project/runtime configuration: `project.godot`
- Export configuration: `export_presets.cfg`
- Public version label source: `scripts/ui/main_menu.gd` (`PUBLIC_VERSION`)

## Non-Obvious Conventions
- Public version is shown on main menu only; update both script constant and fallback label text in scene when bumping version.
- Runtime content format is `.zeppack` from built-in `packs/` and user `user://packs/`.
- Keybinding persistence is save-backed; `ui_cancel` remains effectively reserved/non-remappable behavior for menu/back flow.
- Audio buses (`Music`, `SFX`) are created/validated at runtime by `AudioManager` if missing.

## When To Update This Doc
Update only when project-level conventions change (not when single values like window size or key mapping change).

## Related Docs
- `System/architecture.md`
- `System/architecture-details.md`
- `SOP/critical-workflows.md`
- `SOP/godot-workflow.md`

**Last Updated:** 2026-02-24
