extends Node

## LevelLoader - Autoload singleton for loading levels from JSON
## Parses level data files and provides level information

const LEVELS_PATH = "res://levels/"
const BRICK_SCENE = preload("res://scenes/gameplay/brick.tscn")

# Cache loaded level data
var level_cache = {}

# Brick type mapping from string to enum
var brick_type_map = {
	"NORMAL": 0,     # BrickType.NORMAL
	"STRONG": 1,     # BrickType.STRONG
	"UNBREAKABLE": 2, # BrickType.UNBREAKABLE
	"GOLD": 3,       # BrickType.GOLD
	"RED": 4,        # BrickType.RED
	"BLUE": 5,       # BrickType.BLUE
	"GREEN": 6,      # BrickType.GREEN
	"PURPLE": 7,     # BrickType.PURPLE
	"ORANGE": 8,     # BrickType.ORANGE
	"BOMB": 9,        # BrickType.BOMB
	"DIAMOND": 10,        # BrickType.DIAMOND
	"DIAMOND_GLOSSY": 11, # BrickType.DIAMOND_GLOSSY
	"POLYGON": 12,        # BrickType.POLYGON
	"POLYGON_GLOSSY": 13  # BrickType.POLYGON_GLOSSY
}

func _ready():
	"""Initialize level loader"""
	preload_all_levels()

func preload_all_levels() -> void:
	"""Preload all level JSON files into cache"""
	var total_levels = get_total_level_count()
	for i in range(1, total_levels + 1):
		var level_data = load_level_data(i)
		if level_data:
			level_cache[i] = level_data

func get_total_level_count() -> int:
	"""Get the total number of levels available"""
	# Count level files in the levels directory
	var dir = DirAccess.open(LEVELS_PATH)
	if dir == null:
		push_error("Failed to open levels directory: " + LEVELS_PATH)
		return 0

	var count = 0
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			count += 1
		file_name = dir.get_next()
	dir.list_dir_end()

	return count

func load_level_data(level_id: int) -> Dictionary:
	"""Load level data from JSON file"""
	# Check cache first
	if level_cache.has(level_id):
		return level_cache[level_id]

	var file_path = LEVELS_PATH + "level_%02d.json" % level_id

	if not FileAccess.file_exists(file_path):
		push_error("Level file not found: " + file_path)
		level_cache[level_id] = {}
		return {}

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open level file: " + file_path)
		level_cache[level_id] = {}
		return {}

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		push_error("Failed to parse level JSON: " + file_path)
		level_cache[level_id] = {}
		return {}

	var level_data = json.data
	level_cache[level_id] = level_data
	return level_data

func get_level_info(level_id: int) -> Dictionary:
	"""Get level metadata (name, description) without loading full level"""
	var level_data = load_level_data(level_id)
	if level_data.is_empty():
		return {}

	return {
		"level_id": level_data.get("level_id", level_id),
		"name": level_data.get("name", "Unknown Level"),
		"description": level_data.get("description", "")
	}

func instantiate_level(level_id: int, brick_container: Node2D) -> Dictionary:
	"""Load a level and instantiate all bricks into the provided container
	Returns: Dictionary with level info and brick count"""

	var level_data = load_level_data(level_id)
	if level_data.is_empty():
		push_error("Cannot instantiate level ", level_id, " - data not found")
		return {"success": false, "breakable_count": 0}

	# Clear existing bricks
	for child in brick_container.get_children():
		child.queue_free()

	# Get grid configuration
	var grid = level_data.get("grid", {})
	var brick_size = grid.get("brick_size", 48)
	var spacing = grid.get("spacing", 3)
	var start_x = grid.get("start_x", 150)
	var start_y = grid.get("start_y", 150)

	# Get bricks array
	var bricks_data = level_data.get("bricks", [])
	if bricks_data.is_empty():
		push_warning("Level ", level_id, " has no bricks defined")

	# Instantiate bricks
	var breakable_count = 0
	for brick_def in bricks_data:
		var brick = BRICK_SCENE.instantiate()

		# Position brick based on row/col
		var row = brick_def.get("row", 0)
		var col = brick_def.get("col", 0)
		brick.position = Vector2(
			start_x + col * (brick_size + spacing),
			start_y + row * (brick_size + spacing)
		)

		# Set brick type
		var brick_type_string = brick_def.get("type", "NORMAL")
		if brick_type_map.has(brick_type_string):
			brick.brick_type = brick_type_map[brick_type_string]
		else:
			push_warning("Unknown brick type: ", brick_type_string, " - defaulting to NORMAL")
			brick.brick_type = 0  # NORMAL

		# Add to container
		brick_container.add_child(brick)

		# Count breakable bricks (not UNBREAKABLE)
		if brick.brick_type != 2:  # Not UNBREAKABLE
			breakable_count += 1

	return {
		"success": true,
		"level_id": level_id,
		"name": level_data.get("name", "Unknown"),
		"description": level_data.get("description", ""),
		"total_bricks": bricks_data.size(),
		"breakable_count": breakable_count
	}

func level_exists(level_id: int) -> bool:
	"""Check if a level file exists"""
	var file_path = LEVELS_PATH + "level_%02d.json" % level_id
	return FileAccess.file_exists(file_path)

func get_next_level_id(current_level_id: int) -> int:
	"""Get the next level ID, or -1 if no more levels"""
	var next_id = current_level_id + 1
	if level_exists(next_id):
		return next_id
	return -1

func has_next_level(current_level_id: int) -> bool:
	"""Check if there's a level after the current one"""
	return get_next_level_id(current_level_id) != -1
