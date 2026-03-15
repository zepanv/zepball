extends CharacterBody2D

## Ball - Physics-based ball with collision detection and spin mechanics
## Bounces off walls, paddle, and bricks
## Paddle movement affects ball trajectory (spin)

# Ball physics constants
const BASE_SPEED = 500.0   # Base speed (pixels/second)
const BASE_RADIUS = 16.0
const BASE_VISUAL_SCALE = Vector2(0.0185, 0.0185)
const MAX_VERTICAL_ANGLE = 0.8  # Prevent pure vertical/horizontal motion
const INITIAL_ANGLE = -45.0     # Launch angle (degrees, toward left)
const MAGNET_PULL = 800.0       # Paddle gravity strength for Magnet power-up
const TOP_WALL_Y = 20.0
const BOTTOM_WALL_Y = 700.0
const SPIN_DECAY_RATE = 0.85
const SPIN_CURVE_STRENGTH = 320.0
const SPIN_IMPART_FACTOR = 0.45
const SPIN_MAX_ANGLE_CHANGE_DEG = 25.0
const SPIN_ON_HIT_DECAY = 0.5
const SPIN_MAX = 800.0
const HIGH_SPIN_THRESHOLD = 250.0
const PENETRATING_SPIN_THRESHOLD = 400.0
const FORCE_ARROW_RANGE = 120.0
const FORCE_ARROW_MAX_STRENGTH = 4000.0
const FORCE_ARROW_MIN_STRENGTH = 800.0
const FORCE_ARROW_DWELL_MULTIPLIER = 2.5  # Max multiplier from dwell time
const FORCE_ARROW_DWELL_CHARGE_TIME = 0.8  # Seconds to reach max multiplier
const FAST_SPEED_MULTIPLIER = 1.15
const BRICK_TYPE_UNBREAKABLE = 2
const BRICK_TYPE_FORCE_ARROW = 14
const BRICK_TYPE_POWERUP_BRICK = 15
const RIGHT_BOUNDARY_X = 1300.0
const LEFT_BOUNDARY_X = 0.0
const TOP_BOUNDARY_Y = 0.0
const BOTTOM_BOUNDARY_Y = 720.0
const TOP_ESCAPE_ZONE_Y = 80.0
const BOTTOM_ESCAPE_ZONE_Y = 620.0
const SPEED_UP_MULTIPLIER = 1.30
const SLOW_DOWN_MULTIPLIER = 0.70
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
const AIM_HELPER_SCRIPT = preload("res://scripts/ball_aim_indicator_helper.gd")
const STUCK_HELPER_SCRIPT = preload("res://scripts/ball_stuck_detection_helper.gd")
const BALL_COLLISION_HELPER_SCRIPT = preload("res://scripts/ball_collision_helper.gd")
var collision_helper: RefCounted = null
const BALL_VISUAL_HELPER_SCRIPT = preload("res://scripts/ball_visual_helper.gd")
var visual_helper: RefCounted = null
const TRAIL_COLOR_NORMAL = Color(0.3, 0.6, 0.95, 0.7)
const TRAIL_COLOR_FAST = Color(1.0, 0.8, 0.2, 0.7)
const TRAIL_COLOR_SLOW = Color(0.2, 0.6, 1.0, 0.7)
const TRAIL_COLOR_HIGH_SPIN = Color(1.0, 0.35, 0.9, 0.8)

# Dynamic speed (can be modified by power-ups)
var current_speed: float = BASE_SPEED
var base_speed: float = BASE_SPEED
var external_speed_multiplier: float = 1.0
var speed_powerup_multiplier: float = 1.0

# State
var is_attached_to_paddle = true
var paddle_reference: Node2D = null
var game_manager: Node = null
var is_main_ball: bool = true  # Identifies the original ball in the scene
var paddle_offset: Vector2 = Vector2(-30, 0)  # Offset from paddle when attached/grabbed
var grab_immunity_timer: float = 0.0  # Prevents immediate re-grab after launch
var block_pass_timer: float = 0.0  # Allow pass-through behind block right after launch
var time_since_paddle_hit: float = -1.0  # Seconds since last paddle contact; -1 = never hit

var ball_radius: float = BASE_RADIUS
var last_physics_delta: float = 0.0
var spin_amount: float = 0.0
var force_arrow_dwell_time: float = 0.0
var current_force_arrow: Node = null
var air_ball_helper: RefCounted = null
var aim_helper: RefCounted = null
var stuck_helper: RefCounted = null
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
var force_arrow_audio: AudioStreamPlayer = null

# Signals
signal ball_lost
signal ball_launched(launched_ball: Node)
signal brick_hit(brick)

func _emit_brick_hit(brick: Variant) -> void:
	brick_hit.emit(brick)

func _ready():
	# Add to ball group for collision detection
	add_to_group("ball")
	if PowerUpManager and PowerUpManager.has_method("register_ball"):
		PowerUpManager.register_ball(self)

	# Apply difficulty multiplier to base speed
	_recalculate_speed()
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

	# Create dedicated audio player for force arrow sound
	_init_force_arrow_audio()

	_ensure_aim_helper()
	aim_helper.create_indicator(self)
	aim_helper.virtual_mouse_pos = viewport_ref.get_mouse_position()
	stuck_helper = STUCK_HELPER_SCRIPT.new()
	collision_helper = BALL_COLLISION_HELPER_SCRIPT.new()
	_ensure_visual_helper()
	set_process_unhandled_input(is_main_ball)

	if collision_shape_node and collision_shape_node.shape is CircleShape2D:
		ball_radius = collision_shape_node.shape.radius
	# Grabbed/attached balls have their collision disabled so approaching balls
	# can reach the paddle directly instead of piling up against them.
	if collision_shape_node:
		collision_shape_node.disabled = is_attached_to_paddle
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

	# Decrement timers
	if grab_immunity_timer > 0.0:
		grab_immunity_timer -= delta
	if block_pass_timer > 0.0:
		block_pass_timer -= delta
	if time_since_paddle_hit >= 0.0:
		time_since_paddle_hit += delta
	if paddle_reference == null or not is_instance_valid(paddle_reference):
		_ensure_paddle_reference()
	_refresh_effect_flags()

	if is_attached_to_paddle:
		# Ball follows paddle until launched, maintaining the attachment offset
		if paddle_reference:
			position = paddle_reference.position + paddle_offset
		if aim_helper.aim_active:
			aim_helper.update_direction(self, viewport_ref)

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
		stuck_helper.tick_collision_age(delta)
		# Ball is in motion
		_apply_persistent_spin(delta)
		_apply_force_arrows(delta)
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
		stuck_helper.check(self, delta, current_speed, ball_radius, is_attached_to_paddle)

		# Check if ball went out of bounds
		_handle_out_of_bounds()

		# Maintain constant speed (arcade feel)
		velocity = velocity.normalized() * current_speed

		# Enforce minimum horizontal velocity to prevent near-vertical oscillation
		# between top and bottom walls (same threshold used for paddle bounces)
		var min_vx = current_speed * (1.0 - MAX_VERTICAL_ANGLE)
		if abs(velocity.x) < min_vx:
			var h_dir = sign(velocity.x)
			if h_dir == 0:
				h_dir = -1  # Default toward bricks (left)
			velocity.x = h_dir * min_vx
			velocity = velocity.normalized() * current_speed

		# Rotate ball to show movement/spin (only if actually moving)
		# Rotation based on distance traveled (creates rolling effect)
		if visual_node and velocity.length_squared() > 100.0:
			var spin_ratio = clampf(absf(spin_amount) / SPIN_MAX, 0.0, 1.0)
			var rotation_speed = (current_speed / 16.0) + (spin_ratio * 20.0)
			visual_node.rotation += rotation_speed * delta

		_update_trail_appearance()

func launch_ball():
	"""Launch ball from paddle at initial angle
	If paddle is moving, impart spin. Otherwise, shoot straight left.
	"""
	is_attached_to_paddle = false
	if collision_shape_node:
		collision_shape_node.disabled = false
	var launched_with_aim = false
	spin_amount = 0.0
	if aim_helper.aim_active:
		var aim_dir = aim_helper.aim_direction.normalized()
		aim_helper.set_mode(false, paddle_reference)
		velocity = aim_dir * current_speed
		launched_with_aim = true

	# Set grab immunity to prevent immediate re-grab after launch
	grab_immunity_timer = 0.2  # 200ms immunity
	block_pass_timer = 0.35  # Allow passing block barrier on launch

	# Add small random position offset to prevent stacked balls from colliding
	# This helps when multiple balls are grabbed at the same spot
	# Always offset to the left (negative X) to ensure balls don't spawn behind the paddle
	position += Vector2(randf_range(-8.0, -3.0), randf_range(-3.0, 3.0))

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
			# Launch toward left based on paddle movement direction
			# In Godot: 180° = left, 135° = up-left, 225° = down-left
			var base_angle = 180.0
			if paddle_velocity_y < 0:  # Paddle moving UP - aim more downward
				base_angle = 225.0  # down-left
			else:  # Paddle moving DOWN - aim more upward  
				base_angle = 135.0  # up-left
			var angle_rad = deg_to_rad(base_angle + angle_variation)
			velocity = Vector2(cos(angle_rad), sin(angle_rad)) * current_speed
			# Clamp launch spin to lower value than max to prevent dangerous curves on launch
			var launch_spin_max = SPIN_MAX * 0.5  # 50% of max spin on launch
			var raw_spin = paddle_velocity_y * SPIN_IMPART_FACTOR
			# Reduce spin if paddle is moving very fast (prevents extreme curves that could go behind paddle)
			if abs(raw_spin) > launch_spin_max:
				raw_spin = sign(raw_spin) * launch_spin_max
			# Also reduce spin if ball will be heading right after bouncing (dangerous)
			if position.y > BOTTOM_ESCAPE_ZONE_Y * 0.7 or position.y < TOP_ESCAPE_ZONE_Y * 1.3:
				raw_spin *= 0.5  # Reduce spin when near vertical boundaries
			spin_amount = raw_spin
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

	aim_helper.aim_available = false
	ball_launched.emit(self)

func handle_collision(collision: KinematicCollision2D):
	collision_helper.handle_collision(self, collision)


func reset_ball():
	"""Reset ball to paddle after losing a life"""
	is_attached_to_paddle = true
	paddle_offset = Vector2(-30, 0)  # Restore default front-of-paddle position
	if collision_shape_node:
		collision_shape_node.disabled = true
	velocity = Vector2.ZERO
	spin_amount = 0.0
	force_arrow_dwell_time = 0.0
	current_force_arrow = null
	aim_helper.reset(is_main_ball)

	# Disable trail effect
	if trail_node:
		trail_node.emitting = false

	# Stop force arrow audio
	if force_arrow_audio and force_arrow_audio.playing:
		force_arrow_audio.stop()

func apply_speed_up_effect():
	"""Increase ball speed by a percentage of base speed."""
	speed_powerup_multiplier = SPEED_UP_MULTIPLIER
	_recalculate_speed()
	_update_trail_appearance()

func apply_slow_down_effect():
	"""Decrease ball speed by a percentage of base speed."""
	speed_powerup_multiplier = SLOW_DOWN_MULTIPLIER
	_recalculate_speed()
	_update_trail_appearance()

func reset_ball_speed():
	"""Reset ball speed to normal (with difficulty multiplier applied)"""
	speed_powerup_multiplier = 1.0
	_recalculate_speed()
	_update_trail_appearance()

func set_external_speed_multiplier(multiplier: float) -> void:
	external_speed_multiplier = max(0.1, multiplier)
	_recalculate_speed()
	_update_trail_appearance()

func get_external_speed_multiplier() -> float:
	return external_speed_multiplier

func _recalculate_speed() -> void:
	base_speed = BASE_SPEED * DifficultyManager.get_speed_multiplier() * external_speed_multiplier
	current_speed = base_speed * speed_powerup_multiplier
	if not is_attached_to_paddle and velocity.length_squared() > 0.0001:
		velocity = velocity.normalized() * current_speed

func _update_trail_appearance() -> void:
	_ensure_visual_helper()
	visual_helper._update_trail_appearance(self)


func _get_trail_color() -> Color:
	_ensure_visual_helper()
	return visual_helper._get_trail_color(self)


func _unhandled_input(event: InputEvent) -> void:
	if not is_main_ball:
		return
	aim_helper.handle_input(event, self, viewport_ref)

func set_is_main_ball(value: bool) -> void:
	is_main_ball = value
	set_process_unhandled_input(value)
	_ensure_aim_helper()
	aim_helper.aim_available = value
	if not value:
		aim_helper.set_mode(false, paddle_reference)

func _ensure_aim_helper() -> void:
	if aim_helper != null:
		return
	aim_helper = AIM_HELPER_SCRIPT.new()
	aim_helper.aim_available = is_main_ball

func _ensure_visual_helper() -> void:
	if visual_helper != null:
		return
	visual_helper = BALL_VISUAL_HELPER_SCRIPT.new()


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

func _apply_persistent_spin(delta: float) -> void:
	if absf(spin_amount) < 1.0:
		spin_amount = 0.0
		return
	var velocity_len_sq = velocity.length_squared()
	if velocity_len_sq <= 0.0001:
		return
	var velocity_len = sqrt(velocity_len_sq)

	# Store original direction
	var old_direction = velocity / velocity_len

	# Calculate perpendicular force
	var perp = Vector2(-velocity.y / velocity_len, velocity.x / velocity_len)
	var spin_ratio = clampf(spin_amount / SPIN_MAX, -1.0, 1.0)

	# Reduce spin near bottom boundary to prevent losses
	var danger_factor = 1.0
	if position.y > BOTTOM_ESCAPE_ZONE_Y and velocity.y > 0:
		danger_factor = 0.3  # Drastically reduce spin curve when heading toward loss
	# Reduce spin when heading back toward paddle (right side) to prevent going behind paddle
	if velocity.x > 0 and paddle_reference and is_instance_valid(paddle_reference):
		var dist_to_paddle = paddle_reference.position.x - position.x
		if dist_to_paddle > 0:  # Paddle is to the right
			danger_factor = 0.3  # Reduce curve when heading toward paddle

	velocity += perp * spin_ratio * SPIN_CURVE_STRENGTH * delta * danger_factor

	# Limit angle change per frame to prevent extreme trajectory flips
	var new_direction = velocity.normalized()
	var angle_change = old_direction.angle_to(new_direction)
	var max_angle_rad = deg_to_rad(SPIN_MAX_ANGLE_CHANGE_DEG * delta * 60.0)  # Scale by expected 60fps
	if absf(angle_change) > max_angle_rad:
		var clamped_angle = old_direction.angle() + sign(angle_change) * max_angle_rad
		velocity = Vector2.from_angle(clamped_angle) * velocity_len

	spin_amount *= pow(SPIN_DECAY_RATE, delta)

func _init_force_arrow_audio() -> void:
	"""Create and configure dedicated audio player for force arrow sound"""
	force_arrow_audio = AudioStreamPlayer.new()
	force_arrow_audio.bus = "SFX"
	if AudioManager and AudioManager.sfx_streams.has("force_arrow"):
		force_arrow_audio.stream = AudioManager.sfx_streams["force_arrow"]
	force_arrow_audio.volume_db = -80.0  # Start silent
	add_child(force_arrow_audio)

func _apply_force_arrows(delta: float) -> void:
	var nearest_arrow: Node = null
	var nearest_dist: float = FORCE_ARROW_RANGE + 1.0

	# Find nearest arrow in range
	for arrow in _get_cached_force_arrows():
		if not is_instance_valid(arrow):
			continue
		var dist = global_position.distance_to(arrow.global_position)
		if dist <= FORCE_ARROW_RANGE and dist < nearest_dist:
			nearest_arrow = arrow
			nearest_dist = dist

	# Track dwell time with nearest arrow
	if nearest_arrow != null:
		if current_force_arrow == nearest_arrow:
			# Still near same arrow - increase dwell time
			force_arrow_dwell_time += delta
		else:
			# Switched to different arrow - reset dwell
			current_force_arrow = nearest_arrow
			force_arrow_dwell_time = 0.0

		# Calculate dwell multiplier (1.0 to FORCE_ARROW_DWELL_MULTIPLIER)
		var dwell_progress = minf(force_arrow_dwell_time / FORCE_ARROW_DWELL_CHARGE_TIME, 1.0)
		var dwell_multiplier = 1.0 + (dwell_progress * (FORCE_ARROW_DWELL_MULTIPLIER - 1.0))

		# Apply force with dwell multiplier
		var force_dir = Vector2.RIGHT.rotated(deg_to_rad(int(nearest_arrow.direction)))
		var strength_factor = 1.0 - (nearest_dist / FORCE_ARROW_RANGE)
		var magnitude = lerpf(FORCE_ARROW_MIN_STRENGTH, FORCE_ARROW_MAX_STRENGTH, strength_factor)
		velocity += force_dir * magnitude * delta * dwell_multiplier

		# Control force arrow audio
		if force_arrow_audio:
			if not force_arrow_audio.playing:
				force_arrow_audio.play()
			# Scale volume from -6 dB to +6 dB based on dwell progress
			var target_volume_db = lerpf(-6.0, 6.0, dwell_progress)
			force_arrow_audio.volume_db = target_volume_db
	else:
		# No arrow in range - reset tracking and stop audio
		current_force_arrow = null
		force_arrow_dwell_time = 0.0
		if force_arrow_audio and force_arrow_audio.playing:
			force_arrow_audio.stop()

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

func _get_cached_force_arrows() -> Array[Node]:
	if (main_controller_ref == null or not is_instance_valid(main_controller_ref)):
		_cache_main_controller_ref()
	if main_controller_ref and main_controller_ref.has_method("get_cached_force_arrows"):
		var arrows: Array[Node] = main_controller_ref.get_cached_force_arrows()
		if not arrows.is_empty():
			return arrows
	var fallback: Array[Node] = []
	for node in get_tree().get_nodes_in_group("force_arrow"):
		if node is Node:
			fallback.append(node)
	return fallback

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
	push_warning("[BALL_ESCAPE] %s boundary pos=(%.1f,%.1f) vel=(%.1f,%.1f) speed=%.1f is_main=%s" % [
		boundary_name, position.x, position.y, velocity.x, velocity.y, current_speed, is_main_ball])

	# Nudge back inside the boundary and reflect — no life penalty for a physics edge case
	if position.x < LEFT_BOUNDARY_X:
		# Wall inner face is at x=20 (wall centre 10 + half-width 10).
		# Nudge past the wall geometry so move_and_collide can't re-embed the ball.
		position.x = 20.0 + ball_radius + 2.0
		velocity.x = abs(velocity.x)
	elif position.y < TOP_BOUNDARY_Y:
		# Top wall inner face is at y=20 (wall centre 10 + half-height 10).
		position.y = 20.0 + ball_radius + 2.0
		velocity.y = abs(velocity.y)
	elif position.y > BOTTOM_BOUNDARY_Y:
		# Bottom wall inner face is at y=700 (wall centre 710 - half-height 10).
		position.y = 700.0 - ball_radius - 2.0
		velocity.y = -abs(velocity.y)

	if not is_main_ball:
		# Extra ball escaped a non-right boundary. Position and velocity have been
		# corrected above — let it continue playing rather than removing it.
		# If it truly can't be recovered the right boundary will remove it normally.
		print("[BALL_ESCAPE_RECOVER] extra ball recovered at pos=(%.1f,%.1f) vel=(%.1f,%.1f)" % [
			position.x, position.y, velocity.x, velocity.y])

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
	_ensure_visual_helper()
	visual_helper._apply_bomb_ball_visual(self, active)


func _jump_to_level_center_x(hit_y: float):
	var landing_data = _get_air_ball_landing_data()
	var center_x = landing_data["center_x"]
	var step_x = landing_data["step_x"]
	position = Vector2(center_x, hit_y) + velocity.normalized() * AIR_BALL_LANDING_OFFSET
	# Clear spin on teleport — spin was acquired from the paddle hit and is no longer
	# contextually valid once the ball has jumped to the level center. Without this,
	# high paddle spin curves the ball back toward the paddle immediately after landing.
	spin_amount = 0.0
	_resolve_air_ball_landing(center_x, hit_y, step_x)

func _get_air_ball_helper() -> RefCounted:
	if air_ball_helper == null:
		air_ball_helper = AIR_BALL_HELPER_SCRIPT.new()
	return air_ball_helper

func _get_air_ball_landing_data() -> Dictionary:
	var step_x = ball_radius * 2.0 + AIR_BALL_STEP_FALLBACK_PADDING
	var center_x = _get_fallback_center_x()

	# Resolve step_x from level grid data when available (regular levels).
	# Blitz/survival packs are not in PackLoader so they use the fallback step.
	if game_manager:
		var pack_id: String = str(game_manager.current_pack_id)
		var level_index: int = int(game_manager.current_level_index)
		var level_data: Dictionary = PackLoader.get_level_data(pack_id, level_index)
		if not level_data.is_empty():
			var grid: Dictionary = level_data.get("grid", {})
			step_x = float(int(grid.get("brick_size", 48)) + int(grid.get("spacing", 3)))

	# Land in the second column from the leftmost live brick ("second-to-back row").
	# Using live positions makes this predictable across both regular levels and blitz,
	# and it adapts naturally as the leftmost bricks are cleared.
	var cached_bricks = _get_cached_level_bricks()
	if not cached_bricks.is_empty():
		var min_x: float = INF
		for brick in cached_bricks:
			if brick is Node2D:
				min_x = minf(min_x, (brick as Node2D).position.x)
		if min_x < INF:
			center_x = min_x + step_x

	return {"center_x": center_x, "step_x": step_x}

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
	collision_helper.destroy_surrounding_bricks(self, impact_position)


func apply_big_ball_effect():
	_ensure_visual_helper()
	visual_helper.apply_big_ball_effect(self)


func apply_small_ball_effect():
	_ensure_visual_helper()
	visual_helper.apply_small_ball_effect(self)


func reset_ball_size():
	_ensure_visual_helper()
	visual_helper.reset_ball_size(self)


func get_ball_radius() -> float:
	_ensure_visual_helper()
	return visual_helper.get_ball_radius(self)


func set_ball_radius(new_radius: float):
	_ensure_visual_helper()
	visual_helper.set_ball_radius(self, new_radius)


func get_base_radius() -> float:
	_ensure_visual_helper()
	return visual_helper.get_base_radius(self)


func set_ball_size_multiplier(multiplier: float):
	_ensure_visual_helper()
	visual_helper.set_ball_size_multiplier(self, multiplier)


func _set_ball_radius(new_radius: float):
	_ensure_visual_helper()
	visual_helper._set_ball_radius(self, new_radius)


func refresh_trail_state() -> void:
	_ensure_visual_helper()
	visual_helper.refresh_trail_state(self)


func enable_collision_immunity(_duration: float = 0.5):
	"""No longer needed - ball-to-ball collisions disabled at physics layer"""
	# Balls no longer collide with each other at all (mask excludes layer 1)
	# This function kept for compatibility but does nothing
	pass
