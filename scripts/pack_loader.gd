extends Node

## PackLoader - Autoload singleton for loading .zeppack files
## Provides pack discovery, validation, and level instantiation APIs

const BUILTIN_PACKS_PATH = "res://packs/"
const USER_PACKS_PATH = "user://packs/"
const PACK_EXTENSION = ".zeppack"
const SUPPORTED_PACK_VERSIONS: Array[int] = [1, 2]
const BRICK_SCENE = preload("res://scenes/gameplay/brick.tscn")

const BRICK_TYPE_MAP: Dictionary = {
	"NORMAL": 0,  # BrickType.NORMAL
	"STRONG": 1,  # BrickType.STRONG
	"UNBREAKABLE": 2,  # BrickType.UNBREAKABLE
	"GOLD": 3,  # BrickType.GOLD
	"RED": 4,  # BrickType.RED
	"BLUE": 5,  # BrickType.BLUE
	"GREEN": 6,  # BrickType.GREEN
	"PURPLE": 7,  # BrickType.PURPLE
	"ORANGE": 8,  # BrickType.ORANGE
	"BOMB": 9,  # BrickType.BOMB
	"DIAMOND": 10,  # BrickType.DIAMOND
	"DIAMOND_GLOSSY": 11,  # BrickType.DIAMOND_GLOSSY
	"POLYGON": 12,  # BrickType.POLYGON
	"POLYGON_GLOSSY": 13,  # BrickType.POLYGON_GLOSSY
	"FORCE_ARROW": 14,  # BrickType.FORCE_ARROW
	"POWERUP_BRICK": 15  # BrickType.POWERUP_BRICK
}

const BRICK_BASE_SCORE_MAP: Dictionary = {
	"NORMAL": 10,
	"STRONG": 20,
	"UNBREAKABLE": 0,
	"GOLD": 50,
	"RED": 15,
	"BLUE": 15,
	"GREEN": 15,
	"PURPLE": 25,
	"ORANGE": 20,
	"BOMB": 30,
	"DIAMOND": 15,
	"DIAMOND_GLOSSY": 20,
	"POLYGON": 15,
	"POLYGON_GLOSSY": 20,
	"FORCE_ARROW": 0,
	"POWERUP_BRICK": 0
}

const BRICK_PREVIEW_COLOR_MAP: Dictionary = {
	"NORMAL": Color(0.059, 0.773, 0.627, 1.0),
	"STRONG": Color(0.914, 0.275, 0.376, 1.0),
	"UNBREAKABLE": Color(0.5, 0.5, 0.5, 1.0),
	"GOLD": Color(1.0, 0.843, 0.0, 1.0),
	"RED": Color(1.0, 0.2, 0.2, 1.0),
	"BLUE": Color(0.2, 0.4, 1.0, 1.0),
	"GREEN": Color(0.2, 0.8, 0.2, 1.0),
	"PURPLE": Color(0.6, 0.2, 0.8, 1.0),
	"ORANGE": Color(1.0, 0.5, 0.0, 1.0),
	"BOMB": Color(1.0, 0.3, 0.0, 1.0),
	"DIAMOND": Color(0.2, 0.4, 1.0, 1.0),
	"DIAMOND_GLOSSY": Color(0.2, 0.6, 1.0, 1.0),
	"POLYGON": Color(0.35, 0.7, 1.0, 1.0),
	"POLYGON_GLOSSY": Color(0.55, 0.8, 1.0, 1.0),
	"FORCE_ARROW": Color(1.0, 0.85, 0.3, 1.0),
	"POWERUP_BRICK": Color(0.3, 1.0, 0.45, 1.0)
}
const NON_BREAKABLE_TYPES: Array[String] = ["UNBREAKABLE", "FORCE_ARROW", "POWERUP_BRICK"]
const VALID_FORCE_DIRECTIONS: Array[int] = [0, 45, 90, 135, 180, 225, 270, 315]
const VALID_POWERUP_TYPES: Array[String] = [
	"EXPAND",
	"CONTRACT",
	"SPEED_UP",
	"TRIPLE_BALL",
	"BIG_BALL",
	"SMALL_BALL",
	"SLOW_DOWN",
	"EXTRA_LIFE",
	"GRAB",
	"BRICK_THROUGH",
	"DOUBLE_SCORE",
	"MYSTERY",
	"BOMB_BALL",
	"AIR_BALL",
	"MAGNET",
	"BLOCK"
]

const LEGACY_PACK_ORDER: Array[String] = ["classic-challenge", "prism-showcase", "nebula-ascend"]

var _packs_by_id: Dictionary = {}
var _builtin_pack_ids: Array[String] = []
var _user_pack_ids: Array[String] = []

func _ready() -> void:
	ensure_packs_directory()
	reload_packs()

func ensure_packs_directory() -> void:
	var dir: DirAccess = DirAccess.open("user://")
	if dir == null:
		push_error("PackLoader: failed to open user:// for pack directory setup")
		return
	if not dir.dir_exists("packs"):
		var result: int = dir.make_dir_recursive("packs")
		if result != OK:
			push_error("PackLoader: failed to create user packs directory (%s)" % USER_PACKS_PATH)

func reload_packs() -> void:
	_packs_by_id.clear()
	_builtin_pack_ids.clear()
	_user_pack_ids.clear()

	_load_pack_directory(BUILTIN_PACKS_PATH, true)
	_load_pack_directory(USER_PACKS_PATH, false)

	_builtin_pack_ids.sort_custom(func(a: String, b: String) -> bool:
		return _get_pack_name(a).naturalnocasecmp_to(_get_pack_name(b)) < 0
	)
	_user_pack_ids.sort_custom(func(a: String, b: String) -> bool:
		return _get_pack_name(a).naturalnocasecmp_to(_get_pack_name(b)) < 0
	)

func _load_pack_directory(base_path: String, is_builtin: bool) -> void:
	var files: Array[String] = _list_pack_files(base_path, is_builtin)
	if files.is_empty():
		if is_builtin:
			push_warning("PackLoader: built-in packs directory missing or empty: %s" % base_path)
		return

	for pack_file in files:
		var full_path: String = base_path + pack_file
		var loaded: Dictionary = _load_pack_file(full_path)
		if loaded.is_empty():
			continue

		var pack_id: String = str(loaded.get("pack_id", "")).strip_edges()
		if pack_id.is_empty():
			push_warning("PackLoader: skipping pack without pack_id: %s" % full_path)
			continue

		if _packs_by_id.has(pack_id):
			var existing: Dictionary = _packs_by_id[pack_id]
			var existing_builtin: bool = bool(existing.get("_is_builtin", false))
			if existing_builtin and not is_builtin:
				push_warning("PackLoader: skipping user pack '%s' due to built-in id collision" % pack_id)
				continue
			if is_builtin and not existing_builtin:
				push_warning("PackLoader: replacing user pack with built-in pack for id '%s'" % pack_id)
				_user_pack_ids.erase(pack_id)
			else:
				push_warning("PackLoader: duplicate pack id '%s', skipping file %s" % [pack_id, full_path])
				continue

		loaded["source"] = "builtin" if is_builtin else "user"
		loaded["_is_builtin"] = is_builtin
		loaded["_file_path"] = full_path
		_packs_by_id[pack_id] = loaded
		if is_builtin:
			_builtin_pack_ids.append(pack_id)
		else:
			_user_pack_ids.append(pack_id)

func _list_pack_files(base_path: String, is_builtin: bool) -> Array[String]:
	var files: Array[String] = []
	if is_builtin and ResourceLoader.has_method("list_directory"):
		var resource_files = ResourceLoader.list_directory(base_path.trim_suffix("/"))
		if resource_files != null and resource_files.size() > 0:
			for file_name in resource_files:
				files.append(str(file_name))

	if files.is_empty():
		var dir: DirAccess = DirAccess.open(base_path)
		if dir == null:
			return []
		for file_name in dir.get_files():
			files.append(str(file_name))

	var cleaned: Array[String] = []
	var seen: Dictionary = {}
	for raw_name in files:
		var file_name: String = str(raw_name)
		if file_name.ends_with(".import"):
			file_name = file_name.substr(0, file_name.length() - 7)
		elif file_name.ends_with(".remap"):
			file_name = file_name.substr(0, file_name.length() - 6)
		elif file_name.find(".") == -1:
			var candidate: String = file_name + PACK_EXTENSION
			if FileAccess.file_exists(base_path + candidate):
				file_name = candidate

		if not file_name.to_lower().ends_with(PACK_EXTENSION):
			continue
		if seen.has(file_name):
			continue
		seen[file_name] = true
		cleaned.append(file_name)

	cleaned.sort_custom(func(a: String, b: String) -> bool:
		return a.naturalnocasecmp_to(b) < 0
	)
	return cleaned

func _load_pack_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("PackLoader: failed to open pack: %s" % path)
		return {}

	var json_text: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	if json.parse(json_text) != OK:
		push_warning("PackLoader: failed to parse pack JSON: %s" % path)
		return {}

	var pack_data: Dictionary = json.data if json.data is Dictionary else {}
	if pack_data.is_empty():
		push_warning("PackLoader: pack root is not a dictionary: %s" % path)
		return {}

	var errors: Array[String] = validate_pack(pack_data)
	if not errors.is_empty():
		push_warning("PackLoader: invalid pack %s -> %s" % [path, "; ".join(errors)])
		return {}

	return pack_data

func validate_pack(data: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var zeppack_version: int = int(data.get("zeppack_version", -1))
	if not SUPPORTED_PACK_VERSIONS.has(zeppack_version):
		errors.append("unsupported zeppack_version")

	var pack_id: String = str(data.get("pack_id", "")).strip_edges()
	if pack_id.is_empty():
		errors.append("missing pack_id")

	var pack_name: String = str(data.get("name", "")).strip_edges()
	if pack_name.is_empty():
		errors.append("missing name")

	var levels = data.get("levels", [])
	if not (levels is Array) or levels.is_empty():
		errors.append("missing levels array")
		return errors

	for i in range(levels.size()):
		var level_data = levels[i]
		if not (level_data is Dictionary):
			errors.append("levels[%d] is not an object" % i)
			continue

		var grid = level_data.get("grid", {})
		if not (grid is Dictionary):
			errors.append("levels[%d].grid is missing or invalid" % i)

		var bricks = level_data.get("bricks", [])
		if not (bricks is Array):
			errors.append("levels[%d].bricks is missing or invalid" % i)
			continue

		for j in range(bricks.size()):
			var brick = bricks[j]
			if not (brick is Dictionary):
				errors.append("levels[%d].bricks[%d] is not an object" % [i, j])
				break
			var brick_type: String = str(brick.get("type", ""))
			if not BRICK_TYPE_MAP.has(brick_type):
				errors.append("levels[%d].bricks[%d].type is unknown" % [i, j])
				continue
			if zeppack_version < 2 and (brick_type == "FORCE_ARROW" or brick_type == "POWERUP_BRICK"):
				errors.append("levels[%d].bricks[%d].type requires zeppack_version 2" % [i, j])
				continue
			if zeppack_version >= 2 and brick_type == "FORCE_ARROW":
				var direction: int = int(brick.get("direction", 45))
				if not VALID_FORCE_DIRECTIONS.has(direction):
					errors.append("levels[%d].bricks[%d].direction must be one of 0/45/90/135/180/225/270/315" % [i, j])
			if zeppack_version >= 2 and brick_type == "POWERUP_BRICK":
				var powerup_type: String = str(brick.get("powerup_type", "MYSTERY")).strip_edges().to_upper()
				if not VALID_POWERUP_TYPES.has(powerup_type):
					errors.append("levels[%d].bricks[%d].powerup_type is unknown" % [i, j])

	return errors

func get_all_packs() -> Array[Dictionary]:
	var packs: Array[Dictionary] = []
	for pack_id in _builtin_pack_ids:
		packs.append(get_pack(pack_id))
	for pack_id in _user_pack_ids:
		packs.append(get_pack(pack_id))
	return packs

func get_builtin_packs() -> Array[Dictionary]:
	var packs: Array[Dictionary] = []
	for pack_id in _builtin_pack_ids:
		packs.append(get_pack(pack_id))
	return packs

func get_user_packs() -> Array[Dictionary]:
	var packs: Array[Dictionary] = []
	for pack_id in _user_pack_ids:
		packs.append(get_pack(pack_id))
	return packs

func get_pack(pack_id: String) -> Dictionary:
	var pack_data: Dictionary = _packs_by_id.get(pack_id, {})
	if pack_data.is_empty():
		return {}
	return pack_data.duplicate(true)

func pack_exists(pack_id: String) -> bool:
	return _packs_by_id.has(pack_id)

func get_level_count(pack_id: String) -> int:
	var pack_data: Dictionary = _packs_by_id.get(pack_id, {})
	if pack_data.is_empty():
		return 0
	var levels: Array = pack_data.get("levels", [])
	return levels.size()

func get_level_data(pack_id: String, level_index: int) -> Dictionary:
	var pack_data: Dictionary = _packs_by_id.get(pack_id, {})
	if pack_data.is_empty():
		return {}

	var levels: Array = pack_data.get("levels", [])
	if level_index < 0 or level_index >= levels.size():
		return {}

	var level_data: Dictionary = levels[level_index]
	var copied: Dictionary = level_data.duplicate(true)
	copied["level_index"] = level_index
	return copied

func get_level_info(pack_id: String, level_index: int) -> Dictionary:
	var level_data: Dictionary = get_level_data(pack_id, level_index)
	if level_data.is_empty():
		return {}
	return {
		"pack_id": pack_id,
		"level_index": level_index,
		"name": level_data.get("name", "Unknown Level"),
		"description": level_data.get("description", "")
	}

func instantiate_level(pack_id: String, level_index: int, brick_container: Node2D) -> Dictionary:
	var level_data: Dictionary = get_level_data(pack_id, level_index)
	if level_data.is_empty():
		push_error("PackLoader: cannot instantiate missing level %s:%d" % [pack_id, level_index])
		return {"success": false, "breakable_count": 0}

	for child in brick_container.get_children():
		child.queue_free()

	var grid: Dictionary = level_data.get("grid", {})
	var brick_size: int = int(grid.get("brick_size", 48))
	var spacing: int = int(grid.get("spacing", 3))
	var start_x: int = int(grid.get("start_x", 150))
	var start_y: int = int(grid.get("start_y", 150))
	var bricks_data: Array = level_data.get("bricks", [])

	var breakable_count: int = 0
	for brick_def_variant in bricks_data:
		if not (brick_def_variant is Dictionary):
			continue

		var brick_def: Dictionary = brick_def_variant
		var brick_type_string: String = str(brick_def.get("type", "NORMAL"))
		if not BRICK_TYPE_MAP.has(brick_type_string):
			push_warning("PackLoader: unknown brick type '%s' in %s:%d" % [brick_type_string, pack_id, level_index])
			continue

		var brick = BRICK_SCENE.instantiate()
		var row: int = int(brick_def.get("row", 0))
		var col: int = int(brick_def.get("col", 0))
		brick.position = Vector2(
			start_x + col * (brick_size + spacing),
			start_y + row * (brick_size + spacing)
		)
		brick.brick_type = BRICK_TYPE_MAP[brick_type_string]
		if brick_type_string == "FORCE_ARROW":
			brick.direction = int(brick_def.get("direction", 45))
		elif brick_type_string == "POWERUP_BRICK":
			brick.powerup_type_name = str(brick_def.get("powerup_type", "MYSTERY"))

		brick_container.add_child(brick)
		if not NON_BREAKABLE_TYPES.has(brick_type_string):
			breakable_count += 1

	return {
		"success": true,
		"pack_id": pack_id,
		"level_index": level_index,
		"name": level_data.get("name", "Unknown"),
		"description": level_data.get("description", ""),
		"total_bricks": bricks_data.size(),
		"breakable_count": breakable_count
	}

func get_level_key(pack_id: String, level_index: int) -> String:
	return "%s:%d" % [pack_id, level_index]

func get_level_max_base_score(pack_id: String, level_index: int) -> int:
	var level_data: Dictionary = get_level_data(pack_id, level_index)
	if level_data.is_empty():
		return 0
	var total: int = 0
	var bricks: Array = level_data.get("bricks", [])
	for brick_variant in bricks:
		if not (brick_variant is Dictionary):
			continue
		var brick_def: Dictionary = brick_variant
		var brick_type: String = str(brick_def.get("type", "NORMAL"))
		total += int(BRICK_BASE_SCORE_MAP.get(brick_type, 0))
	return total

func generate_level_preview(pack_id: String, level_index: int, width: int = 120, height: int = 80) -> Texture2D:
	var level_data: Dictionary = get_level_data(pack_id, level_index)
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
		var color: Color = BRICK_PREVIEW_COLOR_MAP.get(brick_type, Color.WHITE)
		var x: int = margin + int(col * cell_w)
		var y: int = margin + int(row * cell_h)
		var w: int = max(1, int(cell_w) - 1)
		var h: int = max(1, int(cell_h) - 1)
		image.fill_rect(Rect2i(x, y, w, h), color)

	var texture: ImageTexture = ImageTexture.create_from_image(image)
	return texture

func save_user_pack(pack_data: Dictionary) -> bool:
	var to_save: Dictionary = pack_data.duplicate(true)
	var errors: Array[String] = validate_pack(to_save)
	if not errors.is_empty():
		push_warning("PackLoader: save rejected due to validation errors: %s" % "; ".join(errors))
		return false

	var pack_id: String = str(to_save.get("pack_id", "")).strip_edges()
	if pack_id.is_empty():
		return false

	to_save["source"] = "user"
	to_save["updated_at"] = Time.get_datetime_string_from_system(true)
	if not to_save.has("created_at"):
		to_save["created_at"] = to_save["updated_at"]

	var path: String = USER_PACKS_PATH + pack_id + PACK_EXTENSION
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("PackLoader: failed to save user pack: %s" % path)
		return false

	file.store_string(JSON.stringify(to_save, "\t"))
	file.close()
	reload_packs()
	return true

func delete_user_pack(pack_id: String) -> bool:
	if not _packs_by_id.has(pack_id):
		return false
	var pack_data: Dictionary = _packs_by_id[pack_id]
	if bool(pack_data.get("_is_builtin", false)):
		push_warning("PackLoader: refusing to delete built-in pack '%s'" % pack_id)
		return false

	var path: String = str(pack_data.get("_file_path", ""))
	if path.is_empty():
		path = USER_PACKS_PATH + pack_id + PACK_EXTENSION

	var result: int = DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if result != OK:
		push_warning("PackLoader: failed to delete user pack '%s'" % pack_id)
		return false

	reload_packs()
	return true

func get_legacy_level_ref(level_id: int) -> Dictionary:
	if level_id <= 0:
		return {}

	var running_start: int = 1
	for legacy_pack_id in LEGACY_PACK_ORDER:
		var count: int = get_level_count(legacy_pack_id)
		if count <= 0:
			continue
		var running_end: int = running_start + count - 1
		if level_id >= running_start and level_id <= running_end:
			return {
				"pack_id": legacy_pack_id,
				"level_index": level_id - running_start
			}
		running_start = running_end + 1

	return {}

func get_legacy_total_level_count() -> int:
	var total: int = 0
	for legacy_pack_id in LEGACY_PACK_ORDER:
		total += get_level_count(legacy_pack_id)
	return total

func get_legacy_level_id(pack_id: String, level_index: int) -> int:
	var running_start: int = 1
	for legacy_pack_id in LEGACY_PACK_ORDER:
		var count: int = get_level_count(legacy_pack_id)
		if legacy_pack_id == pack_id:
			if level_index < 0 or level_index >= count:
				return -1
			return running_start + level_index
		running_start += count
	return -1

func get_all_legacy_sets() -> Array[Dictionary]:
	var sets: Array[Dictionary] = []
	for idx in range(LEGACY_PACK_ORDER.size()):
		var set_id: int = idx + 1
		var set_data: Dictionary = get_legacy_set_data(set_id)
		if not set_data.is_empty():
			sets.append(set_data)
	return sets

func get_legacy_set_data(set_id: int) -> Dictionary:
	if set_id <= 0 or set_id > LEGACY_PACK_ORDER.size():
		return {}
	var pack_id: String = LEGACY_PACK_ORDER[set_id - 1]
	if not pack_exists(pack_id):
		return {}
	var pack: Dictionary = get_pack(pack_id)
	return {
		"set_id": set_id,
		"pack_id": pack_id,
		"name": str(pack.get("name", "Unknown Set")),
		"description": str(pack.get("description", "")),
		"level_ids": get_legacy_set_level_ids(set_id),
		"unlock_condition": "default"
	}

func legacy_set_exists(set_id: int) -> bool:
	return not get_legacy_set_data(set_id).is_empty()

func get_legacy_set_pack_id(set_id: int) -> String:
	if set_id <= 0 or set_id > LEGACY_PACK_ORDER.size():
		return ""
	return LEGACY_PACK_ORDER[set_id - 1]

func get_legacy_set_level_ids(set_id: int) -> Array:
	var pack_id: String = get_legacy_set_pack_id(set_id)
	if pack_id.is_empty():
		return []
	var ids: Array[int] = []
	var level_count: int = get_level_count(pack_id)
	for level_index in range(level_count):
		var legacy_level_id: int = get_legacy_level_id(pack_id, level_index)
		if legacy_level_id != -1:
			ids.append(legacy_level_id)
	return ids

func get_legacy_set_name(set_id: int) -> String:
	var set_data: Dictionary = get_legacy_set_data(set_id)
	return str(set_data.get("name", "Unknown Set"))

func get_legacy_set_description(set_id: int) -> String:
	var set_data: Dictionary = get_legacy_set_data(set_id)
	return str(set_data.get("description", ""))

func get_legacy_set_id_for_pack(pack_id: String) -> int:
	for idx in range(LEGACY_PACK_ORDER.size()):
		if LEGACY_PACK_ORDER[idx] == pack_id:
			return idx + 1
	return -1

func _get_pack_name(pack_id: String) -> String:
	var pack_data: Dictionary = _packs_by_id.get(pack_id, {})
	return str(pack_data.get("name", pack_id))
