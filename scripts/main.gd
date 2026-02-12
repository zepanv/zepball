extends Node2D

## Main scene controller - Orchestrates gameplay systems
##
## Responsibilities:
## - Connect signals between gameplay systems (ball, bricks, power-ups, game manager)
## - Manage level layout and brick spawning
## - Handle ball loss logic (life deduction when last ball is lost)
## - Coordinate power-up spawning and collection
## - Track breakable brick count for level completion
## - Background selection and setup

@onready var game_manager = $GameManager
@onready var ball = $PlayArea/Ball
@onready var hud = $UI/HUD
@onready var brick_container = $PlayArea/BrickContainer
@onready var play_area = $PlayArea
@onready var paddle = $PlayArea/Paddle
@onready var background = $Background
@onready var camera = $Camera2D

# Brick scene to instantiate
const BRICK_SCENE = preload("res://scenes/gameplay/brick.tscn")
const BALL_SCENE = preload("res://scenes/gameplay/ball.tscn")
const BACKGROUND_MANAGER_SCRIPT: GDScript = preload("res://scripts/main_background_manager.gd")
const POWER_UP_HANDLER_SCRIPT: GDScript = preload("res://scripts/main_power_up_handler.gd")
const BASE_RESOLUTION = Vector2i(1280, 720)

# Level layout constants
const BRICK_SIZE = 48         # Square brick size in pixels
const BRICK_SPACING = 3       # Gap between bricks
const LEVEL_START_X = 150     # Default X position for level start
const LEVEL_START_Y = 150     # Default Y position for level start
const BLOCK_BRICK_WIDTH = 48
const BLOCK_BRICK_HEIGHT = 64
const BLOCK_OFFSET_X = 16
const BLOCK_SEGMENT_COUNT = 4
const BLOCK_COLOR_INTERVAL = 4.0
const BLOCK_DEFAULT_DURATION = 12.0

# Screen shake tuning
const SHAKE_BASE_INTENSITY = 2.0
const SHAKE_SCORE_DIVISOR = 50.0
const SHAKE_SCORE_SCALE = 3.0
const SHAKE_COMBO_MIN = 3
const SHAKE_COMBO_OFFSET = 2
const SHAKE_COMBO_STEP = 0.15
const SHAKE_MAX_INTENSITY = 12.0
const SHAKE_DURATION = 0.15

# Debug/testing positions
const DEBUG_POWERUP_SPAWN_POSITION = Vector2(1100.0, 360.0)

# Triple-ball spawning safety bounds
const TRIPLE_BALL_RETRY_DELAY = 0.5
const TRIPLE_BALL_MIN_X = 50.0
const TRIPLE_BALL_MAX_X = 1100.0
const TRIPLE_BALL_MIN_Y = 50.0
const TRIPLE_BALL_MAX_Y = 670.0
const TRIPLE_BALL_LEFT_ZONE_X = 100.0
const TRIPLE_BALL_TOP_ZONE_Y = 150.0
const TRIPLE_BALL_BOTTOM_ZONE_Y = 570.0
const TRIPLE_BALL_OFFSET_DISTANCE = 20.0
const TRIPLE_BALL_SAFE_ANGLE_MIN = 120.0
const TRIPLE_BALL_SAFE_ANGLE_MAX = 240.0
const TRIPLE_BALL_DEFAULT_BASE_ANGLE = 180.0
const TRIPLE_BALL_LEFT_BASE_ANGLE = 105.0
const TRIPLE_BALL_TOP_BASE_ANGLE = 210.0
const TRIPLE_BALL_BOTTOM_BASE_ANGLE = 155.0
const TRIPLE_BALL_LEFT_ZONE_ANGLE_OFFSET = 10.0
const TRIPLE_BALL_STANDARD_ANGLE_OFFSET = 5.0
const TRIPLE_BALL_ADDITIONAL_COUNT = 2
const TRIPLE_BALL_IMMUNITY_DURATION = 0.5
const BRICK_TYPE_FORCE_ARROW = 14
const BRICK_TYPE_POWERUP_BRICK = 15

# Boundary constants
const RIGHT_BOUNDARY = 1300   # Past paddle (ball lost)
const POWER_UP_MISS_X = 1300  # X position where power-ups despawn

# Track only breakable bricks so level completion is deterministic
var remaining_breakable_bricks: int = 0
var cached_level_bricks: Array[Node] = []
var cached_force_arrows: Array[Node] = []
var background_manager: RefCounted = null
var power_up_handler: RefCounted = null

func _enter_tree() -> void:
	add_to_group("main_controller")

func _ready() -> void:
	# Set up background
	setup_background()
	if power_up_handler == null:
		power_up_handler = POWER_UP_HANDLER_SCRIPT.new()
	var viewport = get_viewport()
	if viewport:
		viewport.size_changed.connect(_configure_background_rect)
	_configure_background_rect()

	# Connect ball signals to game manager
	if ball:
		ball.ball_lost.connect(_on_ball_lost)

	# Connect game manager signals to HUD
	if game_manager and hud:
		game_manager.score_changed.connect(hud._on_score_changed)
		game_manager.lives_changed.connect(hud._on_lives_changed)
		game_manager.level_complete.connect(_on_level_complete)
		game_manager.game_over.connect(_on_game_over)

	# Load level from MenuController using pack-native addressing.
	var level_ref := MenuController.get_current_level_ref()
	load_level_ref(str(level_ref.get("pack_id", "classic-challenge")), int(level_ref.get("level_index", 0)))

	# Restore state if in set mode (deferred to ensure HUD is ready)
	if MenuController.current_play_mode == MenuController.PlayMode.SET and MenuController.set_current_index > 0:
		# Not the first level in the set - restore saved state from MenuController
		call_deferred("_restore_set_state",
			MenuController.set_saved_score,
			MenuController.set_saved_lives,
			MenuController.set_saved_combo,
			MenuController.set_saved_no_miss,
			MenuController.set_saved_perfect)

	# Connect existing bricks
	connect_brick_signals()

func _restore_set_state(saved_score: int, saved_lives: int, saved_combo: int, saved_no_miss: int, saved_perfect: bool) -> void:
	"""Restore game state when continuing a set (called deferred to ensure HUD is ready)"""
	game_manager.score = saved_score
	game_manager.lives = saved_lives
	game_manager.combo = saved_combo
	game_manager.no_miss_hits = saved_no_miss
	game_manager.is_perfect_clear = saved_perfect

	# Emit signals to update HUD
	game_manager.score_changed.emit(game_manager.score)
	game_manager.lives_changed.emit(game_manager.lives)
	game_manager.combo_changed.emit(game_manager.combo)
	game_manager.no_miss_streak_changed.emit(game_manager.no_miss_hits)

func setup_background() -> void:
	"""Load and configure a random background image."""
	if background_manager == null:
		background_manager = BACKGROUND_MANAGER_SCRIPT.new()
	if background_manager == null or not background_manager.has_method("setup_background"):
		return

	var configured_background = background_manager.call("setup_background", self, background)
	if configured_background != null:
		background = configured_background

func _configure_background_rect() -> void:
	"""Make the background fit the viewport."""
	if background_manager == null:
		return
	if background_manager.has_method("configure_background_rect"):
		background_manager.call("configure_background_rect", background, get_viewport())


func load_level(level_id: int):
	"""Legacy helper for integer level IDs."""
	var level_ref := PackLoader.get_legacy_level_ref(level_id)
	if level_ref.is_empty():
		push_error("Failed to map legacy level %d" % level_id)
		create_test_level()
		return
	load_level_ref(str(level_ref.get("pack_id", "")), int(level_ref.get("level_index", -1)))

func load_level_ref(pack_id: String, level_index: int):
	"""Load a level from PackLoader using pack-native addressing."""
	var level_result: Dictionary = {}
	if MenuController.has_editor_test_data():
		var test_level_data: Dictionary = MenuController.get_editor_test_level_data()
		level_result = _instantiate_level_from_data(test_level_data, "__editor_test__", level_index)
	else:
		level_result = PackLoader.instantiate_level(pack_id, level_index, brick_container)

	if level_result["success"]:
		# Update game manager with level info
		if game_manager:
			var legacy_level_id: int = PackLoader.get_legacy_level_id(pack_id, level_index)
			if MenuController.is_editor_test_mode:
				game_manager.current_level = level_index + 1
			else:
				game_manager.current_level = legacy_level_id if legacy_level_id != -1 else 1
			game_manager.current_pack_id = pack_id
			game_manager.current_level_index = level_index
			game_manager.current_level_key = "%s:%d" % [pack_id, level_index]

		# Show level intro
		if hud and hud.has_method("show_level_intro"):
			hud.show_level_intro(game_manager.current_level, level_result["name"], level_result["description"])
	else:
		push_error("Failed to load level %s:%d - falling back to test level" % [pack_id, level_index])
		create_test_level()

func _instantiate_level_from_data(level_data: Dictionary, pack_id: String, level_index: int) -> Dictionary:
	"""Instantiate a level directly from provided data (used for editor test mode)."""
	if level_data.is_empty():
		return {"success": false, "breakable_count": 0}

	for child in brick_container.get_children():
		child.queue_free()

	var grid: Dictionary = level_data.get("grid", {})
	var brick_size: int = int(grid.get("brick_size", BRICK_SIZE))
	var spacing: int = int(grid.get("spacing", BRICK_SPACING))
	var start_x: int = int(grid.get("start_x", LEVEL_START_X))
	var start_y: int = int(grid.get("start_y", LEVEL_START_Y))
	var bricks_data: Array = level_data.get("bricks", [])
	var breakable_count: int = 0

	for brick_variant in bricks_data:
		if not (brick_variant is Dictionary):
			continue
		var brick_def: Dictionary = brick_variant
		var brick_type_string: String = str(brick_def.get("type", "NORMAL"))
		if not PackLoader.BRICK_TYPE_MAP.has(brick_type_string):
			continue
		var brick = BRICK_SCENE.instantiate()
		var row: int = int(brick_def.get("row", 0))
		var col: int = int(brick_def.get("col", 0))
		brick.position = Vector2(
			start_x + col * (brick_size + spacing),
			start_y + row * (brick_size + spacing)
		)
		brick.brick_type = PackLoader.BRICK_TYPE_MAP[brick_type_string]
		if brick_type_string == "FORCE_ARROW":
			brick.direction = int(brick_def.get("direction", 45))
		elif brick_type_string == "POWERUP_BRICK":
			brick.powerup_type_name = str(brick_def.get("powerup_type", "MYSTERY"))
		brick_container.add_child(brick)
		if not PackLoader.NON_BREAKABLE_TYPES.has(brick_type_string):
			breakable_count += 1

	return {
		"success": true,
		"pack_id": pack_id,
		"level_index": level_index,
		"name": str(level_data.get("name", "Editor Test")),
		"description": str(level_data.get("description", "")),
		"total_bricks": bricks_data.size(),
		"breakable_count": breakable_count
	}

func create_test_level():
	"""Create a grid of square bricks for testing (fallback)"""
	var rows = 5
	var cols = 8

	for row in range(rows):
		for col in range(cols):
			var brick = BRICK_SCENE.instantiate()
			brick.position = Vector2(
				LEVEL_START_X + col * (BRICK_SIZE + BRICK_SPACING),
				LEVEL_START_Y + row * (BRICK_SIZE + BRICK_SPACING)
			)

			# Vary brick types by row
			if row == 0:
				brick.brick_type = brick.BrickType.STRONG
			else:
				brick.brick_type = brick.BrickType.NORMAL

			brick_container.add_child(brick)


func connect_brick_signals():
	"""Connect all brick signals to game manager"""
	remaining_breakable_bricks = 0
	cached_level_bricks.clear()
	cached_force_arrows.clear()
	for brick in brick_container.get_children():
		if brick.has_signal("brick_broken"):
			brick.brick_broken.connect(_on_brick_broken.bind(brick))
		if brick.has_signal("power_up_spawned"):
			brick.power_up_spawned.connect(_on_power_up_spawned)
		if brick.has_signal("powerup_collected"):
			brick.powerup_collected.connect(_on_power_up_collected)
		cached_level_bricks.append(brick)
		if int(brick.brick_type) == BRICK_TYPE_FORCE_ARROW:
			cached_force_arrows.append(brick)
		if _is_completion_brick(int(brick.brick_type)) and not brick.is_in_group("block_brick"):
			remaining_breakable_bricks += 1
	if remaining_breakable_bricks == 0:
		call_deferred("check_level_complete")

func get_cached_level_bricks() -> Array[Node]:
	"""Return live level bricks with in-place compaction to avoid full container scans."""
	for i in range(cached_level_bricks.size() - 1, -1, -1):
		if not is_instance_valid(cached_level_bricks[i]):
			cached_level_bricks.remove_at(i)
	return cached_level_bricks

func get_cached_force_arrows() -> Array[Node]:
	for i in range(cached_force_arrows.size() - 1, -1, -1):
		if not is_instance_valid(cached_force_arrows[i]):
			cached_force_arrows.remove_at(i)
	return cached_force_arrows

func _on_brick_broken(score_value: int, brick_ref: Node):
	"""Handle brick destruction"""
	game_manager.add_score(score_value)

	# Track statistic
	if not MenuController.is_editor_test_mode:
		SaveManager.increment_stat("total_bricks_broken")

	# Trigger screen shake (intensity scales with score and combo)
	_apply_brick_hit_shake(score_value)

	# Decrement breakable brick count and check completion immediately
	if brick_ref and is_instance_valid(brick_ref) and not brick_ref.is_in_group("block_brick"):
		if _is_completion_brick(int(brick_ref.brick_type)):
			remaining_breakable_bricks = max(remaining_breakable_bricks - 1, 0)
	check_level_complete()

func _is_completion_brick(brick_type_int: int) -> bool:
	return (
		brick_type_int != PackLoader.BRICK_TYPE_MAP["UNBREAKABLE"]
		and brick_type_int != BRICK_TYPE_FORCE_ARROW
		and brick_type_int != BRICK_TYPE_POWERUP_BRICK
	)

func check_level_complete():
	"""Check if all bricks have been destroyed"""
	if remaining_breakable_bricks == 0:
		game_manager.complete_level()

func _on_ball_lost(lost_ball):
	"""Handle ball loss - only lose life if this is the last ball in play"""
	# Get all balls currently in play (before removing this one)
	var balls_in_play = _get_active_balls()

	# Check if this is the last ball
	if balls_in_play.size() <= 1:
		# Last ball lost - lose a life and reset main ball
		game_manager.lose_life()

		# Find the actual main ball in the scene
		var main_ball_ref = null
		for b in balls_in_play:
			if b.is_main_ball:
				main_ball_ref = b
				break

		# If we found a main ball, use it
		if main_ball_ref and is_instance_valid(main_ball_ref):
			if main_ball_ref.has_method("reset_ball"):
				main_ball_ref.reset_ball()
				ball = main_ball_ref  # Update reference
			else:
				push_error("Main ball has no reset_ball method")
		# Otherwise try the scene's ball reference
		elif is_instance_valid(ball) and ball.has_method("reset_ball"):
			ball.reset_ball()
		else:
			push_warning("Cannot reset main ball - no valid main ball found")
			# Try to recover by finding ANY ball in the scene
			if balls_in_play.size() > 0 and is_instance_valid(balls_in_play[0]):
				if balls_in_play[0].has_method("set_is_main_ball"):
					balls_in_play[0].set_is_main_ball(true)
				else:
					balls_in_play[0].is_main_ball = true
				ball = balls_in_play[0]
				if ball.has_method("reset_ball"):
					ball.reset_ball()

		# Clean up the lost ball if it's not the one we're using
		if lost_ball != ball and is_instance_valid(lost_ball):
			lost_ball.queue_free()
	else:
		# Still have other balls in play - no life penalty
		if is_instance_valid(lost_ball):
			lost_ball.queue_free()

func _on_level_complete():
	"""Handle level completion - stop ball and transition to complete screen"""
	# Stop the ball
	if ball and ball.has_method("reset_ball"):
		ball.reset_ball()

	# Show level complete screen with final score
	MenuController.show_level_complete(game_manager.score)

func _on_game_over():
	"""Handle game over - transition to game over screen"""
	# Show game over screen with final score
	MenuController.show_game_over(game_manager.score)

func _input(event):
	"""Handle input for restart and debug/testing"""
	# Restart with input action
	if Input.is_action_just_pressed("restart_game"):
		MenuController.restart_current_level()

	if event is InputEventKey and event.pressed and not event.echo:
		if OS.is_debug_build() and event.keycode == KEY_C:
			_hit_all_bricks()

func _spawn_debug_powerup(_label: String, powerup_type: int):
	var powerup_scene = load("res://scenes/gameplay/power_up.tscn")
	if powerup_scene:
		var powerup = powerup_scene.instantiate()
		powerup.power_up_type = powerup_type
		powerup.position = DEBUG_POWERUP_SPAWN_POSITION
		_on_power_up_spawned(powerup)
	else:
		push_error("Could not load power-up scene for debug spawn")

func _spawn_block_barrier(duration: float):
	if not paddle or not play_area:
		return

	var barrier = Node2D.new()
	barrier.name = "BlockBarrier"
	play_area.add_child(barrier)

	var paddle_width = _get_paddle_width()
	var segment_height = BLOCK_BRICK_HEIGHT
	var segment_width = BLOCK_BRICK_WIDTH
	var segment_count = BLOCK_SEGMENT_COUNT
	var step = segment_height + BRICK_SPACING
	var start_y = paddle.position.y - ((segment_count - 1) * step) / 2.0
	var base_x = paddle.position.x + (paddle_width / 2.0) + (segment_width / 2.0) + BLOCK_OFFSET_X

	var block_texture = load("res://assets/graphics/bricks/element_green_rectangle.png")

	for i in range(segment_count):
		var brick = BRICK_SCENE.instantiate()
		brick.brick_type = brick.BrickType.NORMAL
		brick.power_up_spawn_chance = 0.0
		brick.add_to_group("block_brick")
		barrier.add_child(brick)
		brick.position = Vector2(base_x, start_y + i * step)
		_configure_block_brick(brick, block_texture, segment_width, segment_height)
		if brick.has_signal("brick_broken"):
			brick.brick_broken.connect(_on_block_brick_broken)

	var timer = Timer.new()
	timer.name = "BlockLifetimeTimer"
	timer.one_shot = true
	timer.wait_time = duration
	barrier.add_child(timer)
	timer.timeout.connect(_on_block_barrier_timeout.bind(barrier))
	timer.start()

	var color_timer = Timer.new()
	color_timer.name = "BlockColorTimer"
	color_timer.one_shot = false
	color_timer.wait_time = 1.0
	barrier.add_child(color_timer)
	color_timer.timeout.connect(_update_block_barrier_color.bind(barrier))
	color_timer.start()

func _configure_block_brick(brick: Node, texture: Texture2D, segment_width: float, segment_height: float):
	if not brick:
		return

	if brick.has_node("Sprite"):
		var sprite = brick.get_node("Sprite")
		if texture:
			sprite.texture = texture
			sprite.rotation_degrees = 90.0
			var tex_size = texture.get_size()
			if tex_size.x > 0 and tex_size.y > 0:
				var scale_x = segment_width / tex_size.y
				var scale_y = segment_height / tex_size.x
				sprite.scale = Vector2(scale_x, scale_y)

	if brick.has_node("CollisionShape2D"):
		var collision = brick.get_node("CollisionShape2D")
		if collision.shape is RectangleShape2D:
			var new_shape = collision.shape
			if not new_shape.is_local_to_scene():
				new_shape = new_shape.duplicate()
			new_shape.size = Vector2(segment_width, segment_height)
			collision.set_deferred("shape", new_shape)

	brick.brick_color = Color(0.2, 0.8, 0.2)
	if brick.has_node("Particles"):
		brick.get_node("Particles").color = brick.brick_color
	if brick.has_node("Sprite"):
		brick.get_node("Sprite").modulate = brick.brick_color

func _on_block_brick_broken(score_value: int):
	"""Handle block brick destruction without affecting level completion"""
	if game_manager:
		game_manager.add_score(score_value)
	SaveManager.increment_stat("total_bricks_broken")

	# Trigger screen shake similar to normal bricks
	_apply_brick_hit_shake(score_value)

func _on_block_barrier_timeout(barrier: Node):
	if barrier and barrier.is_inside_tree():
		barrier.queue_free()

func _update_block_barrier_color(barrier: Node):
	if not barrier or not barrier.is_inside_tree():
		return

	var lifetime_timer = barrier.get_node_or_null("BlockLifetimeTimer")
	if not lifetime_timer:
		return

	var time_left = lifetime_timer.time_left
	var new_color = Color(0.2, 0.8, 0.2)
	if time_left <= BLOCK_COLOR_INTERVAL:
		new_color = Color(1.0, 0.35, 0.35)
	elif time_left <= BLOCK_COLOR_INTERVAL * 2.0:
		new_color = Color(1.0, 0.8, 0.2)

	for child in barrier.get_children():
		if not (child is Node):
			continue
		if not child.is_in_group("block_brick"):
			continue
		if child.has_method("set"):
			child.brick_color = new_color
		if child.has_node("Sprite"):
			child.get_node("Sprite").modulate = new_color
		if child.has_node("Particles"):
			child.get_node("Particles").color = new_color

func _get_paddle_height() -> float:
	if not paddle:
		return 130.0
	var height = paddle.get("current_height")
	if height != null:
		return float(height)
	if paddle.has_node("CollisionShape2D"):
		var collision = paddle.get_node("CollisionShape2D")
		if collision.shape is RectangleShape2D:
			return collision.shape.size.y
	return 130.0

func _get_paddle_width() -> float:
	if not paddle:
		return 24.0
	if paddle.has_node("CollisionShape2D"):
		var collision = paddle.get_node("CollisionShape2D")
		if collision.shape is RectangleShape2D:
			return collision.shape.size.x
	return 24.0

func _hit_all_bricks():
	"""Hit all bricks (breaks normals, strongs via double hit)"""
	if not brick_container:
		return
	var bricks = brick_container.get_children()
	for brick in bricks:
		if brick.has_method("hit"):
			brick.hit()
			brick.hit()

func _on_power_up_spawned(power_up_node):
	"""Handle power-up spawning from broken brick"""
	# Add power-up to PlayArea
	play_area.add_child(power_up_node)

	# Connect collection signal
	if power_up_node.has_signal("collected"):
		power_up_node.collected.connect(_on_power_up_collected)

func _on_power_up_collected(type):
	"""Handle power-up collection"""
	# Track statistic
	SaveManager.increment_stat("total_power_ups_collected")

	if power_up_handler == null:
		power_up_handler = POWER_UP_HANDLER_SCRIPT.new()
	if power_up_handler and power_up_handler.has_method("apply_collected_power_up"):
		power_up_handler.call("apply_collected_power_up", self, int(type))

func spawn_additional_balls_with_retry(retries_remaining: int = 3):
	"""Try to spawn additional balls, retrying if ball is in a bad position"""
	var result = try_spawn_additional_balls()

	if not result and retries_remaining > 1:
		await get_tree().create_timer(TRIPLE_BALL_RETRY_DELAY).timeout
		spawn_additional_balls_with_retry(retries_remaining - 1)
	elif not result:
		push_warning("Failed to spawn triple ball after all retries")

func try_spawn_additional_balls() -> bool:
	"""Attempt to spawn additional balls - returns true if successful, false if position is bad"""
	# Find any active ball in play
	var active_balls = _get_active_balls()
	var source_ball = null

	# Prefer a ball that's in motion (not attached to paddle)
	for b in active_balls:
		if not b.is_attached_to_paddle:
			source_ball = b
			break

	# If no moving ball, use any ball (including attached one)
	if not source_ball and active_balls.size() > 0:
		source_ball = active_balls[0]

	# If still no ball, use the main ball reference as fallback
	if not source_ball:
		source_ball = ball

	if not source_ball:
		push_warning("Cannot spawn triple ball: no ball reference found")
		return false

	# Safety check: Don't spawn if ball is too close to edges
	if source_ball.position.x > TRIPLE_BALL_MAX_X:
		return false
	if source_ball.position.x < TRIPLE_BALL_MIN_X:
		return false
	if source_ball.position.y < TRIPLE_BALL_MIN_Y or source_ball.position.y > TRIPLE_BALL_MAX_Y:
		return false

	# Position is good - spawn the balls
	spawn_additional_balls(source_ball)
	return true

func spawn_additional_balls(source_ball):
	"""Spawn 2 additional balls for multi-ball power-up - source_ball position already validated"""
	if not BALL_SCENE:
		push_error("Could not load ball scene")
		return

	# Enable collision immunity on source ball
	if source_ball.has_method("enable_collision_immunity"):
		source_ball.enable_collision_immunity(TRIPLE_BALL_IMMUNITY_DURATION)

	# Spawn 2 additional balls
	for i in range(TRIPLE_BALL_ADDITIONAL_COUNT):
		var new_ball = BALL_SCENE.instantiate()

		# Mark as extra ball (won't count as life loss)
		if new_ball.has_method("set_is_main_ball"):
			new_ball.set_is_main_ball(false)
		else:
			new_ball.is_main_ball = false

		# Position with small offset to prevent physics overlap issues
		# Offset perpendicular to source ball's velocity direction
		var perpendicular_offset = Vector2(0, TRIPLE_BALL_OFFSET_DISTANCE * (1 if i == 0 else -1))
		new_ball.position = source_ball.position + perpendicular_offset

		# Launch with safe angles based on current ball position
		# Angles: 0° = right, 90° = down, 180° = left, 270° = up
		# CRITICAL: Use only SAFE angles (120°-240°) to prevent any escapes
		var angle_offset = 0.0
		var base_angle = TRIPLE_BALL_DEFAULT_BASE_ANGLE

		# CRITICAL: Check boundaries and adjust angles to prevent escapes
		# All angles constrained to 120°-240° range (safe zone)
		# Check left wall (X < 100) - shoot RIGHT-DOWN
		if source_ball.position.x < TRIPLE_BALL_LEFT_ZONE_X:
			# Near left: shoot toward right-down quadrant (90° to 120°)
			base_angle = TRIPLE_BALL_LEFT_BASE_ANGLE
			angle_offset = -TRIPLE_BALL_LEFT_ZONE_ANGLE_OFFSET if i == 0 else TRIPLE_BALL_LEFT_ZONE_ANGLE_OFFSET
		# Check top wall (Y < 150) - shoot DOWN-LEFT
		elif source_ball.position.y < TRIPLE_BALL_TOP_ZONE_Y:
			# Near top: shoot down-left (200°-220°)
			base_angle = TRIPLE_BALL_TOP_BASE_ANGLE
			angle_offset = -TRIPLE_BALL_STANDARD_ANGLE_OFFSET if i == 0 else TRIPLE_BALL_STANDARD_ANGLE_OFFSET
		# Check bottom wall (Y > 570) - shoot LEFT-UP (but still safe)
		elif source_ball.position.y > TRIPLE_BALL_BOTTOM_ZONE_Y:
			# Near bottom: shoot left-up but stay in safe range (150°-160°)
			base_angle = TRIPLE_BALL_BOTTOM_BASE_ANGLE
			angle_offset = -TRIPLE_BALL_STANDARD_ANGLE_OFFSET if i == 0 else TRIPLE_BALL_STANDARD_ANGLE_OFFSET
		# Normal position - horizontal spread
		else:
			# Center area - horizontal spread (175°-185°)
			base_angle = TRIPLE_BALL_DEFAULT_BASE_ANGLE
			angle_offset = -TRIPLE_BALL_STANDARD_ANGLE_OFFSET if i == 0 else TRIPLE_BALL_STANDARD_ANGLE_OFFSET

		var target_angle = base_angle + angle_offset

		# SAFETY CLAMP: Ensure angle is always in safe range
		target_angle = clamp(target_angle, TRIPLE_BALL_SAFE_ANGLE_MIN, TRIPLE_BALL_SAFE_ANGLE_MAX)
		var angle_rad = deg_to_rad(target_angle)

		new_ball.velocity = Vector2(cos(angle_rad), sin(angle_rad)) * source_ball.current_speed
		new_ball.is_attached_to_paddle = false

		# Enable trail
		if new_ball.has_method("refresh_trail_state"):
			new_ball.call_deferred("refresh_trail_state")
		elif new_ball.has_node("Trail"):
			new_ball.get_node("Trail").emitting = SaveManager.get_ball_trail()

		# Add to scene
		play_area.add_child(new_ball)
		if PowerUpManager and new_ball.has_method("set_ball_size_multiplier"):
			var size_multiplier = PowerUpManager.get_ball_size_multiplier()
			new_ball.call_deferred("set_ball_size_multiplier", size_multiplier)

		# Enable collision immunity to prevent spawn collision issues
		if new_ball.has_method("enable_collision_immunity"):
			new_ball.enable_collision_immunity(TRIPLE_BALL_IMMUNITY_DURATION)

		# Connect signals
		new_ball.ball_lost.connect(_on_ball_lost)

func _get_active_balls() -> Array:
	if not play_area:
		return []
	var active_balls: Array = []
	for child in play_area.get_children():
		if is_instance_valid(child) and child.is_in_group("ball"):
			active_balls.append(child)
	return active_balls

func _apply_brick_hit_shake(score_value: int) -> void:
	if not camera or not camera.has_method("shake"):
		return

	var base_intensity = SHAKE_BASE_INTENSITY + (score_value / SHAKE_SCORE_DIVISOR) * SHAKE_SCORE_SCALE
	var combo_multiplier = 1.0
	if game_manager and game_manager.combo >= SHAKE_COMBO_MIN:
		combo_multiplier = 1.0 + (game_manager.combo - SHAKE_COMBO_OFFSET) * SHAKE_COMBO_STEP

	var intensity = min(base_intensity * combo_multiplier, SHAKE_MAX_INTENSITY)
	camera.shake(intensity, SHAKE_DURATION)
