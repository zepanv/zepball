extends Node

## PowerUpManager - Autoload singleton for managing timed power-up effects
## Tracks active effects and automatically removes them when timers expire

# Power-up types (matching power_up.gd)
enum PowerUpType {
	EXPAND,
	CONTRACT,
	SPEED_UP,
	TRIPLE_BALL,
	BIG_BALL,
	SMALL_BALL,
	SLOW_DOWN,
	EXTRA_LIFE,
	GRAB,
	BRICK_THROUGH,
	DOUBLE_SCORE,
	MYSTERY,
	BOMB_BALL,
	AIR_BALL,
	MAGNET,
	BLOCK
}

class ActiveEffect:
	var time_remaining: float
	var target_node: Node

	func _init(time_remaining_value: float, target_node_value: Node) -> void:
		time_remaining = time_remaining_value
		target_node = target_node_value

# Active effects with their remaining time
var active_effects: Dictionary[int, ActiveEffect] = {}
var _cached_paddle: Node = null
var _cached_ball: Node = null
var tracked_balls: Array[Node] = []
var expired_effect_types: Array[int] = []

# Effect durations
const EFFECT_DURATIONS = {
	PowerUpType.EXPAND: 15.0,
	PowerUpType.CONTRACT: 10.0,
	PowerUpType.SPEED_UP: 12.0,
	PowerUpType.BIG_BALL: 12.0,
	PowerUpType.SMALL_BALL: 12.0,
	PowerUpType.SLOW_DOWN: 12.0,
	PowerUpType.GRAB: 15.0,
	PowerUpType.BRICK_THROUGH: 12.0,
	PowerUpType.DOUBLE_SCORE: 15.0,
	PowerUpType.BOMB_BALL: 12.0,
	PowerUpType.AIR_BALL: 12.0,
	PowerUpType.MAGNET: 12.0,
	PowerUpType.BLOCK: 12.0
}

# Signals
signal effect_applied(type: PowerUpType)
signal effect_expired(type: PowerUpType)

func _ready() -> void:
	set_process(false)

func _process(delta):
	# Update all active effect timers
	expired_effect_types.clear()
	for effect_type in active_effects:
		var effect_data: ActiveEffect = active_effects[effect_type]
		effect_data.time_remaining -= delta

		# Check if effect expired
		if effect_data.time_remaining <= 0.0:
			expired_effect_types.append(effect_type)

	for effect_type in expired_effect_types:
		if active_effects.has(effect_type):
			remove_effect(effect_type)

func apply_effect(type: PowerUpType, target_node: Node):
	"""Apply a power-up effect with timer"""
	var duration = EFFECT_DURATIONS.get(type, 0.0)
	var has_timer = duration > 0.0
	if target_node and not is_instance_valid(target_node):
		target_node = null

	# Track only timed effects in active_effects
	if has_timer:
		if active_effects.has(type):
			active_effects[type].time_remaining += duration
		else:
			active_effects[type] = ActiveEffect.new(duration, target_node)
	elif active_effects.has(type):
		active_effects.erase(type)

	_refresh_processing_state()

	effect_applied.emit(type)

	if type == PowerUpType.EXPAND or type == PowerUpType.CONTRACT:
		_update_paddle_size(target_node)
	elif type == PowerUpType.BIG_BALL or type == PowerUpType.SMALL_BALL:
		_update_ball_size(target_node)
	elif type == PowerUpType.GRAB:
		_for_each_ball("enable_grab")
	elif type == PowerUpType.BRICK_THROUGH:
		_for_each_ball("enable_brick_through")
	elif type == PowerUpType.BOMB_BALL:
		_for_each_ball("enable_bomb_ball")
	elif type == PowerUpType.AIR_BALL:
		_for_each_ball("enable_air_ball")
	elif type == PowerUpType.MAGNET:
		_for_each_ball("enable_magnet")

func remove_effect(type: PowerUpType):
	"""Remove an active effect and reset to default"""
	if not active_effects.has(type):
		return

	var effect_data: ActiveEffect = active_effects[type]
	var target = effect_data.target_node
	if target and not is_instance_valid(target):
		target = null

	# Reset based on type
	match type:
		PowerUpType.EXPAND, PowerUpType.CONTRACT:
			active_effects.erase(type)
			var paddle_target = _get_paddle_target()
			_update_paddle_size(paddle_target)
			effect_expired.emit(type)
			_refresh_processing_state()
			return
		PowerUpType.SPEED_UP, PowerUpType.SLOW_DOWN:
			if target and target.has_method("reset_ball_speed"):
				target.reset_ball_speed()
		PowerUpType.BIG_BALL, PowerUpType.SMALL_BALL:
			active_effects.erase(type)
			var ball_target = _get_ball_target()
			_update_ball_size(ball_target)
			effect_expired.emit(type)
			_refresh_processing_state()
			return
		PowerUpType.GRAB:
			_for_each_ball("reset_grab_state")
		PowerUpType.BRICK_THROUGH:
			_for_each_ball("reset_brick_through")
		PowerUpType.DOUBLE_SCORE:
			# Score multiplier is checked via active_effects, no reset needed
			pass
		PowerUpType.BOMB_BALL:
			_for_each_ball("reset_bomb_ball")
		PowerUpType.AIR_BALL:
			_for_each_ball("reset_air_ball")
		PowerUpType.MAGNET:
			_for_each_ball("reset_magnet")

	# Remove from active effects
	active_effects.erase(type)

	effect_expired.emit(type)
	_refresh_processing_state()

func _get_paddle_target() -> Node:
	var expand_target = _get_effect_target(PowerUpType.EXPAND)
	if expand_target:
		_cached_paddle = expand_target
		return expand_target
	var contract_target = _get_effect_target(PowerUpType.CONTRACT)
	if contract_target:
		_cached_paddle = contract_target
		return contract_target
	var fallback = _get_cached_paddle()
	if fallback:
		return fallback
	return null

func _update_paddle_size(target_node: Node):
	if target_node and not is_instance_valid(target_node):
		target_node = null
	if not target_node:
		target_node = _get_paddle_target()
	if not target_node:
		return

	var has_expand = active_effects.has(PowerUpType.EXPAND)
	var has_contract = active_effects.has(PowerUpType.CONTRACT)

	if has_expand and has_contract:
		if target_node.has_method("reset_paddle_height"):
			target_node.reset_paddle_height()
		return

	if has_expand:
		if target_node.has_method("apply_expand_effect"):
			target_node.apply_expand_effect()
	elif has_contract:
		if target_node.has_method("apply_contract_effect"):
			target_node.apply_contract_effect()
	else:
		if target_node.has_method("reset_paddle_height"):
			target_node.reset_paddle_height()

func _get_ball_target() -> Node:
	var big_target = _get_effect_target(PowerUpType.BIG_BALL)
	if big_target:
		_cached_ball = big_target
		return big_target
	var small_target = _get_effect_target(PowerUpType.SMALL_BALL)
	if small_target:
		_cached_ball = small_target
		return small_target
	var fallback = _get_cached_ball()
	if fallback:
		return fallback
	return null

func _update_ball_size(target_node: Node):
	if target_node and not is_instance_valid(target_node):
		target_node = null
	if not target_node:
		target_node = _get_ball_target()
	if not target_node:
		return

	var has_big = active_effects.has(PowerUpType.BIG_BALL)
	var has_small = active_effects.has(PowerUpType.SMALL_BALL)

	if has_big and has_small:
		if target_node.has_method("reset_ball_size"):
			target_node.reset_ball_size()
		return

	if has_big:
		if target_node.has_method("apply_big_ball_effect"):
			target_node.apply_big_ball_effect()
	elif has_small:
		if target_node.has_method("apply_small_ball_effect"):
			target_node.apply_small_ball_effect()
	else:
		if target_node.has_method("reset_ball_size"):
			target_node.reset_ball_size()

func _get_effect_target(effect_type: int) -> Node:
	if active_effects.has(effect_type):
		var effect_data: ActiveEffect = active_effects[effect_type]
		var target = effect_data.target_node
		if is_instance_valid(target):
			return target
		effect_data.target_node = null
	return null

func _for_each_ball(method_name: String) -> void:
	for ball in get_active_balls():
		if is_instance_valid(ball) and ball.has_method(method_name):
			ball.call(method_name)

func _get_cached_paddle() -> Node:
	if _cached_paddle and is_instance_valid(_cached_paddle):
		return _cached_paddle
	var tree = get_tree()
	if tree == null:
		return null
	_cached_paddle = tree.get_first_node_in_group("paddle")
	if is_instance_valid(_cached_paddle):
		return _cached_paddle
	return null

func _get_cached_ball() -> Node:
	if _cached_ball and is_instance_valid(_cached_ball):
		return _cached_ball
	var active_balls = get_active_balls()
	if active_balls.size() > 0:
		_cached_ball = active_balls[0]
	if is_instance_valid(_cached_ball):
		return _cached_ball
	return null

func register_ball(ball: Node) -> void:
	if not ball or not is_instance_valid(ball):
		return
	if tracked_balls.has(ball):
		return
	tracked_balls.append(ball)

func unregister_ball(ball: Node) -> void:
	if not ball:
		return
	tracked_balls.erase(ball)

func get_active_balls() -> Array[Node]:
	_compact_tracked_balls()
	if tracked_balls.is_empty():
		var tree = get_tree()
		if tree:
			for ball in tree.get_nodes_in_group("ball"):
				if is_instance_valid(ball):
					tracked_balls.append(ball)
	return tracked_balls

func _compact_tracked_balls() -> void:
	if tracked_balls.is_empty():
		return
	for i in range(tracked_balls.size() - 1, -1, -1):
		if not is_instance_valid(tracked_balls[i]):
			tracked_balls.remove_at(i)

func _refresh_processing_state() -> void:
	set_process(not active_effects.is_empty())

func get_ball_size_multiplier() -> float:
	var has_big = active_effects.has(PowerUpType.BIG_BALL)
	var has_small = active_effects.has(PowerUpType.SMALL_BALL)
	if has_big and has_small:
		return 1.0
	if has_big:
		return 2.0
	if has_small:
		return 0.5
	return 1.0

func get_active_effects() -> Array:
	"""Get list of currently active power-up types"""
	return active_effects.keys()

func get_time_remaining(type: PowerUpType) -> float:
	"""Get remaining time for a specific effect"""
	if active_effects.has(type):
		return active_effects[type].time_remaining
	return 0.0

func is_grab_active() -> bool:
	"""Check if grab power-up is currently active"""
	return active_effects.has(PowerUpType.GRAB)

func is_brick_through_active() -> bool:
	"""Check if brick through power-up is currently active"""
	return active_effects.has(PowerUpType.BRICK_THROUGH)

func is_double_score_active() -> bool:
	"""Check if double score power-up is currently active"""
	return active_effects.has(PowerUpType.DOUBLE_SCORE)

func is_bomb_ball_active() -> bool:
	"""Check if bomb ball power-up is currently active"""
	return active_effects.has(PowerUpType.BOMB_BALL)

func is_air_ball_active() -> bool:
	"""Check if air ball power-up is currently active"""
	return active_effects.has(PowerUpType.AIR_BALL)

func is_magnet_active() -> bool:
	"""Check if magnet power-up is currently active"""
	return active_effects.has(PowerUpType.MAGNET)
