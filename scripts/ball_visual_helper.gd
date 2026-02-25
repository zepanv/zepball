class_name BallVisualHelper
extends RefCounted

func _update_trail_appearance(parent: Node) -> void:
	if not parent.trail_node:
		return
	if not SaveManager.get_ball_trail():
		return
	var new_texture = parent.TRAIL_SMALL
	if absf(parent.spin_amount) >= parent.HIGH_SPIN_THRESHOLD:
		new_texture = parent.TRAIL_LARGE
	elif parent.current_speed >= parent.base_speed * parent.FAST_SPEED_MULTIPLIER:
		new_texture = parent.TRAIL_MEDIUM
	if parent.trail_node.texture != new_texture:
		parent.trail_node.texture = new_texture
	var new_color = _get_trail_color(parent)
	if parent.trail_node.color != new_color:
		parent.trail_node.color = new_color

func _get_trail_color(parent: Node) -> Color:
	if parent.visual_node:
		var visual_color = parent.visual_node.modulate
		if visual_color != Color(1.0, 1.0, 1.0, 1.0):
			return visual_color
	if absf(parent.spin_amount) >= parent.HIGH_SPIN_THRESHOLD:
		return parent.TRAIL_COLOR_HIGH_SPIN
	if parent.current_speed >= parent.base_speed * parent.FAST_SPEED_MULTIPLIER:
		return parent.TRAIL_COLOR_FAST
	if parent.current_speed <= parent.base_speed * parent.SLOW_SPEED_MULTIPLIER:
		return parent.TRAIL_COLOR_SLOW
	return parent.TRAIL_COLOR_NORMAL

func _apply_bomb_ball_visual(parent: Node, active: bool) -> void:
	parent.bomb_visual_active = active
	if parent.visual_node:
		# Orange-red while bomb-ball is active, white otherwise.
		parent.visual_node.modulate = Color(1.0, 0.4, 0.1, 1.0) if active else Color(1.0, 1.0, 1.0, 1.0)
	_update_trail_appearance(parent)

func apply_big_ball_effect(parent: Node) -> void:
	"""Double ball size for power-up duration"""
	_set_ball_radius(parent, parent.BASE_RADIUS * 2.0)

func apply_small_ball_effect(parent: Node) -> void:
	"""Half ball size for power-up duration"""
	_set_ball_radius(parent, parent.BASE_RADIUS * 0.5)

func reset_ball_size(parent: Node) -> void:
	"""Reset ball to base size"""
	_set_ball_radius(parent, parent.BASE_RADIUS)

func get_ball_radius(parent: Node) -> float:
	return parent.ball_radius

func set_ball_radius(parent: Node, new_radius: float) -> void:
	_set_ball_radius(parent, new_radius)

func get_base_radius(parent: Node) -> float:
	return parent.BASE_RADIUS

func set_ball_size_multiplier(parent: Node, multiplier: float) -> void:
	_set_ball_radius(parent, parent.BASE_RADIUS * multiplier)

func _set_ball_radius(parent: Node, new_radius: float) -> void:
	parent.ball_radius = new_radius
	if parent.collision_shape_node and parent.collision_shape_node.shape is CircleShape2D:
		parent.collision_shape_node.shape.radius = new_radius
	if parent.visual_node:
		var scale_factor = new_radius / parent.BASE_RADIUS
		parent.visual_node.scale = parent.BASE_VISUAL_SCALE * scale_factor
	_update_trail_appearance(parent)

func refresh_trail_state(parent: Node) -> void:
	if not parent.trail_node:
		return
	parent.trail_node.emitting = SaveManager.get_ball_trail() and not parent.is_attached_to_paddle
	_update_trail_appearance(parent)
