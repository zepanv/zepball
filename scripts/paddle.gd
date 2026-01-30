extends CharacterBody2D

## Paddle - Vertical movement on right side of screen
## Controls: Arrow keys, W/S keys, or mouse Y position
## Tracks velocity for ball spin mechanics

# Movement constants
const PADDLE_SPEED = 1000.0  # Pixels per second
const WALL_TOP_Y = 20.0     # Top wall bottom edge
const WALL_BOTTOM_Y = 700.0 # Bottom wall top edge
const BASE_HEIGHT = 130.0   # Default paddle height (matches collision shape)

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
var current_height: float = 130.0

# Settings
var sensitivity_multiplier: float = 1.0

func _ready():
	print("Paddle ready at position: ", position)
	previous_y = position.y
	last_mouse_y = get_viewport().get_mouse_position().y
	game_manager = get_tree().get_first_node_in_group("game_manager")

	# Load paddle sensitivity setting
	sensitivity_multiplier = SaveManager.get_paddle_sensitivity()
	print("Paddle sensitivity: ", sensitivity_multiplier, "x")

func _physics_process(delta):
	# Store old position for velocity calculation
	previous_y = position.y

	# Calculate dynamic boundaries based on current paddle height
	var half_height = current_height / 2.0
	var min_y = WALL_TOP_Y + half_height
	var max_y = WALL_BOTTOM_Y - half_height

	# Get input direction
	var input_velocity = Vector2.ZERO

	# Keyboard control
	if use_keyboard_control:
		var direction = Input.get_axis("move_up", "move_down")
		input_velocity.y = direction * PADDLE_SPEED * sensitivity_multiplier

	# Mouse control (direct position setting for instant response)
	if use_mouse_control:
		var mouse_y = get_viewport().get_mouse_position().y
		var mouse_moved = abs(mouse_y - last_mouse_y) > MOUSE_MOVE_DEADZONE
		last_mouse_y = mouse_y

		if mouse_moved:
			# Center paddle on mouse cursor within bounds
			var target_y = clamp(mouse_y, min_y, max_y)

			# Apply sensitivity: lerp toward target faster/slower based on sensitivity
			# Higher sensitivity = faster response (less lerp smoothing)
			var lerp_speed = 0.3 * sensitivity_multiplier  # Base lerp speed scaled by sensitivity
			position.y = lerp(position.y, target_y, lerp_speed)

			# Set velocity to 0 since we're using positioning
			input_velocity.y = 0.0

	# Set velocity
	velocity = input_velocity

	# Move paddle (only matters for keyboard control now)
	if input_velocity.y != 0:
		move_and_slide()

	# Clamp position to boundaries (dynamic based on paddle height)
	position.y = clamp(position.y, min_y, max_y)

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

	# Update collision shape FIRST (before calculating bounds)
	if has_node("CollisionShape2D"):
		var collision = $CollisionShape2D
		if collision.shape is RectangleShape2D:
			# Duplicate the shape if it's shared to avoid affecting other instances
			if not collision.shape.is_local_to_scene():
				collision.shape = collision.shape.duplicate()

			# Create a new size vector with updated height
			var new_size = collision.shape.size
			new_size.y = new_height
			collision.shape.size = new_size

	# Ensure paddle stays within dynamic bounds after size change
	var half_height = current_height / 2.0
	var min_y = WALL_TOP_Y + half_height
	var max_y = WALL_BOTTOM_Y - half_height
	position.y = clamp(position.y, min_y, max_y)

	# Update visual with animation (Sprite2D rotated 90°, so scale X for height)
	if has_node("Visual"):
		var visual = $Visual
		var scale_factor = new_height / BASE_HEIGHT
		var tween = create_tween()
		# Paddle is rotated 90°, so X axis is vertical (height)
		tween.tween_property(visual, "scale:x", scale_factor, 0.2)

func _input(event):
	# Debug: Toggle control modes with keys
	if event.is_action_pressed("ui_cancel"):
		pass  # Future: Open pause menu
