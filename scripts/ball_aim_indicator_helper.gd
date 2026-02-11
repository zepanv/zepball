extends RefCounted
class_name BallAimIndicatorHelper

## BallAimIndicatorHelper - Aim indicator subsystem extracted from ball.gd.

const AIM_MIN_ANGLE = 120.0
const AIM_MAX_ANGLE = 240.0
const AIM_LENGTH = 140.0
const AIM_HEAD_LENGTH = 18.0
const AIM_HEAD_ANGLE = 25.0

var aim_available: bool = false
var aim_active: bool = false
var aim_direction: Vector2 = Vector2(-1, 0)
var aim_indicator_root: Node2D = null
var aim_shaft: Line2D = null
var aim_head: Line2D = null
var virtual_mouse_pos: Vector2 = Vector2.ZERO
var was_mouse_captured: bool = false

func create_indicator(ball: Node2D) -> void:
	if aim_indicator_root != null:
		return
	aim_indicator_root = Node2D.new()
	aim_indicator_root.name = "AimIndicator"
	ball.add_child(aim_indicator_root)
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

func update_direction(ball: Node2D, viewport: Viewport) -> void:
	if aim_indicator_root == null:
		return
	aim_indicator_root.global_position = ball.global_position
	var mouse_captured = Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	if mouse_captured != was_mouse_captured:
		if not mouse_captured:
			virtual_mouse_pos = viewport.get_mouse_position()
		was_mouse_captured = mouse_captured
	var mouse_pos = virtual_mouse_pos if mouse_captured else viewport.get_mouse_position()
	if not mouse_captured:
		virtual_mouse_pos = mouse_pos
	var global_dir = (mouse_pos - ball.global_position)
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
		aim_head.set_point_position(0, head_left)
		aim_head.set_point_position(1, end_point)
		aim_head.set_point_position(2, head_right)

func set_mode(enabled: bool, paddle: Node2D) -> void:
	if aim_active == enabled:
		return
	aim_active = enabled
	if paddle and paddle.has_method("set_aim_lock"):
		paddle.set_aim_lock(enabled)
	if aim_indicator_root:
		aim_indicator_root.visible = enabled

func can_use(is_attached: bool, game_manager: Node) -> bool:
	if not aim_available:
		return false
	if not is_attached:
		return false
	if game_manager == null:
		return false
	return game_manager.game_state == game_manager.GameState.READY

func handle_input(event: InputEvent, ball: Node2D, viewport: Viewport) -> bool:
	"""Handle aim-related input. Returns true if the event was consumed."""
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and aim_active:
			virtual_mouse_pos += event.relative
			var viewport_size = viewport.get_visible_rect().size
			virtual_mouse_pos.x = clampf(virtual_mouse_pos.x, 0.0, viewport_size.x)
			virtual_mouse_pos.y = clampf(virtual_mouse_pos.y, 0.0, viewport_size.y)
	if event.is_action_pressed("ui_cancel") and aim_active:
		set_mode(false, ball.paddle_reference)
		return true
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			if can_use(ball.is_attached_to_paddle, ball.game_manager):
				set_mode(true, ball.paddle_reference)
		else:
			if aim_active:
				set_mode(false, ball.paddle_reference)
				aim_direction = Vector2.LEFT
	return false

func reset(is_main_ball: bool) -> void:
	aim_available = is_main_ball
	set_mode(false, null)
	aim_direction = Vector2.LEFT
