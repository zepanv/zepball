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

- **NORMAL**: 1 hit to break, 10 points (teal color)
- **STRONG**: 2 hits to break, 20 points (pink color)
- **UNBREAKABLE**: Cannot be destroyed (gray color)

## Current Levels

1. **First Contact** - Simple 4x6 grid, all normal bricks
2. **The Wall** - 5x8 grid with strong top row
3. **Checkered Challenge** - Checkerboard pattern with gaps
4. **Diamond Formation** - Diamond shape with strong outer layer
5. **The Fortress** - Large fortress with strong defenses

## Usage

To load a level in code:
```gdscript
var level_data = load_json("res://levels/level_01.json")
# Parse and create bricks based on level_data
```
