extends CharacterBody2D

## Ball - Physics-based ball with collision detection and spin mechanics
## Bounces off walls, paddle, and bricks
## Paddle movement affects ball trajectory (spin)

# Ball physics constants
const BASE_SPEED = 500.0   # Base speed (pixels/second)
const BASE_RADIUS = 16.0
const BASE_VISUAL_SCALE = Vector2(0.0185, 0.0185)
const SPIN_FACTOR = 0.3         # How much paddle velocity affects ball
const MAX_VERTICAL_ANGLE = 0.8  # Prevent pure vertical/horizontal motion
const INITIAL_ANGLE = -45.0     # Launch angle (degrees, toward left)
const MAGNET_PULL = 800.0       # Paddle gravity strength for Magnet power-up
const TOP_WALL_Y = 20.0
const BOTTOM_WALL_Y = 700.0
const HIGH_SPIN_THRESHOLD = 250.0
const HIGH_SPIN_TRAIL_DURATION = 0.35
const FAST_SPEED_MULTIPLIER = 1.15
const AIM_MIN_ANGLE = 120.0
const AIM_MAX_ANGLE = 240.0
const AIM_LENGTH = 140.0
const AIM_HEAD_LENGTH = 18.0
const AIM_HEAD_ANGLE = 25.0
const BRICK_TYPE_UNBREAKABLE = 2
const RIGHT_BOUNDARY_X = 1300.0
const LEFT_BOUNDARY_X = 0.0
const TOP_BOUNDARY_Y = 0.0
const BOTTOM_BOUNDARY_Y = 720.0
const TOP_ESCAPE_ZONE_Y = 40.0
const BOTTOM_ESCAPE_ZONE_Y = 660.0
const SPEED_UP_VALUE = 650.0
const SLOW_DOWN_VALUE = 350.0
const SLOW_SPEED_MULTIPLIER = 0.85
const AIR_BALL_LANDING_OFFSET = 2.0
const AIR_BALL_SEARCH_MAX_STEPS = 7
const AIR_BALL_QUERY_MAX_RESULTS = 8
const AIR_BALL_FALLBACK_CENTER_X = 640.0
const AIR_BALL_STEP_FALLBACK_PADDING = 6.0
const AIR_BALL_UNBREAKABLE_HALF_SIZE = 24.0
const AIR_BALL_ROW_MARGIN = 2.0
const BOMB_BALL_RADIUS = 75.0
const BOUNDARY_LEFT_ERROR_LABEL = "LEFT (ERROR!)"
const BOUNDARY_TOP_ERROR_LABEL = "TOP (ERROR!)"
const BOUNDARY_BOTTOM_ERROR_LABEL = "BOTTOM (ERROR!)"

const TRAIL_SMALL = preload("res://assets/graphics/particles/particleSmallStar.png")
const TRAIL_MEDIUM = preload("res://assets/graphics/particles/particleStar.png")
const TRAIL_LARGE = preload("res://assets/graphics/particles/particleCartoonStar.png")
const AIR_BALL_HELPER_SCRIPT = preload("res://scripts/ball_air_ball_helper.gd")
const TRAIL_COLOR_NORMAL = Color(0.3, 0.6, 0.95, 0.7)
const TRAIL_COLOR_FAST = Color(1.0, 0.8, 0.2, 0.7)
const TRAIL_COLOR_SLOW = Color(0.2, 0.6, 1.0, 0.7)

# Dynamic speed (can be modified by power-ups)
var current_speed: float = BASE_SPEED
var base_speed: float = BASE_SPEED

# State
var is_attached_to_paddle = true
var paddle_reference: Node2D = null
var game_manager: Node = null
var is_main_ball: bool = true  # Identifies the original ball in the scene
var paddle_offset: Vector2 = Vector2(-30, 0)  # Offset from paddle when attached/grabbed
var grab_immunity_timer: float = 0.0  # Prevents immediate re-grab after launch
var block_pass_timer: float = 0.0  # Allow pass-through behind block right after launch

# Stuck detection
var stuck_check_timer: float = 0.0
var last_position: Vector2 = Vector2.ZERO
var stuck_threshold: float = 2.0  # seconds
var movement_threshold: float = 30.0  # pixels
var ball_radius: float = BASE_RADIUS
var last_physics_delta: float = 0.0
var spin_trail_timer: float = 0.0
var aim_available: bool = false
var aim_active: bool = false
var aim_direction: Vector2 = Vector2(-1, 0)
var aim_indicator_root: Node2D = null
var aim_shaft: Line2D = null
var aim_head: Line2D = null
var virtual_mouse_pos: Vector2 = Vector2.ZERO
var was_mouse_captured: bool = false
var last_collision_normal: Vector2 = Vector2.ZERO
var last_collision_collider = null
var last_collision_age: float = 0.0
var air_ball_helper: RefCounted = null
var main_controller_ref: Node = null
var bomb_visual_active: bool = false
var frame_grab_active: bool = false
var frame_brick_through_active: bool = false
var frame_bomb_ball_active: bool = false
var frame_air_ball_active: bool = false
var frame_magnet_active: bool = false
@onready var trail_node: CPUParticles2D = get_node_or_null("Trail")
@onready var visual_node: Sprite2D = get_node_or_null("Visual")
@onready var collision_shape_node: CollisionShape2D = get_node_or_null("CollisionShape2D")
@onready var viewport_ref: Viewport = get_viewport()

# Signals
signal ball_lost
signal brick_hit(brick)

func _ready():
	# Add to ball group for collision detection
	add_to_group("ball")
	if PowerUpManager and PowerUpManager.has_method("register_ball"):
		PowerUpManager.register_ball(self)

	# Apply difficulty multiplier to base speed
	base_speed = BASE_SPEED * DifficultyManager.get_speed_multiplier()
	current_speed = base_speed
	_cache_main_controller_ref()

	# Find paddle in parent scene
	paddle_reference = get_tree().get_first_node_in_group("paddle")
	game_manager = get_tree().get_first_node_in_group("game_manager")
	if not paddle_reference:
		push_warning("Ball could not find paddle reference")

	# Apply ball trail setting
	if trail_node:
		trail_node.emitting = false  # Starts disabled until launched
		trail_node.texture = TRAIL_SMALL
		trail_node.color = TRAIL_COLOR_NORMAL

	aim_available = is_main_ball
	_create_aim_indicator()
	virtual_mouse_pos = viewport_ref.get_mouse_position()
	set_process_unhandled_input(is_main_ball)

	if collision_shape_node and collision_shape_node.shape is CircleShape2D:
		ball_radius = collision_shape_node.shape.radius
	if visual_node:
		visual_node.scale = BASE_VISUAL_SCALE
	_refresh_effect_flags()

func _exit_tree() -> void:
	if PowerUpManager and PowerUpManager.has_method("unregister_ball"):
		PowerUpManager.unregister_ball(self)

func _physics_process(delta):
	last_physics_delta = delta
	# Stop ball movement if level is complete or game over
	if game_manager and (game_manager.game_state == game_manager.GameState.LEVEL_COMPLETE or game_manager.game_state == game_manager.GameState.GAME_OVER):
		velocity = Vector2.ZERO
		return

	# Decrement grab immunity timer
	if grab_immunity_timer > 0.0:
		grab_immunity_timer -= delta
	if block_pass_timer > 0.0:
		block_pass_timer -= delta
	if spin_trail_timer > 0.0:
		spin_trail_timer -= delta
	if paddle_reference == null or not is_instance_valid(paddle_reference):
		_ensure_paddle_reference()
	_refresh_effect_flags()

	if is_attached_to_paddle:
		# Ball follows paddle until launched, maintaining the attachment offset
		if paddle_reference:
			position = paddle_reference.position + paddle_offset
		if aim_active:
			_update_aim_direction()

		# Launch on input
		# Allow launch in READY state, or anytime ball is attached during PLAYING (includes grabbed balls)
		var can_launch = false
		if not game_manager:
			can_launch = true
		elif game_manager.game_state == game_manager.GameState.READY:
			can_launch = true
		elif game_manager.game_state == game_manager.GameState.PLAYING:
			# During gameplay, any attached ball can be launched (grabbed or waiting for respawn)
			can_launch = true

		if Input.is_action_just_pressed("launch_ball") and can_launch:
			launch_ball()
	else:
		if last_collision_collider != null:
			last_collision_age += delta
		# Ball is in motion
		# Apply magnet pull toward paddle (curve trajectory, keep speed)
		if frame_magnet_active:
			_apply_magnet_pull(delta)

		# First check if we would collide with another ball
		var delta_move = velocity * delta
		var test_collision = move_and_collide(delta_move, true, true)  # test_only=true, safe_margin=true

		if test_collision and test_collision.get_collider().is_in_group("ball"):
			# Would collide with another ball - just move through it without collision
			position += delta_move
		else:
			# Normal collision detection for walls, paddle, bricks
			var collision = move_and_collide(delta_move)
			if collision:
				handle_collision(collision)

		# Check if ball is stuck (not moving much for too long)
		check_if_stuck(delta)

		# Check if ball went out of bounds
		_handle_out_of_bounds()

		# Maintain constant speed (arcade feel)
		velocity = velocity.normalized() * current_speed

		# Rotate ball to show movement/spin (only if actually moving)
		# Rotation based on distance traveled (creates rolling effect)
		if visual_node and velocity.length_squared() > 100.0:
			var rotation_speed = current_speed / 16.0  # Ball radius for natural rolling
			visual_node.rotation += rotation_speed * delta

		_update_trail_appearance()

func launch_ball():
	"""Launch ball from paddle at initial angle
	If paddle is moving, impart spin. Otherwise, shoot straight left.
	"""
	is_attached_to_paddle = false
	var launched_with_aim = false
	if aim_active:
		var aim_dir = aim_direction.normalized()
		_set_aim_mode(false)
		velocity = aim_dir * current_speed
		launched_with_aim = true

	# Set grab immunity to prevent immediate re-grab after launch
	grab_immunity_timer = 0.2  # 200ms immunity
	block_pass_timer = 0.35  # Allow passing block barrier on launch

	# Add small random position offset to prevent stacked balls from colliding
	# This helps when multiple balls are grabbed at the same spot
	position += Vector2(randf_range(-3.0, 3.0), randf_range(-3.0, 3.0))

	if not launched_with_aim:
		# Check if paddle is moving
		var paddle_velocity_y = 0.0
		if paddle_reference and paddle_reference.has_method("get_velocity_for_spin"):
			paddle_velocity_y = paddle_reference.get_velocity_for_spin()

		# Add small random variation to prevent stacked balls from colliding
		# This helps when multiple grabbed balls are launched simultaneously
		var angle_variation = randf_range(-5.0, 5.0)  # ±5 degrees

		# If paddle is moving significantly, add vertical component
		if abs(paddle_velocity_y) > 50:  # Minimum movement threshold
			# Launch with spin based on paddle movement
			var angle_rad = deg_to_rad(INITIAL_ANGLE + angle_variation)
			velocity = Vector2(cos(angle_rad), sin(angle_rad)) * current_speed
			# Add paddle spin influence
			velocity.y += paddle_velocity_y * SPIN_FACTOR
			velocity = velocity.normalized() * current_speed
		else:
			# Launch straight left with slight angle variation
			var angle_rad = deg_to_rad(180.0 + angle_variation)  # 180° = straight left
			velocity = Vector2(cos(angle_rad), sin(angle_rad)) * current_speed

	# Apply air-ball jump on release from grab
	if frame_air_ball_active:
		_jump_to_level_center_x(position.y)

	# Enable trail effect (if enabled in settings)
	if trail_node and SaveManager.get_ball_trail():
		trail_node.emitting = true

	# Notify game manager
	if not game_manager:
		game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		game_manager.start_playing()

	aim_available = false

func handle_collision(collision: KinematicCollision2D):
	"""Handle ball collision with walls, paddle, or bricks"""
	var collider = collision.get_collider()
	var normal = collision.get_normal()

	# Ignore ball-to-ball collisions entirely (prevents physics pausing)
	if collider.is_in_group("ball"):
		return

	# Check what we hit
	if collider.is_in_group("paddle"):
		if paddle_reference == null and collider is Node2D:
			paddle_reference = collider as Node2D
		var hit_y = position.y
		# Special case: Allow ball to pass through paddle if stuck near walls and moving left
		# This prevents the ball from getting wedged between paddle and walls
		if position.y < TOP_ESCAPE_ZONE_Y and velocity.x < 0:
			# Ball is near top wall and moving left - let it pass through paddle
			return
		elif position.y > BOTTOM_ESCAPE_ZONE_Y and velocity.x < 0:
			# Ball is near bottom wall and moving left - let it pass through paddle
			return

		# Check if grab is enabled and ball is not immune to grab
		if frame_grab_active and grab_immunity_timer <= 0.0:
			# Attach ball to paddle (grab mode) at the exact contact point
			is_attached_to_paddle = true
			velocity = Vector2.ZERO
			# Store the current offset from paddle so ball sticks where it was grabbed
			if paddle_reference:
				paddle_offset = position - paddle_reference.position
				# Ensure ball is on the front (left) side of paddle, not the back (right)
				# Paddle is vertical on the right side, so negative X offset = front/left = good
				# Positive X offset = back/right = bad (ball would be lost immediately)
				if paddle_offset.x > 0:
					# Ball grabbed on back side - move it to front side at same Y position
					paddle_offset.x = -abs(paddle_offset.x)
		else:
			# Paddle collision: reflect + add spin
			velocity = velocity.bounce(normal)

			# Add paddle spin influence
			if paddle_reference and paddle_reference.has_method("get_velocity_for_spin"):
				var paddle_velocity = paddle_reference.get_velocity_for_spin()
				velocity.y += paddle_velocity * SPIN_FACTOR
				if abs(paddle_velocity) >= HIGH_SPIN_THRESHOLD:
					spin_trail_timer = HIGH_SPIN_TRAIL_DURATION

			# Prevent pure vertical motion
			if abs(velocity.x) < current_speed * (1.0 - MAX_VERTICAL_ANGLE):
				velocity.x = sign(velocity.x) * current_speed * (1.0 - MAX_VERTICAL_ANGLE)

			# Prevent paddle-bottom wall wedge by nudging ball upward at the boundary
			var min_y = TOP_WALL_Y + ball_radius
			var max_y = BOTTOM_WALL_Y - ball_radius
			if position.y < min_y:
				position.y = min_y
				velocity.y = abs(velocity.y)
			elif position.y > max_y:
				position.y = max_y
				velocity.y = -abs(velocity.y)

			if frame_air_ball_active:
				_jump_to_level_center_x(hit_y)
				return
		AudioManager.play_sfx("hit_paddle")

	elif collider.is_in_group("brick"):
		# Brick collision: reflect + notify brick
		var old_velocity = velocity  # Store for particle direction
		var hit_brick_position = collider.global_position  # Store for bomb effect
		var is_unbreakable = false
		if "brick_type" in collider:
			is_unbreakable = collider.brick_type == BRICK_TYPE_UNBREAKABLE

		var is_block_brick = collider.is_in_group("block_brick")
		if is_block_brick and (velocity.x < 0.0 or grab_immunity_timer > 0.0 or block_pass_timer > 0.0):
			# Allow held/just-launched balls to pass block bricks when moving left
			position += velocity * last_physics_delta
			return

		# Check if brick through is enabled (block + unbreakable bricks always behave normally)
		if not is_block_brick and not is_unbreakable and frame_brick_through_active:
			# Don't bounce, just pass through and notify brick
			brick_hit.emit(collider)
			if collider.has_method("hit"):
				collider.hit(old_velocity.normalized())
		else:
			var bounce_normal = normal
			if collider.has_method("_get_brick_shape") and collider._get_brick_shape() == "square":
				var hit_pos = collision.get_position()
				var offset = hit_pos - collider.global_position
				if abs(offset.x) > abs(offset.y):
					var x_sign = sign(offset.x)
					if x_sign != 0:
						bounce_normal = Vector2(x_sign, 0)
				elif abs(offset.y) > abs(offset.x):
					var y_sign = sign(offset.y)
					if y_sign != 0:
						bounce_normal = Vector2(0, y_sign)
			# Normal bounce behavior
			velocity = velocity.bounce(bounce_normal)
			normal = bounce_normal
			if is_unbreakable:
				# Add a small random deflection to avoid edge hugging
				velocity = velocity.rotated(deg_to_rad(randf_range(-12.0, 12.0)))
				position += bounce_normal * (ball_radius * 0.6)
			brick_hit.emit(collider)
			if collider.has_method("hit"):
				collider.hit(old_velocity.normalized())
		AudioManager.play_sfx("hit_brick")

		# Check if bomb ball is active - destroy surrounding bricks (skip block bricks)
		if not is_block_brick and frame_bomb_ball_active:
			destroy_surrounding_bricks(hit_brick_position)

	else:
		# Wall collision: simple reflection
		AudioManager.play_sfx("hit_wall")
		velocity = velocity.bounce(normal)

	if collider != null:
		last_collision_normal = normal
		last_collision_collider = collider
		last_collision_age = 0.0

func reset_ball():
	"""Reset ball to paddle after losing a life"""
	is_attached_to_paddle = true
	velocity = Vector2.ZERO
	aim_available = is_main_ball
	_set_aim_mode(false)
	aim_direction = Vector2.LEFT

	# Disable trail effect
	if trail_node:
		trail_node.emitting = false

func apply_speed_up_effect():
	"""Increase ball speed to 650 for 12 seconds"""
	current_speed = SPEED_UP_VALUE
	# Update velocity magnitude immediately if ball is moving
	if not is_attached_to_paddle:
		velocity = velocity.normalized() * current_speed

	# Change trail color to yellow/orange for fast speed (if trail enabled)
	_update_trail_appearance()

func apply_slow_down_effect():
	"""Decrease ball speed to 350 for 12 seconds"""
	current_speed = SLOW_DOWN_VALUE
	# Update velocity magnitude immediately if ball is moving
	if not is_attached_to_paddle:
		velocity = velocity.normalized() * current_speed

	# Change trail color to blue for slow speed (if trail enabled)
	_update_trail_appearance()

func reset_ball_speed():
	"""Reset ball speed to normal (with difficulty multiplier applied)"""
	base_speed = BASE_SPEED * DifficultyManager.get_speed_multiplier()
	current_speed = base_speed
	# Update velocity magnitude immediately if ball is moving
	if not is_attached_to_paddle:
		velocity = velocity.normalized() * current_speed

	# Reset trail color to default (if trail enabled)
	_update_trail_appearance()

func _update_trail_appearance() -> void:
	if not trail_node:
		return
	if not SaveManager.get_ball_trail():
		return
	var new_texture = TRAIL_SMALL
	if spin_trail_timer > 0.0:
		new_texture = TRAIL_LARGE
	elif current_speed >= base_speed * FAST_SPEED_MULTIPLIER:
		new_texture = TRAIL_MEDIUM
	if trail_node.texture != new_texture:
		trail_node.texture = new_texture
	var new_color = _get_trail_color()
	if trail_node.color != new_color:
		trail_node.color = new_color

func _get_trail_color() -> Color:
	if visual_node:
		var visual_color = visual_node.modulate
		if visual_color != Color(1.0, 1.0, 1.0, 1.0):
			return visual_color
	if current_speed >= base_speed * FAST_SPEED_MULTIPLIER:
		return TRAIL_COLOR_FAST
	if current_speed <= base_speed * SLOW_SPEED_MULTIPLIER:
		return TRAIL_COLOR_SLOW
	return TRAIL_COLOR_NORMAL

func _unhandled_input(event: InputEvent) -> void:
	if not is_main_ball:
		return
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and aim_active:
			virtual_mouse_pos += event.relative
			var viewport_size = viewport_ref.get_visible_rect().size
			virtual_mouse_pos.x = clampf(virtual_mouse_pos.x, 0.0, viewport_size.x)
			virtual_mouse_pos.y = clampf(virtual_mouse_pos.y, 0.0, viewport_size.y)
	if event.is_action_pressed("ui_cancel") and aim_active:
		_set_aim_mode(false)
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			if _can_use_aim():
				_set_aim_mode(true)
		else:
			if aim_active:
				_set_aim_mode(false)
				aim_direction = Vector2.LEFT

func set_is_main_ball(value: bool) -> void:
	is_main_ball = value
	set_process_unhandled_input(value)
	if not value:
		aim_available = false
		_set_aim_mode(false)

func _can_use_aim() -> bool:
	if not aim_available:
		return false
	if not is_attached_to_paddle:
		return false
	if game_manager == null:
		return false
	return game_manager.game_state == game_manager.GameState.READY

func _set_aim_mode(enabled: bool) -> void:
	if aim_active == enabled:
		return
	aim_active = enabled
	if paddle_reference and paddle_reference.has_method("set_aim_lock"):
		paddle_reference.set_aim_lock(enabled)
	if aim_indicator_root:
		aim_indicator_root.visible = enabled
	if enabled:
		_update_aim_direction()

func _create_aim_indicator() -> void:
	if aim_indicator_root != null:
		return
	aim_indicator_root = Node2D.new()
	aim_indicator_root.name = "AimIndicator"
	add_child(aim_indicator_root)
	aim_indicator_root.visible = false

	aim_shaft = Line2D.new()
	aim_shaft.width = 4.0
	aim_shaft.default_color = Color(0.9, 0.9, 1.0, 0.9)
	aim_shaft.points = [Vector2.ZERO, Vector2.LEFT * AIM_LENGTH]
	aim_indicator_root.add_child(aim_shaft)

	aim_head = Line2D.new()
	aim_head.width = 4.0
	aim_head.default_color = Color(0.9, 0.9, 1.0, 0.9)
	aim_head.points = [Vector2.LEFT * AIM_LENGTH, Vector2.LEFT * (AIM_LENGTH - AIM_HEAD_LENGTH), Vector2.LEFT * AIM_LENGTH]
	aim_indicator_root.add_child(aim_head)

func _update_aim_direction() -> void:
	if aim_indicator_root == null:
		return
	if paddle_reference:
		aim_indicator_root.global_position = global_position
	var mouse_captured = Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	if mouse_captured != was_mouse_captured:
		if not mouse_captured:
			virtual_mouse_pos = viewport_ref.get_mouse_position()
		was_mouse_captured = mouse_captured
	var mouse_pos = virtual_mouse_pos if mouse_captured else viewport_ref.get_mouse_position()
	if not mouse_captured:
		virtual_mouse_pos = mouse_pos
	var global_dir = (mouse_pos - global_position)
	global_dir.x = -abs(global_dir.x) - 6.0
	if global_dir.length() < 1.0:
		global_dir = Vector2.LEFT
	var angle = rad_to_deg(atan2(global_dir.y, global_dir.x))
	if angle < 0:
		angle += 360.0
	angle = clamp(angle, AIM_MIN_ANGLE, AIM_MAX_ANGLE)
	var angle_rad = deg_to_rad(angle)
	aim_direction = Vector2(cos(angle_rad), sin(angle_rad)).normalized()

	var end_point = aim_direction * AIM_LENGTH
	if aim_shaft:
		aim_shaft.set_point_position(0, Vector2.ZERO)
		aim_shaft.set_point_position(1, end_point)
	if aim_head:
		var back_dir = -aim_direction
		var head_left = end_point + back_dir.rotated(deg_to_rad(AIM_HEAD_ANGLE)) * AIM_HEAD_LENGTH
		var head_right = end_point + back_dir.rotated(deg_to_rad(-AIM_HEAD_ANGLE)) * AIM_HEAD_LENGTH
		aim_head.set_point_position(0, head_left)
		aim_head.set_point_position(1, end_point)
		aim_head.set_point_position(2, head_right)

func enable_grab():
	"""Compatibility hook: grab state is sourced from PowerUpManager."""
	pass

func reset_grab_state():
	"""Compatibility hook: grab state is sourced from PowerUpManager."""
	pass

func enable_brick_through():
	"""Compatibility hook: brick-through state is sourced from PowerUpManager."""
	pass

func reset_brick_through():
	"""Compatibility hook: brick-through state is sourced from PowerUpManager."""
	pass

func enable_bomb_ball():
	"""Compatibility hook: keep visual state in sync for active bomb-ball."""
	_apply_bomb_ball_visual(true)

func reset_bomb_ball():
	"""Compatibility hook: keep visual state in sync for inactive bomb-ball."""
	_apply_bomb_ball_visual(false)

func enable_air_ball():
	"""Compatibility hook: air-ball state is sourced from PowerUpManager."""
	pass

func reset_air_ball():
	"""Compatibility hook: air-ball state is sourced from PowerUpManager."""
	pass

func enable_magnet():
	"""Compatibility hook: magnet state is sourced from PowerUpManager."""
	pass

func reset_magnet():
	"""Compatibility hook: magnet state is sourced from PowerUpManager."""
	pass

func _ensure_paddle_reference() -> void:
	if paddle_reference and is_instance_valid(paddle_reference):
		return
	var candidate = get_tree().get_first_node_in_group("paddle")
	if candidate and is_instance_valid(candidate) and candidate is Node2D:
		paddle_reference = candidate as Node2D
	else:
		paddle_reference = null

func _is_moving_toward_paddle_horizontally() -> bool:
	if not paddle_reference or not is_instance_valid(paddle_reference):
		return false
	var to_paddle_x = paddle_reference.position.x - position.x
	return to_paddle_x * velocity.x > 0.0

func _apply_magnet_pull(delta: float) -> void:
	if not _is_moving_toward_paddle_horizontally():
		return
	var to_paddle = paddle_reference.position - position
	var dist_sq = to_paddle.length_squared()
	if dist_sq <= 0.0001:
		return
	var accel = MAGNET_PULL * delta
	var inv_len = 1.0 / sqrt(dist_sq)
	var next_vx = velocity.x + (to_paddle.x * inv_len * accel)
	var next_vy = velocity.y + (to_paddle.y * inv_len * accel)
	var next_len_sq = (next_vx * next_vx) + (next_vy * next_vy)
	if next_len_sq <= 0.0001:
		return
	var speed_scale = current_speed / sqrt(next_len_sq)
	velocity.x = next_vx * speed_scale
	velocity.y = next_vy * speed_scale

func _handle_out_of_bounds() -> void:
	if position.x > RIGHT_BOUNDARY_X:
		# Past right boundary (lost) - handler in main.gd decides life penalty.
		ball_lost.emit(self)
		return
	if position.x < LEFT_BOUNDARY_X:
		_handle_error_boundary_escape(BOUNDARY_LEFT_ERROR_LABEL)
		return
	if position.y < TOP_BOUNDARY_Y:
		_handle_error_boundary_escape(BOUNDARY_TOP_ERROR_LABEL)
		return
	if position.y > BOTTOM_BOUNDARY_Y:
		_handle_error_boundary_escape(BOUNDARY_BOTTOM_ERROR_LABEL)

func _handle_error_boundary_escape(boundary_name: String) -> void:
	ball_lost.emit(self)
	push_warning("Ball escaped %s boundary at %s" % [boundary_name, str(position)])

	# Main ball should be reset, not removed
	if is_main_ball:
		call_deferred("reset_ball")
		return

	# Extra balls can be safely removed
	set_physics_process(false)
	visible = false
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	call_deferred("queue_free")

func _refresh_effect_flags() -> void:
	if PowerUpManager:
		frame_grab_active = PowerUpManager.is_grab_active()
		frame_brick_through_active = PowerUpManager.is_brick_through_active()
		frame_bomb_ball_active = PowerUpManager.is_bomb_ball_active()
		frame_air_ball_active = PowerUpManager.is_air_ball_active()
		frame_magnet_active = PowerUpManager.is_magnet_active()
	else:
		frame_grab_active = false
		frame_brick_through_active = false
		frame_bomb_ball_active = false
		frame_air_ball_active = false
		frame_magnet_active = false

	if frame_bomb_ball_active != bomb_visual_active:
		_apply_bomb_ball_visual(frame_bomb_ball_active)

func _apply_bomb_ball_visual(active: bool) -> void:
	bomb_visual_active = active
	if visual_node:
		# Orange-red while bomb-ball is active, white otherwise.
		visual_node.modulate = Color(1.0, 0.4, 0.1, 1.0) if active else Color(1.0, 1.0, 1.0, 1.0)
	_update_trail_appearance()

func _jump_to_level_center_x(hit_y: float):
	var landing_data = _get_air_ball_landing_data()
	var center_x = landing_data["center_x"]
	var step_x = landing_data["step_x"]
	position = Vector2(center_x, hit_y) + velocity.normalized() * AIR_BALL_LANDING_OFFSET
	_resolve_air_ball_landing(center_x, hit_y, step_x)

func _get_air_ball_helper() -> RefCounted:
	if air_ball_helper == null:
		air_ball_helper = AIR_BALL_HELPER_SCRIPT.new()
	return air_ball_helper

func _get_air_ball_landing_data() -> Dictionary:
	var center_x = _get_fallback_center_x()
	var step_x = ball_radius * 2.0 + AIR_BALL_STEP_FALLBACK_PADDING
	var helper = _get_air_ball_helper()

	if game_manager:
		var level_id: int = game_manager.current_level
		if helper and helper.has_method("is_cached_level") and helper.call("is_cached_level", level_id):
			return helper.call("get_landing_data", level_id, center_x, step_x)

		var level_data = LevelLoader.load_level_data(level_id)
		if not level_data.is_empty():
			var grid = level_data.get("grid", {})
			var brick_size = grid.get("brick_size", 48)
			var spacing = grid.get("spacing", 3)
			var start_x = grid.get("start_x", 150)
			step_x = float(brick_size + spacing)

			var bricks = level_data.get("bricks", [])
			if bricks.size() > 0:
				var min_col = bricks[0].get("col", 0)
				var max_col = min_col
				for brick_def in bricks:
					var col = brick_def.get("col", 0)
					min_col = min(min_col, col)
					max_col = max(max_col, col)
				center_x = float(start_x) + ((min_col + max_col) / 2.0) * step_x
			else:
				center_x = float(start_x)
			if helper and helper.has_method("cache_landing_data"):
				helper.call("cache_landing_data", level_id, center_x, step_x)

	return {
		"center_x": center_x,
		"step_x": step_x
	}

func _get_fallback_center_x() -> float:
	if viewport_ref:
		return viewport_ref.get_visible_rect().size.x * 0.5
	return AIR_BALL_FALLBACK_CENTER_X

func _resolve_air_ball_landing(center_x: float, hit_y: float, step_x: float) -> void:
	var base_pos = Vector2(center_x, hit_y)
	var helper = _get_air_ball_helper()
	if helper == null:
		return

	var unbreakable_row = helper.call(
		"get_unbreakable_bricks_near_y",
		hit_y,
		ball_radius,
		AIR_BALL_UNBREAKABLE_HALF_SIZE,
		AIR_BALL_ROW_MARGIN,
		_get_cached_level_bricks(),
		BRICK_TYPE_UNBREAKABLE
	)
	if not unbreakable_row.is_empty():
		if not helper.call(
			"is_unbreakable_slot_blocked",
			base_pos,
			unbreakable_row,
			ball_radius,
			AIR_BALL_UNBREAKABLE_HALF_SIZE,
			AIR_BALL_ROW_MARGIN
		):
			return
		for i in range(1, AIR_BALL_SEARCH_MAX_STEPS + 1):
			for dir in [-1, 1]:
				var test_pos = base_pos + Vector2(step_x * float(i) * float(dir), 0.0)
				if helper.call(
					"is_unbreakable_slot_blocked",
					test_pos,
					unbreakable_row,
					ball_radius,
					AIR_BALL_UNBREAKABLE_HALF_SIZE,
					AIR_BALL_ROW_MARGIN
				):
					continue
				position = test_pos + velocity.normalized() * AIR_BALL_LANDING_OFFSET
				return

		# Last resort: nudge upward away from the blocked slot.
		position = base_pos + Vector2(0.0, -ball_radius * 2.0)
		return

	# Fallback when cached row data is unavailable.
	var world = get_world_2d()
	if world == null:
		return
	var space = world.direct_space_state
	if space == null:
		return

	var air_landing_query: PhysicsShapeQueryParameters2D = helper.call(
		"ensure_landing_query",
		self,
		ball_radius,
		collision_mask
	)
	if air_landing_query == null:
		return

	air_landing_query.transform = Transform2D(0, base_pos)
	if not helper.call(
		"is_unbreakable_overlap",
		space,
		air_landing_query,
		AIR_BALL_QUERY_MAX_RESULTS,
		BRICK_TYPE_UNBREAKABLE
	):
		return

	for i in range(1, AIR_BALL_SEARCH_MAX_STEPS + 1):
		for dir in [-1, 1]:
			var test_pos = base_pos + Vector2(step_x * float(i) * float(dir), 0.0)
			air_landing_query.transform = Transform2D(0, test_pos)
			if not helper.call(
				"is_unbreakable_overlap",
				space,
				air_landing_query,
				AIR_BALL_QUERY_MAX_RESULTS,
				BRICK_TYPE_UNBREAKABLE
			):
				position = test_pos + velocity.normalized() * AIR_BALL_LANDING_OFFSET
				return

	# Last resort: nudge upward away from the blocked slot.
	position = base_pos + Vector2(0.0, -ball_radius * 2.0)

func _get_cached_level_bricks() -> Array[Node]:
	if (main_controller_ref == null or not is_instance_valid(main_controller_ref)):
		_cache_main_controller_ref()
	if main_controller_ref and main_controller_ref.has_method("get_cached_level_bricks"):
		return main_controller_ref.get_cached_level_bricks()
	# Fallback to current behavior when cached list is unavailable.
	var brick_parent = get_parent()
	if brick_parent and brick_parent.has_node("BrickContainer"):
		return brick_parent.get_node("BrickContainer").get_children()
	return []

func _cache_main_controller_ref() -> void:
	var candidate = get_tree().get_first_node_in_group("main_controller")
	if candidate and is_instance_valid(candidate):
		main_controller_ref = candidate

func destroy_surrounding_bricks(impact_position: Vector2):
	"""Destroy bricks in a radius around the impact point (bomb ball effect)"""
	var bomb_radius_sq = BOMB_BALL_RADIUS * BOMB_BALL_RADIUS

	var all_bricks = _get_cached_level_bricks()

	for brick in all_bricks:
		if not is_instance_valid(brick):
			continue
		if brick.is_in_group("block_brick"):
			continue
		if "brick_type" in brick and brick.brick_type == BRICK_TYPE_UNBREAKABLE:
			continue

		# Check distance from impact point using squared values (avoid sqrt in hot path)
		var dist_sq = brick.global_position.distance_squared_to(impact_position)
		if dist_sq <= bomb_radius_sq:
			# Break this brick with a fake velocity
			if brick.has_method("break_brick"):
				brick.break_brick(Vector2(-1, 0))  # Use left direction for consistency
			elif brick.has_method("hit"):
				brick.hit(Vector2(-1, 0))  # Fallback for safety

	_update_trail_appearance()

func apply_big_ball_effect():
	"""Double ball size for power-up duration"""
	_set_ball_radius(BASE_RADIUS * 2.0)

func apply_small_ball_effect():
	"""Half ball size for power-up duration"""
	_set_ball_radius(BASE_RADIUS * 0.5)

func reset_ball_size():
	"""Reset ball to base size"""
	_set_ball_radius(BASE_RADIUS)

func get_ball_radius() -> float:
	return ball_radius

func set_ball_radius(new_radius: float):
	_set_ball_radius(new_radius)

func get_base_radius() -> float:
	return BASE_RADIUS

func set_ball_size_multiplier(multiplier: float):
	_set_ball_radius(BASE_RADIUS * multiplier)

func _set_ball_radius(new_radius: float):
	ball_radius = new_radius
	if collision_shape_node and collision_shape_node.shape is CircleShape2D:
		collision_shape_node.shape.radius = new_radius
	if visual_node:
		var scale_factor = new_radius / BASE_RADIUS
		visual_node.scale = BASE_VISUAL_SCALE * scale_factor
	_update_trail_appearance()

func refresh_trail_state() -> void:
	if not trail_node:
		return
	trail_node.emitting = SaveManager.get_ball_trail() and not is_attached_to_paddle
	_update_trail_appearance()

func enable_collision_immunity(_duration: float = 0.5):
	"""No longer needed - ball-to-ball collisions disabled at physics layer"""
	# Balls no longer collide with each other at all (mask excludes layer 1)
	# This function kept for compatibility but does nothing
	pass

func check_if_stuck(delta: float):
	"""Detect if ball is stuck and give it a boost to escape"""
	# Skip check if attached to paddle
	if is_attached_to_paddle:
		stuck_check_timer = 0.0
		last_position = position
		return

	# Use per-frame threshold (ball should move at least speed*delta pixels per frame)
	# At 500 speed and 60fps, that's ~8.3 pixels per frame minimum
	var expected_movement = current_speed * delta * 0.5  # 50% of expected (account for bouncing)
	var distance_moved_sq = position.distance_squared_to(last_position)
	var expected_movement_sq = expected_movement * expected_movement

	if distance_moved_sq < expected_movement_sq:
		# Ball hasn't moved much - increment timer
		stuck_check_timer += delta

		if stuck_check_timer >= stuck_threshold:
			# Ball is stuck! Give it a boost to escape
			push_warning("Ball appears stuck at %s - applying escape boost" % str(position))

			var used_collision_escape = false
			if last_collision_collider != null and is_instance_valid(last_collision_collider):
				if last_collision_collider.is_in_group("brick") and "brick_type" in last_collision_collider:
					if last_collision_collider.brick_type == BRICK_TYPE_UNBREAKABLE and last_collision_age <= 0.75:
						# Push away from the unbreakable face and add a deflection
						var escape_normal = last_collision_normal if last_collision_normal != Vector2.ZERO else Vector2.LEFT
						position += escape_normal * (ball_radius * 1.2)
						velocity = velocity.bounce(escape_normal).rotated(deg_to_rad(randf_range(-18.0, 18.0)))
						used_collision_escape = true

			if not used_collision_escape:
				# Random escape direction (prefer left and down/up to avoid paddle)
				var escape_angle = randf_range(135.0, 225.0)  # Left hemisphere
				var angle_rad = deg_to_rad(escape_angle)
				velocity = Vector2(cos(angle_rad), sin(angle_rad)) * current_speed

			# Reset timer
			stuck_check_timer = 0.0
	else:
		# Ball is moving normally - reset timer
		stuck_check_timer = 0.0

	# IMPORTANT: Always update last_position for next frame comparison
	last_position = position
