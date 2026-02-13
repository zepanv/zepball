# Unused Assets

## Summary

This document lists assets that exist in the project but are not currently referenced in any code files.

| Category | Unused Count | Total in Category | Percentage |
|----------|--------------|-------------------|------------|
| Brick Graphics | 12 | 52 | 23.1% |
| Paddle Graphics | 1 | 2 | 50% |
| Powerup Graphics | 7 | 24 | 29.2% |
| Audio SFX | 0 | 10 | 0% |
| **TOTAL** | **20** | **88** | **22.7%** |

---

## 1. Brick Graphics (12 unused)

Location: `assets/graphics/bricks/`

### Source/Documentation Files
| Asset | Size | Recommendation |
|-------|------|----------------|
| `bricks.svg` | Source file | Keep - Source file for brick graphics |

### Unused Rectangle Variants
Note: Only `element_green_rectangle.png` is used (for block barrier). All other rectangle variants are unused.

| Asset | Size | Recommendation |
|-------|------|----------------|
| `element_blue_rectangle.png` | ~7 KB | Review - Consider for future brick types |
| `element_blue_rectangle_glossy.png` | ~8 KB | Review - Consider for future brick types |
| `element_green_rectangle_glossy.png` | ~8 KB | Review - Consider for future brick types |
| `element_grey_rectangle.png` | ~7 KB | Review - Consider for future brick types |
| `element_grey_rectangle_glossy.png` | ~7 KB | Review - Consider for future brick types |
| `element_purple_rectangle.png` | ~7 KB | Review - Consider for future brick types |
| `element_purple_rectangle_glossy.png` | ~8 KB | Review - Consider for future brick types |
| `element_red_rectangle.png` | ~7 KB | Review - Consider for future brick types |
| `element_red_rectangle_glossy.png` | ~8 KB | Review - Consider for future brick types |
| `element_yellow_rectangle.png` | ~7 KB | Review - Consider for future brick types |
| `element_yellow_rectangle_glossy.png` | ~8 KB | Review - Consider for future brick types |

### Unused Variants
| Asset | Size | Recommendation |
|-------|------|----------------|
| `element_purple_cube_glossy.png` | ~9 KB | Delete - Cube variant not used (only diamond is used) |

---

## 2. Paddle Graphics (1 unused)

Location: `assets/graphics/paddles/`

| Asset | Size | Recommendation |
|-------|------|----------------|
| `paddleRed.png` | ~9 KB | Review - Could be used for alternate paddle skins or player 2 |

---

## 3. Powerup Graphics (7 unused)

Location: `assets/graphics/powerups/`

Unused assets stored alongside active powerup graphics. Usage tracked in agent documentation.

| Asset | Size | Status |
|-------|------|--------|
| `attract.png` | ~4 KB | Keep - Future: Attract power-up |
| `bine.png` | ~4 KB | Keep - Future: Multi-ball variant |
| `powerups.jpg` | ~150 KB | Keep - Source sheet |
| `powerups-transparent.png` | ~80 KB | Keep - Source sheet (transparent) |
| `shield.png` | ~5 KB | Keep - Future: Shield power-up |
| `shockwave.png` | ~5 KB | Keep - Future: Area damage power-up |
| `warp.png` | ~4 KB | Keep - Future: Teleport power-up |

**Note**: `arrow_down_right.png` is now in use for Force Arrow tiles (Advanced Tile Elements feature).

---

## 4. Audio SFX (0 unused)

Location: `assets/audio/sfx/`

All audio SFX files are now in use.

**Note**: `bzzrt.mp3` is now used for Force Arrow field effects (Advanced Tile Elements feature).

---

## Potential Cleanup Actions

### Safe to Delete
- `element_purple_cube_glossy.png` - No references, cube variant not planned

### Review Recommended
- **Rectangle brick variants** - Consider if these will be used for new brick types
- **paddleRed.png** - Decide if alternate paddle colors are planned

### Keep (Future Use)
- Unused powerup assets in `powerups/` folder - Documented for future features
- `bricks.svg` - Source file

---

*Last updated: February 13, 2026*
