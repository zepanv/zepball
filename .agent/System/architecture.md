# ZepBall - System Architecture (Overview)

Use this file for the runtime mental model and change impact mapping.
For subsystem internals, data schemas, and edge-case behavior, use `System/architecture-details.md`.

## Quick Facts
- Engine/runtime: Godot 4.6, 2D breakout/arkanoid gameplay.
- Core loop: menu -> load level/wave -> play -> complete/fail -> next menu/state.
- Endless mode entry: main menu routes to `Endless Waves` hub (`scenes/ui/endless_waves.tscn`) before Survival starts.
- Endless run persistence includes mode-specific boards: `survival_top_runs` (score+wave) and `blitz_top_runs` (score-only).
- Blitz runtime loop is helper-owned (`scripts/main_blitz_helper.gd`) and drives timed brick pushes with paddle-zone fail checks.
- Manual exits from endless gameplay (menu navigation/restart/quit before game over) are treated as run end and persist the current score.
- Primary data model: pack-native (`pack_id + level_index`) with compatibility fields retained.

## Runtime Topology
- Gameplay scene: `scenes/main/main.tscn`
- Scene orchestrator: `scripts/main.gd`
- Blitz loop helper: `scripts/main_blitz_helper.gd`
- Endless hub scene/controller: `scenes/ui/endless_waves.tscn` + `scripts/ui/endless_waves.gd`
- State/scoring authority: `scripts/game_manager.gd`
- Gameplay HUD: `scripts/hud.gd` with fixed scene slots in `scenes/main/main.tscn`
- Global systems (autoload):
  - `PowerUpManager`
  - `DifficultyManager`
  - `SaveManager`
  - `AudioManager`
  - `PackLoader`
  - `MenuController`

Detailed scene graph and node-level breakdown:
- `System/architecture-details.md` -> `Cross-System Invariants`
- `System/architecture-details.md` -> `Runtime Coupling To Watch`

## System Contracts (High-Level)
- Gameplay events flow through signals (`ball_lost`, `brick_broken`, score/life/state updates).
- Explicit cross-system actions use direct method calls.
- Hot-path runtime queries must use cached references/registries, not ad-hoc tree scans.
- In-play HUD layout is slot-based: score, mode/detail, lives, difficulty, player, objective, power-ups, multiplier, and center overlays each have stable regions. Game modes should update slot content rather than swap layout structure.
- HUD edge elements are intentionally gutter-bound so mode additions do not reclaim playfield space.

Detailed conventions and examples:
- `System/architecture-details.md` -> `Cross-System Invariants`

## Critical Change Surfaces

### 1) Gameplay Flow and State
Touching these can impact progression, lives, level completion, and transitions:
- `scripts/main.gd`
- `scripts/game_manager.gd`
- `scripts/ui/menu_controller.gd`

Details:
- `System/architecture-details.md` -> `Runtime Coupling To Watch`

### 2) Ball/Paddle/Brick Runtime
Touching these can impact physics determinism, scoring events, and completion logic:
- `scripts/ball.gd`
- `scripts/paddle.gd`
- `scripts/brick.gd`
- `scripts/main.gd`

Details:
- `System/architecture-details.md` -> `Runtime Coupling To Watch`
- `System/architecture-details.md` -> `High-Risk Behaviors and Mitigations`

### 3) Power-Ups and Difficulty
Touching these can impact active effect state, timers, and score/speed multipliers:
- `scripts/power_up.gd`
- `scripts/power_up_manager.gd`
- `scripts/difficulty_manager.gd`

Details:
- `System/architecture-details.md` -> `Cross-System Invariants`
- `System/architecture-details.md` -> `Runtime Coupling To Watch`

### 4) Save and Progression Compatibility
Touching these can break existing player data if migration is missing:
- `scripts/save_manager.gd`
- Save-backed UI/state consumers (stats, settings, profile, progress)
- Profile loads are expected to reapply save-backed runtime settings before UI refresh, including difficulty, keybindings, and audio state.

Required migration procedure:
- `SOP/critical-workflows.md` -> `1) Save System Compatibility (Required)`

Detailed persistence shape and migration context:
- `System/architecture-details.md` -> `Save Compatibility`

### 5) Pack/Level Loading
Touching these can break content discovery, addressing, and level instantiation:
- `scripts/pack_loader.gd`
- `packs/*.zeppack`
- pack-aware UI scenes/scripts

Details:
- `System/architecture-details.md` -> `Runtime Identity`
- `System/architecture-details.md` -> `Runtime Coupling To Watch`

## Verification Checklist After Runtime Changes
- [ ] Game state transitions still work (`READY` -> `PLAYING` -> complete/fail paths).
- [ ] Level completion and life-loss logic remain correct (single-ball and multi-ball).
- [ ] Survival wave transitions preserve or recreate a valid primary ball after multiball cleanup.
- [ ] Pack-level addressing still resolves correct levels (`pack_id + level_index`).
- [ ] Save-backed features load old saves without crashes (if schema changed).
- [ ] Changed behavior is documented in canonical docs.

## Where To Go Next
- Runtime internals: `System/architecture-details.md`
- Project settings/input/autoload facts: `System/tech-stack.md`
- Required procedures (save/assets/commit/release): `SOP/critical-workflows.md`
- Supplemental Godot workflow notes: `SOP/godot-workflow.md`

**Last Updated:** 2026-03-10
