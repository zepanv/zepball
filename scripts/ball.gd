extends CharacterBody2D

## Ball - Physics-based ball with collision detection and spin mechanics
## Bounces off walls, paddle, and bricks
## Paddle movement affects ball trajectory (spin)

# Ball physics constants
const BASE_current_speed = 500.0   # Base speed (pixels/second)
const SPIN_FACTOR = 0.3         # How much paddle velocity affects ball
const MAX_VERTICAL_ANGLE = 0.8  # Prevent pure vertical/horizontal motion
const INITIAL_ANGLE = -45.0     # Launch angle (degrees, toward left)

# Dynamic speed (can be modified by power-ups)
var current_speed: float = BASE_current_speed

# State
var is_attached_to_paddle = true
var paddle_reference = null
var game_manager = null
var is_main_ball: bool = true  # Identifies the original ball in the scene
var direction_indicator: Line2D = null  # Visual launch direction indicator

# Stuck detection
var stuck_check_timer: float = 0.0
var last_position: Vector2 = Vector2.ZERO
var stuck_threshold: float = 2.0  # seconds
var movement_threshold: float = 30.0  # pixels

# Signals
signal ball_lost
signal brick_hit(brick)

func _ready():
	print("Ball initialized")
	# Add to ball group for collision detection
	add_to_group("ball")

	# Apply difficulty multiplier to base speed
	current_speed = BASE_current_speed * DifficultyManager.get_speed_multiplier()

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

	# Direction indicator disabled for now
	# create_direction_indicator()

func _physics_process(delta):
	# Stop ball movement if level is complete or game over
	if game_manager and (game_manager.game_state == game_manager.GameState.LEVEL_COMPLETE or game_manager.game_state == game_manager.GameState.GAME_OVER):
		velocity = Vector2.ZERO
		return

	if is_attached_to_paddle:
		# Ball follows paddle until launched
		if paddle_reference:
			position = paddle_reference.position + Vector2(-30, 0)  # Offset to left of paddle

		# Direction indicator disabled
		# update_direction_indicator()

		# Launch on input
		if Input.is_action_just_pressed("launch_ball") and (not game_manager or game_manager.game_state == game_manager.GameState.READY):
			launch_ball()
	else:
		# Ball is in motion
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

func launch_ball():
	"""Launch ball from paddle at initial angle
	If paddle is moving, impart spin. Otherwise, shoot straight left.
	"""
	is_attached_to_paddle = false

	# Hide direction indicator
	if direction_indicator:
		direction_indicator.visible = false

	# Check if paddle is moving
	var paddle_velocity_y = 0.0
	if paddle_reference and paddle_reference.has_method("get_velocity_for_spin"):
		paddle_velocity_y = paddle_reference.get_velocity_for_spin()

	# If paddle is moving significantly, add vertical component
	if abs(paddle_velocity_y) > 50:  # Minimum movement threshold
		# Launch with spin based on paddle movement
		var angle_rad = deg_to_rad(INITIAL_ANGLE)
		velocity = Vector2(cos(angle_rad), sin(angle_rad)) * current_speed
		# Add paddle spin influence
		velocity.y += paddle_velocity_y * SPIN_FACTOR
		velocity = velocity.normalized() * current_speed
		print("Ball launched with spin! Velocity: ", velocity)
	else:
		# Launch straight left (no vertical component)
		velocity = Vector2(-current_speed, 0)
		print("Ball launched straight! Velocity: ", velocity)

	# Enable trail effect (if enabled in settings)
	if has_node("Trail") and SaveManager.get_ball_trail():
		$Trail.emitting = true

	# Notify game manager
	if not game_manager:
		game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		game_manager.start_playing()

func handle_collision(collision: KinematicCollision2D):
	"""Handle ball collision with walls, paddle, or bricks"""
	var collider = collision.get_collider()
	var normal = collision.get_normal()

	# Ignore ball-to-ball collisions entirely (prevents physics pausing)
	if collider.is_in_group("ball"):
		return

	# Check what we hit
	if collider.is_in_group("paddle"):
		# Paddle collision: reflect + add spin
		velocity = velocity.bounce(normal)

		# Add paddle spin influence
		if paddle_reference and paddle_reference.has_method("get_velocity_for_spin"):
			var paddle_velocity = paddle_reference.get_velocity_for_spin()
			velocity.y += paddle_velocity * SPIN_FACTOR

		# Prevent pure vertical motion
		if abs(velocity.x) < current_speed * (1.0 - MAX_VERTICAL_ANGLE):
			velocity.x = sign(velocity.x) * current_speed * (1.0 - MAX_VERTICAL_ANGLE)

		print("Ball hit paddle, velocity: ", velocity)

	elif collider.is_in_group("brick"):
		# Brick collision: reflect + notify brick
		var old_velocity = velocity  # Store for particle direction
		velocity = velocity.bounce(normal)
		brick_hit.emit(collider)

		# Tell brick it was hit with impact direction
		if collider.has_method("hit"):
			collider.hit(old_velocity.normalized())

		print("Ball hit brick")

	else:
		# Wall collision: simple reflection
		velocity = velocity.bounce(normal)

func reset_ball():
	"""Reset ball to paddle after losing a life"""
	is_attached_to_paddle = true
	velocity = Vector2.ZERO

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
	if has_node("Trail") and SaveManager.get_ball_trail():
		$Trail.color = Color(1.0, 0.8, 0.2, 0.7)  # Yellow-orange

	print("Ball speed increased to 650!")

func reset_ball_speed():
	"""Reset ball speed to normal (with difficulty multiplier applied)"""
	current_speed = BASE_current_speed * DifficultyManager.get_speed_multiplier()
	# Update velocity magnitude immediately if ball is moving
	if not is_attached_to_paddle:
		velocity = velocity.normalized() * current_speed

	# Reset trail color to normal cyan/blue (if trail enabled)
	if has_node("Trail") and SaveManager.get_ball_trail():
		$Trail.color = Color(0.3, 0.6, 0.95, 0.7)  # Cyan-blue

	print("Ball speed reset to ", current_speed)

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
