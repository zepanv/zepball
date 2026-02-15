# Agent Instructions

Use this file as the entry point for implementation work in Zep Ball.

## Start Here
1. Read `.agent/README.md` for documentation boundaries and source-of-truth rules.
2. Read `.agent/QUICK-REF.md` for task routing.
3. Read `.agent/System/architecture.md` before changing runtime behavior.

## Three Non-Negotiables
1. Save data changes require migration logic.
2. Asset adds/removals require asset doc updates.
3. Commits must follow the required commit format.

Details for all three are canonical in `.agent/SOP/critical-workflows.md`.

## Before You Code
- Changing save structure: read `.agent/SOP/critical-workflows.md` (Save System Compatibility)
- Adding/removing assets: read `.agent/SOP/critical-workflows.md` (Asset Documentation)
- Preparing a commit: read `.agent/SOP/critical-workflows.md` (Commit Message Format)
- Bumping public version: read `.agent/SOP/critical-workflows.md` (SemVer + Git tags; no auto-bumps)

## Documentation Responsibilities
Update docs with code changes, but avoid duplicate content:
- Runtime behavior: update `.agent/System/architecture.md`
- Project settings/config/input/autoloads: update `.agent/System/tech-stack.md`
- User-visible release notes: update `.agent/CHANGELOG.md`
- Asset usage: update `.agent/System/used-assets.md` and `.agent/System/unused-assets.md`
- Task lifecycle: move items between `.agent/Tasks/Backlog/` and `.agent/Tasks/Completed/`

## Where To Look
- Quick operational lookup: `.agent/QUICK-REF.md`
- Mandatory procedures: `.agent/SOP/critical-workflows.md`
- Extended Godot reference: `.agent/SOP/godot-workflow.md`
- Runtime architecture: `.agent/System/architecture.md`
- Historical changes: `.agent/CHANGELOG.md`
- Future planning: `.agent/Tasks/Backlog/future-features.md`

**Last Updated:** 2026-02-15
