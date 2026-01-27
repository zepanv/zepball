extends CharacterBody2D

## Paddle - Vertical movement on right side of screen
## Controls: Arrow keys, W/S keys, or mouse Y position
## Tracks velocity for ball spin mechanics

# Movement constants
const PADDLE_SPEED = 500.0  # Pixels per second
const MIN_Y = 60.0          # Top boundary (respects HUD)
const MAX_Y = 660.0         # Bottom boundary (respects screen)

# Control mode
@export var use_mouse_control: bool = true
@export var use_keyboard_control: bool = true

# Velocity tracking for spin mechanics
var previous_y: float = 0.0
var actual_velocity_y: float = 0.0

func _ready():
	print("Paddle ready at position: ", position)
	previous_y = position.y

func _physics_process(delta):
	# Store old position for velocity calculation
	previous_y = position.y

	# Get input direction
	var input_velocity = Vector2.ZERO

	# Keyboard control
	if use_keyboard_control:
		var direction = Input.get_axis("move_up", "move_down")
		input_velocity.y = direction * PADDLE_SPEED

	# Mouse control (override keyboard if enabled)
	if use_mouse_control:
		var mouse_y = get_viewport().get_mouse_position().y
		var target_y = clamp(mouse_y, MIN_Y, MAX_Y)

		# Smooth movement toward mouse
		var distance_to_target = target_y - position.y
		if abs(distance_to_target) > 5.0:  # Dead zone to prevent jitter
			input_velocity.y = sign(distance_to_target) * PADDLE_SPEED

	# Set velocity
	velocity = input_velocity

	# Move paddle
	move_and_slide()

	# Clamp position to boundaries
	position.y = clamp(position.y, MIN_Y, MAX_Y)

	# Calculate actual velocity (for spin mechanics)
	actual_velocity_y = (position.y - previous_y) / delta

func get_velocity_for_spin() -> float:
	"""Returns the paddle's vertical velocity for ball spin calculations"""
	return actual_velocity_y

func _input(event):
	# Debug: Toggle control modes with keys
	if event.is_action_pressed("ui_cancel"):
		pass  # Future: Open pause menu
