# Quick Reference

Use this for fast task routing. Keep detail in canonical docs.

## I Need To...
| Task | Read |
|------|------|
| Understand doc boundaries | `.agent/README.md` |
| Understand runtime behavior | `.agent/System/architecture.md` |
| Check engine/config/input/autoloads | `.agent/System/tech-stack.md` |
| Change save data safely | `.agent/SOP/critical-workflows.md` |
| Add/remove assets correctly | `.agent/SOP/critical-workflows.md` |
| Prepare a commit | `.agent/SOP/critical-workflows.md` |
| Bump public version / release tag | `.agent/SOP/critical-workflows.md` |
| Find historical changes | `.agent/CHANGELOG.md` |
| See future plans | `.agent/Tasks/Backlog/future-features.md` |

## Non-Negotiables
1. Save schema changes require migration logic.
2. Asset changes require updates to asset documentation.
3. Commit messages must follow the project format.

Canonical source: `.agent/SOP/critical-workflows.md`.

## Common Change Paths
- New gameplay/system behavior:
  - Code + `.agent/System/architecture.md`
- New/changed settings, input, autoloads:
  - Code + `.agent/System/tech-stack.md`
- User-visible release impact:
  - Code + `.agent/CHANGELOG.md`
- Asset add/remove:
  - Code + `.agent/System/used-assets.md` + `.agent/System/unused-assets.md`

## Guardrails
- Prefer links over copied detail in index/reference docs.
- Avoid duplicating volatile counts across multiple files.
- Treat old `data/level_sets.json` and `levels/level_XX.json` runtime references as stale.

**Last Updated:** 2026-02-15
