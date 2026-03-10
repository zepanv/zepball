# Used Assets

This document tracks which asset groups are actively referenced by gameplay/runtime systems.
Do not duplicate line-level references here; use `rg` when you need the exact call site.

## Active Asset Groups

### Bricks and field tiles
- Location: `assets/graphics/bricks/`
- Used by: `scripts/brick.gd`, `scripts/main.gd`
- Active families:
  - square brick sprites for normal/strong/unbreakable/gold/color variants
  - diamond, glossy diamond, polygon, and glossy polygon variant pools
  - `special_bomb.png`
  - `element_green_rectangle.png` for the block barrier

### Ball and particle visuals
- Locations: `assets/graphics/balls/`, `assets/graphics/particles/`
- Used by: `scenes/gameplay/ball.tscn`, `scripts/ball.gd`
- Active files:
  - `blue_ball.png`
  - `particleSmallStar.png`
  - `particleStar.png`
  - `particleCartoonStar.png`

### Paddle visuals
- Location: `assets/graphics/paddles/`
- Used by: `scenes/gameplay/paddle.tscn`
- Active file:
  - `paddleBlu.png`

### Backgrounds
- Location: `assets/graphics/backgrounds/`
- Used by: `scripts/main_background_manager.gd`
- Contract:
  - all shipped background JPGs in this folder are part of the runtime rotation

### Power-up and special tile icons
- Location: `assets/graphics/powerups/`
- Used by: `scripts/power_up.gd`, `scripts/brick.gd`
- Active files:
  - `expand.png`
  - `contract.png`
  - `speed_up.png`
  - `triple_ball.png`
  - `big_ball.png`
  - `small_ball.png`
  - `slow_down.png`
  - `extra_life.png`
  - `grab.png`
  - `brick_through.png`
  - `double_score.png`
  - `mystery.png`
  - `bomb_ball.png`
  - `air_ball.png`
  - `magnet.png`
  - `block.png`
  - `arrow_down_right.png` (Force Arrow base sprite)

### Audio SFX
- Location: `assets/audio/sfx/`
- Used by: `scripts/audio_manager.gd`, `scripts/ball.gd`
- Active contract:
  - all current SFX in this folder are in use, including `bzzrt.mp3` for Force Arrow feedback

## Maintenance Rule
- Update this file when an asset starts or stops being referenced by runtime code or scenes.
- Prefer grouping by owning system over recording line numbers or percentages.

*Last updated: March 10, 2026*
