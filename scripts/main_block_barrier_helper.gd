class_name MainBlockBarrierHelper
extends RefCounted

const PLAY_AREA_TOP_Y = 35.0     # 15px clearance from wall inner face (y=20)
const PLAY_AREA_BOTTOM_Y = 685.0 # 15px clearance from wall inner face (y=700)
const PLAY_AREA_RIGHT_X = 1270.0

func _spawn_block_barrier(parent: Node, duration: float) -> void:
	if not parent.paddle or not parent.play_area:
		return

	var barrier = Node2D.new()
	barrier.name = "BlockBarrier"
	parent.play_area.add_child(barrier)

	var paddle_width = _get_paddle_width(parent)
	var segment_height = parent.BLOCK_BRICK_HEIGHT
	var segment_width = parent.BLOCK_BRICK_WIDTH
	var segment_count = parent.BLOCK_SEGMENT_COUNT
	var step = segment_height + parent.BRICK_SPACING
	var half_h = segment_height / 2.0
	var start_y = parent.paddle.position.y - ((segment_count - 1) * step) / 2.0
	# Clamp so bricks stay within the play area walls
	start_y = clampf(start_y,
		PLAY_AREA_TOP_Y + half_h,
		PLAY_AREA_BOTTOM_Y - (segment_count - 1) * step - half_h)
	var base_x = parent.paddle.position.x + (paddle_width / 2.0) + (segment_width / 2.0) + parent.BLOCK_OFFSET_X
	# Clamp so bricks stay within the right play area boundary
	base_x = minf(base_x, PLAY_AREA_RIGHT_X - segment_width / 2.0)

	var block_texture = load("res://assets/graphics/bricks/element_green_rectangle.png")

	for i in range(segment_count):
		var brick = parent.BRICK_SCENE.instantiate()
		brick.brick_type = brick.BrickType.NORMAL
		brick.power_up_spawn_chance = 0.0
		brick.add_to_group("block_brick")
		barrier.add_child(brick)
		brick.position = Vector2(base_x, start_y + i * step)
		_configure_block_brick(parent, brick, block_texture, segment_width, segment_height)
		if brick.has_signal("brick_broken"):
			brick.brick_broken.connect(_on_block_brick_broken.bind(parent))

	var timer = Timer.new()
	timer.name = "BlockLifetimeTimer"
	timer.one_shot = true
	timer.wait_time = duration
	barrier.add_child(timer)
	timer.timeout.connect(_on_block_barrier_timeout.bind(barrier))
	timer.start()

	var color_timer = Timer.new()
	color_timer.name = "BlockColorTimer"
	color_timer.one_shot = false
	color_timer.wait_time = 1.0
	barrier.add_child(color_timer)
	color_timer.timeout.connect(_update_block_barrier_color.bind(barrier))
	color_timer.start()

func _configure_block_brick(_parent: Node, brick: Node, texture: Texture2D, segment_width: float, segment_height: float) -> void:
	if not brick:
		return

	if brick.has_node("Sprite"):
		var sprite = brick.get_node("Sprite")
		if texture:
			sprite.texture = texture
			sprite.rotation_degrees = 90.0
			var tex_size = texture.get_size()
			if tex_size.x > 0 and tex_size.y > 0:
				var scale_x = segment_width / tex_size.y
				var scale_y = segment_height / tex_size.x
				sprite.scale = Vector2(scale_x, scale_y)

	if brick.has_node("CollisionShape2D"):
		var collision = brick.get_node("CollisionShape2D")
		if collision.shape is RectangleShape2D:
			var new_shape = collision.shape
			if not new_shape.is_local_to_scene():
				new_shape = new_shape.duplicate()
			new_shape.size = Vector2(segment_width, segment_height)
			collision.set_deferred("shape", new_shape)

	brick.brick_color = Color(0.2, 0.8, 0.2)
	if brick.has_node("Particles"):
		brick.get_node("Particles").color = brick.brick_color
	if brick.has_node("Sprite"):
		brick.get_node("Sprite").modulate = brick.brick_color

func _on_block_brick_broken(score_value: int, parent: Node) -> void:
	"""Handle block brick destruction without affecting level completion"""
	if parent.game_manager:
		parent.game_manager.add_score(score_value)
	SaveManager.increment_stat("total_bricks_broken")

	# Trigger screen shake similar to normal bricks
	parent._apply_brick_hit_shake(score_value)

func _on_block_barrier_timeout(barrier: Node) -> void:
	if barrier and barrier.is_inside_tree():
		barrier.queue_free()

func _update_block_barrier_color(barrier: Node) -> void:
	if not barrier or not barrier.is_inside_tree():
		return

	var lifetime_timer = barrier.get_node_or_null("BlockLifetimeTimer")
	if not lifetime_timer:
		return

	var time_left = lifetime_timer.time_left
	var new_color = Color(0.2, 0.8, 0.2)
	if time_left <= 4.0: # BLOCK_COLOR_INTERVAL is 4.0
		new_color = Color(1.0, 0.35, 0.35)
	elif time_left <= 8.0: # BLOCK_COLOR_INTERVAL * 2.0
		new_color = Color(1.0, 0.8, 0.2)

	for child in barrier.get_children():
		if not (child is Node):
			continue
		if not child.is_in_group("block_brick"):
			continue
		if child.has_method("set"):
			child.brick_color = new_color
		if child.has_node("Sprite"):
			child.get_node("Sprite").modulate = new_color
		if child.has_node("Particles"):
			child.get_node("Particles").color = new_color

func _get_paddle_height(parent: Node) -> float:
	if not parent.paddle:
		return 130.0
	var height = parent.paddle.get("current_height")
	if height != null:
		return float(height)
	if parent.paddle.has_node("CollisionShape2D"):
		var collision = parent.paddle.get_node("CollisionShape2D")
		if collision.shape is RectangleShape2D:
			return collision.shape.size.y
	return 130.0

func _get_paddle_width(parent: Node) -> float:
	if not parent.paddle:
		return 24.0
	if parent.paddle.has_node("CollisionShape2D"):
		var collision = parent.paddle.get_node("CollisionShape2D")
		if collision.shape is RectangleShape2D:
			return collision.shape.size.x
	return 24.0
