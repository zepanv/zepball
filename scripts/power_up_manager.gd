extends Node

## PowerUpManager - Autoload singleton for managing timed power-up effects
## Tracks active effects and automatically removes them when timers expire

# Power-up types (matching power_up.gd)
enum PowerUpType {
	EXPAND,
	CONTRACT,
	SPEED_UP,
	TRIPLE_BALL
}

# Active effects with their remaining time
var active_effects: Dictionary = {}
# Format: {PowerUpType: {time_remaining: float, target_node: Node}}

# Effect durations
const EFFECT_DURATIONS = {
	PowerUpType.EXPAND: 15.0,
	PowerUpType.CONTRACT: 10.0,
	PowerUpType.SPEED_UP: 12.0,
	PowerUpType.TRIPLE_BALL: 0.0  # Permanent (doesn't expire)
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

func remove_effect(type: PowerUpType):
	"""Remove an active effect and reset to default"""
	if not active_effects.has(type):
		return

	var effect_data = active_effects[type]
	var target = effect_data.target_node

	# Reset based on type
	match type:
		PowerUpType.EXPAND, PowerUpType.CONTRACT:
			if target and target.has_method("reset_paddle_height"):
				target.reset_paddle_height()
		PowerUpType.SPEED_UP:
			if target and target.has_method("reset_ball_speed"):
				target.reset_ball_speed()

	# Remove from active effects
	active_effects.erase(type)

	effect_expired.emit(type)
	print("Power-up expired: ", PowerUpType.keys()[type])

func get_active_effects() -> Array:
	"""Get list of currently active power-up types"""
	return active_effects.keys()

func get_time_remaining(type: PowerUpType) -> float:
	"""Get remaining time for a specific effect"""
	if active_effects.has(type):
		return active_effects[type].time_remaining
	return 0.0
