extends CharacterBody2D

## Paddle - Vertical movement on right side of screen
## Controls: Arrow keys, W/S keys, or mouse Y position
## Tracks velocity for ball spin mechanics

# Movement constants
const PADDLE_SPEED = 1000.0  # Pixels per second
const WALL_TOP_Y = 20.0     # Top wall bottom edge
const WALL_BOTTOM_Y = 700.0 # Bottom wall top edge
const BASE_HEIGHT = 130.0   # Default paddle height (matches collision shape)
const EXPANDED_HEIGHT = 180.0
const CONTRACTED_HEIGHT = 80.0
const MOUSE_LERP_BASE_SPEED = 0.3
const RESIZE_TWEEN_DURATION = 0.2

# Control mode
@export var use_mouse_control: bool = true
@export var use_keyboard_control: bool = true

# Mouse tracking to allow keyboard control when mouse is idle
const MOUSE_MOVE_DEADZONE = 0.5
const MOUSE_FOLLOW_GAIN = 25.0  # Increased from 12.0 for faster mouse response
const MOUSE_TARGET_DEADZONE = 2.0
var last_mouse_y: float = 0.0
var mouse_delta_y: float = 0.0
var was_mouse_captured: bool = false

# Velocity tracking for spin mechanics
var previous_y: float = 0.0
var actual_velocity_y: float = 0.0
var game_manager: Node = null
var base_visual_scale: Vector2 = Vector2.ONE
var min_bound_y: float = 0.0
var max_bound_y: float = 0.0
@onready var viewport_ref: Viewport = get_viewport()
@onready var collision_shape_node: CollisionShape2D = get_node_or_null("CollisionShape2D")
@onready var visual_node: Sprite2D = get_node_or_null("Visual")

# Power-up effects
var current_height: float = BASE_HEIGHT

# Settings
var sensitivity_multiplier: float = 1.0
var aim_locked: bool = false

func _ready():
	previous_y = position.y
	last_mouse_y = viewport_ref.get_mouse_position().y
	game_manager = get_tree().get_first_node_in_group("game_manager")
	_update_movement_bounds()

	# Load paddle sensitivity setting
	sensitivity_multiplier = SaveManager.get_paddle_sensitivity()
	if visual_node:
		base_visual_scale = visual_node.scale

func set_sensitivity_multiplier(value: float) -> void:
	"""Update paddle sensitivity during gameplay"""
	sensitivity_multiplier = clampf(value, 0.5, 2.0)

func _physics_process(delta):
	if game_manager and not _is_active_gameplay_state():
		previous_y = position.y
		velocity = Vector2.ZERO
		actual_velocity_y = 0.0
		return

	if aim_locked:
		previous_y = position.y
		velocity = Vector2.ZERO
		actual_velocity_y = 0.0
		last_mouse_y = viewport_ref.get_mouse_position().y
		return
	# Store old position for velocity calculation
	previous_y = position.y

	# Get input direction
	var input_velocity_y = 0.0
	var mouse_captured = Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED

	if mouse_captured != was_mouse_captured:
		if not mouse_captured:
			last_mouse_y = viewport_ref.get_mouse_position().y
		mouse_delta_y = 0.0
		was_mouse_captured = mouse_captured

	# Keyboard control
	if use_keyboard_control:
		var direction = Input.get_axis("move_up", "move_down")
		input_velocity_y = direction * PADDLE_SPEED * sensitivity_multiplier

	# Mouse control (direct position setting for instant response)
	if use_mouse_control:
		if mouse_captured:
			if abs(mouse_delta_y) > 0.0:
				var target_y = clamp(position.y + (mouse_delta_y * sensitivity_multiplier), min_bound_y, max_bound_y)
				position.y = target_y
				input_velocity_y = 0.0
			mouse_delta_y = 0.0
		else:
			var mouse_y = viewport_ref.get_mouse_position().y
			var mouse_moved = abs(mouse_y - last_mouse_y) > MOUSE_MOVE_DEADZONE
			last_mouse_y = mouse_y

			if mouse_moved:
				# Center paddle on mouse cursor within bounds
				var target_y = clamp(mouse_y, min_bound_y, max_bound_y)

				# Apply sensitivity: lerp toward target faster/slower based on sensitivity
				# Higher sensitivity = faster response (less lerp smoothing)
				var lerp_speed = MOUSE_LERP_BASE_SPEED * sensitivity_multiplier
				position.y = lerp(position.y, target_y, lerp_speed)

				# Set velocity to 0 since we're using positioning
				input_velocity_y = 0.0

	# Set velocity
	velocity.x = 0.0
	velocity.y = input_velocity_y

	# Move paddle (only matters for keyboard control now)
	if input_velocity_y != 0.0:
		move_and_slide()

	# Clamp position to boundaries (dynamic based on paddle height)
	if position.y < min_bound_y:
		position.y = min_bound_y
	elif position.y > max_bound_y:
		position.y = max_bound_y

	# Calculate actual velocity (for spin mechanics)
	actual_velocity_y = (position.y - previous_y) / delta

func set_aim_lock(enabled: bool) -> void:
	aim_locked = enabled

func get_velocity_for_spin() -> float:
	"""Returns the paddle's vertical velocity for ball spin calculations"""
	return actual_velocity_y

func apply_expand_effect():
	"""Expand paddle height to 180 for 15 seconds"""
	set_paddle_height(EXPANDED_HEIGHT)

func apply_contract_effect():
	"""Contract paddle height to 80 for 10 seconds"""
	set_paddle_height(CONTRACTED_HEIGHT)

func reset_paddle_height():
	"""Reset paddle to base height"""
	set_paddle_height(BASE_HEIGHT)

func set_paddle_height(new_height: float):
	"""Change paddle height with animation"""
	if Engine.is_in_physics_frame():
		call_deferred("_apply_paddle_height", new_height)
		return
	_apply_paddle_height(new_height)

func _apply_paddle_height(new_height: float) -> void:
	current_height = new_height

	# Update collision shape FIRST (before calculating bounds)
	if collision_shape_node and collision_shape_node.shape and collision_shape_node.shape is RectangleShape2D:
		# Duplicate the shape if it's shared to avoid affecting other instances
		if not collision_shape_node.shape.is_local_to_scene():
			collision_shape_node.shape = collision_shape_node.shape.duplicate()

		# Create a new size vector with updated height
		var new_size = collision_shape_node.shape.size
		new_size.y = new_height
		collision_shape_node.shape.size = new_size

	_update_movement_bounds()

	# Ensure paddle stays within dynamic bounds after size change
	position.y = clamp(position.y, min_bound_y, max_bound_y)

	# Update visual with animation (Sprite2D rotated 90°, so scale X for height)
	if visual_node:
		var scale_factor = new_height / BASE_HEIGHT
		var tween = create_tween()
		# Paddle is rotated 90°, so X axis is vertical (height)
		tween.tween_property(visual_node, "scale:x", base_visual_scale.x * scale_factor, RESIZE_TWEEN_DURATION)

func _update_movement_bounds() -> void:
	var half_height = current_height / 2.0
	min_bound_y = WALL_TOP_Y + half_height
	max_bound_y = WALL_BOTTOM_Y - half_height

func _is_active_gameplay_state() -> bool:
	return game_manager.game_state == game_manager.GameState.READY or game_manager.game_state == game_manager.GameState.PLAYING

func _input(event):
	# Debug: Toggle control modes with keys
	if event.is_action_pressed("ui_cancel"):
		pass  # Future: Open pause menu
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and use_mouse_control and not aim_locked:
			mouse_delta_y += event.relative.y
