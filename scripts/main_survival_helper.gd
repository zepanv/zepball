class_name MainSurvivalHelper
extends RefCounted

var current_wave: int = 1
var survival_speed_multiplier: float = 1.0
var survival_transition_in_progress: bool = false

func _start_survival_run(parent: Node) -> void:
	current_wave = max(1, int(MenuController.get_survival_wave_reached()))
	survival_transition_in_progress = false
	_load_survival_wave(parent, current_wave, true)

func _load_survival_wave(parent: Node, wave_number: int, show_intro: bool) -> void:
	var wave: int = wave_number if wave_number > 1 else 1
	var level_data: Dictionary = parent.SURVIVAL_GENERATOR_SCRIPT.generate_wave(wave)
	var level_result := parent._instantiate_level_from_data(level_data, parent.SURVIVAL_PACK_ID, wave - 1)
	if not level_result.get("success", false):
		push_error("Failed to load survival wave %d" % wave)
		return

	current_wave = wave
	MenuController.survival_wave_reached = current_wave
	if parent.game_manager:
		parent.game_manager.current_level = current_wave
		parent.game_manager.current_pack_id = parent.SURVIVAL_PACK_ID
		parent.game_manager.current_level_index = current_wave - 1
		parent.game_manager.current_level_key = "%s:%d" % [parent.SURVIVAL_PACK_ID, current_wave]
		if parent.game_manager.has_method("set_survival_wave"):
			parent.game_manager.set_survival_wave(current_wave)
		parent.game_manager.set_state(parent.game_manager.GameState.READY)

	parent.connect_brick_signals()

	if parent.ball and is_instance_valid(parent.ball) and parent.ball.has_method("reset_ball"):
		parent.ball.reset_ball()
	_apply_survival_speed_step(parent)

	if show_intro and parent.hud and parent.hud.has_method("show_survival_wave_intro"):
		parent.hud.show_survival_wave_intro(current_wave)

func _on_survival_wave_complete(parent: Node) -> void:
	if not parent.is_survival_mode or survival_transition_in_progress:
		return
	survival_transition_in_progress = true
	current_wave += 1

	_clear_non_main_balls(parent)
	_clear_active_powerups(parent)
	if parent.ball and is_instance_valid(parent.ball) and parent.ball.has_method("reset_ball"):
		parent.ball.reset_ball()
	if parent.game_manager:
		parent.game_manager.set_state(parent.game_manager.GameState.READY)

	if parent.hud and parent.hud.has_method("show_survival_wave_countdown"):
		await parent.hud.show_survival_wave_countdown(current_wave)
	_load_survival_wave(parent, current_wave, false)
	survival_transition_in_progress = false

func _clear_non_main_balls(parent: Node) -> void:
	var active_balls := parent._get_active_balls()
	for existing_ball in active_balls:
		if not is_instance_valid(existing_ball):
			continue
		if existing_ball == parent.ball:
			continue
		existing_ball.queue_free()

func _clear_active_powerups(parent: Node) -> void:
	if not parent.play_area:
		return
	for child in parent.play_area.get_children():
		if not is_instance_valid(child):
			continue
		var child_script: Variant = child.get_script()
		if child_script and child_script.resource_path == "res://scripts/power_up.gd":
			child.queue_free()

func _apply_survival_speed_step(parent: Node) -> void:
	if not parent.is_survival_mode:
		return
	var wave_one_speed := parent.SURVIVAL_BASE_BALL_SPEED * DifficultyManager.get_speed_multiplier()
	var target_speed: float = float(parent.SURVIVAL_GENERATOR_SCRIPT.get_speed_for_wave(current_wave, wave_one_speed))
	survival_speed_multiplier = target_speed / wave_one_speed if wave_one_speed > 0.0 else 1.0

	for active_ball in parent._get_active_balls():
		if not is_instance_valid(active_ball):
			continue
		if active_ball.has_method("set_external_speed_multiplier"):
			active_ball.set_external_speed_multiplier(survival_speed_multiplier)
		else:
			var base_speed_value: Variant = active_ball.get("base_speed")
			if base_speed_value == null:
				continue
			active_ball.base_speed = target_speed
			active_ball.current_speed = target_speed
