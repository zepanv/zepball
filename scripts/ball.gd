extends CharacterBody2D

## Ball - Physics-based ball with collision detection and spin mechanics
## Bounces off walls, paddle, and bricks
## Paddle movement affects ball trajectory (spin)

# Ball physics constants
const BALL_SPEED = 400.0        # Constant speed (pixels/second)
const SPIN_FACTOR = 0.3         # How much paddle velocity affects ball
const MAX_VERTICAL_ANGLE = 0.8  # Prevent pure vertical/horizontal motion
const INITIAL_ANGLE = -45.0     # Launch angle (degrees, toward left)

# State
var is_attached_to_paddle = true
var paddle_reference = null

# Signals
signal ball_lost
signal brick_hit(brick)

func _ready():
	print("Ball initialized")
	# Find paddle in parent scene
	paddle_reference = get_tree().get_first_node_in_group("paddle")
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
		if Input.is_action_just_pressed("launch_ball"):
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
		velocity = velocity.normalized() * BALL_SPEED

func launch_ball():
	"""Launch ball from paddle at initial angle"""
	is_attached_to_paddle = false

	# Calculate launch velocity
	var angle_rad = deg_to_rad(INITIAL_ANGLE)
	velocity = Vector2(cos(angle_rad), sin(angle_rad)) * BALL_SPEED

	print("Ball launched! Velocity: ", velocity)

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
		if abs(velocity.x) < BALL_SPEED * (1.0 - MAX_VERTICAL_ANGLE):
			velocity.x = sign(velocity.x) * BALL_SPEED * (1.0 - MAX_VERTICAL_ANGLE)

		print("Ball hit paddle, velocity: ", velocity)

	elif collider.is_in_group("brick"):
		# Brick collision: reflect + notify brick
		velocity = velocity.bounce(normal)
		brick_hit.emit(collider)

		# Tell brick it was hit
		if collider.has_method("hit"):
			collider.hit()

		print("Ball hit brick")

	else:
		# Wall collision: simple reflection
		velocity = velocity.bounce(normal)

func reset_ball():
	"""Reset ball to paddle after losing a life"""
	is_attached_to_paddle = true
	velocity = Vector2.ZERO
	print("Ball reset to paddle")
