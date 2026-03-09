# Run Variety Expansion

## Status: 📋 BACKLOG

Exploration brief for post-core features that deepen replayability, strengthen Survival's identity, and add more strategic decisions without requiring a full genre shift.

Created: 2026-03-09
Last Updated: 2026-03-09 (discussion notes updated 2026-03-09)

---

## Goal

Identify a short list of high-value features that can make ZepBall runs feel more distinct from one another while staying compatible with the current paddle / ball / brick loop.

This task is intentionally exploratory. It should narrow the field to a few candidates worth full PRDs later, not commit the project to shipping every concept below.

---

## Recommended Shortlist

### 1. Mutators
- **Why it fits**: Extends existing modes and layouts without needing a large content pipeline.
- **Player value**: Makes repeat runs feel different and supports challenge-style play.
- **Examples**:
  - Fast Balls Only (disable slow ball powerup as well)
  - Tiny Paddle (disable big paddle powerup as well)
  - Reverse Controls (not really sold on this one)
  - Need a few more options here!
  - Moving Brick Rows (probably just do this in Blitz mode?)
- **Implementation shape**:
  - Add a run modifier descriptor layer above gameplay scene setup.
  - Apply selected modifiers through `MenuController`, `game_manager.gd`, `ball.gd`, `paddle.gd`, and brick spawning hooks.
  - Optionally seed mutator sets for Survival and Daily Run.
- **Key risk**: Modifier stacking can create impossible or unfun combinations if not curated.
- **Discussion note (2026-03-09)**: UI clutter is a real concern — avoid a full mutator selection screen. Preferred approaches:
  - A single "Random Modifier" pre-run toggle (no selection, just applies one automatically). Possible dropdown selector, where to place?
  - Show active modifier as a small badge/label in-game rather than a menu surface
- **Discussion note (2026-03-09 cont.)**: With 16 power-ups already covering stat changes (speed, size, ball effects), mutators should modify *rules* rather than *stats*. Revised ideas:
  - **No Walls** — ball wraps screen edges instead of bouncing (portal-like, no art needed)
  - **Ricochet Chaos** — ball bounces off bricks at randomized angles (±15°)
  - **Countdown** — bricks regenerate after N seconds if not cleared as part of a chain
  - **Speed Ramp** — ball accelerates each time it hits something (persistent escalation, unlike timed Speed Up power-up)
  - "Reverse Controls" may be more annoying than fun in a reflex game — keep for hard/challenge pool but maybe not in the casual random pool

### 2. Wave Objectives ⭐ (new — added from discussion)
- **Why it fits**: Adds per-wave decision interest to Survival with near-zero implementation cost and no new UI surface.
- **Player value**: Breaks monotony of identical waves; rewards skillful play with a visible bonus.
- **Key risk**: Objectives must be achievable even for weaker players — should feel like a bonus, not a gate.
- **Discussion note (2026-03-09)**: Preferred concept from discussion. Low cost, no new assets, minimal UI footprint.

#### Objective Pool (refined 2026-03-09)

| Objective | Condition | Always valid? | Scales? |
|-----------|-----------|---------------|---------|
| No Ball Loss | Don't lose the ball this wave | ✅ Yes | No (naturally harder as speed increases) |
| Speed Clear | Clear wave in under X seconds | ✅ Yes | Yes — tighten timer gently; floor ~30s (ball travel time is the bottleneck) |
| Combo Streak | Reach Nx combo | ✅ Yes | Yes — raise N, cap ~15 (RNG limits how much ball angle can be influenced) |
| Bomb Chain | Trigger N bomb explosions | ❌ Layout-check required | Gentle — only if wave contains enough bombs |
| Spin Master | Clear N bricks with penetrating spin | ✅ Yes | Gentle — cap ~5 |
| Opening Salvo | Break N bricks in the first 15 seconds | ✅ Yes | Yes — raise N |
| Score Target | Score X points this wave | ✅ Yes | Yes — scale with wave number |

- Power-up-specific objectives (e.g., "collect a negative power-up") are **cut** — player can't control what drops, violating the "bonus, not a gate" principle.
- ~60-70% chance of an objective appearing per wave. Some waves are just "play" waves. Early waves (1-3) could have higher odds to teach the mechanic.
- Objectives should reward "I played well" not "I played perfectly." A decent player should complete ~50-60% of objectives they see.

#### Scaling philosophy
- Gentle scaling with caps. There is a lot of randomness in the game — the player can only influence ball angle so much from the paddle.
- Reward types can scale with wave depth: early waves give points, later waves give lives (more valuable deep in a run).

#### HUD placement
- Persistent top HUD element (not a fading banner) so players always know the objective:  `⭐ No ball loss | +500`
- For threshold objectives, show live progress: `⭐ 10x Combo: 6/10 | +500`
- On completion: brief flash + checkmark. On failure: fade/strikethrough quietly.
- Since waves are randomly generated, the objective system must inspect each wave *after* generation to assign something achievable (especially for layout-dependent objectives like Bomb Chain).

#### Implementation shape
- Objective assignment logic runs post-wave-generation in `game_manager.gd` or a new helper.
- Track objective state alongside wave progress.
- Award bonus at wave completion if condition was met.
- ~~Multi-ball edge case: does losing one of four balls fail "No Ball Loss"?~~ **Resolved: No** — only losing the primary/last ball counts. Penalizing multi-ball loss would discourage Triple Ball pickup.

### 3. Timed Survival / Blitz Mode ⭐ (new — added from discussion)
- **Why it fits**: Gives Survival a meaningfully different feel without a new content pipeline. Addresses the "deliberate/slow" problem where skilled players can be overly methodical.
- **Player value**: Forces efficiency over patience; skill ceiling shifts from ball control to ball control *under pressure*.
- **Description**: New brick rows push in from the left on a fixed timer regardless of whether previous bricks are cleared. Uncleared bricks shift rightward toward the paddle; if they reach the paddle zone it's game over. Very arcade — almost Tetris pressure applied to breakout.
- **Key risk**: Timer pacing needs careful tuning — too fast is unplayable, too slow removes the pressure point.

#### Resolved Decisions (2026-03-09)
- **Push direction**: Option B — new rows spawn at the left edge, existing bricks shift rightward toward the paddle. This creates the most visible pressure given the vertical paddle on the right.
- **Unbreakable bricks**: ~~Options: (a) no unbreakable bricks, (b) expire after N pushes, (c) edge positions only.~~ **Resolved: no unbreakable bricks in Blitz.** The timed push pressure is the difficulty lever.
- **Difficulty scaling**: `DifficultyManager` multipliers must apply to Blitz for score and speed, same as other modes.
- **Menu concept**: Rather than a standalone button, create an **"Endless Modes" hub menu** (or similar label — "Random", "Arcade", etc.) that replaces the current Survival main-menu button. Hub shows mode cards with descriptions (similar to pack/mode selection UI) and houses both current Survival and new Blitz. Provides a natural home for future endless modes. Naming TBD.

#### Core Mechanic Differences from Survival
- Survival: clear all breakable bricks → wave complete → transition → load next wave. Bricks don't persist.
- Blitz: bricks from multiple "generations" coexist. No wave-complete trigger — the game just keeps going. Score/wave counter increments based on rows survived or time elapsed.

#### Row Push Mechanics
- On a fixed timer, all existing bricks shift one column rightward (instant snap, not animated slide).
- A new row of bricks spawns at the leftmost column(s).
- Game over when any brick occupies the paddle zone (rightmost column area) after a push.
- Push timer tightens gradually: start ~15-20s between pushes, tighten by ~1s every N pushes, floor ~8s. Needs playtesting.
- **Ball collision on push**: Instant snap — if a brick shifts into the ball's position, the ball should collide/bounce off the new brick position. Avoids physics edge cases of animated movement.

#### Initial Board State
- Start with 2-3 pre-placed rows so there's something to clear immediately. Empty board → first push would be a dead wait.

#### Power-Ups in Blitz
- Normal power-up drops for now — needs more thought. Note: `BRICK_THROUGH` is extremely strong in Blitz (clears entire columns as bricks stack). May need balancing or a modified pool.

#### Leaderboard
- Blitz needs its own leaderboard tab, separate from Survival.
- Tracked metrics: score + rows survived (or time survived).
- Current leaderboard UI may need rethinking to accommodate additional endless mode tabs (Survival + Blitz + future modes).

#### Technical Change Surface

| Area | Change needed |
|------|--------------|
| `survival_generator.gd` | New `generate_blitz_row()` static function — single row of bricks, no unbreakable type |
| `main_survival_helper.gd` | New Blitz helper (or `BlitzHelper` class) — timed row injection loop, no wave-complete trigger, right-edge game-over check |
| `main.gd` | `is_blitz_mode` flag (or mode enum alongside `is_survival_mode`); hook into Blitz helper |
| `menu_controller.gd` | New `start_blitz()` function (similar to `start_survival()`); Endless Modes hub scene routing |
| `game_manager.gd` | Blitz-specific game-over check (bricks in paddle zone), score tracking |
| New scene | Endless Modes selection screen (mode cards with descriptions) |
| `SaveManager` | `blitz_top_runs` save key + migration for existing saves |
| HUD | Timer display showing next row push countdown |
| High Scores UI | New Blitz tab; may need UI rework to support multiple endless mode tabs |

#### Discussion notes
- Emerged from thinking about brick persistence across waves. The timed pressure framing is stronger and more arcade-appropriate.
- Survival already has "increasing speed pressure" — Blitz differentiates by adding *brick push pressure* on top. That's a meaningfully different feel.

### 4. Drafted Power-Ups
- **Why it fits**: Builds directly on the existing power-up system and makes Survival less luck-driven.
- **Player value**: Adds meaningful mid-run choices and stronger build identity.
- **Example beats**:
  - After every N waves, present 3 power-up options and pick 1.
  - Offer a reroll or "skip for score" decision.
  - Weight choices to avoid dead options when certain effects are already active.
- **Implementation shape**:
  - New inter-wave choice UI.
  - Power-up pools and rarity weighting.
  - Compatibility rules for timed vs. persistent run bonuses.
- **Key risk**: If implemented as normal timed effects only, choices may feel too temporary to matter.

### 5. Boss Waves
- **Why it fits**: Gives Survival a stronger arc and creates memorable milestones.
- **Player value**: Breaks the rhythm of ordinary brick fields and adds spectacle.
- **Examples**:
  - Weak-point boss made from moving breakable segments.
  - Shield phases that require clearing side targets first.
  - Hazard emitters that spawn force arrows, blocks, or projectile lanes.
- **Implementation shape**:
  - Dedicated wave generator branch for boss milestones.
  - Boss-specific nodes/scenes with weak-point health and movement patterns.
  - Survival reward pacing around boss clears.
- **Key risk**: This has the highest implementation and balancing cost in the shortlist.

---

## Secondary Concepts Worth Revisiting

### Environmental Hazards / Pinball Elements
- How it works: Instead of modifying the bricks, modify the empty space. Add Gravity Wells (curves the ball's trajectory), Portals/Warp pipes (Pac-Man style screen wrapping), or Pinball Bumpers (drastically accelerates the ball in a random direction).
- Why it fits: Adds massive run variety based on level layouts without needing complex brick logic.
- **Discussion note (2026-03-09)**: Potentially under-valued. Force Arrow tiles already exist as non-collidable field effects — gravity wells and portals would fit the same architectural pattern. Portals (teleport ball node to paired location) are especially low-cost to implement. Consider promoting closer to the shortlist.
- **Cross-reference (2026-03-09)**: Strong overlap with `Tasks/Backlog/advanced-tile-elements.md` and `Tasks/Backlog/future-features.md` (Ball Speed Zones, Brick Chains). These are extensions of existing tile types, not a brand-new system:
  - **Portal/Warp** ← Air Ball already has teleport + collision-safe landing logic. Tile-triggered portals would reuse this, adding paired destinations instead of center-only.
  - **Gravity Well** ← Force Arrow already applies directional force. Gravity well = radial force with distance falloff instead of linear push.
  - **Pinball Bumper** ← Brick collision + high-energy bounce at randomized angle; non-breakable obstacle.
- **Implementation order note**: Whichever task (this or Advanced Tile Elements) is implemented first should consider building the shared tile infrastructure to support the other. The run-variety angle is *which waves/layouts include these hazards* (Survival/Blitz wave generation decides placement), while the tile elements angle is *building the hazard tiles themselves*.

### Shrinking Playfield (new — added from discussion 2026-03-09)
- How it works: Walls slowly close in during a wave, making the play area smaller and increasing pressure.
- Why it fits: Distinct from both speed pressure (Survival) and brick-push pressure (Blitz). Purely spatial tension — no new content needed, just wall-position animation.
- Worth exploring as a Survival variant or mutator.

### Elite Waves (new — lighter Boss Wave alternative, added from discussion 2026-03-09)
- How it works: Every N waves in Survival, inject a hand-crafted harder layout with a score multiplier. Uses existing level editor format — no boss AI or custom nodes needed.
- Why it fits: Provides the milestone/spectacle feeling of boss waves at a fraction of the implementation cost. Could serve as a stepping stone before full boss waves.

### Curse / Negative Power-Ups (expansion)
- Negative drop items are already partially in place (red-highlighted power-ups exist).
- Expanding the pool would add tension to every drop decision without structural changes.
- **Blocker**: New entries require art assets — not a free addition like Wave Objectives.
- Worth revisiting when an asset pass is planned.

### Daily Run
- Fixed daily seed with a leaderboard and maybe one curated mutator set.
- Good low-content replay driver if score verification and seeded generation stay deterministic.

### Brick Affixes
- Add traits like shielded, splitting, healing, teleporting, or timed bricks.
- Strong long-term depth, but probably requires assets

### Paddle Modules
- Pre-run passive selection like wider catch zone, better spin control, or improved power-up magnetism.
- Promising for progression, but depends on whether the game wants loadout meta or mostly run-based variety.

---

## Evaluation Lens

Use these criteria before promoting any candidate to a full implementation task:

1. Does it preserve the core fantasy of readable, skill-based paddle control?
2. Does it add replayability without demanding a large bespoke art/content pipeline?
3. Can it integrate cleanly with Survival, challenge modes, and leaderboards?
4. Can difficulty be tuned to feel demanding without producing unavoidable losses?
5. Does it create clear player-facing variety, not just hidden systemic complexity?

---

## Suggested Sequence

### Phase 1: Low Cost, High Impact (arcade-first)
- Wave Objectives
- Timed Survival / Blitz Mode

### Phase 2: Expand Survival Identity
- Mutators (via random/auto approach — no selection menu)
- Boss Waves (after Advanced Tile Elements ships — strong synergy with force arrow tiles)
- Curated wave milestones

### Phase 3: Deeper Systemic Layering
- Curse Power-Ups (asset-dependent)
- Brick Affixes
- Paddle Modules

---

## Open Questions

- ~~Should ZepBall lean harder into arcade purity, or is a light roguelite structure acceptable?~~ **Resolved: arcade-first. No deep roguelite structure.**
- Are run-level choices meant to be ephemeral within a session, or persist through unlocks/profile progression?
- Should Daily Run and Survival share the same seeded-generation system?
- How much UI complexity is acceptable between waves before pacing starts to drag? (preference: minimal — banners over menus)
- Do leaderboards need separate buckets for mutator-enabled runs?
- ~~Is Timed Survival a separate mode or a toggle on existing Survival?~~ **Resolved: standalone Blitz mode under an Endless Waves hub menu.**
- ~~What should the "Endless Modes" hub menu be called?~~ **Resolved: "Endless Waves" for now.** Should mirror pack/mode selection UI style (mode cards with descriptions).
- ~~Should Environmental Hazards / Portals be promoted to the main shortlist?~~ **Partially resolved: may depend on available assets.** Some unused assets exist but unclear if they fit. Could also use Godot-generated visuals (particles, shaders). Needs an asset audit before committing.
- **Leaderboard UI rework needed (2026-03-09)**: Current High Scores screen doesn't feel good — especially the Sets board with double tabs. Adding Blitz as another tab makes this worse. Should revisit the leaderboard UI holistically when implementing Blitz, not just bolt on another tab.

---

## Definition of Done For This Backlog Task

- ~~Decide whether the project wants arcade-first or strategy-first.~~ **Resolved: arcade-first.**
- Promote Wave Objectives and Timed Survival to full PRDs when ready to implement.
- Decide whether Timed Survival is a standalone mode or a Survival variant/toggle.
- Decide whether Mutators are free-pick or auto/random (UI clutter concern drives this).
- Document final implementation order with effort/risk notes once PRDs are drafted.

---

## Related Docs

- `Tasks/Completed/new-game-modes.md`
- `Tasks/Completed/challenge-modes.md`
- `Tasks/Backlog/future-features.md`
