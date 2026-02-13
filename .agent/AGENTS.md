# Agent Instructions

## Required Reading

**Before starting any work on this project, you MUST read the following files in order:**

1. **`.agent/README.md`** - Start here. This is the documentation index and provides:
   - Complete overview of the documentation structure
   - Current game state and feature status
   - Critical warnings and important notes
   - Quick start guide for new developers
   - Recent update history

2. **`SOP/godot-workflow.md`** - After README, read this SOP document which contains:
   - **MANDATORY development workflows**
   - Save System Compatibility requirements (CRITICAL)
   - Asset Documentation requirements (CRITICAL)
   - Commit message format requirements
   - Testing checklists
   - Godot-specific best practices

3. **`System/architecture.md`** - Read for full system context:
   - Complete project architecture
   - Autoload systems
   - Core gameplay systems
   - Scene graph
   - All implemented features

## Documentation Maintenance

**You are responsible for keeping documentation up to date with your changes.**

### When to Update Documentation

Update documentation immediately when you:

- ✅ **Add/remove/modify features** → Update `Tasks/`, `System/architecture.md`, and this README
- ✅ **Add/remove assets** → Update `System/used-assets.md` and `System/unused-assets.md`
- ✅ **Change save data structure** → Update SOP migration section and add migration code
- ✅ **Modify settings** → Update `System/tech-stack.md`
- ✅ **Complete implementation** → Move task from `Tasks/Backlog/` to `Tasks/Completed/`
- ✅ **Change tech stack or configuration** → Update `System/tech-stack.md`
- ✅ **Add new systems** → Update `System/architecture.md`

### Documentation Update Checklist

Before committing any changes:

- [ ] Read `.agent/README.md` to understand current state
- [ ] Read relevant SOP sections if applicable
- [ ] Made changes to code/scenes
- [ ] Updated documentation to reflect changes:
  - [ ] `README.md` - Update Current Game State section
  - [ ] `System/architecture.md` - Update architecture details if systems changed
  - [ ] `System/used-assets.md` - If new assets added
  - [ ] `System/unused-assets.md` - If assets removed from use
  - [ ] `Tasks/` - Move completed items to Completed/, update Backlog/
- [ ] Updated "Last Updated" dates in documentation files
- [ ] Followed commit message format from SOP

## Critical Reminders

### ⚠️ Save System Compatibility
**ALWAYS** add migration logic when modifying save data structure. See `SOP/godot-workflow.md` → "Save System Compatibility" section.

### ⚠️ Asset Documentation
**ALWAYS** update asset docs when adding/removing assets. See `SOP/godot-workflow.md` → "Asset Documentation Requirements" section.

### ⚠️ Follow the SOP
The Standard Operating Procedures in `SOP/godot-workflow.md` are **mandatory**. They exist to prevent bugs, ensure consistency, and maintain documentation accuracy.

## Workflow Summary

```
1. READ .agent/README.md (always start here)
2. READ SOP/godot-workflow.md (follow all procedures)
3. READ System/architecture.md (understand the system)
4. IMPLEMENT changes
5. UPDATE documentation (keep in sync with changes)
6. TEST thoroughly
7. COMMIT with proper format
```

## Questions?

- **Architecture**: See `System/architecture.md`
- **Workflows**: See `SOP/godot-workflow.md`
- **Current State**: See `.agent/README.md`
- **Future Plans**: See `Tasks/Backlog/`

---

*This file ensures all agents working on this project follow consistent procedures and maintain accurate documentation.*

**Last Updated**: 2026-02-13
