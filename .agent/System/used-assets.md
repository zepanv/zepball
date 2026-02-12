# Used Assets

## Summary

This document lists all assets currently referenced and in use by the game code.

| Category | Used Count | Total in Category | Percentage |
|----------|------------|-------------------|------------|
| Brick Graphics | 40 | 52 | 76.9% |
| Ball Graphics | 1 | 1 | 100% |
| Particle Graphics | 3 | 3 | 100% |
| Paddle Graphics | 1 | 2 | 50% |
| Background Graphics | 7 | 7 | 100% |
| Powerup Graphics | 17 | 24 | 70.8% |
| Audio SFX | 9 | 10 | 90% |
| **TOTAL** | **78** | **99** | **78.8%** |

---

## 1. Brick Graphics (40 used)

Location: `assets/graphics/bricks/`

### Referenced in `scripts/brick.gd`

#### Square Bricks (Direct assignments in `setup_sprite()`)
| Asset | Usage | Line Reference |
|-------|-------|----------------|
| `element_green_square.png` | NORMAL brick type | brick.gd:183 |
| `element_red_square_glossy.png` | STRONG brick type | brick.gd:185 |
| `element_grey_square.png` | UNBREAKABLE brick type | brick.gd:187 |
| `element_yellow_square_glossy.png` | GOLD brick type | brick.gd:189 |
| `element_red_square.png` | RED brick type | brick.gd:191 |
| `element_blue_square.png` | BLUE brick type | brick.gd:193 |
| `element_purple_square.png` | PURPLE brick type | brick.gd:197 |
| `element_yellow_square.png` | ORANGE brick type | brick.gd:199 |
| `special_bomb.png` | BOMB brick type | brick.gd:201 |

#### Diamond Variants (DIAMOND_VARIANTS array)
| Asset | Usage | Line Reference |
|-------|-------|----------------|
| `element_blue_diamond.png` | Random diamond brick | brick.gd:37 |
| `element_green_diamond.png` | Random diamond brick | brick.gd:38 |
| `element_grey_diamond.png` | Random diamond brick | brick.gd:39 |
| `element_purple_diamond.png` | Random diamond brick | brick.gd:40 |
| `element_red_diamond.png` | Random diamond brick | brick.gd:41 |
| `element_yellow_diamond.png` | Random diamond brick | brick.gd:42 |

#### Diamond Glossy Variants (DIAMOND_GLOSSY_VARIANTS array)
| Asset | Usage | Line Reference |
|-------|-------|----------------|
| `element_blue_diamond_glossy.png` | Random glossy diamond | brick.gd:45 |
| `element_green_diamond_glossy.png` | Random glossy diamond | brick.gd:46 |
| `element_grey_diamond_glossy.png` | Random glossy diamond | brick.gd:47 |
| `element_purple_diamond_glossy.png` | Random glossy diamond | brick.gd:48 |
| `element_red_diamond_glossy.png` | Random glossy diamond | brick.gd:49 |
| `element_yellow_diamond_glossy.png` | Random glossy diamond | brick.gd:50 |

#### Polygon Variants (POLYGON_VARIANTS array)
| Asset | Usage | Line Reference |
|-------|-------|----------------|
| `element_blue_polygon.png` | Random polygon brick | brick.gd:53 |
| `element_green_polygon.png` | Random polygon brick | brick.gd:54 |
| `element_grey_polygon.png` | Random polygon brick | brick.gd:55 |
| `element_purple_polygon.png` | Random polygon brick | brick.gd:56 |
| `element_red_polygon.png` | Random polygon brick | brick.gd:57 |
| `element_yellow_polygon.png` | Random polygon brick | brick.gd:58 |

#### Polygon Glossy Variants (POLYGON_GLOSSY_VARIANTS array)
| Asset | Usage | Line Reference |
|-------|-------|----------------|
| `element_blue_polygon_glossy.png` | Random glossy polygon | brick.gd:61 |
| `element_green_polygon_glossy.png` | Random glossy polygon | brick.gd:62 |
| `element_grey_polygon_glossy.png` | Random glossy polygon | brick.gd:63 |
| `element_purple_polygon_glossy.png` | Random glossy polygon | brick.gd:64 |
| `element_red_polygon_glossy.png` | Random glossy polygon | brick.gd:65 |
| `element_yellow_polygon_glossy.png` | Random glossy polygon | brick.gd:66 |

### Referenced in `scripts/main.gd`

| Asset | Usage | Line Reference |
|-------|-------|----------------|
| `element_green_rectangle.png` | Block barrier texture | main.gd:400 |

---

## 2. Ball Graphics (1 used)

Location: `assets/graphics/balls/`

| Asset | Usage | Reference |
|-------|-------|-----------|
| `blue_ball.png` | Ball visual sprite | ball.tscn:4 (scene file), ball.gd (indirect) |

---

## 3. Particle Graphics (3 used)

Location: `assets/graphics/particles/`

| Asset | Usage | Line Reference |
|-------|-------|----------------|
| `particleSmallStar.png` | Small ball trail | ball.gd:42 |
| `particleStar.png` | Medium ball trail | ball.gd:43 |
| `particleCartoonStar.png` | Large/high-spin trail | ball.gd:44 |

---

## 4. Paddle Graphics (1 used)

Location: `assets/graphics/paddles/`

| Asset | Usage | Reference |
|-------|-------|-----------|
| `paddleBlu.png` | Paddle visual sprite | paddle.tscn:4 (scene file) |

---

## 5. Background Graphics (7 used)

Location: `assets/graphics/backgrounds/`

All backgrounds are randomly selected by `main_background_manager.gd`.

| Asset | Usage | Line Reference |
|-------|-------|----------------|
| `bg_minimal_3_1769629212643.jpg` | Random background | main_background_manager.gd:11 |
| `bg_minimal_4_1769629224923.jpg` | Random background | main_background_manager.gd:12 |
| `bg_minimal_5_1769629238427.jpg` | Random background | main_background_manager.gd:13 |
| `bg_refined_1_1769629758259.jpg` | Random background | main_background_manager.gd:14 |
| `bg_refined_2_1769629770443.jpg` | Random background | main_background_manager.gd:15 |
| `bg_nebula_dark_1769629799342.jpg` | Random background | main_background_manager.gd:16 |
| `bg_stars_subtle_1769629782553.jpg` | Random background | main_background_manager.gd:17 |

---

## 6. Powerup Graphics (17 used)

Location: `assets/graphics/powerups/`

All referenced in `scripts/power_up.gd` in the texture loading dictionary.

| Asset | Powerup Type | Line Reference |
|-------|--------------|----------------|
| `expand.png` | Expand paddle | power_up.gd:34 |
| `contract.png` | Contract paddle | power_up.gd:35 |
| `speed_up.png` | Speed up ball | power_up.gd:36 |
| `triple_ball.png` | Triple ball | power_up.gd:37 |
| `big_ball.png` | Big ball | power_up.gd:38 |
| `small_ball.png` | Small ball | power_up.gd:39 |
| `slow_down.png` | Slow down ball | power_up.gd:40 |
| `extra_life.png` | Extra life | power_up.gd:41 |
| `grab.png` | Grab/sticky paddle | power_up.gd:42 |
| `brick_through.png` | Brick through | power_up.gd:43 |
| `double_score.png` | Double score | power_up.gd:44 |
| `mystery.png` | Mystery/random | power_up.gd:45 |
| `bomb_ball.png` | Bomb ball | power_up.gd:46 |
| `air_ball.png` | Air ball | power_up.gd:47 |
| `magnet.png` | Magnet | power_up.gd:48 |
| `block.png` | Block barrier | power_up.gd:49 |
| `unused/arrow_down_right.png` | FORCE_ARROW tile sprite (rotated per direction) | brick.gd:39 |

---

## 7. Audio SFX (9 used)

Location: `assets/audio/sfx/`

All referenced in `scripts/audio_manager.gd` in the `_load_sfx_streams()` function.

| Asset | Event | Line Reference |
|-------|-------|----------------|
| `hit_brick.mp3` | Ball hitting brick | audio_manager.gd:214 |
| `hit_paddle.mp3` | Ball hitting paddle | audio_manager.gd:215 |
| `hit_wall.mp3` | Ball hitting wall | audio_manager.gd:216 |
| `power_up.mp3` | Collecting good power-up | audio_manager.gd:217 |
| `power_down.mp3` | Collecting bad power-up | audio_manager.gd:218 |
| `life_lost.mp3` | Losing a life | audio_manager.gd:219 |
| `level_complete.mp3` | Level completion | audio_manager.gd:220 |
| `game_over.mp3` | Game over | audio_manager.gd:221 |
| `combo_milestone.mp3` | Combo milestone reached | audio_manager.gd:222 |

---

## Asset Usage by System

| System | Asset Types | File References |
|--------|-------------|-----------------|
| **Brick System** | Brick sprites, textures | `brick.gd` |
| **Ball System** | Ball sprite, particle textures | `ball.tscn`, `ball.gd` |
| **Paddle System** | Paddle sprite | `paddle.tscn` |
| **Powerup System** | Powerup icons | `power_up.gd` |
| **Background System** | Background images | `main_background_manager.gd` |
| **Audio System** | Sound effects | `audio_manager.gd` |
| **Block Barrier** | Block texture | `main.gd` |

---

*Last updated: February 12, 2026*
