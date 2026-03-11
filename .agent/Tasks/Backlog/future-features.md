# Future Features - Pending Implementation

## Status: 📋 BACKLOG

Last Updated: 2026-03-11

---

## Survival & Run Depth

### Mutators

Pre-run rule modifier for Survival. Expose a single dropdown before run start, defaulting to `None`. Show the active modifier as a small badge/label in-game. Modifiers change *rules*, not *stats* (stats are covered by the 16 existing power-ups).

**Selection UI:**
- Single dropdown in the Survival hub
- Default option: `None`
- Additional options: `Random`, `No Walls`, `Ricochet Chaos`, `Countdown`, `Speed Ramp`, `Shrinking Playfield`
- `Random` resolves to one concrete mutator at run start and surfaces that resolved mutator in HUD / run-end results
- Explicit mutator picks are allowed for player experimentation and deterministic testing; no separate test-only UI needed

**Modifier pool:**
- **No Walls** — ball wraps screen edges instead of bouncing
- **Ricochet Chaos** — ball bounces off bricks at randomized angles (±15°)
- **Countdown** — bricks regenerate after N seconds if not cleared as part of a chain
- **Speed Ramp** — ball accelerates permanently each time it hits something
- **Shrinking Playfield** — walls slowly close in, increasing spatial pressure each wave
- *Reverse Controls* — keep out of the initial pool; does not currently seem fun enough to justify inclusion.

**Leaderboard policy:**
- `None` uses the normal Survival leaderboard
- Any mutator run (`Random` or a named mutator) writes to a new Survival Mutators leaderboard
- Survival Mutators leaderboard should include a filter/toggle in the header so players can inspect `Random` vs specific named mutators
- Default leaderboard filter should be `Random`
- This keeps player choice available without fragmenting score storage into one board per mutator in v1

**Key risk:** Curate carefully — some combinations become unfun or unplayable.

**Implementation shape:** Run modifier descriptor above gameplay scene setup; apply through the Endless Waves / Survival entry UI, `MenuController`, `game_manager.gd`, `ball.gd`, `paddle.gd`, and brick spawning hooks.

---

### Boss / Elite Waves

Milestone waves that break the rhythm of ordinary brick fields. Two-phase approach — ship Elite first, Boss second.

**Phase A — Elite Waves:** Every N waves in Survival, inject a hand-crafted harder layout with a score multiplier. Uses existing level editor format — no custom nodes or AI needed. Immediate spectacle at low cost.

**Phase B — Boss Waves:** Replace Elite layout with a scripted encounter:
- Weak-point boss made from moving breakable segments
- Shield phases requiring side targets first
- Hazard emitters spawning force arrows, blocks, or projectile lanes

**Key risk:** Phase B has the highest implementation and balancing cost on the list. Best implemented after Advanced Tile Elements ships — strong synergy with force arrow tiles.

---

### Drafted Power-Ups

After every N waves, pause and present 3 power-up options — pick 1. Adds meaningful mid-run decisions and run identity.

- Options: reroll, "skip for score," RNG weighting to avoid dead picks when effects are already active
- **Key risk:** If only timed effects are offered, choices may feel too temporary to matter — consider persistent run bonuses alongside timed ones.

---

### Curse / Negative Power-Ups

Expand the existing red-highlighted negative drop pool. The current risky pool (`Contract`, `Speed Up`, `Small Ball`) is functional but too small, so more entries would add tension to every drop decision without changing the overall pickup/drop architecture.

**Good v1 candidates:**
- **Heavy Paddle** — paddle movement speed is reduced for a short duration. Pressures recovery and positioning without changing paddle size.
- **Power Drain** — remove one active beneficial timed power-up at random. Stronger once run-identity systems exist, but still readable in the current game.
- **Split Paddle** — paddle opens a center dead zone for a short duration, forcing cleaner tracking and edge catches.
- **Brick Armor** — remaining breakable bricks gain a temporary extra hit layer. Increases wave pressure without directly sabotaging controls.
- **Wild Bounce** — paddle hits add a small angle jitter, making precision routing less reliable without making the ball uncontrollable.
- **Drop Jam** — suppress positive random power-up drops for a short duration. Hurts resource flow instead of directly attacking survival.

**Suggested ship-first shortlist:**
- `Heavy Paddle`
- `Power Drain`
- `Drop Jam`

These are the cleanest additions because they are easy to understand, mechanically distinct from the existing bad pool, and relatively low-cost compared with more bespoke curses like `Split Paddle`.

**Suggested asset direction:**
- **Heavy Paddle** — dark iron weight / anvil / chained paddle icon; optional darker paddle tint or subtle drag trail while active
- **Power Drain** — broken star / cracked buff icon / downward spark icon; optional brief drain pulse on the HUD power-up stack when it removes an effect
- **Split Paddle** — paddle icon snapped into two halves with a glowing gap; requires a visible altered paddle state during effect
- **Brick Armor** — shield plate / riveted panel icon; bricks should gain a thin temporary armor overlay, rim glow, or crackable shell effect
- **Wild Bounce** — crooked ricochet arrows / wobble path icon; optional unstable ball trail color while active
- **Drop Jam** — crossed-out capsule / jammed chute icon; optional muted or “locked” treatment on spawned drop indicators while active

**Avoid for now:**
- Reverse controls
- Visibility-denial effects
- Instant life loss
- Pure score punishment with no gameplay change

These are more likely to feel unfair than tense.

**Blocker:** New entries require art assets and, for some entries, temporary runtime state visuals. Revisit when an asset pass is planned.

---

## Field & Tile Systems

### Environmental Hazards / Pinball Elements

> **Prerequisite**: Advanced Tile Elements is ✅ complete (`Tasks/Completed/advanced-tile-elements.md`). Force Arrow tiles, Enhanced Spin, Power-up Bricks, etc. are already shipped. These are the next wave of tile types to build on that foundation.

New tile types that modify the field rather than the bricks:

- **Ball Speed Zones** — Slow Zone (60% speed, 3s) and Fast Zone (140% speed, 3s) brick types; visual glow on ball; stacks with power-ups
- **Portal/Warp** — tile-triggered teleport to a paired location; Air Ball's teleport logic is the starting point
- **Gravity Well** — radial force with distance falloff; variant of the existing Force Arrow system (same proximity-force pattern already in `ball.gd`)
- **Pinball Bumper** — non-breakable obstacle, high-energy bounce at randomized angle

**Suggested implementation order:**
- `Pinball Bumper` first — highest spectacle, clearest readability, strongest “pinball” identity
- `Ball Speed Zones` second — easy to teach and creates route-planning pressure without too much rules overhead
- `Portal/Warp` third — strong once paired-entry/exit readability is solved cleanly
- `Gravity Well` later — highest tuning risk; easiest to make confusing or unfair if the force is too subtle or too strong

**Suggested asset direction:**
- **Pinball Bumper** — circular bumper cap with a bright ring, illuminated center, hit flash, and strong contact particles
- **Ball Speed Zones** — square or hex field tile with animated directional bands or pulse rings; matching fast/slow ball glow while active
- **Portal/Warp** — paired gate visuals with linked colors/shapes, clear entry pulse, and an exit burst so the destination reads immediately
- **Gravity Well** — swirling lens, concentric rings, and subtle orbiting particles to communicate pull radius and center

**Editor impact:** These features also require level-editor support so designers can place, configure, and preview them in authored levels. Pairing/parameterized hazards such as `Portal/Warp`, `Gravity Well`, and speed zones will need editor-side property controls, not just runtime implementation.

*Note: some unused assets may exist — audit before committing. Godot-generated visuals (particles, shaders) are a fallback.*

---

### Brick Affixes

Individual bricks gain traits that change how they behave:

- **Shielded** — requires two hits
- **Splitting** — breaks into smaller bricks
- **Healing** — regenerates HP over time
- **Timed** — disappears after N seconds if not broken

Strong long-term depth — likely requires new assets.

---

## Scoring & Replayability

### Combo Cashout

Deliberately cash in a current combo for a bonus score reward — one explicit decision point per wave. Low implementation cost, fits the arcade-first philosophy with no new UI surface needed beyond a prompt or button.

---

### Daily Run

Fixed daily seed with a shared leaderboard and optionally one curated mutator set. Low-content replayability driver — viable once seeded generation is confirmed deterministic.

---

### Ghost Replays

Record and replay the best run (personal or friend) as a ghost. No new gameplay logic — input recording only. Social replayability hook with minimal implementation surface.

---

## Character & Build Systems

### Paddle Enhancements

Two complementary layers — active ability and pre-run passive selection.

**Active — Pulse:**
An on-demand shockwave that knocks nearby bricks/ball upward. Useful for dislodging a stubborn brick that's hard to reach. Cooldown-gated to prevent abuse.

**Passive — Paddle Modules:**
Pre-run selection of a passive trait:
- Wider catch zone
- Better spin control
- Improved power-up magnetism

**Implementation shape:** Ability system in `paddle.gd`; cooldown timer in `PowerUpManager`; HUD indicator for Pulse charge state; module selection in pre-run flow.

---

## Implementation Order

| Phase | Feature | Notes |
|-------|---------|-------|
| **Next** | Mutators | Low cost, high run variety impact |
| **Next** | Elite Waves | Low cost, adds Survival milestones |
| **Next** | Combo Cashout | Very low cost, scoring depth |
| **Soon** | Drafted Power-Ups | New inter-wave UI needed |
| **Soon** | Environmental Hazards / Pinball Elements | Builds on completed tile system |
| **Soon** | Boss Waves | After Advanced Tile Elements ships |
| **Later** | Daily Run | Needs deterministic seeded gen |
| **Later** | Ghost Replays | Nice-to-have replayability hook |
| **Later** | Curse Power-Ups | Asset-gated |
| **Later** | Brick Affixes | Likely asset-gated |
| **Later** | Paddle Enhancements | Complex; balancing risk |

---

## Open Questions

- Are run-level choices (Drafted Power-Ups, Modules) ephemeral per session, or do they persist through unlocks/profile progression?  Leaning towards session.
- Should Daily Run and Survival share the same seeded-generation system?
- How much UI complexity between waves is acceptable before pacing drags? (preference: minimal — banners over menus)
- Do mutator-enabled runs need separate leaderboard buckets, or is a filter/tag sufficient? Filter or "badge"?

---

## Related Docs

- `Tasks/Completed/phase1-wave-objectives-blitz.md` — Wave Objectives + Blitz (implemented)
- `Tasks/Completed/ui-overhaul.md` — menu/HUD overhaul (implemented)
- `Tasks/Completed/new-game-modes.md` — Time Attack + Survival (implemented)
- `Tasks/Completed/challenge-modes.md` — Iron Ball + One Life (implemented)
- `Tasks/Completed/advanced-tile-elements.md` — tile elements (implemented: Enhanced Spin, Force Arrows, Power-up Bricks)
