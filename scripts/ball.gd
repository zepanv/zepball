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

# Signals
signal ball_lost
signal brick_hit(brick)

func _ready():
	print("Ball initialized")
	# Find paddle in parent scene
	paddle_reference = get_tree().get_first_node_in_group("paddle")
	game_manager = get_tree().get_first_node_in_group("game_manager")
	if paddle_reference:
		print("Ball found paddle reference")
	else:
		print("Warning: Ball couldn't find paddle!")

func _physics_process(delta):
	if is_attached_to_paddle:
		# Ball follows paddle until launched
		if paddle_reference:
			position = paddle_reference.position + Vector2(-30, 0)  # Offset to left of paddle

		# Launch on input
		if Input.is_action_just_pressed("launch_ball") and (not game_manager or game_manager.game_state == game_manager.GameState.READY):
			launch_ball()
	else:
		# Ball is in motion
		var collision = move_and_collide(velocity * delta)

		if collision:
			handle_collision(collision)

		# Check if ball passed right edge (lost)
		if position.x > 1300:  # Past right boundary
			ball_lost.emit()
			reset_ball()

		# Maintain constant speed (arcade feel)
		velocity = velocity.normalized() * current_speed

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
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		game_manager.start_playing()

func handle_collision(collision: KinematicCollision2D):
	"""Handle ball collision with walls, paddle, or bricks"""
	var collider = collision.get_collider()
	var normal = collision.get_normal()

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
