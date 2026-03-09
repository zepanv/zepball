# ZepBall - Architecture Deep Notes

Use this file for non-obvious runtime invariants, coupling points, and failure-prone behavior.
Do not use this file for easily discoverable inventories (full scene trees, full node lists, full input maps).

## Documentation Scope Rule
Document here only when at least one is true:
- Behavior is cross-system and easy to break unintentionally.
- The correct behavior is not obvious from a single file.
- A bug class has occurred before and has a known mitigation.

## Cross-System Invariants

### Runtime Identity
- Level identity is pack-native: `pack_id + level_index`.
- Legacy integer level/set fields still exist for compatibility and must not become primary identity.
- Pack-run UI may still use "set" naming; runtime/data flow should remain pack-native.

### Scoring Order (Contract)
Score multiplier order is intentional and must remain stable:
1. Base brick points
2. Difficulty multiplier
3. Combo multiplier
4. Streak (`no_miss_hits`) multiplier
5. Double-score effect
6. Perfect-clear bonus at completion

Changing order changes balancing and leaderboard comparability.

### Level Completion Semantics
- Completion is based on breakable target count, not on all placed tiles.
- `UNBREAKABLE`, `FORCE_ARROW`, `POWERUP_BRICK`, and block barrier tiles must not gate completion.
- Any change in brick classification must be validated against completion logic in `main.gd` and `brick.gd`.

### Challenge Mode Constraints
- Non-`normal` challenge modes are pack-run only (not individual-level mode).
- `one_life` blocks effective extra-life progression even if pickup logic still executes path checks.
- Time Attack leaderboards compare lower-is-better time values, unlike score leaderboards.

### Save Compatibility
- New/changed save keys require migration handling in `SaveManager.load_save()` and default updates in `create_default_save()`.
- Migrations must preserve prior progression and be safe on repeated load.
- Canonical procedure: `SOP/critical-workflows.md`.

## Runtime Coupling To Watch

### Ball <-> Main <-> PowerUpManager
- Ball runtime effect truth for timed effects comes from manager-active state.
- Compatibility hook methods may still exist on ball/paddle; manager state remains source of truth.
- Multi-ball and effect expiry timing must be checked together after changes.
- Main-ball ownership must remain valid across multiball loss and Survival wave transitions. If the original main ball is lost while extras remain, gameplay must promote a surviving ball (or recreate one) before any READY-state reset/transition path runs.

### MenuController <-> GameManager <-> SaveManager
- Mode/challenge context influences what is persisted and how results are interpreted.
- Set/pack completion flags and best-result markers depend on active mode semantics.

### PackLoader <-> Export Runtime
- Built-in pack discovery must remain export-safe (`ResourceLoader.list_directory()` with fallback strategy).
- Regressions typically appear only in exported builds, not editor runs.

## High-Risk Behaviors and Mitigations

### Physics callback mutation
- Risk: spawning/modifying physics objects inside collision callbacks can trigger query-flush errors.
- Mitigation: defer scene mutations (`call_deferred`) from collision paths.

### Multi-ball spawn safety
- Risk: invalid spawn angle/position creates immediate loss or out-of-bounds behavior.
- Mitigation: constrained angle ranges + retry path + validity checks.

### Stuck-ball recovery
- Risk: ball can deadlock in edge geometry.
- Mitigation: movement-threshold timer with controlled escape impulse.

### Scene-transition collision timing
- Risk: awaiting timers during unload can crash.
- Mitigation: guard with tree-presence checks before delayed operations.

## Settings Application Boundaries
- Audio settings apply live through `AudioManager`/`AudioServer`.
- Some gameplay settings are initialized per-scene and may require gameplay reload depending on subsystem.
- Pause-overlay settings can apply a subset live; treat live-apply behavior as feature-specific, not global.

## Intentional Limitations
- Pack unlocking is effectively open; legacy progression keys remain for compatibility.
- Existing compatibility fields should be removed only with explicit migration and validation plan.

## Related Docs
- `System/architecture.md` - Overview and change-impact routing
- `System/tech-stack.md` - Engine/config/input/autoload facts
- `SOP/critical-workflows.md` - Required save/asset/commit/release procedures
- `Tasks/Completed/INDEX.md` - Implementation history index

**Last Updated:** 2026-03-09
