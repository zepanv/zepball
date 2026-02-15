# Zep Ball Agent Docs Index

This folder is for internal agent/developer documentation only.

## Read Order
1. `AGENTS.md` - Entry point and required behavior for agents
2. `QUICK-REF.md` - Fast lookup for common tasks
3. `SOP/critical-workflows.md` - Mandatory procedures (save migrations, asset docs, commits)
4. `System/architecture.md` - Source of truth for runtime systems and behavior

## Documentation Map
| Path | Purpose | Update When |
|------|---------|-------------|
| `AGENTS.md` | Agent onboarding and execution rules | Agent workflow expectations change |
| `QUICK-REF.md` | Short operational lookup | Frequently needed task routing changes |
| `SOP/critical-workflows.md` | Mandatory project procedures | Save, asset, or commit process changes |
| `SOP/godot-workflow.md` | Extended Godot guidance | General workflow guidance changes |
| `System/architecture.md` | Runtime architecture and system behavior | Systems, flows, or game behavior changes |
| `System/tech-stack.md` | Engine/config/input/autoload facts | Project settings or runtime config changes |
| `System/used-assets.md` | Assets currently in use | Assets are added or references move |
| `System/unused-assets.md` | Assets not currently used | Assets are retired/replaced |
| `Tasks/Completed/` | Implemented feature records | Backlog items are completed |
| `Tasks/Backlog/` | Planned future work | New ideas or priorities are added |
| `CHANGELOG.md` | Chronological changes | User-visible releases/changes occur |

## Boundary: Agent Docs vs User README
- `../README.md` is player-facing only.
- `.agent/*` is implementation-facing only.
- Do not duplicate technical internals in `../README.md`.
- Do not duplicate player-facing controls/licensing content in `.agent/*`.

## Anti-Duplication Rules
- Keep one source of truth per topic:
  - Runtime behavior: `System/architecture.md`
  - Process/procedures: `SOP/critical-workflows.md`
  - Chronological history: `CHANGELOG.md`
- In index files (`AGENTS.md`, `README.md`, `QUICK-REF.md`), prefer links over copied detail.
- Avoid repeating volatile counts (packs/levels/autoload count) in multiple files.

## Maintenance Checklist
Before committing a feature:
- Update code
- Update canonical docs only
- Update index/reference docs only if routing changed
- Verify stale paths were not reintroduced (for example old `data/level_sets.json`)
- If version bump was requested: update main menu SemVer display + release docs together, then tag (`vMAJOR.MINOR.PATCH`)

**Last Updated:** 2026-02-15
