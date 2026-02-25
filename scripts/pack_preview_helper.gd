class_name PackPreviewHelper
extends RefCounted

func generate_level_preview(parent: Node, pack_id: String, level_index: int, width: int = 120, height: int = 80) -> Texture2D:
	var level_data: Dictionary = parent.get_level_data(pack_id, level_index)
	if level_data.is_empty():
		return null

	var image: Image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.06, 0.07, 0.1, 1.0))

	var grid: Dictionary = level_data.get("grid", {})
	var rows: int = max(1, int(grid.get("rows", 1)))
	var cols: int = max(1, int(grid.get("cols", 1)))
	var margin: int = 4
	var draw_w: int = max(1, width - margin * 2)
	var draw_h: int = max(1, height - margin * 2)
	var cell_w: float = max(1.0, float(draw_w) / float(cols))
	var cell_h: float = max(1.0, float(draw_h) / float(rows))

	var bricks: Array = level_data.get("bricks", [])
	for brick_variant in bricks:
		if not (brick_variant is Dictionary):
			continue
		var brick_def: Dictionary = brick_variant
		var row: int = int(brick_def.get("row", -1))
		var col: int = int(brick_def.get("col", -1))
		if row < 0 or col < 0 or row >= rows or col >= cols:
			continue
		var brick_type: String = str(brick_def.get("type", "NORMAL"))
		var color: Color = parent.BRICK_PREVIEW_COLOR_MAP.get(brick_type, Color.WHITE)
		var x: int = margin + int(col * cell_w)
		var y: int = margin + int(row * cell_h)
		var w: int = max(1, int(cell_w) - 1)
		var h: int = max(1, int(cell_h) - 1)
		image.fill_rect(Rect2i(x, y, w, h), color)

	var texture: ImageTexture = ImageTexture.create_from_image(image)
	return texture
