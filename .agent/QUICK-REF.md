# Quick Reference Guide

**Use this for fast lookups. For deep dives, see the full docs.**

---

## I need to...

| Task | Read This | Line Reference |
|------|-----------|----------------|
| Understand project overview | `README.md` | Full file |
| Add a new feature | `System/architecture.md` | Full file |
| Change save data structure | `SOP/critical-workflows.md` → Save System | - |
| Add/remove assets | `SOP/critical-workflows.md` → Asset Docs | - |
| Make a commit | `SOP/critical-workflows.md` → Commits | - |
| Find recent changes | `CHANGELOG.md` | Latest entries |
| Understand game architecture | `System/architecture.md` | Full file |
| Check tech stack/settings | `System/tech-stack.md` | Full file |
| See future plans | `Tasks/Backlog/future-features.md` | Full file |

---

## ⚠️ Critical Rules (NEVER SKIP)

### 1. **Save System Compatibility**
**When changing save data structure, ALWAYS add migration logic.**

```gdscript
// In SaveManager.load_save()
if not save_data.has("new_field"):
    save_data["new_field"] = default_value
    save_to_disk()
```

**See:** `SOP/critical-workflows.md` → "Save System Compatibility"

### 2. **Asset Documentation**
**When adding/removing assets, ALWAYS update asset docs.**

- Add assets → Update `System/used-assets.md`
- Remove assets → Move to `System/unused-assets.md`

**See:** `SOP/critical-workflows.md` → "Asset Documentation"

### 3. **Commit Message Format**
**All commits MUST follow this format:**

```
<type>: <short summary>

Major Features:
- Feature area
  - Subdetail

Co-Authored-By: <Your Agent Name/Model> <email>
```

**Examples:**
- `Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>`
- `Co-Authored-By: GPT-4 <noreply@openai.com>`
- `Co-Authored-By: Gemini Pro <noreply@google.com>`

**Types:** `feat`, `fix`, `refactor`, `docs`, `chore`

**See:** `SOP/critical-workflows.md` → "Commit Format"

---

## Common Scenarios

### Adding a New Power-Up
1. Add sprite to `assets/graphics/powerups/`
2. Update `System/used-assets.md`
3. Add logic to `scripts/power_up_manager.gd`
4. If adding save data → Add migration logic
5. Test with old save file
6. Commit with proper format

### Adding a New Setting
1. Add field to `SaveManager.create_default_save()`
2. Add migration in `SaveManager.load_save()`:
   ```gdscript
   if not save_data["settings"].has("new_setting"):
       save_data["settings"]["new_setting"] = default_value
       save_to_disk()
   ```
3. Wire UI in `scenes/ui/settings.tscn`
4. Test with existing save file
5. Update `System/architecture.md` settings list

### Creating a New Level
1. Use level editor (`EDITOR` from main menu)
2. Or add `.zeppack` to `packs/` folder
3. Follow pack schema (see `System/architecture.md` → Pack Format)

---

## Project Stats (Quick Facts)

- **Engine:** Godot 4.6
- **Main Scene:** `res://scenes/ui/main_menu.tscn`
- **Gameplay Scene:** `res://scenes/main/main.tscn`
- **Total Levels:** 30 (across 3 packs)
- **Autoloads:** 6 (PowerUpManager, DifficultyManager, SaveManager, AudioManager, PackLoader, MenuController)
- **Power-Ups:** 16 types
- **Brick Types:** 16 types
- **Achievements:** 12

---

## File Locations

```
zepball/
├── .agent/                    # Documentation
│   ├── AGENTS.md              # Start here (entry point)
│   ├── QUICK-REF.md           # This file
│   ├── README.md              # Project overview
│   ├── CHANGELOG.md           # Recent updates
│   ├── System/
│   │   ├── architecture.md    # Complete system docs ⭐
│   │   ├── tech-stack.md      # Settings/config
│   │   ├── used-assets.md     # Active assets
│   │   └── unused-assets.md   # Deprecated assets
│   ├── Tasks/
│   │   ├── Completed/         # Done features
│   │   └── Backlog/           # Future work
│   └── SOP/
│       └── critical-workflows.md  # MUST-FOLLOW procedures ⚠️
├── scenes/                    # All .tscn files
├── scripts/                   # All .gd files
├── packs/                     # Built-in .zeppack levels
└── assets/                    # Graphics, audio
```

---

## When in Doubt

1. **Search this file** for your scenario
2. **Check SOP/critical-workflows.md** for procedures
3. **Read System/architecture.md** for context
4. **Ask user** if requirements are unclear

---

**Last Updated:** 2026-02-15
