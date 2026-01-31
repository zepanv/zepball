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

# Active effects with their remaining time
var active_effects: Dictionary = {}
# Format: {PowerUpType: {time_remaining: float, target_node: Node}}

# Effect durations
const EFFECT_DURATIONS = {
	PowerUpType.EXPAND: 15.0,
	PowerUpType.CONTRACT: 10.0,
	PowerUpType.SPEED_UP: 12.0,
	PowerUpType.TRIPLE_BALL: 0.0,  # Permanent (doesn't expire)
	PowerUpType.BIG_BALL: 12.0,
	PowerUpType.SMALL_BALL: 12.0,
	PowerUpType.SLOW_DOWN: 12.0,
	PowerUpType.EXTRA_LIFE: 0.0,  # Instant (doesn't expire)
	PowerUpType.GRAB: 15.0,
	PowerUpType.BRICK_THROUGH: 12.0,
	PowerUpType.DOUBLE_SCORE: 15.0,
	PowerUpType.MYSTERY: 0.0,  # Instant (doesn't expire, applies random effect)
	PowerUpType.BOMB_BALL: 12.0,
	PowerUpType.AIR_BALL: 12.0,
	PowerUpType.MAGNET: 12.0,
	PowerUpType.BLOCK: 12.0
}

# Signals
signal effect_applied(type: PowerUpType)
signal effect_expired(type: PowerUpType)

func _process(delta):
	# Update all active effect timers
	for effect_type in active_effects.keys():
		var effect_data = active_effects[effect_type]
		effect_data.time_remaining -= delta

		# Check if effect expired
		if effect_data.time_remaining <= 0:
			remove_effect(effect_type)

func apply_effect(type: PowerUpType, target_node: Node):
	"""Apply a power-up effect with timer"""
	var duration = EFFECT_DURATIONS.get(type, 0.0)
	if target_node and not is_instance_valid(target_node):
		target_node = null

	# If effect already active, refresh timer
	if active_effects.has(type):
		active_effects[type].time_remaining = duration
		print("Refreshed power-up: ", PowerUpType.keys()[type])
	else:
		# Add new effect
		active_effects[type] = {
			"time_remaining": duration,
			"target_node": target_node
		}
		print("Applied power-up: ", PowerUpType.keys()[type], " for ", duration, "s")

	effect_applied.emit(type)

	if type == PowerUpType.EXPAND or type == PowerUpType.CONTRACT:
		_update_paddle_size(target_node)
	elif type == PowerUpType.BIG_BALL or type == PowerUpType.SMALL_BALL:
		_update_ball_size(target_node)
	elif type == PowerUpType.GRAB:
		# Enable grab on all balls
		var balls = get_tree().get_nodes_in_group("ball")
		for ball in balls:
			if ball.has_method("enable_grab"):
				ball.enable_grab()
	elif type == PowerUpType.BRICK_THROUGH:
		# Enable brick through on all balls
		var balls = get_tree().get_nodes_in_group("ball")
		for ball in balls:
			if ball.has_method("enable_brick_through"):
				ball.enable_brick_through()
	elif type == PowerUpType.BOMB_BALL:
		# Enable bomb ball on all balls
		var balls = get_tree().get_nodes_in_group("ball")
		for ball in balls:
			if ball.has_method("enable_bomb_ball"):
				ball.enable_bomb_ball()
	elif type == PowerUpType.AIR_BALL:
		# Enable air ball on all balls
		var balls = get_tree().get_nodes_in_group("ball")
		for ball in balls:
			if ball.has_method("enable_air_ball"):
				ball.enable_air_ball()
	elif type == PowerUpType.MAGNET:
		# Enable magnet on all balls
		var balls = get_tree().get_nodes_in_group("ball")
		for ball in balls:
			if ball.has_method("enable_magnet"):
				ball.enable_magnet()

func remove_effect(type: PowerUpType):
	"""Remove an active effect and reset to default"""
	if not active_effects.has(type):
		return

	var effect_data = active_effects[type]
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
			print("Power-up expired: ", PowerUpType.keys()[type])
			return
		PowerUpType.SPEED_UP, PowerUpType.SLOW_DOWN:
			if target and target.has_method("reset_ball_speed"):
				target.reset_ball_speed()
		PowerUpType.BIG_BALL, PowerUpType.SMALL_BALL:
			active_effects.erase(type)
			var ball_target = _get_ball_target()
			_update_ball_size(ball_target)
			effect_expired.emit(type)
			print("Power-up expired: ", PowerUpType.keys()[type])
			return
		PowerUpType.GRAB:
			# Reset grab state on all balls
			var balls = get_tree().get_nodes_in_group("ball")
			for ball in balls:
				if ball.has_method("reset_grab_state"):
					ball.reset_grab_state()
		PowerUpType.BRICK_THROUGH:
			# Reset brick through state on all balls
			var balls = get_tree().get_nodes_in_group("ball")
			for ball in balls:
				if ball.has_method("reset_brick_through"):
					ball.reset_brick_through()
		PowerUpType.DOUBLE_SCORE:
			# Score multiplier is checked via active_effects, no reset needed
			pass
		PowerUpType.BOMB_BALL:
			# Reset bomb ball state on all balls
			var balls = get_tree().get_nodes_in_group("ball")
			for ball in balls:
				if ball.has_method("reset_bomb_ball"):
					ball.reset_bomb_ball()
		PowerUpType.AIR_BALL:
			# Reset air ball state on all balls
			var balls = get_tree().get_nodes_in_group("ball")
			for ball in balls:
				if ball.has_method("reset_air_ball"):
					ball.reset_air_ball()
		PowerUpType.MAGNET:
			# Reset magnet state on all balls
			var balls = get_tree().get_nodes_in_group("ball")
			for ball in balls:
				if ball.has_method("reset_magnet"):
					ball.reset_magnet()

	# Remove from active effects
	active_effects.erase(type)

	effect_expired.emit(type)
	print("Power-up expired: ", PowerUpType.keys()[type])

func _get_paddle_target() -> Node:
	var expand_target = _get_effect_target(PowerUpType.EXPAND)
	if expand_target:
		return expand_target
	var contract_target = _get_effect_target(PowerUpType.CONTRACT)
	if contract_target:
		return contract_target
	var fallback = get_tree().get_first_node_in_group("paddle")
	if is_instance_valid(fallback):
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
		return big_target
	var small_target = _get_effect_target(PowerUpType.SMALL_BALL)
	if small_target:
		return small_target
	var fallback = get_tree().get_first_node_in_group("ball")
	if is_instance_valid(fallback):
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
		var target = active_effects[effect_type].target_node
		if is_instance_valid(target):
			return target
		active_effects[effect_type].target_node = null
	return null

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
