extends RefCounted
class_name SurvivalGenerator

const BRICK_SIZE = 48
const BRICK_SPACING = 3
const START_X = 150
const START_Y = 120
const GRID_ROWS = 9
const GRID_COLS = 20

const WAVE_ONE_BRICK_COUNT = 10
const BRICK_COUNT_STEP = 2
const MAX_BREAKABLE_BRICKS = 48

const SPEED_STEP_INTERVAL_WAVES = 3
const SPEED_STEP_SIZE = 50.0
const SPEED_CAP_MULTIPLIER = 3.0

const INDESTRUCTIBLE_START_WAVE = 5
const INDESTRUCTIBLE_INTERVAL = 4
const INDESTRUCTIBLE_MAX = 6

const TIER0_TYPES = ["NORMAL", "RED", "BLUE", "GREEN"]
const TIER1_TYPES = ["STRONG", "PURPLE", "DIAMOND", "POLYGON"]
const TIER2_TYPES = ["GOLD", "ORANGE", "POWERUP_BRICK"]
const TIER3_TYPES = ["BOMB", "DIAMOND_GLOSSY", "POLYGON_GLOSSY"]
const TIER4_TYPES = ["NORMAL", "STRONG", "GOLD", "RED", "BLUE", "GREEN", "PURPLE", "ORANGE", "BOMB", "DIAMOND", "DIAMOND_GLOSSY", "POLYGON", "POLYGON_GLOSSY", "POWERUP_BRICK"]
const BLITZ_ROW_MIN_BRICKS = 3
const BLITZ_ROW_MAX_BRICKS = 8
const BLITZ_INITIAL_COLUMNS_MIN = 2
const BLITZ_INITIAL_COLUMNS_MAX = 3

const POWERUP_BRICK_TYPES = [
	"EXPAND", "CONTRACT", "SPEED_UP", "TRIPLE_BALL", "BIG_BALL", "SMALL_BALL",
	"SLOW_DOWN", "EXTRA_LIFE", "GRAB", "BRICK_THROUGH", "DOUBLE_SCORE",
	"MYSTERY", "BOMB_BALL", "AIR_BALL", "MAGNET", "BLOCK"
]

static func generate_wave(wave_number: int) -> Dictionary:
	var wave: int = wave_number if wave_number > 1 else 1
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	var tier = _tier_for_wave(wave)
	var target_breakables: int = min(WAVE_ONE_BRICK_COUNT + ((wave - 1) * BRICK_COUNT_STEP), MAX_BREAKABLE_BRICKS)
	var cells = _build_pattern_cells(wave, tier, target_breakables, rng)

	var occupied: Dictionary = {}
	var bricks: Array = []

	for cell in cells:
		var row = int(cell.x)
		var col = int(cell.y)
		var key = "%d:%d" % [row, col]
		if occupied.has(key):
			continue
		occupied[key] = true

		var brick_type = _pick_breakable_type(tier, wave, rng)
		var brick_entry = {
			"row": row,
			"col": col,
			"type": brick_type
		}
		if brick_type == "POWERUP_BRICK":
			brick_entry["powerup_type"] = POWERUP_BRICK_TYPES[rng.randi_range(0, POWERUP_BRICK_TYPES.size() - 1)]
		bricks.append(brick_entry)

	for unbreakable_cell in _pick_unbreakable_cells(wave, occupied, rng):
		bricks.append({
			"row": int(unbreakable_cell.x),
			"col": int(unbreakable_cell.y),
			"type": "UNBREAKABLE"
		})

	return {
		"name": "Wave %d" % wave,
		"description": "Survive as long as possible.",
		"grid": {
			"brick_size": BRICK_SIZE,
			"spacing": BRICK_SPACING,
			"start_x": START_X,
			"start_y": START_Y
		},
		"bricks": bricks
	}

static func get_speed_for_wave(wave_number: int, wave_one_speed: float) -> float:
	var wave: int = wave_number if wave_number > 1 else 1
	var steps: int = int(floor(float(wave - 1) / float(SPEED_STEP_INTERVAL_WAVES)))
	var stepped_speed = wave_one_speed + (SPEED_STEP_SIZE * float(steps))
	return min(stepped_speed, wave_one_speed * SPEED_CAP_MULTIPLIER)

static func generate_blitz_initial(rng: RandomNumberGenerator, grid_rows: int = GRID_ROWS) -> Array:
	var initial_columns: int = rng.randi_range(BLITZ_INITIAL_COLUMNS_MIN, BLITZ_INITIAL_COLUMNS_MAX)
	var generated_columns: Array = []
	for column_index in range(initial_columns):
		generated_columns.append(generate_blitz_row(column_index + 1, rng, grid_rows))
	return generated_columns

static func generate_blitz_row(row_number: int, rng: RandomNumberGenerator, grid_rows: int = GRID_ROWS) -> Array:
	var wave: int = max(1, row_number)
	var tier: int = _tier_for_wave(wave)
	var blitz_rows: int = max(1, grid_rows)
	var candidates: Array[int] = []
	for row_index in range(blitz_rows):
		candidates.append(row_index)

	candidates.shuffle()
	var target_count: int = clampi(
		BLITZ_ROW_MIN_BRICKS + int(floor(float(wave - 1) / 3.0)),
		BLITZ_ROW_MIN_BRICKS,
		BLITZ_ROW_MAX_BRICKS
	)
	target_count = min(target_count, candidates.size())

	var entries: Array = []
	for index in range(target_count):
		var row_slot: int = int(candidates[index])
		var brick_type: String = _pick_breakable_type(tier, wave, rng)
		var entry: Dictionary = {
			"row": row_slot,
			"type": brick_type
		}
		if brick_type == "POWERUP_BRICK":
			entry["powerup_type"] = POWERUP_BRICK_TYPES[rng.randi_range(0, POWERUP_BRICK_TYPES.size() - 1)]
		entries.append(entry)
	return entries

static func _tier_for_wave(wave: int) -> int:
	if wave <= 2:
		return 0
	if wave <= 4:
		return 1
	if wave <= 8:
		return 2
	if wave <= 12:
		return 3
	return 4

static func _build_pattern_cells(wave: int, tier: int, target_count: int, rng: RandomNumberGenerator) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var max_row = 7 if tier == 0 else 8
	# Safe zone shrinks from 5 cols at wave 1 to 0 by wave 6, keeping early bricks away from the paddle.
	var safe_cols = clampi(6 - wave, 0, 5)

	# Base scatter keeps early waves sparse and readable.
	while cells.size() < min(target_count, 8 + (tier * 2)):
		_try_add_cell(cells, Vector2i(rng.randi_range(0, max_row), rng.randi_range(1, GRID_COLS - 2 - safe_cols)))

	if tier >= 1:
		_add_rectangle_cluster(cells, Vector2i(rng.randi_range(2, 4), rng.randi_range(6, 12)), 2, 3)
	if tier >= 2:
		_add_hollow_ring(cells, Vector2i(rng.randi_range(2, 4), rng.randi_range(7, 11)), 2, 3)
	if tier >= 3:
		_add_l_shape(cells, Vector2i(rng.randi_range(1, 4), rng.randi_range(4, 13)), 4, 5)
	if tier >= 4:
		_add_diagonal_band(cells, rng.randi_range(1, 3), rng.randi_range(3, 9), 8)

	while cells.size() < target_count:
		_try_add_cell(cells, Vector2i(rng.randi_range(0, max_row), rng.randi_range(1, GRID_COLS - 2 - safe_cols)))

	if cells.size() > target_count:
		cells = cells.slice(0, target_count)

	return cells

static func _pick_breakable_type(tier: int, wave: int, rng: RandomNumberGenerator) -> String:
	var pool: Array = []
	pool.append_array(TIER0_TYPES)
	if tier >= 1:
		pool.append_array(TIER1_TYPES)
	if tier >= 2:
		pool.append_array(TIER2_TYPES)
	if tier >= 3:
		pool.append_array(TIER3_TYPES)
	if tier >= 4:
		pool = TIER4_TYPES.duplicate()

	# Bias special bricks in later tiers.
	if tier >= 2 and wave % 2 == 0:
		pool.append("POWERUP_BRICK")
	if tier >= 3 and wave % 3 == 0:
		pool.append("BOMB")

	return str(pool[rng.randi_range(0, pool.size() - 1)])

static func _pick_unbreakable_cells(wave: int, occupied: Dictionary, rng: RandomNumberGenerator) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if wave < INDESTRUCTIBLE_START_WAVE:
		return result

	var count: int = 1 + int(floor(float(wave - INDESTRUCTIBLE_START_WAVE) / float(INDESTRUCTIBLE_INTERVAL)))
	count = min(count, INDESTRUCTIBLE_MAX)

	var attempts = 0
	while result.size() < count and attempts < 200:
		attempts += 1
		var row = rng.randi_range(0, 4)
		var col = rng.randi_range(2, GRID_COLS - 3)
		var key = "%d:%d" % [row, col]
		if occupied.has(key):
			continue
		occupied[key] = true
		result.append(Vector2i(row, col))

	return result

static func _try_add_cell(cells: Array[Vector2i], cell: Vector2i) -> void:
	if cell.x < 0 or cell.x >= GRID_ROWS:
		return
	if cell.y < 0 or cell.y >= GRID_COLS:
		return
	if not cells.has(cell):
		cells.append(cell)

static func _add_rectangle_cluster(cells: Array[Vector2i], center: Vector2i, half_h: int, half_w: int) -> void:
	for row in range(center.x - half_h, center.x + half_h + 1):
		for col in range(center.y - half_w, center.y + half_w + 1):
			_try_add_cell(cells, Vector2i(row, col))

static func _add_hollow_ring(cells: Array[Vector2i], center: Vector2i, half_h: int, half_w: int) -> void:
	for row in range(center.x - half_h, center.x + half_h + 1):
		for col in range(center.y - half_w, center.y + half_w + 1):
			if row == center.x - half_h or row == center.x + half_h or col == center.y - half_w or col == center.y + half_w:
				_try_add_cell(cells, Vector2i(row, col))

static func _add_l_shape(cells: Array[Vector2i], origin: Vector2i, h: int, w: int) -> void:
	for row in range(origin.x, origin.x + h):
		_try_add_cell(cells, Vector2i(row, origin.y))
	for col in range(origin.y, origin.y + w):
		_try_add_cell(cells, Vector2i(origin.x + h - 1, col))

static func _add_diagonal_band(cells: Array[Vector2i], start_row: int, start_col: int, band_length: int) -> void:
	for idx in range(band_length):
		_try_add_cell(cells, Vector2i(start_row + idx % 4, start_col + idx))
		_try_add_cell(cells, Vector2i(start_row + idx % 4 + 1, start_col + idx))
