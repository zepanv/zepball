class_name MainBlitzHelper
extends RefCounted

const BLITZ_PUSH_TIMER_NAME = "BlitzPushTimer"
const BLITZ_PACK_ID = "__blitz__"
const BLITZ_START_INTERVAL_EASY = 18.0
const BLITZ_START_INTERVAL_NORMAL = 16.0
const BLITZ_START_INTERVAL_HARD = 14.0
const BLITZ_INTERVAL_STEP = 1.0
const BLITZ_INTERVAL_STEP_PUSHES = 4
const BLITZ_INTERVAL_FLOOR = 8.0
const BLITZ_PADDLE_ZONE_BUFFER = 8.0
const BRICK_TYPE_POWERUP_BRICK = 15
const BALL_MAX_VERTICAL_ANGLE_FALLBACK = 0.8
const BALL_SPIN_DECAY_FALLBACK = 0.5
const BLITZ_ALL_CLEAR_BONUS_POINTS = 300
const LEFT_WALL_HALF_WIDTH_FALLBACK = 10.0
const WALL_HALF_HEIGHT_FALLBACK = 10.0
const DEFAULT_BLITZ_GRID_ROWS = 9

var blitz_speed_multiplier: float = 1.0  # Current external speed multiplier (mirrors survival_helper pattern)
var _push_timer: Timer = null
var _push_count: int = 0
var _rows_spawned: int = 0

func get_rows_spawned() -> int:
	return _rows_spawned
var _rows_survived: int = 0
var _current_push_interval: float = BLITZ_START_INTERVAL_NORMAL
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _parent_ref: Node = null
var _all_clear_bonus_awarded_for_cycle: bool = false
var _blitz_grid_rows: int = DEFAULT_BLITZ_GRID_ROWS
var _blitz_top_row_y: float = 0.0

func _init() -> void:
	_rng.randomize()

func _start_blitz_run(parent: Node) -> void:
	_parent_ref = parent
	_push_count = 0
	_rows_spawned = 0
	_rows_survived = 0
	_current_push_interval = _get_start_interval()
	_all_clear_bonus_awarded_for_cycle = false
	_blitz_grid_rows = DEFAULT_BLITZ_GRID_ROWS
	_blitz_top_row_y = float(parent.LEVEL_START_Y)
	MenuController.blitz_rows_survived = _rows_survived

	_ensure_push_timer(parent)
	_configure_blitz_playfield_geometry(parent)
	_clear_level_bricks(parent)
	_spawn_initial_columns(parent)
	parent.connect_brick_signals()

	var primary_ball: Node = null
	if parent.has_method("ensure_primary_ball"):
		primary_ball = parent.ensure_primary_ball()
	elif parent.ball and is_instance_valid(parent.ball):
		primary_ball = parent.ball
	if primary_ball and primary_ball.has_method("reset_ball"):
		primary_ball.reset_ball()
	_apply_blitz_speed_step(parent)

	if parent.game_manager:
		parent.game_manager.current_level = 1
		parent.game_manager.current_pack_id = BLITZ_PACK_ID
		parent.game_manager.current_level_index = 0
		parent.game_manager.current_level_key = "%s:%d" % [BLITZ_PACK_ID, 0]
		parent.game_manager.set_state(parent.game_manager.GameState.READY)

	if parent.hud and parent.hud.has_method("_configure_topbar_mode"):
		parent.hud._configure_topbar_mode()
	_update_hud_status(parent)
	_start_push_timer()

func _process_blitz(parent: Node, _delta: float) -> void:
	if not parent.is_blitz_mode:
		return
	_check_all_clear_bonus(parent)
	_update_hud_status(parent)

func _ensure_push_timer(parent: Node) -> void:
	if _push_timer and is_instance_valid(_push_timer):
		return

	var existing: Node = parent.get_node_or_null(BLITZ_PUSH_TIMER_NAME)
	if existing and existing is Timer:
		_push_timer = existing as Timer
	else:
		_push_timer = Timer.new()
		_push_timer.name = BLITZ_PUSH_TIMER_NAME
		_push_timer.one_shot = true
		_push_timer.process_mode = Node.PROCESS_MODE_PAUSABLE
		parent.add_child(_push_timer)

	if not _push_timer.timeout.is_connected(_on_push_timer_timeout):
		_push_timer.timeout.connect(_on_push_timer_timeout)

func _start_push_timer() -> void:
	if _push_timer == null or not is_instance_valid(_push_timer):
		return
	_all_clear_bonus_awarded_for_cycle = false
	_push_timer.start(_current_push_interval)

func _on_push_timer_timeout() -> void:
	if _parent_ref == null or not is_instance_valid(_parent_ref):
		return
	var parent: Node = _parent_ref
	if not parent.is_blitz_mode:
		return
	if parent.game_manager and parent.game_manager.game_state == parent.game_manager.GameState.GAME_OVER:
		return
	_push_bricks_forward(parent)

func _push_bricks_forward(parent: Node) -> void:
	var step_x: float = float(parent.BRICK_SIZE + parent.BRICK_SPACING)
	var moved_bricks: Array[Node] = []
	for brick in parent.get_cached_level_bricks():
		if not is_instance_valid(brick) or brick.is_queued_for_deletion():
			continue
		if brick.is_in_group("block_brick"):
			continue
		brick.position.x += step_x
		moved_bricks.append(brick)

	_rows_spawned += 1
	var row_entries: Array = parent.SURVIVAL_GENERATOR_SCRIPT.generate_blitz_row(_rows_spawned, _rng, _blitz_grid_rows)
	var spawned_bricks: Array[Node] = _spawn_blitz_column(parent, 0, row_entries)
	parent.connect_brick_signals()

	for brick in moved_bricks:
		_resolve_ball_overlap_for_brick(parent, brick)
	for brick in spawned_bricks:
		_resolve_ball_overlap_for_brick(parent, brick)

	_push_count += 1
	_rows_survived = _push_count
	MenuController.blitz_rows_survived = _rows_survived
	_apply_blitz_speed_step(parent)

	if _check_paddle_zone_occupied(parent):
		_trigger_blitz_game_over(parent)
		_update_hud_status(parent)
		return

	_recalculate_push_interval()
	_start_push_timer()
	if parent.hud and parent.hud.has_method("_configure_topbar_mode"):
		parent.hud._configure_topbar_mode()
	_update_hud_status(parent)

func _get_start_interval() -> float:
	match DifficultyManager.get_difficulty():
		DifficultyManager.Difficulty.EASY:
			return BLITZ_START_INTERVAL_EASY
		DifficultyManager.Difficulty.HARD:
			return BLITZ_START_INTERVAL_HARD
		_:
			return BLITZ_START_INTERVAL_NORMAL

func _recalculate_push_interval() -> void:
	var reduction_steps: int = int(floor(float(_push_count) / float(BLITZ_INTERVAL_STEP_PUSHES)))
	var target_interval: float = _get_start_interval() - (float(reduction_steps) * BLITZ_INTERVAL_STEP)
	_current_push_interval = max(BLITZ_INTERVAL_FLOOR, target_interval)

func _trigger_blitz_game_over(parent: Node) -> void:
	if parent.game_manager == null:
		MenuController.show_blitz_over(0)
		return
	if parent.game_manager.game_state == parent.game_manager.GameState.GAME_OVER:
		return
	parent.game_manager.set_state(parent.game_manager.GameState.GAME_OVER)
	parent.game_manager.game_over.emit()

func _apply_blitz_speed_step(parent: Node) -> void:
	var wave_one_speed: float = parent.SURVIVAL_BASE_BALL_SPEED * DifficultyManager.get_speed_multiplier()
	var target_speed: float = float(parent.SURVIVAL_GENERATOR_SCRIPT.get_speed_for_wave(_push_count + 1, wave_one_speed))
	var external_multiplier: float = target_speed / wave_one_speed if wave_one_speed > 0.0 else 1.0
	blitz_speed_multiplier = external_multiplier

	for active_ball in parent._get_active_balls():
		if not is_instance_valid(active_ball):
			continue
		if active_ball.has_method("set_external_speed_multiplier"):
			active_ball.set_external_speed_multiplier(external_multiplier)
		else:
			var base_speed_value: Variant = active_ball.get("base_speed")
			if base_speed_value == null:
				continue
			active_ball.base_speed = target_speed
			active_ball.current_speed = target_speed

func _check_paddle_zone_occupied(parent: Node) -> bool:
	if parent.paddle == null or not is_instance_valid(parent.paddle):
		return false

	var paddle_width: float = 32.0
	if parent.has_method("_get_paddle_width"):
		paddle_width = float(parent._get_paddle_width())
	var paddle_left_x: float = parent.paddle.global_position.x - (paddle_width * 0.5)
	var threshold_x: float = paddle_left_x - BLITZ_PADDLE_ZONE_BUFFER
	var brick_half_width: float = float(parent.BRICK_SIZE) * 0.5

	for brick in parent.get_cached_level_bricks():
		if not is_instance_valid(brick) or brick.is_queued_for_deletion():
			continue
		if brick.is_in_group("block_brick"):
			continue
		var brick_right_x: float = brick.global_position.x + brick_half_width
		if brick_right_x >= threshold_x:
			return true
	return false

func _clear_level_bricks(parent: Node) -> void:
	for child in parent.brick_container.get_children():
		if not is_instance_valid(child):
			continue
		parent.brick_container.remove_child(child)
		child.queue_free()

func _spawn_initial_columns(parent: Node) -> void:
	var columns: Array = parent.SURVIVAL_GENERATOR_SCRIPT.generate_blitz_initial(_rng, _blitz_grid_rows)
	for column_index in range(columns.size()):
		_rows_spawned += 1
		var column_entries_variant: Variant = columns[column_index]
		if not (column_entries_variant is Array):
			continue
		var column_entries: Array = column_entries_variant
		_spawn_blitz_column(parent, column_index, column_entries)

func _spawn_blitz_column(parent: Node, col_index: int, row_entries: Array) -> Array[Node]:
	var spawned: Array[Node] = []
	var step: float = float(parent.BRICK_SIZE + parent.BRICK_SPACING)
	var left_column_x: float = _get_blitz_left_column_x(parent)

	for entry_variant in row_entries:
		if not (entry_variant is Dictionary):
			continue
		var entry: Dictionary = entry_variant
		var row_index: int = int(entry.get("row", 0))
		var brick_type_name: String = str(entry.get("type", "NORMAL"))
		if brick_type_name == "UNBREAKABLE" or brick_type_name == "FORCE_ARROW":
			continue
		if not PackLoader.BRICK_TYPE_MAP.has(brick_type_name):
			continue

		var brick: Node = parent.BRICK_SCENE.instantiate()
		brick.position = Vector2(
			left_column_x + (float(col_index) * step),
			_blitz_top_row_y + (float(row_index) * step)
		)
		brick.brick_type = PackLoader.BRICK_TYPE_MAP[brick_type_name]
		if brick_type_name == "POWERUP_BRICK":
			brick.powerup_type_name = str(entry.get("powerup_type", "MYSTERY"))
		parent.brick_container.add_child(brick)
		spawned.append(brick)

	return spawned

func _resolve_ball_overlap_for_brick(parent: Node, brick: Node) -> void:
	if brick == null or not is_instance_valid(brick) or brick.is_queued_for_deletion():
		return
	if parent.game_manager and parent.game_manager.game_state == parent.game_manager.GameState.GAME_OVER:
		return

	for ball in parent._get_active_balls():
		if not is_instance_valid(ball):
			continue
		if not _is_ball_overlapping_brick(parent, ball, brick):
			continue
		_apply_ball_brick_contact(ball, brick)
		if not is_instance_valid(brick) or brick.is_queued_for_deletion():
			break

func _is_ball_overlapping_brick(parent: Node, ball: Node, brick: Node) -> bool:
	var ball_radius: float = float(ball.get("ball_radius")) if ball.get("ball_radius") != null else 16.0
	var brick_half_size: float = float(parent.BRICK_SIZE) * 0.5
	var delta_x: float = absf(ball.global_position.x - brick.global_position.x)
	var delta_y: float = absf(ball.global_position.y - brick.global_position.y)
	return delta_x <= (brick_half_size + ball_radius) and delta_y <= (brick_half_size + ball_radius)

func _apply_ball_brick_contact(ball: Node, brick: Node) -> void:
	if not is_instance_valid(ball) or not is_instance_valid(brick):
		return
	if brick.is_queued_for_deletion():
		return

	if ball.has_method("_emit_brick_hit"):
		ball._emit_brick_hit(brick)

	var brick_type_value: Variant = brick.get("brick_type")
	if brick_type_value != null and int(brick_type_value) == BRICK_TYPE_POWERUP_BRICK and brick.has_method("collect_powerup"):
		brick.collect_powerup()
	elif brick.has_method("hit"):
		var impact_direction: Vector2 = Vector2.LEFT
		var velocity_value: Variant = ball.get("velocity")
		if velocity_value is Vector2 and (velocity_value as Vector2).length_squared() > 0.0001:
			impact_direction = (velocity_value as Vector2).normalized()
		brick.hit(impact_direction)

	var normal: Vector2 = _calculate_contact_normal(ball, brick)
	var ball_velocity_value: Variant = ball.get("velocity")
	if ball_velocity_value is Vector2:
		var bounced_velocity: Vector2 = (ball_velocity_value as Vector2).bounce(normal)
		var current_speed_value: Variant = ball.get("current_speed")
		var speed: float = float(current_speed_value) if current_speed_value != null else bounced_velocity.length()
		if speed > 0.0 and bounced_velocity.length_squared() > 0.0001:
			bounced_velocity = bounced_velocity.normalized() * speed
		ball.velocity = bounced_velocity

		var max_vertical_angle_value: Variant = ball.get("MAX_VERTICAL_ANGLE")
		var max_vertical_angle: float = float(max_vertical_angle_value) if max_vertical_angle_value != null else BALL_MAX_VERTICAL_ANGLE_FALLBACK
		if speed > 0.0:
			var min_horizontal: float = speed * (1.0 - max_vertical_angle)
			if absf(ball.velocity.x) < min_horizontal:
				var horizontal_direction: float = signf(ball.velocity.x)
				if horizontal_direction == 0.0:
					horizontal_direction = -1.0
				ball.velocity.x = horizontal_direction * min_horizontal
				if ball.velocity.length_squared() > 0.0001:
					ball.velocity = ball.velocity.normalized() * speed

	var spin_decay: Variant = ball.get("SPIN_ON_HIT_DECAY")
	var spin_amount: Variant = ball.get("spin_amount")
	if spin_amount != null:
		var decay_value: float = float(spin_decay) if spin_decay != null else BALL_SPIN_DECAY_FALLBACK
		ball.spin_amount = float(spin_amount) * decay_value

	AudioManager.play_sfx("hit_brick")

func _calculate_contact_normal(ball: Node, brick: Node) -> Vector2:
	var delta: Vector2 = ball.global_position - brick.global_position
	if absf(delta.x) > absf(delta.y):
		var x_sign: float = signf(delta.x)
		if x_sign == 0.0:
			x_sign = -1.0
		return Vector2(x_sign, 0.0)
	var y_sign: float = signf(delta.y)
	if y_sign == 0.0:
		y_sign = -1.0
	return Vector2(0.0, y_sign)

func _update_hud_status(parent: Node) -> void:
	if parent.hud == null:
		return
	var remaining_seconds: int = int(ceil(_current_push_interval))
	var interval_seconds: float = _current_push_interval
	if _push_timer and is_instance_valid(_push_timer) and _push_timer.time_left > 0.0:
		remaining_seconds = int(ceil(_push_timer.time_left))
		interval_seconds = _push_timer.wait_time
	if parent.hud.has_method("set_blitz_push_status"):
		parent.hud.set_blitz_push_status(remaining_seconds, _rows_survived, interval_seconds)
	elif parent.hud.has_method("set_objective_text"):
		parent.hud.set_objective_text("BLITZ PUSH IN: %ds | ROWS %d" % [max(0, remaining_seconds), max(0, _rows_survived)], false)

func _get_blitz_left_column_x(parent: Node) -> float:
	var half_brick: float = float(parent.BRICK_SIZE) * 0.5
	var left_wall_x: float = 0.0
	var left_wall_half_width: float = LEFT_WALL_HALF_WIDTH_FALLBACK
	var found_left_wall: bool = false

	if parent.play_area:
		var left_wall: Node = parent.play_area.get_node_or_null("Walls/LeftWall")
		if left_wall and left_wall is Node2D:
			found_left_wall = true
			left_wall_x = float((left_wall as Node2D).position.x)
			var collision_shape_node: Node = left_wall.get_node_or_null("CollisionShape2D")
			if collision_shape_node and collision_shape_node is CollisionShape2D:
				var rectangle_shape: Variant = (collision_shape_node as CollisionShape2D).shape
				if rectangle_shape and rectangle_shape is RectangleShape2D:
					left_wall_half_width = float((rectangle_shape as RectangleShape2D).size.x) * 0.5

	if not found_left_wall:
		return float(parent.LEVEL_START_X)
	return left_wall_x + left_wall_half_width + half_brick

func _configure_blitz_playfield_geometry(parent: Node) -> void:
	_blitz_grid_rows = DEFAULT_BLITZ_GRID_ROWS
	_blitz_top_row_y = float(parent.LEVEL_START_Y)

	if parent.play_area == null:
		return

	var walls_root: Node = parent.play_area.get_node_or_null("Walls")
	if walls_root == null:
		return

	var top_wall: Node = walls_root.get_node_or_null("TopWall")
	var bottom_wall: Node = walls_root.get_node_or_null("BottomWall")
	if not (top_wall is Node2D) or not (bottom_wall is Node2D):
		return

	var top_half_height: float = _get_wall_half_height(top_wall)
	var bottom_half_height: float = _get_wall_half_height(bottom_wall)
	var inner_top_y: float = float((top_wall as Node2D).position.y) + top_half_height
	var inner_bottom_y: float = float((bottom_wall as Node2D).position.y) - bottom_half_height
	var brick_size: float = float(parent.BRICK_SIZE)
	var step: float = float(parent.BRICK_SIZE + parent.BRICK_SPACING)
	var available_height: float = inner_bottom_y - inner_top_y
	if available_height < brick_size:
		return

	var computed_rows: int = int(floor((available_height - brick_size) / step)) + 1
	_blitz_grid_rows = max(1, computed_rows)
	_blitz_top_row_y = inner_top_y + (brick_size * 0.5)

func _get_wall_half_height(wall_node: Node) -> float:
	if wall_node == null:
		return WALL_HALF_HEIGHT_FALLBACK
	var collision_shape_node: Node = wall_node.get_node_or_null("CollisionShape2D")
	if collision_shape_node and collision_shape_node is CollisionShape2D:
		var rectangle_shape: Variant = (collision_shape_node as CollisionShape2D).shape
		if rectangle_shape and rectangle_shape is RectangleShape2D:
			return float((rectangle_shape as RectangleShape2D).size.y) * 0.5
	return WALL_HALF_HEIGHT_FALLBACK

func _check_all_clear_bonus(parent: Node) -> void:
	if _all_clear_bonus_awarded_for_cycle:
		return
	if _push_timer == null or not is_instance_valid(_push_timer):
		return
	if _push_timer.time_left <= 0.0:
		return
	if parent.game_manager == null:
		return
	if parent.game_manager.game_state == parent.game_manager.GameState.GAME_OVER:
		return
	if int(parent.remaining_breakable_bricks) > 0:
		return
	_award_all_clear_bonus(parent)

func _award_all_clear_bonus(parent: Node) -> void:
	if parent.game_manager == null:
		return
	var awarded_points: int = BLITZ_ALL_CLEAR_BONUS_POINTS
	if parent.game_manager.has_method("add_objective_bonus_score"):
		awarded_points = int(parent.game_manager.add_objective_bonus_score(BLITZ_ALL_CLEAR_BONUS_POINTS))
	else:
		parent.game_manager.add_score(BLITZ_ALL_CLEAR_BONUS_POINTS)
	if parent.hud and parent.hud.has_method("show_blitz_all_clear_bonus"):
		parent.hud.show_blitz_all_clear_bonus(awarded_points)
	_all_clear_bonus_awarded_for_cycle = true
