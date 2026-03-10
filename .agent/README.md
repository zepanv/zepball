# ZepBall Agent Docs Index

This folder contains implementation-facing docs for contributors and agents.

## Progressive Disclosure Read Path
1. `AGENTS.md` - Entry rules and non-negotiables
2. `QUICK-REF.md` - Fast task-to-doc routing
3. Canonical docs for the active change
4. Deep/historical docs only when needed

## Canonical Sources (Layer 2)
| Topic | Canonical Doc |
|------|------|
| Runtime architecture and behavior | `System/architecture.md` |
| Runtime subsystem internals (deep reference) | `System/architecture-details.md` |
| Engine/config/input/autoload facts | `System/tech-stack.md` |
| Required procedures (save/assets/commit/release) | `SOP/critical-workflows.md` |
| Asset usage inventory | `System/used-assets.md`, `System/unused-assets.md` |

## Deep/Historical References (Layer 3)
| Doc | Purpose |
|------|------|
| `SOP/godot-workflow.md` | Supplemental Godot workflow notes (non-canonical) |
| `Tasks/Backlog/` | Planned work |
| `Tasks/Completed/INDEX.md` | Entry point for completed work history (active + archive) |

## Boundary Rules
- `../README.md` is player-facing.
- `.agent/*` is implementation-facing.
- Do not duplicate implementation internals in `../README.md`.
- Do not duplicate player-facing controls/licensing content in `.agent/*`.

## Maintenance Rules
- Update canonical docs when behavior/process changes.
- Keep index docs concise; prefer links over repeated instructions.
- Remove stale path/version claims when no longer true.
- Prefer documenting non-obvious contracts over easily discoverable file inventories.
- Run docs lint after `.agent` doc edits: `scripts/check_agent_docs.sh`

**Last Updated:** 2026-03-10
