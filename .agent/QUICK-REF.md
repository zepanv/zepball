# Quick Reference

Use this file for routing only. Canonical details live in Layer 2 docs.

## If You Need To...
| Task | Read |
|------|------|
| Understand runtime behavior | `.agent/System/architecture.md` |
| Deep-dive subsystem internals | `.agent/System/architecture-details.md` |
| Check project settings/input/autoloads | `.agent/System/tech-stack.md` |
| Change save structure safely | `.agent/SOP/critical-workflows.md` |
| Add/remove assets correctly | `.agent/SOP/critical-workflows.md` |
| Prepare commit or release/version bump | `.agent/SOP/critical-workflows.md` |
| Review user-facing change history | `.agent/CHANGELOG.md` |
| Find planned work | `.agent/Tasks/Backlog/future-features.md` |
| Find completed work history | `.agent/Tasks/Completed/INDEX.md` |

## Fast Change Impact Map
- Gameplay behavior changes:
  - Update code + `.agent/System/architecture.md`
- Settings/input/autoload changes:
  - Update code + `.agent/System/tech-stack.md`
- Save schema or asset usage changes:
  - Update code + `.agent/SOP/critical-workflows.md` and relevant asset docs
- User-visible release change:
  - Update `.agent/CHANGELOG.md`

## Guardrails
1. Keep one source of truth per topic.
2. Prefer links in index docs over copied detail.
3. Remove stale legacy references when found.
4. Run `scripts/check_agent_docs.sh` after `.agent` doc edits.

**Last Updated:** 2026-02-24
