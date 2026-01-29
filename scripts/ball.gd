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

# Signals
signal ball_lost
signal brick_hit(brick)

func _ready():
	print("Ball initialized")
	# Add to ball group for collision detection
	add_to_group("ball")

	# Find paddle in parent scene
	paddle_reference = get_tree().get_first_node_in_group("paddle")
	game_manager = get_tree().get_first_node_in_group("game_manager")
	if paddle_reference:
		print("Ball found paddle reference")
	else:
		print("Warning: Ball couldn't find paddle!")

func _physics_process(delta):
	# Stop ball movement if level is complete or game over
	if game_manager and (game_manager.game_state == game_manager.GameState.LEVEL_COMPLETE or game_manager.game_state == game_manager.GameState.GAME_OVER):
		velocity = Vector2.ZERO
		return

	if is_attached_to_paddle:
		# Ball follows paddle until launched
		if paddle_reference:
			position = paddle_reference.position + Vector2(-30, 0)  # Offset to left of paddle

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

	# Enable trail effect
	if has_node("Trail"):
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

	print("Ball reset to paddle")

func apply_speed_up_effect():
	"""Increase ball speed to 650 for 12 seconds"""
	current_speed = 650.0
	# Update velocity magnitude immediately if ball is moving
	if not is_attached_to_paddle:
		velocity = velocity.normalized() * current_speed
	print("Ball speed increased to 650!")

func reset_ball_speed():
	"""Reset ball speed to normal"""
	current_speed = BASE_current_speed
	# Update velocity magnitude immediately if ball is moving
	if not is_attached_to_paddle:
		velocity = velocity.normalized() * current_speed
	print("Ball speed reset to 500")

func enable_collision_immunity(duration: float = 0.5):
	"""No longer needed - ball-to-ball collisions disabled at physics layer"""
	# Balls no longer collide with each other at all (mask excludes layer 1)
	# This function kept for compatibility but does nothing
	pass
