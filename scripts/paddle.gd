extends CharacterBody2D

## Paddle - Vertical movement on right side of screen
## Controls: Arrow keys, W/S keys, or mouse Y position
## Tracks velocity for ball spin mechanics

# Movement constants
const PADDLE_SPEED = 1000.0  # Pixels per second
const MIN_Y = 60.0          # Top boundary (respects HUD)
const MAX_Y = 660.0         # Bottom boundary (respects screen)
const BASE_HEIGHT = 120.0   # Default paddle height

# Control mode
@export var use_mouse_control: bool = true
@export var use_keyboard_control: bool = true

# Mouse tracking to allow keyboard control when mouse is idle
const MOUSE_MOVE_DEADZONE = 0.5
const MOUSE_FOLLOW_GAIN = 25.0  # Increased from 12.0 for faster mouse response
const MOUSE_TARGET_DEADZONE = 2.0
var last_mouse_y: float = 0.0

# Velocity tracking for spin mechanics
var previous_y: float = 0.0
var actual_velocity_y: float = 0.0
var game_manager = null

# Power-up effects
var current_height: float = 120.0

func _ready():
	print("Paddle ready at position: ", position)
	previous_y = position.y
	last_mouse_y = get_viewport().get_mouse_position().y
	game_manager = get_tree().get_first_node_in_group("game_manager")

func _physics_process(delta):
	if game_manager and game_manager.game_state == game_manager.GameState.PAUSED:
		return

	# Store old position for velocity calculation
	previous_y = position.y

	# Get input direction
	var input_velocity = Vector2.ZERO

	# Keyboard control
	if use_keyboard_control:
		var direction = Input.get_axis("move_up", "move_down")
		input_velocity.y = direction * PADDLE_SPEED

	# Mouse control (override keyboard only when the mouse is moving)
	if use_mouse_control:
		var mouse_y = get_viewport().get_mouse_position().y
		var mouse_moved = abs(mouse_y - last_mouse_y) > MOUSE_MOVE_DEADZONE
		last_mouse_y = mouse_y

		if mouse_moved:
			var target_y = clamp(mouse_y, MIN_Y, MAX_Y)
			var distance_to_target = target_y - position.y
			if abs(distance_to_target) > MOUSE_TARGET_DEADZONE:
				input_velocity.y = clamp(distance_to_target * MOUSE_FOLLOW_GAIN, -PADDLE_SPEED, PADDLE_SPEED)
			else:
				input_velocity.y = 0.0

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

func apply_expand_effect():
	"""Expand paddle height to 180 for 15 seconds"""
	set_paddle_height(180.0)
	print("Paddle expanded to 180!")

func apply_contract_effect():
	"""Contract paddle height to 80 for 10 seconds"""
	set_paddle_height(80.0)
	print("Paddle contracted to 80!")

func reset_paddle_height():
	"""Reset paddle to base height"""
	set_paddle_height(BASE_HEIGHT)

func set_paddle_height(new_height: float):
	"""Change paddle height with animation"""
	current_height = new_height

	# Update visual if it exists
	if has_node("Visual"):
		var visual = $Visual
		var tween = create_tween()
		tween.tween_property(visual, "size:y", new_height, 0.2)
		tween.tween_property(visual, "position:y", -new_height / 2, 0.2)

	# Update collision shape
	if has_node("CollisionShape2D"):
		var collision = $CollisionShape2D
		if collision.shape is RectangleShape2D:
			var tween = create_tween()
			tween.tween_property(collision.shape, "size:y", new_height, 0.2)

func _input(event):
	# Debug: Toggle control modes with keys
	if event.is_action_pressed("ui_cancel"):
		pass  # Future: Open pause menu
