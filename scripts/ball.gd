extends CharacterBody2D

## Ball - Physics-based ball with collision detection and spin mechanics
## Bounces off walls, paddle, and bricks
## Paddle movement affects ball trajectory (spin)

# Ball physics constants
const BASE_current_speed = 500.0   # Base speed (pixels/second)
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

const TRAIL_SMALL = preload("res://assets/graphics/particles/particleSmallStar.png")
const TRAIL_MEDIUM = preload("res://assets/graphics/particles/particleStar.png")
const TRAIL_LARGE = preload("res://assets/graphics/particles/particleCartoonStar.png")
const TRAIL_COLOR_NORMAL = Color(0.3, 0.6, 0.95, 0.7)
const TRAIL_COLOR_FAST = Color(1.0, 0.8, 0.2, 0.7)
const TRAIL_COLOR_SLOW = Color(0.2, 0.6, 1.0, 0.7)

# Dynamic speed (can be modified by power-ups)
var current_speed: float = BASE_current_speed
var base_speed: float = BASE_current_speed

# State
var is_attached_to_paddle = true
var paddle_reference = null
var game_manager = null
var is_main_ball: bool = true  # Identifies the original ball in the scene
var direction_indicator: Line2D = null  # Visual launch direction indicator
var grab_enabled: bool = false  # Can ball be grabbed by paddle on contact
var brick_through_enabled: bool = false  # Does ball pass through bricks
var bomb_ball_enabled: bool = false  # Does ball destroy surrounding bricks
var air_ball_enabled: bool = false  # Does ball jump over bricks to center
var magnet_enabled: bool = false  # Does paddle attract ball
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

# Signals
signal ball_lost
signal brick_hit(brick)

func _ready():
	print("Ball initialized")
	# Add to ball group for collision detection
	add_to_group("ball")

	# Apply difficulty multiplier to base speed
	base_speed = BASE_current_speed * DifficultyManager.get_speed_multiplier()
	current_speed = base_speed

	# Find paddle in parent scene
	paddle_reference = get_tree().get_first_node_in_group("paddle")
	game_manager = get_tree().get_first_node_in_group("game_manager")
	if paddle_reference:
		print("Ball found paddle reference")
	else:
		print("Warning: Ball couldn't find paddle!")

	# Apply ball trail setting
	if has_node("Trail"):
		$Trail.emitting = false  # Starts disabled until launched
		$Trail.texture = TRAIL_SMALL
		$Trail.color = TRAIL_COLOR_NORMAL

	aim_available = is_main_ball
	_create_aim_indicator()
	set_process_unhandled_input(true)

	# Direction indicator disabled for now
	# create_direction_indicator()
	if has_node("CollisionShape2D"):
		var collision = $CollisionShape2D
		if collision.shape is CircleShape2D:
			ball_radius = collision.shape.radius
	if has_node("Visual"):
		$Visual.scale = BASE_VISUAL_SCALE

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
		# Ball is in motion
		# Apply magnet pull toward paddle (curve trajectory, keep speed)
		if magnet_enabled or PowerUpManager.is_magnet_active():
			if paddle_reference and velocity.dot(paddle_reference.position - position) > 0.0:
				var pull_dir = (paddle_reference.position - position).normalized()
				velocity = (velocity + pull_dir * MAGNET_PULL * delta).normalized() * current_speed

		# First check if we would collide with another ball
		var test_collision = move_and_collide(velocity * delta, true, true)  # test_only=true, safe_margin=true

		if test_collision and test_collision.get_collider().is_in_group("ball"):
			# Would collide with another ball - just move through it without collision
			position += velocity * delta
		else:
			# Normal collision detection for walls, paddle, bricks
			var collision = move_and_collide(velocity * delta)
			if collision:
				handle_collision(collision)

		# Check if ball is stuck (not moving much for too long)
		check_if_stuck(delta)

		# Check if ball went out of bounds
		var out_of_bounds = false
		var boundary_name = ""
		var is_error_boundary = false

		if position.x > 1300:  # Past right boundary (lost)
			out_of_bounds = true
			boundary_name = "RIGHT (past paddle)"
			ball_lost.emit(self)
			# Handler in main.gd will determine if this causes life loss
		elif position.x < 0:  # Past left wall (shouldn't happen!)
			out_of_bounds = true
			is_error_boundary = true
			boundary_name = "LEFT (ERROR!)"
			print("WARNING: Ball escaped through LEFT boundary!")
			ball_lost.emit(self)
		elif position.y < 0:  # Above top wall (shouldn't happen!)
			out_of_bounds = true
			is_error_boundary = true
			boundary_name = "TOP (ERROR!)"
			print("WARNING: Ball escaped through TOP boundary!")
			ball_lost.emit(self)
		elif position.y > 720:  # Below bottom wall (shouldn't happen!)
			out_of_bounds = true
			is_error_boundary = true
			boundary_name = "BOTTOM (ERROR!)"
			print("WARNING: Ball escaped through BOTTOM boundary!")
			ball_lost.emit(self)

		if out_of_bounds:
			print("=== BALL OUT OF BOUNDS ===")
			print("  Boundary: ", boundary_name)
			print("  Position: ", position, " (X: ", position.x, ", Y: ", position.y, ")")
			print("  Velocity: ", velocity, " (X: ", velocity.x, ", Y: ", velocity.y, ")")
			print("  Speed: ", current_speed)
			print("  Is main ball: ", is_main_ball)

			# CRITICAL: Remove balls that escape through error boundaries immediately
			# They should never exist outside the play area
			if is_error_boundary:
				print("  ACTION: Removing ball from scene (error boundary)")

				# Main ball should be reset, not removed
				if is_main_ball:
					print("  Main ball escaping - resetting to paddle")
					call_deferred("reset_ball")
				else:
					# Extra balls can be safely removed
					# Stop processing this ball
					set_physics_process(false)
					# Make it invisible
					visible = false
					# Disable collisions (deferred to avoid physics query errors)
					set_deferred("collision_layer", 0)
					set_deferred("collision_mask", 0)
					# Schedule for removal (deferred to avoid issues during physics)
					call_deferred("queue_free")

			print("==========================")

		# Maintain constant speed (arcade feel)
		velocity = velocity.normalized() * current_speed

		# Rotate ball to show movement/spin (only if actually moving)
		# Rotation based on distance traveled (creates rolling effect)
		if has_node("Visual") and velocity.length() > 10.0:
			var visual = $Visual
			var rotation_speed = current_speed / 16.0  # Ball radius for natural rolling
			visual.rotation += rotation_speed * delta

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

	# Hide direction indicator
	if direction_indicator:
		direction_indicator.visible = false

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
			print("Ball launched with spin! Velocity: ", velocity)
		else:
			# Launch straight left with slight angle variation
			var angle_rad = deg_to_rad(180.0 + angle_variation)  # 180° = straight left
			velocity = Vector2(cos(angle_rad), sin(angle_rad)) * current_speed
			print("Ball launched straight! Velocity: ", velocity)

	# Enable trail effect (if enabled in settings)
	if has_node("Trail") and SaveManager.get_ball_trail():
		$Trail.emitting = true

	# Notify game manager
	if not game_manager:
		game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		game_manager.start_playing()

	aim_available = false
	if launched_with_aim:
		print("Ball launched with aim! Velocity: ", velocity)

func handle_collision(collision: KinematicCollision2D):
	"""Handle ball collision with walls, paddle, or bricks"""
	var collider = collision.get_collider()
	var normal = collision.get_normal()

	# Ignore ball-to-ball collisions entirely (prevents physics pausing)
	if collider.is_in_group("ball"):
		return

	# Check what we hit
	if collider.is_in_group("paddle"):
		var hit_y = position.y
		# Special case: Allow ball to pass through paddle if stuck near walls and moving left
		# This prevents the ball from getting wedged between paddle and walls
		const TOP_ESCAPE_ZONE_Y = 40.0  # Near top wall threshold
		const BOTTOM_ESCAPE_ZONE_Y = 660.0  # Near bottom wall threshold

		if position.y < TOP_ESCAPE_ZONE_Y and velocity.x < 0:
			# Ball is near top wall and moving left - let it pass through paddle
			print("Ball escaping through paddle (stuck near top wall)")
			return
		elif position.y > BOTTOM_ESCAPE_ZONE_Y and velocity.x < 0:
			# Ball is near bottom wall and moving left - let it pass through paddle
			print("Ball escaping through paddle (stuck near bottom wall)")
			return

		# Check if grab is enabled and ball is not immune to grab
		if (grab_enabled or PowerUpManager.is_grab_active()) and grab_immunity_timer <= 0.0:
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
					print("Ball grabbed on back of paddle, moved to front")
			print("Ball grabbed by paddle at offset: ", paddle_offset)
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

			if air_ball_enabled or PowerUpManager.is_air_ball_active():
				_jump_to_level_center_x(hit_y)
				print("Ball jumped to level center!")
				return

			print("Ball hit paddle, velocity: ", velocity)
		AudioManager.play_sfx("hit_paddle")

	elif collider.is_in_group("brick"):
		# Brick collision: reflect + notify brick
		var old_velocity = velocity  # Store for particle direction
		var hit_brick_position = collider.global_position  # Store for bomb effect

		var is_block_brick = collider.is_in_group("block_brick")
		if is_block_brick and (velocity.x < 0.0 or grab_immunity_timer > 0.0 or block_pass_timer > 0.0):
			# Allow held/just-launched balls to pass block bricks when moving left
			position += velocity * last_physics_delta
			return

		# Check if brick through is enabled (block bricks always behave normally)
		if not is_block_brick and (brick_through_enabled or PowerUpManager.is_brick_through_active()):
			# Don't bounce, just pass through and notify brick
			brick_hit.emit(collider)
			if collider.has_method("hit"):
				collider.hit(old_velocity.normalized())
			print("Ball passed through brick!")
		else:
			# Normal bounce behavior
			velocity = velocity.bounce(normal)
			brick_hit.emit(collider)
			if collider.has_method("hit"):
				collider.hit(old_velocity.normalized())
			print("Ball hit brick")
		AudioManager.play_sfx("hit_brick")

		# Check if bomb ball is active - destroy surrounding bricks (skip block bricks)
		if not is_block_brick and (bomb_ball_enabled or PowerUpManager.is_bomb_ball_active()):
			destroy_surrounding_bricks(hit_brick_position)

	else:
		# Wall collision: simple reflection
		AudioManager.play_sfx("hit_wall")
		velocity = velocity.bounce(normal)

func reset_ball():
	"""Reset ball to paddle after losing a life"""
	is_attached_to_paddle = true
	velocity = Vector2.ZERO
	aim_available = is_main_ball
	_set_aim_mode(false)
	aim_direction = Vector2.LEFT

	# Disable trail effect
	if has_node("Trail"):
		$Trail.emitting = false

	# Show direction indicator again
	if direction_indicator:
		direction_indicator.visible = true

	print("Ball reset to paddle")


func apply_speed_up_effect():
	"""Increase ball speed to 650 for 12 seconds"""
	current_speed = 650.0
	# Update velocity magnitude immediately if ball is moving
	if not is_attached_to_paddle:
		velocity = velocity.normalized() * current_speed

	# Change trail color to yellow/orange for fast speed (if trail enabled)
	_update_trail_appearance()

	print("Ball speed increased to 650!")

func apply_slow_down_effect():
	"""Decrease ball speed to 350 for 12 seconds"""
	current_speed = 350.0
	# Update velocity magnitude immediately if ball is moving
	if not is_attached_to_paddle:
		velocity = velocity.normalized() * current_speed

	# Change trail color to blue for slow speed (if trail enabled)
	_update_trail_appearance()

	print("Ball speed decreased to 350!")

func reset_ball_speed():
	"""Reset ball speed to normal (with difficulty multiplier applied)"""
	base_speed = BASE_current_speed * DifficultyManager.get_speed_multiplier()
	current_speed = base_speed
	# Update velocity magnitude immediately if ball is moving
	if not is_attached_to_paddle:
		velocity = velocity.normalized() * current_speed

	# Reset trail color to default (if trail enabled)
	_update_trail_appearance()

func _update_trail_appearance() -> void:
	if not has_node("Trail"):
		return
	if not SaveManager.get_ball_trail():
		return
	var trail = $Trail
	var new_texture = TRAIL_SMALL
	if spin_trail_timer > 0.0:
		new_texture = TRAIL_LARGE
	elif current_speed >= base_speed * FAST_SPEED_MULTIPLIER:
		new_texture = TRAIL_MEDIUM
	if trail.texture != new_texture:
		trail.texture = new_texture
	var new_color = _get_trail_color()
	if trail.color != new_color:
		trail.color = new_color

func _get_trail_color() -> Color:
	if has_node("Visual"):
		var visual_color = $Visual.modulate
		if visual_color != Color(1.0, 1.0, 1.0, 1.0):
			return visual_color
	if current_speed >= base_speed * FAST_SPEED_MULTIPLIER:
		return TRAIL_COLOR_FAST
	if current_speed <= base_speed * 0.85:
		return TRAIL_COLOR_SLOW
	return TRAIL_COLOR_NORMAL

func _unhandled_input(event: InputEvent) -> void:
	if not is_main_ball:
		return
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
	var mouse_pos = get_viewport().get_mouse_position()
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
		aim_head.points = [head_left, end_point, head_right]

func enable_grab():
	"""Enable grab mode - ball can stick to paddle"""
	grab_enabled = true
	print("Grab enabled on ball")

func reset_grab_state():
	"""Disable grab mode - already-grabbed balls stay held until player releases"""
	grab_enabled = false
	# Note: Balls that are currently attached (is_attached_to_paddle = true)
	# will remain attached and can be manually launched by the player
	print("Grab disabled on ball (held balls remain until released)")

func enable_brick_through():
	"""Enable brick through - ball passes through bricks"""
	brick_through_enabled = true
	print("Brick through enabled on ball")

func reset_brick_through():
	"""Disable brick through mode"""
	brick_through_enabled = false
	print("Brick through disabled on ball")

func enable_bomb_ball():
	"""Enable bomb ball mode - ball destroys surrounding bricks"""
	bomb_ball_enabled = true
	# Add orange/red glow to ball visual
	if has_node("Visual"):
		$Visual.modulate = Color(1.0, 0.4, 0.1, 1.0)  # Orange-red tint
	_update_trail_appearance()
	print("Bomb ball enabled on ball")

func reset_bomb_ball():
	"""Disable bomb ball mode and remove glow"""
	bomb_ball_enabled = false
	# Reset ball visual to normal
	if has_node("Visual"):
		$Visual.modulate = Color(1.0, 1.0, 1.0, 1.0)  # White (normal)
	_update_trail_appearance()
	print("Bomb ball disabled on ball")

func enable_air_ball():
	"""Enable air ball mode - ball jumps over bricks to center"""
	air_ball_enabled = true
	print("Air ball enabled on ball")

func reset_air_ball():
	"""Disable air ball mode"""
	air_ball_enabled = false
	print("Air ball disabled on ball")

func enable_magnet():
	"""Enable magnet mode - paddle attracts ball"""
	magnet_enabled = true
	print("Magnet enabled on ball")

func reset_magnet():
	"""Disable magnet mode"""
	magnet_enabled = false
	print("Magnet disabled on ball")

func _jump_to_level_center_x(hit_y: float):
	var center_x = _get_level_center_x()
	position = Vector2(center_x, hit_y) + velocity.normalized() * 2.0

func _get_level_center_x() -> float:
	if game_manager:
		var level_id = game_manager.current_level
		var level_data = LevelLoader.load_level_data(level_id)
		if not level_data.is_empty():
			var grid = level_data.get("grid", {})
			var brick_size = grid.get("brick_size", 48)
			var spacing = grid.get("spacing", 3)
			var start_x = grid.get("start_x", 150)
			var bricks = level_data.get("bricks", [])
			if bricks.size() > 0:
				var min_row = bricks[0].get("row", 0)
				var max_row = min_row
				var min_col = bricks[0].get("col", 0)
				var max_col = min_col
				for brick_def in bricks:
					var row = brick_def.get("row", 0)
					var col = brick_def.get("col", 0)
					min_row = min(min_row, row)
					max_row = max(max_row, row)
					min_col = min(min_col, col)
					max_col = max(max_col, col)

				var step = float(brick_size + spacing)
				var center_x = start_x + ((min_col + max_col) / 2.0) * step
				return center_x

			return float(start_x)

	var viewport = get_viewport()
	if viewport:
		return viewport.get_visible_rect().size.x * 0.5
	return 640.0

func destroy_surrounding_bricks(impact_position: Vector2):
	"""Destroy bricks in a radius around the impact point (bomb ball effect)"""
	const BOMB_RADIUS = 75.0  # Pixels - immediately adjacent bricks (left/right/above/below)

	# Find all bricks in the scene
	var all_bricks = get_tree().get_nodes_in_group("brick")
	var destroyed_count = 0

	for brick in all_bricks:
		if not is_instance_valid(brick):
			continue
		if brick.is_in_group("block_brick"):
			continue

		# Check distance from impact point
		var distance = brick.global_position.distance_to(impact_position)
		if distance <= BOMB_RADIUS:
			# Hit this brick with a fake velocity
			if brick.has_method("hit"):
				brick.hit(Vector2(-1, 0))  # Use left direction for consistency
				destroyed_count += 1

	if destroyed_count > 0:
		print("Bomb ball destroyed ", destroyed_count, " surrounding bricks!")

	_update_trail_appearance()

	print("Ball speed reset to ", current_speed)

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
	if has_node("CollisionShape2D"):
		var collision = $CollisionShape2D
		if collision.shape is CircleShape2D:
			collision.shape.radius = new_radius
	if has_node("Visual"):
		var scale_factor = new_radius / BASE_RADIUS
		$Visual.scale = BASE_VISUAL_SCALE * scale_factor
	_update_trail_appearance()

func refresh_trail_state() -> void:
	if not has_node("Trail"):
		return
	$Trail.emitting = SaveManager.get_ball_trail() and not is_attached_to_paddle
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

	# Check if ball has moved significantly since last check
	var distance_moved = position.distance_to(last_position)

	# Use per-frame threshold (ball should move at least speed*delta pixels per frame)
	# At 500 speed and 60fps, that's ~8.3 pixels per frame minimum
	var expected_movement = current_speed * delta * 0.5  # 50% of expected (account for bouncing)

	if distance_moved < expected_movement:
		# Ball hasn't moved much - increment timer
		stuck_check_timer += delta

		if stuck_check_timer >= stuck_threshold:
			# Ball is stuck! Give it a boost to escape
			print("WARNING: Ball appears stuck at ", position, " - applying escape boost")

			# Random escape direction (prefer left and down/up to avoid paddle)
			var escape_angle = randf_range(135.0, 225.0)  # Left hemisphere
			var angle_rad = deg_to_rad(escape_angle)
			velocity = Vector2(cos(angle_rad), sin(angle_rad)) * current_speed

			print("  Escape velocity applied: ", velocity, " (angle: ", escape_angle, "°)")

			# Reset timer
			stuck_check_timer = 0.0
	else:
		# Ball is moving normally - reset timer
		stuck_check_timer = 0.0

	# IMPORTANT: Always update last_position for next frame comparison
	last_position = position

func create_direction_indicator():
	"""Create a visual indicator showing launch direction"""
	# Only create indicator for the main ball, not extra balls from power-ups
	if not is_main_ball:
		return

	direction_indicator = Line2D.new()
	direction_indicator.width = 3.0
	direction_indicator.default_color = Color(0, 0.9, 1, 0.6)  # Cyan with transparency
	direction_indicator.begin_cap_mode = Line2D.LINE_CAP_ROUND
	direction_indicator.end_cap_mode = Line2D.LINE_CAP_ROUND

	# Arrow head points
	var arrow_length = 80.0
	var arrow_width = 15.0
	direction_indicator.add_point(Vector2(0, 0))  # Start at ball center
	direction_indicator.add_point(Vector2(-arrow_length, 0))  # Main line
	direction_indicator.add_point(Vector2(-arrow_length + arrow_width, -arrow_width))  # Arrow head top
	direction_indicator.add_point(Vector2(-arrow_length, 0))  # Back to tip
	direction_indicator.add_point(Vector2(-arrow_length + arrow_width, arrow_width))  # Arrow head bottom

	add_child(direction_indicator)
	direction_indicator.visible = true

func update_direction_indicator():
	"""Update direction indicator based on paddle movement - shows correct spin physics"""
	if not direction_indicator or not is_attached_to_paddle:
		return

	# Calculate launch direction with CORRECTED spin physics
	var paddle_velocity_y = 0.0
	if paddle_reference and paddle_reference.has_method("get_velocity_for_spin"):
		paddle_velocity_y = paddle_reference.get_velocity_for_spin()

	# Calculate preview direction with inverted spin (correct physics)
	# When paddle moves DOWN (+Y), ball should curve UP (-Y) and vice versa
	var launch_velocity: Vector2
	if abs(paddle_velocity_y) > 50:  # Paddle is moving
		# Launch with spin - INVERTED for correct physics
		var angle_rad = deg_to_rad(INITIAL_ANGLE)
		launch_velocity = Vector2(cos(angle_rad), sin(angle_rad)) * current_speed
		# INVERT paddle spin influence for correct physics (down = curve up)
		launch_velocity.y -= paddle_velocity_y * SPIN_FACTOR  # Note: MINUS instead of PLUS
		launch_velocity = launch_velocity.normalized() * current_speed
	else:
		# Launch straight left (no vertical component)
		launch_velocity = Vector2(-current_speed, 0)

	# Normalize to get direction
	var launch_direction = launch_velocity.normalized()

	# Update indicator points
	var arrow_length = 80.0
	var arrow_width = 15.0
	var end_point = launch_direction * arrow_length

	# Perpendicular vector for arrow head
	var perpendicular = Vector2(-launch_direction.y, launch_direction.x) * arrow_width

	direction_indicator.set_point_position(0, Vector2.ZERO)
	direction_indicator.set_point_position(1, end_point)
	direction_indicator.set_point_position(2, end_point + perpendicular * 0.5 - launch_direction * arrow_width)
	direction_indicator.set_point_position(3, end_point)
	direction_indicator.set_point_position(4, end_point - perpendicular * 0.5 - launch_direction * arrow_width)
