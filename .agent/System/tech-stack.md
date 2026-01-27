# Zep Ball - Technology Stack

## Core Technology Decision: Godot Engine 4.x

### Why Godot?

After evaluating multiple options (Godot, Bevy/Rust, Web-based, C++/SDL2), **Godot Engine 4.3+** was selected as the optimal choice for Zep Ball.

### Key Rationale

**Perfect Fit for Game Type**
- 2D arcade physics game with vertical paddle and ball mechanics
- Built-in physics engine (CharacterBody2D, collision detection)
- Native support for particles, audio, UI systems
- Scene-based architecture ideal for levels and game states

**Multiplatform Support** (Primary Requirement)
- Single codebase exports to: macOS, Linux, Windows
- Also supports Web, iOS, Android if needed later
- Native performance on all platforms
- No runtime dependencies or fees

**Development Velocity**
- Visual editor for rapid scene creation
- Built-in debugger and profiler
- Hot-reload for fast iteration
- Excellent documentation and tutorials

**Learning Curve**
- GDScript syntax similar to Python (familiar to user)
- Intermediate coding skills transfer well
- Large, helpful community
- "Your First 2D Game" official tutorial is excellent

**Asset Integration**
- Native sprite, audio, and font support
- Easy particle system for "3D tile breaking" effects
- Shader support for visual polish
- Animation system built-in

**Save System**
- ConfigFile class for player profiles
- user:// directory for cross-platform save data
- Resource system for level data
- JSON support for custom data formats

### Alternatives Considered

**Bevy Engine (Rust)**
- Pros: Modern ECS, great performance, type safety
- Cons: Steeper learning curve, younger ecosystem, longer dev time
- Decision: Overkill for 2D arcade game, Rust ownership model adds complexity

**Web-based (Phaser/Three.js)**
- Pros: Universal browser access, familiar JavaScript
- Cons: Not truly native, requires Electron for desktop feel, performance ceiling
- Decision: Want native desktop apps, not web-first

**C++ with SDL2/SFML**
- Pros: Maximum control, lightweight
- Cons: Build everything from scratch, manual memory management, much longer dev time
- Decision: Too much low-level work for learning project

### Technology Stack Summary

| Component | Technology | Version |
|-----------|-----------|---------|
| Game Engine | Godot | 4.3+ |
| Scripting Language | GDScript | Godot 4.x |
| Version Control | Git | Latest |
| Asset Sources | Kenney.nl, OpenGameArt.org, Freesound.org | - |
| Audio Format | OGG Vorbis (music), WAV (SFX) | - |
| Image Format | PNG (sprites), SVG (vector) | - |
| Level Data | JSON or Godot Resources | - |
| Save Data | Godot ConfigFile | - |

## GDScript Language Choice

**Why GDScript over C#?**
- Python-like syntax (easier learning curve)
- Tighter Godot integration
- Faster iteration (no compilation step)
- Better documentation and examples
- Sufficient performance for 2D arcade game

**When to use C# instead:**
- Need .NET libraries
- Team already expert in C#
- Performance-critical 3D game
- *Not applicable to this project*

## Physics Approach

**Hybrid: Engine Physics + Custom Arcade Feel**

### Built-in Godot Physics
- CharacterBody2D for paddle (controllable)
- CharacterBody2D for ball (with move_and_collide)
- StaticBody2D for walls and bricks
- Area2D for power-up detection zones

### Custom Arcade Enhancements
- Constant ball speed (normalize velocity each frame)
- Paddle spin mechanics (add paddle velocity to ball on collision)
- Simplified reflection angles (no true physics simulation)
- Ball speed caps to prevent "too fast to see" issues

**Rationale:** Pure physics engines feel "too real" for arcade games. Hybrid approach gives predictable, fun gameplay while leveraging Godot's collision detection.

## Asset Pipeline

### Graphics
1. **Prototyping**: Colored rectangles (ColorRect nodes)
2. **Placeholder Art**: Kenney.nl asset packs (free)
3. **Custom Art**: AI-generated sprites + manual touch-up
4. **Formats**: PNG for raster, SVG for UI elements
5. **Resolution**: Design at 1280x720, scale with viewport stretch

### Audio
1. **Sound Effects**: Freesound.org (CC0/CC-BY licensed)
2. **Music**: Incompetech (Kevin MacLeod) or similar royalty-free
3. **Formats**: OGG for music (smaller), WAV for SFX (quality)
4. **Tools**: Audacity for editing, Godot's AudioStreamPlayer

### Fonts
1. **UI Font**: Google Fonts (Open Font License)
2. **Score/HUD**: Bitmap fonts or pixel fonts
3. **Formats**: TTF/OTF with dynamic font in Godot

## Development Tools

### Required
- **Godot Editor 4.3+**: Main development environment
- **Git**: Version control
- **Text Editor**: Godot's built-in or VS Code with godot-tools extension

### Recommended
- **GIMP/Krita**: Image editing (free alternatives to Photoshop)
- **Audacity**: Audio editing
- **Aseprite**: Pixel art creation (if doing custom sprites)
- **Tiled Map Editor**: Level design (optional, can use Godot scenes)

### Optional
- **Godot Discord**: Community support
- **GitHub/GitLab**: Remote repository hosting

## Export Configuration

### Target Platforms (Priority Order)
1. **macOS** (developer's platform)
2. **Linux** (common indie game platform)
3. **Windows** (largest market)

### Export Templates
- Download official Godot export templates for version 4.3+
- Configure export presets for each platform
- Test on actual hardware (or VMs for Linux/Windows)

### Distribution Strategy
- **Phase 1**: itch.io (free hosting, easy updates)
- **Phase 2**: Steam (if project grows)
- **Future**: Game Jolt, Humble Store, etc.

## Performance Targets

### Minimum Specs
- **CPU**: Any dual-core from last 10 years
- **RAM**: 2GB available
- **GPU**: Integrated graphics (Intel HD, Apple Silicon)
- **Resolution**: 1280x720 minimum

### Target Performance
- **FPS**: Locked 60 FPS (vsync on)
- **Load Times**: < 2 seconds to main menu
- **Level Load**: < 0.5 seconds
- **Memory**: < 200MB RAM usage

**Rationale:** 2D arcade game should run on nearly anything. Godot is efficient.

## Development Environment Setup

### macOS (Developer's System)
1. Download Godot 4.3+ from godotengine.org
2. Move Godot.app to /Applications
3. Open project from `/Users/tcowart/Projects/zepball`
4. Configure external editor (if using VS Code)

### VS Code Integration (Optional)
1. Install "godot-tools" extension
2. In Godot: Editor → Editor Settings → Text Editor → External
3. Check "Use External Editor"
4. Set exec path to VS Code

### Git Configuration
- .gitignore already configured for Godot
- Commit frequently (small, working changes)
- Use descriptive commit messages
- Don't commit .godot/ folder (cache)

## Project Settings

### Display
- **Window Size**: 1280x720 (16:9 aspect ratio)
- **Stretch Mode**: viewport (scales content cleanly)
- **Aspect**: keep (maintains ratio on different screens)
- **Resizable**: true (allow fullscreen/windowing)

### Physics
- **Default Gravity**: 0 (2D space game, no down)
- **Gravity Vector**: (0, 0)
- **Physics FPS**: 60 (match render FPS)

### Rendering
- **Texture Filter**: Nearest (pixel-perfect for retro look)
- **Default Clear Color**: #1a1a2e (dark blue-grey)
- **MSAA**: Disabled (not needed for 2D pixel art)

### Input
- **move_up**: Up Arrow, W key
- **move_down**: Down Arrow, S key
- **launch_ball**: Space, Left Mouse Button
- **ui_cancel**: Escape (menus)

## File Organization Conventions

### Scene Files (.tscn)
```
scenes/
├── main/
│   └── main.tscn              # Root game scene
├── gameplay/
│   ├── paddle.tscn            # Reusable paddle
│   ├── ball.tscn              # Reusable ball
│   └── brick.tscn             # Reusable brick template
├── ui/
│   ├── hud.tscn               # In-game HUD
│   ├── main_menu.tscn         # Title screen
│   └── game_over.tscn         # Game over screen
└── levels/
    ├── level_template.tscn    # Base level scene
    └── level_01.tscn          # Specific levels
```

### Script Files (.gd)
```
scripts/
├── paddle.gd                  # Paddle movement logic
├── ball.gd                    # Ball physics and spin
├── brick.gd                   # Brick hit detection
├── game_manager.gd            # Global game state
└── ui/
    ├── hud.gd                 # HUD updates
    └── menu.gd                # Menu navigation
```

### Asset Organization
```
assets/
├── sprites/
│   ├── paddle/
│   ├── ball/
│   ├── bricks/
│   └── effects/
├── audio/
│   ├── music/
│   └── sfx/
└── fonts/
```

## Naming Conventions

### Scenes and Nodes
- **PascalCase** for node names: `PlayerPaddle`, `GameBall`, `BrickRed`
- **snake_case** for scene file names: `player_paddle.tscn`, `game_ball.tscn`

### Scripts
- **snake_case** for files: `paddle.gd`, `game_manager.gd`
- **PascalCase** for class names: `class_name Paddle extends CharacterBody2D`
- **snake_case** for variables and functions: `ball_velocity`, `launch_ball()`
- **UPPER_CASE** for constants: `MAX_SPEED`, `PADDLE_WIDTH`

### Signals
- **snake_case** with descriptive names: `brick_broken`, `ball_lost`, `level_complete`

## Version Control Strategy

### Branch Structure
- **main**: Stable, playable builds
- **dev**: Active development
- **feature/X**: Specific features (e.g., feature/power-ups)

### Commit Message Format
```
<type>: <short summary>

<optional detailed description>
```

**Types:** feat, fix, refactor, docs, test, chore

**Examples:**
- `feat: Add paddle spin mechanics`
- `fix: Ball clipping through fast-moving paddle`
- `docs: Update architecture diagram`

### When to Commit
- After completing a feature or fix
- Before major refactoring
- End of each coding session
- When tests pass

## Next Steps

See `.agent/System/architecture.md` for detailed scene structure and node hierarchy.

---

*Last Updated: 2026-01-27*
*Godot Version: 4.3+*
*Developer: Learning/Exploration Project*
