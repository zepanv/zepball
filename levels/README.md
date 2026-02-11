# Level Data Format

Legacy `level_XX.json` files were removed after migration completion. This README remains as a format reference.

## Current Source of Truth

The active runtime level format is `.zeppack` loaded by `PackLoader`:
- Built-in packs: `res://packs/`
- User packs: `user://packs/`
- Current built-in packs:
  - `classic-challenge.zeppack` (levels 1-10)
  - `prism-showcase.zeppack` (levels 11-20)
  - `nebula-ascend.zeppack` (levels 21-30)

## `.zeppack` Schema (v1)

```json
{
  "zeppack_version": 1,
  "pack_id": "classic-challenge",
  "name": "Classic Challenge",
  "author": "Zep Ball Team",
  "description": "Master the basics across 10 progressive levels",
  "created_at": "2026-02-10T12:00:00Z",
  "updated_at": "2026-02-10T12:00:00Z",
  "source": "builtin",
  "tags": ["official", "beginner"],
  "levels": [
    {
      "level_index": 0,
      "name": "First Contact",
      "description": "Learn the basics - break all the bricks!",
      "grid": {
        "rows": 10,
        "cols": 6,
        "start_x": 200,
        "start_y": 106,
        "brick_size": 48,
        "spacing": 3
      },
      "bricks": [
        {"row": 0, "col": 0, "type": "NORMAL"}
      ]
    }
  ]
}
```

## Brick Types

Supported brick `type` values:
- `NORMAL`
- `STRONG`
- `UNBREAKABLE`
- `GOLD`
- `RED`
- `BLUE`
- `GREEN`
- `PURPLE`
- `ORANGE`
- `BOMB`
- `DIAMOND`
- `DIAMOND_GLOSSY`
- `POLYGON`
- `POLYGON_GLOSSY`

## Runtime Usage

Runtime loading is pack-native:

```gdscript
var result: Dictionary = PackLoader.instantiate_level(pack_id, level_index, brick_container)
```

Legacy compatibility lookups for integer level/set IDs are provided by `PackLoader` helper methods.

## Notes

- New content should be authored and saved as `.zeppack` via the in-game editor.
- Do not add new `levels/level_XX.json` files.
- Runtime level/set loading is fully pack-native.
