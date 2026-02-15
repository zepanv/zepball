# Agent Instructions

**Welcome! This is your entry point to the Zep Ball codebase.**

---

## 🚀 Quick Start (3-5 minutes)

**Read these files in order before starting work:**

1. **`QUICK-REF.md`** (1 min) - Fast lookup reference
   - Common scenarios with line references
   - Critical rules summary
   - Quick facts about the project

2. **`README.md`** (2 min) - Project overview
   - Current game state and features
   - Documentation structure
   - Tech stack and autoloads

3. **`System/architecture.md`** (5-10 min, can skim if experienced)
   - Complete system architecture
   - Scene graph and core systems
   - All implemented features

---

## ⚠️ BEFORE YOU CODE - Critical Checks

**When modifying code, ask yourself:**

- [ ] Am I changing save data structure? → See `SOP/critical-workflows.md` → Save System
- [ ] Am I adding/removing assets? → See `SOP/critical-workflows.md` → Asset Docs
- [ ] Am I ready to commit? → See `SOP/critical-workflows.md` → Commit Format

**If yes to any, read the relevant section BEFORE making changes.**

**Quick version:** `QUICK-REF.md` has abbreviated versions of these rules.

---

## 📚 Deep Dives (Reference as Needed)

Use these when you need detailed information:

| Task | Read This |
|------|-----------|
| Change save data? | `SOP/critical-workflows.md` → Save System Compatibility |
| Add/remove assets? | `SOP/critical-workflows.md` → Asset Documentation |
| Make a commit? | `SOP/critical-workflows.md` → Commit Format |
| Godot workflow help? | `SOP/godot-workflow.md` (general Godot reference) |
| Current features? | `README.md` → Current Game State |
| Recent changes? | `CHANGELOG.md` |
| Future plans? | `Tasks/Backlog/future-features.md` |
| Completed work? | `Tasks/Completed/` |

---

## 🎯 Documentation Maintenance

**You are responsible for keeping documentation up to date with your changes.**

### When to Update Documentation

Update docs immediately when you:

- ✅ **Add/remove/modify features** → Update `Tasks/`, `System/architecture.md`, and `README.md`
- ✅ **Add/remove assets** → Update `System/used-assets.md` and `System/unused-assets.md` (MANDATORY)
- ✅ **Change save data** → Update SOP and add migration code (MANDATORY)
- ✅ **Modify settings** → Update `System/tech-stack.md`
- ✅ **Complete tasks** → Move from `Tasks/Backlog/` to `Tasks/Completed/`
- ✅ **Add new systems** → Update `System/architecture.md`
- ✅ **Make major changes** → Update `CHANGELOG.md`

### Documentation Update Checklist

Before committing any changes:

- [ ] Read relevant docs to understand current state
- [ ] Made changes to code/scenes
- [ ] Updated documentation to reflect changes:
  - [ ] `README.md` - If major features added
  - [ ] `CHANGELOG.md` - If user-facing changes
  - [ ] `System/architecture.md` - If systems changed
  - [ ] `System/used-assets.md` - If assets added
  - [ ] `System/unused-assets.md` - If assets removed
  - [ ] `Tasks/` - Move completed items to Completed/
- [ ] Updated "Last Updated" dates in docs
- [ ] Followed commit format from `SOP/critical-workflows.md`

---

## ⚡ Workflow Summary

```
1. READ QUICK-REF.md (fast lookups)
2. READ README.md (project overview)
3. SKIM System/architecture.md (system context)
4. CHECK critical workflows (if changing save/assets/commits)
5. IMPLEMENT changes
6. UPDATE documentation (keep in sync)
7. TEST thoroughly
8. COMMIT with proper format
```

---

## ❓ Finding Information

**Architecture & Systems:**
- See `System/architecture.md`

**Workflows & Procedures:**
- See `SOP/critical-workflows.md` (mandatory)
- See `SOP/godot-workflow.md` (general reference)

**Current State:**
- See `README.md` → Current Game State
- See `CHANGELOG.md` → Recent updates

**Future Plans:**
- See `Tasks/Backlog/`

**Completed Work:**
- See `Tasks/Completed/`

**Quick Lookups:**
- See `QUICK-REF.md`

---

## 🔥 The Three Non-Negotiables

### 1. Save System Migration
**When changing save data structure, ALWAYS add migration logic.**

Bad: Adding a new save field without migration → Users crash
Good: Add field with migration check → Old saves work

**See:** `SOP/critical-workflows.md` → Save System Compatibility

### 2. Asset Documentation
**When adding/removing assets, ALWAYS update asset docs.**

Bad: Add powerup sprite, skip docs → Docs become inaccurate
Good: Add sprite + update `used-assets.md` → Docs stay current

**See:** `SOP/critical-workflows.md` → Asset Documentation

### 3. Commit Format
**All commits MUST follow the required format.**

Bad: `git commit -m "fixed stuff"` → Inconsistent history
Good: Follow template with Co-Authored-By → Clean history

**See:** `SOP/critical-workflows.md` → Commit Format

---

## 📂 Documentation File Structure

```
.agent/
├── AGENTS.md              ← YOU ARE HERE (start point)
├── QUICK-REF.md           ← Fast lookups (read first!)
├── README.md              ← Project overview (read second)
├── CHANGELOG.md           ← Recent updates
├── System/
│   ├── architecture.md    ← Complete system docs (read third)
│   ├── tech-stack.md      ← Settings/config
│   ├── used-assets.md     ← Active assets (keep updated!)
│   └── unused-assets.md   ← Deprecated assets
├── Tasks/
│   ├── Completed/         ← Done features
│   └── Backlog/           ← Future work
└── SOP/
    ├── critical-workflows.md  ← MANDATORY procedures ⚠️
    └── godot-workflow.md      ← General Godot reference
```

---

## 🎮 Project Quick Facts

- **Engine:** Godot 4.6
- **Language:** GDScript
- **Main Scene:** `res://scenes/ui/main_menu.tscn`
- **Gameplay:** 30 levels across 3 packs
- **Power-Ups:** 16 types
- **Achievements:** 12 total
- **Autoloads:** 6 (PowerUpManager, DifficultyManager, SaveManager, AudioManager, PackLoader, MenuController)

---

**Last Updated:** 2026-02-15

**Remember:** When in doubt, check `QUICK-REF.md` first, then dive into specific docs as needed.
