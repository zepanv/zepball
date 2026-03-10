# Agent Instructions

Use this file as the entry point for implementation work in ZepBall.

## Progressive Disclosure
Start with the shallowest layer that answers the task, then go deeper only when needed.

| Layer | Goal | Read |
|------|------|------|
| Layer 0 (mandatory) | Entry rules and guardrails | `.agent/AGENTS.md` |
| Layer 1 (routing) | Find the right canonical doc quickly | `.agent/README.md`, `.agent/QUICK-REF.md` |
| Layer 2 (canonical) | Source of truth for behavior/procedures | `.agent/System/architecture.md`, `.agent/System/tech-stack.md`, `.agent/SOP/critical-workflows.md` |
| Layer 3 (deep/historical) | Long-form background and change history | `.agent/System/architecture-details.md`, `.agent/SOP/godot-workflow.md`, `.agent/Tasks/Completed/INDEX.md` |

## Non-Negotiables
1. Save data structure changes require migration logic.
2. Asset usage changes require asset documentation updates.
3. Commits must follow the required project format.

Canonical source for all three: `.agent/SOP/critical-workflows.md`.

## Task Routing
- Runtime/gameplay behavior changes: `.agent/System/architecture.md`
- Engine settings/input/autoload changes: `.agent/System/tech-stack.md`
- Save, asset, commit, release workflow: `.agent/SOP/critical-workflows.md`
- Day-to-day Godot workflow help: `.agent/SOP/godot-workflow.md`

## Documentation Update Rules
Update canonical docs when behavior changes. Avoid repeating the same detail in index docs.

- Runtime behavior: `.agent/System/architecture.md`
- Config/input/autoload/project settings: `.agent/System/tech-stack.md`
- Save/asset/release procedure changes: `.agent/SOP/critical-workflows.md`
- Asset inventory: `.agent/System/used-assets.md` and `.agent/System/unused-assets.md`
- Task lifecycle: `.agent/Tasks/Backlog/` and `.agent/Tasks/Completed/`
- User-visible release notes/history: git history and release notes drafts during release prep

## Pre-Commit Doc Gate
- Run `.agent` docs lint after doc updates:
  - `scripts/check_agent_docs.sh`

## Anti-Bloat Rules
- Keep one canonical source per topic.
- Keep index docs short and link-heavy.
- Remove stale references instead of documenting legacy behavior in multiple places.
- Do not document facts that are trivial to discover from code, scenes, or `project.godot` unless they are part of a fragile contract.

**Last Updated:** 2026-03-10
