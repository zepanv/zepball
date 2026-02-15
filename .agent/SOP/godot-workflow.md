# Godot Workflow - Standard Operating Procedures

**⚠️ CRITICAL PROJECT-SPECIFIC PROCEDURES ARE AT THE BOTTOM OF THIS FILE**

Jump to: [Save System Compatibility](#save-system-compatibility) | [Asset Documentation](#asset-documentation-requirements) | [Commit Format](#commit-message-format)

**For quick reference, see:** `SOP/critical-workflows.md`

---

# PART 1: GENERAL GODOT REFERENCE

*This section contains general Godot development guidance. For project-specific mandatory procedures, scroll to Part 2.*

---

## Daily Development Workflow

### Starting a Coding Session
1. Open Godot Editor (double-click project.godot or launch from Godot)
2. Pull latest changes if using remote repo: `git pull`
3. Check current task: `cat .agent/Tasks/Backlog/[current-feature].md`
4. Review last commit: `git log -1`

### During Development
1. Make small, incremental changes
2. Test frequently (F5 to run project, F6 to run current scene)
3. Use debugger breakpoints when needed
4. Commit working changes before major refactors

### Ending a Session
1. Test current state
2. Commit work in progress if functional
3. Update task documentation if needed
4. Push to remote if applicable

## Working with Scenes

### Creating a New Scene

**Via Editor:**
1. Scene → New Scene
2. Choose root node type:
   - Node2D for gameplay objects
   - Control for UI elements
   - Node for logic-only (e.g., managers)
3. Build node hierarchy
4. Save to appropriate folder (scenes/gameplay/, scenes/ui/, etc.)
5. Name with snake_case: `player_paddle.tscn`

**Via Script (Dynamic Instantiation):**
```gdscript
# Load scene
var brick_scene = preload("res://scenes/gameplay/brick.tscn")

# Instantiate
var brick_instance = brick_scene.instantiate()

# Configure
brick_instance.position = Vector2(100, 100)

# Add to tree
add_child(brick_instance)
```

### Scene Best Practices
- One clear purpose per scene (paddle, ball, brick)
- Reusable scenes should be self-contained
- Use signals to communicate outward, not get_parent()
- Save frequently (Ctrl+S / Cmd+S)

## Working with Nodes

### Adding Nodes
1. Click "+" icon or right-click scene tree → Add Child Node
2. Search for node type (CharacterBody2D, Sprite2D, etc.)
3. Rename node immediately (right-click → Rename)
4. Configure properties in Inspector panel

### Common Node Types

**Physics:**
- CharacterBody2D: Player-controlled objects (paddle, ball with move_and_collide)
- RigidBody2D: Physics-simulated objects (alternative for ball)
- StaticBody2D: Non-moving collision objects (walls, bricks)
- Area2D: Detection zones (power-up pickup)

**Visuals:**
- Sprite2D: Display textures/images
- ColorRect: Colored rectangles (placeholders)
- AnimatedSprite2D: Frame-based animations

**UI:**
- Control: Base UI node
- Label: Text display
- Button: Clickable buttons
- Panel: UI container with background

**Effects:**
- GPUParticles2D: Particle effects (brick breaks)
- CPUParticles2D: Simpler particles (trails)
- AudioStreamPlayer: Sound effects

**Organization:**
- Node: Generic container
- Node2D: 2D container with transform
- CanvasLayer: UI layer (always on top)

### Node Properties to Configure

**Transform (Node2D):**
- Position: (x, y) in pixels
- Rotation: Degrees (usually 0 for this game)
- Scale: (1, 1) is normal size

**Collision Shapes:**
- Shape: RectangleShape2D or CircleShape2D
- Size: Match visual sprite
- Debug: Collision Shapes → Visible (in editor)

## Working with Scripts

### Attaching Scripts to Nodes

**Method 1: Create and Attach**
1. Select node in scene tree
2. Click script icon or right-click → Attach Script
3. Choose script path: `res://scripts/paddle.gd`
4. Template: Node (default)
5. Click Create

**Method 2: Attach Existing**
1. Drag script from FileSystem to node in Scene tree
2. Script icon appears next to node name

### Script Template
```gdscript
extends CharacterBody2D  # Or appropriate node type

# Constants (UPPER_CASE)
const SPEED = 400

# Exported variables (appear in Inspector)
@export var max_health: int = 100

# Regular variables
var current_velocity: Vector2 = Vector2.ZERO

# Signals
signal health_changed(new_health)

# Called when node enters scene tree
func _ready():
    print("Node ready: ", name)

# Called every frame (delta = time since last frame)
func _process(delta):
    pass

# Called every physics frame (60 FPS by default)
func _physics_process(delta):
    pass

# Custom functions
func take_damage(amount: int):
    max_health -= amount
    health_changed.emit(max_health)
```

### Script Best Practices
- One script per scene (paddle.gd for paddle.tscn)
- Use `class_name` for scripts you'll reference elsewhere
- Constants at top, then exports, then variables
- Group related functions together
- Comment complex logic only (code should be self-documenting)

## Working with Signals

### Defining Signals
```gdscript
# In ball.gd
signal ball_lost
signal brick_hit(brick_node)
```

### Emitting Signals
```gdscript
# When event happens
ball_lost.emit()
brick_hit.emit(brick_reference)
```

### Connecting Signals

**Method 1: Code (in _ready())**
```gdscript
# In main.gd or game_manager.gd
func _ready():
    var ball = $Ball
    ball.ball_lost.connect(_on_ball_lost)

func _on_ball_lost():
    print("Ball was lost!")
```

**Method 2: Editor**
1. Select node with signal (e.g., Ball)
2. Go to Node panel (next to Inspector)
3. Signals tab
4. Double-click signal name
5. Select receiving node
6. Choose or create receiver function
7. Connect

**Recommended:** Use code for dynamic connections, editor for static.

### Signal Naming Convention
- Past tense: `ball_lost`, `brick_broken`
- Or noun: `collision_detected`
- Descriptive: `level_complete` not just `complete`

## Working with Input

### Input Map (Already Configured)

**Gameplay Actions:**
- move_up: Up Arrow, W, D-Pad Up, Left Stick Up
- move_down: Down Arrow, S, D-Pad Down, Left Stick Down
- launch_ball: Space, Left Mouse, A Button (Gamepad)
- restart_game: R, Y Button (Gamepad)

**UI Navigation:**
- ui_accept: Enter, Space, A Button (Gamepad)
- ui_cancel: Escape, B Button (Gamepad)
- ui_up/down/left/right: Arrow Keys, D-Pad, Left Stick

**Audio Controls:**
- audio_volume_down: -, L3 (Gamepad)
- audio_volume_up: =, R3 (Gamepad)
- audio_prev_track: [, LB/L1 (Gamepad)
- audio_next_track: ], RB/R1 (Gamepad)
- audio_toggle_pause: \\, Back/Select (Gamepad)

### Controller Button Indices (Godot 4.x)
- 0: A (Xbox) / Cross (PS)
- 1: B (Xbox) / Circle (PS)
- 2: X (Xbox) / Square (PS)
- 3: Y (Xbox) / Triangle (PS)
- 4: LB/L1
- 5: RB/R1
- 6: Back/Select
- 7: Start
- 8: L3 (Left stick press)
- 9: R3 (Right stick press)
- 11-14: D-Pad (Up/Down/Left/Right)
- Axis 0: Left Stick X
- Axis 1: Left Stick Y

### Using Input in Scripts
```gdscript
# Keyboard (action-based)
func _physics_process(delta):
    var direction = Input.get_axis("move_up", "move_down")
    velocity.y = direction * SPEED

# Mouse position
func _process(delta):
    var mouse_y = get_viewport().get_mouse_position().y
    position.y = mouse_y

# Check if action just pressed
func _unhandled_input(event):
    if Input.is_action_just_pressed("launch_ball"):
        launch_ball()
```

### Adding New Input Actions
1. Project → Project Settings
2. Input Map tab
3. Add new action name
4. Click "+" to add bindings:
   - Key: Keyboard keys
   - Mouse Button: Mouse clicks
   - Joypad Button: Controller buttons (see indices above)
   - Joypad Axis: Analog stick movement
5. Use in scripts with `Input.is_action_pressed("action_name")`

### Controller Support Checklist

When adding new UI screens:
- [ ] Call `grab_focus()` on first button in `_ready()` after `await get_tree().process_frame`
- [ ] Handle `ui_cancel` in `_unhandled_input()` for back navigation
- [ ] Call `accept_event()` after handling input to prevent propagation
- [ ] Make level panels/cards focusable with `focus_mode = Control.FOCUS_ALL`
- [ ] Connect `focus_entered/exited` signals for visual feedback

**Example:**
```gdscript
func _ready() -> void:
	# ... setup code ...
	await get_tree().process_frame
	first_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		accept_event()
```

## Testing and Debugging

### Running the Game
- **F5**: Run project (main scene)
- **F6**: Run current scene
- **F7**: Step into (debugging)
- **F8**: Continue (debugging)
- **Ctrl+F5**: Run without debugging

### Headless Validation (CLI)

When running Godot in headless mode from terminal, always isolate runtime data to a temp location and force process exit:

- Always include `--quit` so the process exits after startup/check actions.
- Always use temp paths so `user://` writes (logs/settings) do not touch your normal profile data.
- Prefer this pattern:

```bash
HOME=/tmp/zepball-godot-home \
  godot --headless --quit --path .
```

For script/check commands, keep the same rule: `--quit` + temp user/output paths.

### Debugging Tools

**Print Debugging:**
```gdscript
print("Velocity: ", velocity)
print_debug("Debug info")  # Includes file:line
```

**Breakpoints:**
1. Click left margin in script editor (red dot appears)
2. Run with debugger (F5)
3. Execution pauses at breakpoint
4. Inspect variables in Debugger panel
5. Step through with F7 (step into), F8 (continue)

**Remote Inspector:**
- Debug → Deploy with Remote Debug
- View live scene tree while game runs
- Modify properties in real-time

**Performance Monitoring:**
- Debug → Visible Collision Shapes (see all collision areas)
- Monitor panel: FPS, physics time, memory usage

### Common Issues and Solutions

**"Scene could not be loaded"**
- Check file path is correct
- Ensure scene file exists
- Look for corrupted .tscn file (check git)

**Physics objects passing through each other**
- Enable Continuous CD in collision shape
- Reduce physics speed (lower velocity)
- Check collision layers/masks

**Script errors not showing**
- Check Output panel at bottom
- Look for red error text
- Debugger panel shows runtime errors

**Performance issues**
- Check Monitor panel for FPS
- Reduce particle count
- Use object pooling for frequently instantiated objects

## Version Control with Godot

### What to Commit
- ✅ .tscn files (scene files)
- ✅ .gd files (scripts)
- ✅ .uid files (Godot UID companion files) - **always commit these**
- ✅ .tres files (resources)
- ✅ Assets (sprites, audio)
- ✅ project.godot
- ✅ .godot/global_script_class_cache.cfg (class_name definitions)

UID rule:
- If Godot creates or updates a `*.uid` file for a script/resource/scene change, include it in the same commit.
- Do not delete or ignore `.uid` files unless the referenced source file is intentionally removed.

### What NOT to Commit (.gitignore handles)
- ❌ .godot/ folder (except class cache)
- ❌ .import/ folder
- ❌ *.import files
- ❌ export_presets.cfg (has sensitive data)

### Resolving Merge Conflicts in .tscn
- Scene files are text-based (easy to merge)
- If conflict is complex, choose one version and redo changes
- Use `git diff` to see differences

### Good Commit Practices
```bash
# After completing paddle movement feature
git add scenes/gameplay/paddle.tscn scripts/paddle.gd
git commit -m "feat: Implement paddle vertical movement

- Added CharacterBody2D with collision shape
- Keyboard controls (W/S, arrows)
- Mouse following (optional toggle)
- Constrained to screen bounds (40-680 Y)
- Velocity tracking for spin mechanics

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

**Note:** This example shows Claude Sonnet 4.5. Use your actual agent name/model when committing.

### Commit Message Format (Required)
All commits must follow the format, the agent should be the co-author:

```
<type>: <short summary>

Major Features:
- Feature area
  - Subdetail
  - Subdetail

Quality of Life:
- Improvement
  - Subdetail

Level System:
- Content changes
  - Subdetail

Code Improvements:
- Technical changes
  - Subdetail

Documentation:
- Doc updates

Co-Authored-By: <Your Agent Name/Model> <email>
```

**Note:** Replace with your actual agent identifier (e.g., "Claude Sonnet 4.5 <noreply@anthropic.com>", "GPT-4 <noreply@openai.com>", etc.)

Notes:
- `<type>` should be `feat`, `fix`, `refactor`, `docs`, or `chore`.
- Omit sections that don’t apply, but keep headings for major changes.

### Versioning Note
Public releases use Semantic Versioning (`MAJOR.MINOR.PATCH`).
Current baseline is `0.5.0`.
Do not auto-increment version unless explicitly requested by the user.

### Main Menu Version Label
When the project version changes, update the main menu version label in:
- `scripts/ui/main_menu.gd` (`PUBLIC_VERSION`)
- `scenes/ui/main_menu.tscn` (`VersionLabel.text`, fallback/default)

Keep this label aligned with release docs/changelog, and create a matching Git tag (`vMAJOR.MINOR.PATCH`) when requested.

---

# ════════════════════════════════════════════════════════════════════
# PART 2: PROJECT-SPECIFIC CRITICAL PROCEDURES
# ════════════════════════════════════════════════════════════════════

**⚠️ THE FOLLOWING SECTIONS ARE MANDATORY FOR ALL CODE CHANGES**

**Quick link:** See `SOP/critical-workflows.md` for a condensed version of these procedures.

---

## Save System Compatibility

### CRITICAL: Always Check Save Format When Adding Features

When adding new features that modify the save data structure, you **MUST** add migration logic to handle existing save files. Failure to do this will cause crashes for users with existing saves.

### When to Add Migration Logic

Add migration code whenever you:
- ✅ Add new keys to the save_data dictionary
- ✅ Add new statistics or achievement tracking
- ✅ Add new settings or preferences
- ✅ Change the structure of existing save data
- ✅ Rename or remove save data keys

### Migration Pattern

**Location:** `scripts/save_manager.gd` in the `load_save()` function

**Template:**
```gdscript
func load_save() -> void:
	# ... existing load code ...

	save_data = loaded_data

	# MIGRATION: Add new section if it doesn't exist
	if not save_data.has("new_section"):
		print("Adding new_section to save data...")
		save_data["new_section"] = {
			"new_field_1": default_value,
			"new_field_2": default_value
		}
		save_to_disk()  # Save the migrated data immediately

	# ... rest of load code ...
```

### Example: Adding Statistics Section (2026-01-29)

**Problem:** Added statistics tracking, but old saves don't have "statistics" key.
**Result:** Game crashes with "Invalid access to property 'statistics'" when viewing stats.

**Solution:**
```gdscript
# Migrate old saves that don't have statistics
if not save_data.has("statistics"):
	print("Adding statistics section to save data...")
	save_data["statistics"] = {
		"total_bricks_broken": 0,
		"total_power_ups_collected": 0,
		"total_levels_completed": 0,
		"total_playtime": 0.0,
		"highest_combo": 0,
		"highest_score": 0,
		"total_games_played": 0,
		"perfect_clears": 0
	}
	save_to_disk()
```

### Migration Checklist

Before committing changes that modify save data:
- [ ] Added migration code in `load_save()` to handle old saves
- [ ] Updated `create_default_save()` with new structure
- [ ] Tested with both new save (delete user://save_data.json) and old save
- [ ] Verified migration preserves existing player progress
- [ ] Checked that new features work with migrated data
- [ ] Added print statement for debugging migration

### Testing Save Migrations

**Test with old save:**
1. Run game with existing save file
2. Check console for migration messages
3. Verify new feature doesn't crash
4. Check that old data (levels, scores) still works

**Test with new save:**
1. Delete `user://save_data.json` (see SaveManager.get_save_file_location())
2. Run game to create fresh save
3. Verify all features work with new structure

**Finding save file:**
```gdscript
# Run this in game or debug console
print(SaveManager.get_save_file_location())

# Typical locations:
# macOS: ~/Library/Application Support/Godot/app_userdata/[ProjectName]/
# Linux: ~/.local/share/godot/app_userdata/[ProjectName]/
# Windows: %APPDATA%/Godot/app_userdata/[ProjectName]/
```

### Save Version System

The save file includes a `"version"` field for major migrations:

```gdscript
const SAVE_VERSION = 1  # Increment for breaking changes

# Check version and perform major migration if needed
if loaded_data.get("version", 0) < SAVE_VERSION:
	print("Performing major save migration from v", loaded_data.get("version"), " to v", SAVE_VERSION)
	# Perform migration...
	save_data["version"] = SAVE_VERSION
	save_to_disk()
```

**When to increment SAVE_VERSION:**
- Major restructuring that can't be handled by simple key checks
- Removing old data that's no longer needed
- Changing data types (e.g., String to int)
- Multiple related changes that should happen atomically

**For simple additions:** Use `if not save_data.has("key")` checks (no version bump needed)

## Asset Integration

### Importing Sprites
1. Copy PNG/JPG to `assets/sprites/`
2. Godot auto-imports (creates .import file)
3. Select in FileSystem panel
4. Check Import panel for settings
5. Drag to Sprite2D node or set in Texture property
6. **Update asset documentation** (see below)

### Import Settings
- **Filter**: Nearest (pixel art) or Linear (smooth)
- **Mipmaps**: Disabled for 2D
- **Repeat**: Disabled usually

### Importing Audio
1. Copy OGG/WAV to `assets/audio/`
2. Auto-imported
3. Drag to AudioStreamPlayer or set in Stream property

### Audio Import Settings
- **Loop**: Enable for music, disable for SFX
- **Format**: Keep as OGG Vorbis (smaller) or WAV (quality)

### Asset Documentation Requirements

**CRITICAL: Always update asset documentation when adding or removing assets**

When you add a new asset to the project or remove one from use, you **MUST** update the corresponding documentation files. Failure to do this will cause the documentation to become out of sync with the actual asset usage.

#### When to Update Documentation

Update the docs when you:
- ✅ Add a new graphic asset (sprites, backgrounds, powerups, particles)
- ✅ Add a new audio asset (SFX, music)
- ✅ Remove an asset from use (stop referencing it in code)
- ✅ Change which assets are used (e.g., switching paddle sprite)
- ✅ Add new powerup types that need icons
- ✅ Add new brick types with new textures

#### Documentation Files

| File | Purpose | Update When |
|------|---------|-------------|
| `.agent/System/used-assets.md` | Lists all actively used assets | Add new assets, update references |
| `.agent/System/unused-assets.md` | Lists assets not currently in use | Remove assets from use, clean up unused |

#### Update Process

**Adding a New Asset:**
1. Import the asset into the appropriate `assets/` folder
2. Reference it in your code/scene
3. Add entry to `used-assets.md` with:
   - Asset path and filename
   - Usage description
   - Line reference (file:line)
4. If replacing an existing asset, move old asset to `unused-assets.md`

**Removing an Asset from Use:**
1. Remove references from code/scenes
2. Move entry from `used-assets.md` to `unused-assets.md`
3. Add reason for removal in unused-assets.md
4. Recommendation: Keep or Delete

**Example - Adding a New Powerup:**
```
In used-assets.md:
| `freeze_time.png` | Freeze time power-up | power_up.gd:50 |

In power_up.gd:
# Add to texture dictionary
POWERUP_TEXTURES[PowerUpType.FREEZE_TIME] = preload("res://assets/graphics/powerups/freeze_time.png")
```

**Example - Removing an Asset:**
```
In unused-assets.md:
| `old_sprite.png` | assets/graphics/ | Removed - Replaced with new_sprite.png |
```

#### Asset Documentation Checklist

Before committing changes involving assets:
- [ ] New assets added to `used-assets.md`
- [ ] Line references updated for code changes
- [ ] Removed assets moved to `unused-assets.md`
- [ ] Unused folder assets documented (if applicable)
- [ ] File paths are correct and relative to project root
- [ ] Usage descriptions are clear and accurate

## Building and Exporting

### Setting Up Export Templates (One-time)
1. Editor → Manage Export Templates
2. Download and Install (for Godot 4.6)
3. Wait for download to complete

### Configuring Export Presets
1. Project → Export
2. Add → Choose platform (macOS, Linux, Windows)
3. Configure options:
   - Application name
   - Icon
   - Code signing (macOS)
   - Include non-resource pack files in `include_filter` (for this project: `packs/*.zeppack`)
4. Save preset

### Exporting Build
1. Project → Export
2. Select preset
3. Click Export Project
4. Choose output file location
5. Export

### Automated Release Export (CLI)
For this project, use the release automation script when you want all release presets plus a distributable bundle:

```bash
./scripts/export_release_bundle.sh
```

What it does:
- Exports every configured preset in `export_presets.cfg` via `--export-release`
- Uses each preset's configured `export_path`
- Copies root `README.md` into each preset bundle
- Creates one zip per preset in `dist/releases/` (overwrites on subsequent runs)
  - Linux executable (`zepball.x86_64`) -> `dist/releases/zepball.x86_64.zip`
  - Windows executable (`zepball.exe`) -> `dist/releases/zepball.zip`
- Keeps temporary staging artifacts in `dist/releases/.staging/`

Optional:
- Set a custom Godot binary with `GODOT_BIN`, e.g. `GODOT_BIN=godot4 ./scripts/export_release_bundle.sh`

### Testing Exports
- **macOS**: Run .app bundle, check for errors
- **Linux**: Run via terminal to see console output
- **Windows**: Test on actual Windows machine (or VM)

## Godot Editor Tips

### Keyboard Shortcuts
- **Ctrl/Cmd+S**: Save scene
- **Ctrl/Cmd+D**: Duplicate node
- **Ctrl/Cmd+Z**: Undo
- **Ctrl/Cmd+Y**: Redo
- **F**: Focus selected node (in 2D view)
- **Ctrl/Cmd+F**: Search in script
- **Ctrl/Cmd+Shift+F**: Find in files

### 2D Viewport Navigation
- **Middle Mouse**: Pan
- **Mouse Wheel**: Zoom
- **Space+Drag**: Pan (alternative)

### Scene Editor
- **Ctrl/Cmd+Drag**: Duplicate while moving
- **Shift+Drag**: Constrain to axis
- **Snap to Grid**: Snap checkbox in toolbar

### Script Editor
- **Ctrl/Cmd+K**: Comment/uncomment lines
- **Ctrl/Cmd+Click**: Go to definition
- **Ctrl/Cmd+Shift+Space**: Show function parameters

## Project Organization Checklist

Before committing:
- [ ] Scene saved in correct folder
- [ ] Script saved in scripts/ folder
- [ ] Assets in assets/ subfolders
- [ ] Node names are descriptive (not "Node2D", "Sprite2D")
- [ ] No broken references (red icons in scene tree)
- [ ] Tested current scene (F6)
- [ ] No errors in Output panel
- [ ] New levels use vertically centered `start_y` based on rows with bricks (PlayArea height = 720)

**Level Centering Formula (rows with bricks):**
```
used_rows = max_row - min_row + 1
used_height = used_rows * brick_size + (used_rows - 1) * spacing
start_y = round((720 - used_height) / 2) - min_row * (brick_size + spacing)
```

## Getting Help

### Official Resources
- **Godot Docs**: https://docs.godotengine.org/en/stable/
- **Q&A**: https://ask.godotengine.org/
- **Discord**: https://discord.gg/godot

### Useful Searches
- "Godot 4 CharacterBody2D tutorial"
- "Godot 2D collision detection"
- "Godot signal tutorial"
- "Godot [your_problem] stackoverflow"

### Debugging Strategy
1. Read error message carefully
2. Check Output panel for full stacktrace
3. Add print() statements to trace execution
4. Use debugger breakpoints
5. Search error message + "Godot 4"
6. Ask on Godot Discord with code snippet

---

*Last Updated: 2026-02-12*
*Godot Version: 4.6*
*See: architecture.md for scene structure details*
