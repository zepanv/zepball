class_name EditorGridHelper
extends RefCounted

func _reindex_levels(levels: Array) -> void:
	for idx in range(levels.size()):
		if not (levels[idx] is Dictionary):
			continue
		var level_data: Dictionary = levels[idx]
		level_data["level_index"] = idx
		levels[idx] = level_data

func _get_direction_label(direction: int) -> String:
	match direction:
		0:
			return "Right (0)"
		45:
			return "Down-Right (45)"
		90:
			return "Down (90)"
		135:
			return "Down-Left (135)"
		180:
			return "Left (180)"
		225:
			return "Up-Left (225)"
		270:
			return "Up (270)"
		315:
			return "Up-Right (315)"
		_:
			return "Right (0)"

func _get_direction_marker(direction: int) -> String:
	match direction:
		0:
			return "R"
		45:
			return "DR"
		90:
			return "D"
		135:
			return "DL"
		180:
			return "L"
		225:
			return "UL"
		270:
			return "U"
		315:
			return "UR"
		_:
			return "R"

func _get_powerup_abbreviation(powerup_type: String) -> String:
	var normalized: String = powerup_type.strip_edges().to_upper()
	match normalized:
		"TRIPLE_BALL":
			return "TB"
		"EXTRA_LIFE":
			return "XL"
		"SPEED_UP":
			return "SU"
		"SLOW_DOWN":
			return "SD"
		"BIG_BALL":
			return "BB"
		"SMALL_BALL":
			return "SB"
		"BRICK_THROUGH":
			return "BT"
		"DOUBLE_SCORE":
			return "DS"
		"BOMB_BALL":
			return "BO"
		"AIR_BALL":
			return "AB"
		_:
			return normalized.substr(0, min(2, normalized.length()))

func _get_grid_limits_for_play_area(parent: Node, _grid: Dictionary) -> Dictionary:
	return {
		"max_rows": parent.MAX_PLAYABLE_ROWS,
		"max_cols": parent.MAX_PLAYABLE_COLS
	}

func _normalize_level_to_play_area(parent: Node, level_data: Dictionary) -> Dictionary:
	if level_data.is_empty():
		return level_data
	var output: Dictionary = level_data.duplicate(true)
	var grid: Dictionary = output.get("grid", {}).duplicate(true)
	var max_rows: int = parent.MAX_PLAYABLE_ROWS
	var max_cols: int = parent.MAX_PLAYABLE_COLS
	var rows: int = clampi(int(grid.get("rows", parent.DEFAULT_ROWS)), 1, max_rows)
	var cols: int = clampi(int(grid.get("cols", parent.DEFAULT_COLS)), 1, max_cols)
	grid["rows"] = rows
	grid["cols"] = cols
	output["grid"] = grid

	var bricks: Array = output.get("bricks", [])
	var filtered: Array = []
	for brick_variant in bricks:
		if not (brick_variant is Dictionary):
			continue
		var brick_data: Dictionary = brick_variant
		var row: int = int(brick_data.get("row", -1))
		var col: int = int(brick_data.get("col", -1))
		if row >= 0 and row < rows and col >= 0 and col < cols:
			var normalized_brick: Dictionary = {
				"row": row,
				"col": col,
				"type": str(brick_data.get("type", "NORMAL"))
			}
			if normalized_brick["type"] == "FORCE_ARROW":
				var direction: int = int(brick_data.get("direction", 45))
				normalized_brick["direction"] = direction if parent.FORCE_ARROW_DIRECTIONS.has(direction) else 45
			elif normalized_brick["type"] == "POWERUP_BRICK":
				var powerup_type: String = str(brick_data.get("powerup_type", "MYSTERY")).strip_edges().to_upper()
				normalized_brick["powerup_type"] = powerup_type if parent.POWERUP_TYPE_OPTIONS.has(powerup_type) else "MYSTERY"
			filtered.append(normalized_brick)
	output["bricks"] = filtered
	return output

func _refresh_grid(parent: Node) -> void:
	for child in parent.grid_container.get_children():
		child.queue_free()

	var level_data: Dictionary = parent._get_current_level()
	var grid: Dictionary = level_data.get("grid", {})
	var rows: int = int(grid.get("rows", parent.DEFAULT_ROWS))
	var cols: int = int(grid.get("cols", parent.DEFAULT_COLS))
	parent.grid_container.columns = cols

	for row in range(rows):
		for col in range(cols):
			var button: Button = Button.new()
			button.custom_minimum_size = Vector2(32, 22)
			button.text = _get_cell_short_text(parent, row, col)
			button.modulate = _get_cell_color(parent, row, col)
			button.pressed.connect(parent._on_grid_cell_pressed.bind(row, col))
			button.gui_input.connect(parent._on_grid_cell_gui_input.bind(row, col))
			parent.grid_container.add_child(button)

	parent.status_label.text = "Level %d | Grid %dx%d | Bricks %d" % [
		parent.selected_level_index + 1,
		rows,
		cols,
		_get_brick_count(level_data)
	]

func _get_brick_count(level_data: Dictionary) -> int:
	var bricks: Array = level_data.get("bricks", [])
	return bricks.size()

func _get_cell_short_text(parent: Node, row: int, col: int) -> String:
	var brick_data: Dictionary = _get_brick_data_at(parent, row, col)
	var brick_type: String = str(brick_data.get("type", ""))
	if brick_type.is_empty():
		return ""
	if brick_type == "FORCE_ARROW":
		return _get_direction_marker(int(brick_data.get("direction", 45)))
	if brick_type == "POWERUP_BRICK":
		return _get_powerup_abbreviation(str(brick_data.get("powerup_type", "MYSTERY")))
	return brick_type.substr(0, 1)

func _get_cell_color(parent: Node, row: int, col: int) -> Color:
	var brick_type: String = _get_brick_type_at(parent, row, col)
	if brick_type.is_empty():
		return Color(0.16, 0.16, 0.2, 1.0)
	return parent.BRICK_COLORS.get(brick_type, Color.WHITE)

func _get_brick_type_at(parent: Node, row: int, col: int) -> String:
	var brick_data: Dictionary = _get_brick_data_at(parent, row, col)
	return str(brick_data.get("type", ""))

func _get_brick_data_at(parent: Node, row: int, col: int) -> Dictionary:
	var level_data: Dictionary = parent._get_current_level()
	var bricks: Array = level_data.get("bricks", [])
	for brick_variant in bricks:
		if not (brick_variant is Dictionary):
			continue
		var brick_data: Dictionary = brick_variant
		if int(brick_data.get("row", -1)) == row and int(brick_data.get("col", -1)) == col:
			return brick_data
	return {}

func _set_brick_type_at(parent: Node, row: int, col: int, brick_type: String) -> bool:
	var level_data: Dictionary = parent._get_current_level()
	var bricks: Array = level_data.get("bricks", [])
	var index: int = -1

	for idx in range(bricks.size()):
		var brick_variant = bricks[idx]
		if not (brick_variant is Dictionary):
			continue
		var brick_data: Dictionary = brick_variant
		if int(brick_data.get("row", -1)) == row and int(brick_data.get("col", -1)) == col:
			index = idx
			break

	if brick_type.is_empty():
		if index != -1:
			bricks.remove_at(index)
		else:
			return false
	else:
		var entry: Dictionary = {
			"row": row,
			"col": col,
			"type": brick_type
		}
		if brick_type == "FORCE_ARROW":
			entry["direction"] = parent.selected_direction
		elif brick_type == "POWERUP_BRICK":
			entry["powerup_type"] = parent.selected_powerup_type
		if index == -1:
			bricks.append(entry)
		else:
			var existing: Dictionary = bricks[index]
			if existing == entry:
				return false
			bricks[index] = entry

	level_data["bricks"] = bricks
	parent._set_current_level(level_data)
	return true

func _update_grid_size(parent: Node, rows: int, cols: int) -> void:
	var level_data: Dictionary = parent._get_current_level()
	var grid: Dictionary = level_data.get("grid", {})
	var limits: Dictionary = _get_grid_limits_for_play_area(parent, grid)
	rows = clampi(rows, 1, int(limits.get("max_rows", 1)))
	cols = clampi(cols, 1, int(limits.get("max_cols", 1)))
	var current_rows: int = int(grid.get("rows", parent.DEFAULT_ROWS))
	var current_cols: int = int(grid.get("cols", parent.DEFAULT_COLS))
	if current_rows == rows and current_cols == cols:
		return
	parent._push_undo_state()
	grid["rows"] = rows
	grid["cols"] = cols
	level_data["grid"] = grid

	var bricks: Array = level_data.get("bricks", [])
	var filtered: Array = []
	for brick_variant in bricks:
		if not (brick_variant is Dictionary):
			continue
		var brick_data: Dictionary = brick_variant
		var row: int = int(brick_data.get("row", -1))
		var col: int = int(brick_data.get("col", -1))
		if row >= 0 and row < rows and col >= 0 and col < cols:
			filtered.append(brick_data)
	level_data["bricks"] = filtered
	parent._set_current_level(level_data)
	_refresh_grid(parent)
	parent.status_label.text = "Resized grid to %dx%d" % [rows, cols]
