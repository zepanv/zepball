extends RefCounted
class_name MainPowerUpHandler

## MainPowerUpHandler - Applies collected power-up effects for main gameplay orchestration.

const TYPE_EXPAND = 0
const TYPE_CONTRACT = 1
const TYPE_SPEED_UP = 2
const TYPE_TRIPLE_BALL = 3
const TYPE_BIG_BALL = 4
const TYPE_SMALL_BALL = 5
const TYPE_SLOW_DOWN = 6
const TYPE_EXTRA_LIFE = 7
const TYPE_GRAB = 8
const TYPE_BRICK_THROUGH = 9
const TYPE_DOUBLE_SCORE = 10
const TYPE_MYSTERY = 11
const TYPE_BOMB_BALL = 12
const TYPE_AIR_BALL = 13
const TYPE_MAGNET = 14
const TYPE_BLOCK = 15

const TRIPLE_BALL_RETRY_COUNT = 3
const MYSTERY_RANDOM_TYPES = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 13, 14, 15]

func apply_collected_power_up(controller: Node, power_up_type: int) -> void:
	if controller == null:
		return

	match power_up_type:
		TYPE_EXPAND:
			_apply_paddle_effect(controller, PowerUpManager.PowerUpType.EXPAND)
		TYPE_CONTRACT:
			_apply_paddle_effect(controller, PowerUpManager.PowerUpType.CONTRACT)
		TYPE_SPEED_UP:
			var ball_target = _get_valid_node(controller.get("ball"))
			if ball_target and ball_target.has_method("apply_speed_up_effect"):
				ball_target.apply_speed_up_effect()
			PowerUpManager.apply_effect(PowerUpManager.PowerUpType.SPEED_UP, ball_target)
		TYPE_TRIPLE_BALL:
			# Defer spawning to avoid physics query conflicts in collision callback paths.
			controller.call_deferred("spawn_additional_balls_with_retry", TRIPLE_BALL_RETRY_COUNT)
		TYPE_BIG_BALL:
			var ball_target = _get_valid_node(controller.get("ball"))
			PowerUpManager.apply_effect(PowerUpManager.PowerUpType.BIG_BALL, ball_target)
		TYPE_SMALL_BALL:
			var ball_target = _get_valid_node(controller.get("ball"))
			PowerUpManager.apply_effect(PowerUpManager.PowerUpType.SMALL_BALL, ball_target)
		TYPE_SLOW_DOWN:
			var ball_target = _get_valid_node(controller.get("ball"))
			if ball_target and ball_target.has_method("apply_slow_down_effect"):
				ball_target.apply_slow_down_effect()
			PowerUpManager.apply_effect(PowerUpManager.PowerUpType.SLOW_DOWN, ball_target)
		TYPE_EXTRA_LIFE:
			var game_manager = _get_valid_node(controller.get("game_manager"))
			if game_manager and game_manager.has_method("add_life"):
				game_manager.add_life()
		TYPE_GRAB:
			PowerUpManager.apply_effect(PowerUpManager.PowerUpType.GRAB, null)
		TYPE_BRICK_THROUGH:
			PowerUpManager.apply_effect(PowerUpManager.PowerUpType.BRICK_THROUGH, null)
		TYPE_DOUBLE_SCORE:
			PowerUpManager.apply_effect(PowerUpManager.PowerUpType.DOUBLE_SCORE, null)
		TYPE_MYSTERY:
			# Mystery applies a random non-mystery effect.
			var random_type = MYSTERY_RANDOM_TYPES[randi() % MYSTERY_RANDOM_TYPES.size()]
			apply_collected_power_up(controller, random_type)
		TYPE_BOMB_BALL:
			PowerUpManager.apply_effect(PowerUpManager.PowerUpType.BOMB_BALL, null)
		TYPE_AIR_BALL:
			PowerUpManager.apply_effect(PowerUpManager.PowerUpType.AIR_BALL, null)
		TYPE_MAGNET:
			PowerUpManager.apply_effect(PowerUpManager.PowerUpType.MAGNET, null)
		TYPE_BLOCK:
			var default_duration = float(controller.get("BLOCK_DEFAULT_DURATION"))
			var duration = PowerUpManager.EFFECT_DURATIONS.get(PowerUpManager.PowerUpType.BLOCK, default_duration)
			controller.call_deferred("_spawn_block_barrier", duration)
			PowerUpManager.apply_effect(PowerUpManager.PowerUpType.BLOCK, null)

func _apply_paddle_effect(controller: Node, effect_type: int) -> void:
	var paddle_target = _get_valid_node(controller.get("paddle"))
	PowerUpManager.apply_effect(effect_type, paddle_target)

func _get_valid_node(value: Variant) -> Node:
	if value == null:
		return null
	if value is Node and is_instance_valid(value):
		return value
	return null
