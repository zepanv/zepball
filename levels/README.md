# Level Data Format

This folder contains level data files in JSON format. Each level defines the brick layout and metadata for a single playable level.

## File Naming Convention
- `level_01.json` - Level 1
- `level_02.json` - Level 2
- etc.

## JSON Schema

```json
{
  "level_id": 1,                    // Numeric ID for the level
  "name": "Level Name",             // Display name
  "description": "Level description", // Short description of the level
  "grid": {
    "rows": 5,                      // Number of rows in the grid
    "cols": 8,                      // Number of columns in the grid
    "start_x": 150,                 // X position of top-left brick
    "start_y": 150,                 // Y position of top-left brick
    "brick_size": 48,               // Size of each brick (pixels)
    "spacing": 3                    // Gap between bricks (pixels)
  },
  "bricks": [
    {
      "row": 0,                     // Row position (0-indexed)
      "col": 0,                     // Column position (0-indexed)
      "type": "NORMAL"              // Brick type: "NORMAL", "STRONG", or "UNBREAKABLE"
    }
    // ... more bricks
  ]
}
```

## Brick Types

- **NORMAL**: 1 hit to break, 10 points (green square)
- **STRONG**: 2 hits to break, 20 points (red glossy square)
- **UNBREAKABLE**: Cannot be destroyed (gray square)
- **GOLD**: 1 hit to break, 50 points (yellow glossy square)
- **RED / BLUE / GREEN**: 1 hit to break, 15 points (colored squares)
- **PURPLE**: 2 hits to break, 25 points (purple square)
- **ORANGE**: 1 hit to break, 20 points (yellow square)
- **BOMB**: 1 hit to break, 30 points (explodes nearby bricks)
- **DIAMOND**: 1 hit to break, 15 points (random color diamond)
- **DIAMOND_GLOSSY**: 2 hits to break, 20 points (random color diamond)
- **POLYGON**: 1 hit to break, 15 points (random color pentagon)
- **POLYGON_GLOSSY**: 2 hits to break, 20 points (random color pentagon)

## Current Levels

1. **level_01** - First Contact
2. **level_02** - The Wall
3. **level_03** - Checkered Challenge
4. **level_04** - Diamond Formation
5. **level_05** - The Fortress
6. **level_06** - Diamond Formation
7. **level_07** - Fortress
8. **level_08** - Pyramid of Power
9. **level_09** - Corridors
10. **level_10** - The Gauntlet
11. **level_11** - Facet Bloom
12. **level_12** - Crown Circuit
13. **level_13** - Stellar Kite
14. **level_14** - Gilded Steps
15. **level_15** - Prism Lattice
16. **level_16** - Orbitals
17. **level_17** - Shard Lanes
18. **level_18** - Crystal Gate
19. **level_19** - Prism V
20. **level_20** - Aurora Array

## Usage

To load a level in code:
```gdscript
var level_data = load_json("res://levels/level_01.json")
# Parse and create bricks based on level_data
```
