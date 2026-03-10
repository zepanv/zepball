class_name MainSurvivalHelper
extends RefCounted

const WAVE_OBJECTIVE_HELPER_SCRIPT: GDScript = preload("res://scripts/wave_objective_helper.gd")
const BRICK_TYPE_BOMB: int = 9

var current_wave: int = 1
var survival_speed_multiplier: float = 1.0
var survival_transition_in_progress: bool = false
var objective_helper: RefCounted = null

func _start_survival_run(parent: Node) -> void:
	current_wave = max(1, int(MenuController.get_survival_wave_reached()))
	survival_transition_in_progress = false
	if objective_helper == null:
		objective_helper = WAVE_OBJECTIVE_HELPER_SCRIPT.new()
	_load_survival_wave(parent, current_wave, true)

func _load_survival_wave(parent: Node, wave_number: int, show_intro: bool) -> void:
	var wave: int = wave_number if wave_number > 1 else 1
	var level_data: Dictionary = parent.SURVIVAL_GENERATOR_SCRIPT.generate_wave(wave)
	var level_result = parent._instantiate_level_from_data(level_data, parent.SURVIVAL_PACK_ID, wave - 1)
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

	var primary_ball: Node = null
	if parent.has_method("ensure_primary_ball"):
		primary_ball = parent.ensure_primary_ball()
	elif parent.ball and is_instance_valid(parent.ball):
		primary_ball = parent.ball
	if primary_ball and primary_ball.has_method("reset_ball"):
		primary_ball.reset_ball()
	_apply_survival_speed_step(parent)
	_assign_wave_objective(parent, level_data, current_wave)

	if show_intro and parent.hud and parent.hud.has_method("show_survival_wave_intro"):
		parent.hud.show_survival_wave_intro(current_wave)

func _on_survival_wave_complete(parent: Node) -> void:
	if not parent.is_survival_mode or survival_transition_in_progress:
		return
	survival_transition_in_progress = true
	_finalize_wave_objective(parent)
	current_wave += 1

	var primary_ball: Node = null
	if parent.has_method("ensure_primary_ball"):
		primary_ball = parent.ensure_primary_ball()
	_clear_non_main_balls(parent, primary_ball)
	_clear_active_powerups(parent)
	if primary_ball == null and parent.has_method("ensure_primary_ball"):
		primary_ball = parent.ensure_primary_ball()
	if primary_ball and primary_ball.has_method("reset_ball"):
		primary_ball.reset_ball()
	if parent.game_manager:
		parent.game_manager.set_state(parent.game_manager.GameState.READY)

	if parent.hud and parent.hud.has_method("show_survival_wave_countdown"):
		await parent.hud.show_survival_wave_countdown(current_wave)
	_load_survival_wave(parent, current_wave, false)
	survival_transition_in_progress = false

func _on_survival_ball_lost(parent: Node, is_life_loss: bool) -> void:
	if not parent.is_survival_mode or objective_helper == null:
		return
	var result: Dictionary = objective_helper.check_objective_progress("ball_lost", {"is_life_loss": is_life_loss})
	_emit_objective_result(parent, result)

func _on_survival_brick_broken(parent: Node, brick_ref: Node, high_spin_hit: bool) -> void:
	if not parent.is_survival_mode or objective_helper == null:
		return
	if parent.game_manager == null:
		return

	var progress_result: Dictionary = objective_helper.check_objective_progress("brick_broken", {"count": 1})
	_emit_objective_result(parent, progress_result)

	var combo_result: Dictionary = objective_helper.check_objective_progress("combo_updated", {"combo": int(parent.game_manager.combo)})
	_emit_objective_result(parent, combo_result)

	if high_spin_hit:
		var spin_result: Dictionary = objective_helper.check_objective_progress("high_spin_hit", {"count": 1})
		_emit_objective_result(parent, spin_result)

	if brick_ref and is_instance_valid(brick_ref):
		var brick_type_value: Variant = brick_ref.get("brick_type")
		if brick_type_value != null and int(brick_type_value) == BRICK_TYPE_BOMB:
			var bomb_result: Dictionary = objective_helper.check_objective_progress("bomb_exploded", {"count": 1})
			_emit_objective_result(parent, bomb_result)

func _process_survival(parent: Node, _delta: float) -> void:
	if not parent.is_survival_mode or objective_helper == null:
		return
	var timed_result: Dictionary = objective_helper.poll_timed_objective()
	_emit_objective_result(parent, timed_result)

func _clear_non_main_balls(parent: Node, preserved_ball: Node = null) -> void:
	if preserved_ball == null and parent.has_method("ensure_primary_ball"):
		preserved_ball = parent.ensure_primary_ball()
	var active_balls = parent._get_active_balls()
	for existing_ball in active_balls:
		if not is_instance_valid(existing_ball):
			continue
		if existing_ball == preserved_ball:
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
	var wave_one_speed = parent.SURVIVAL_BASE_BALL_SPEED * DifficultyManager.get_speed_multiplier()
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

func _assign_wave_objective(parent: Node, level_data: Dictionary, wave_number: int) -> void:
	if objective_helper == null:
		objective_helper = WAVE_OBJECTIVE_HELPER_SCRIPT.new()
	if objective_helper == null:
		return

	var start_score: int = 0
	var start_combo: int = 0
	if parent.game_manager:
		start_score = int(parent.game_manager.score)
		start_combo = int(parent.game_manager.combo)
	objective_helper.assign_objective(level_data, wave_number, start_score, start_combo)
	var objective_text: String = objective_helper.get_display_text()
	if parent.game_manager:
		if parent.game_manager.has_method("emit_objective_assigned"):
			parent.game_manager.emit_objective_assigned(objective_text)
		elif parent.game_manager.has_signal("objective_assigned"):
			parent.game_manager.objective_assigned.emit(objective_text)

func _finalize_wave_objective(parent: Node) -> void:
	if objective_helper == null or parent.game_manager == null:
		return

	var final_score: int = int(parent.game_manager.score)
	var result: Dictionary = objective_helper.finalize_wave(final_score)
	if not bool(result.get("active", false)):
		return

	var reward_points: int = int(result.get("reward_points", 0))
	if bool(result.get("completed", false)) and reward_points > 0 and parent.game_manager.has_method("add_objective_bonus_score"):
		parent.game_manager.add_objective_bonus_score(reward_points)
		if not MenuController.is_editor_test_mode and SaveManager and SaveManager.has_method("increment_stat"):
			SaveManager.increment_stat("wave_objectives_completed")

	var objective_text: String = str(result.get("text", ""))
	if bool(result.get("completed", false)):
		if parent.game_manager.has_method("emit_objective_completed"):
			parent.game_manager.emit_objective_completed(objective_text)
		else:
			parent.game_manager.objective_completed.emit(objective_text)
	elif bool(result.get("failed", false)):
		if parent.game_manager.has_method("emit_objective_failed"):
			parent.game_manager.emit_objective_failed(objective_text)
		else:
			parent.game_manager.objective_failed.emit(objective_text)
	else:
		if parent.game_manager.has_method("emit_objective_progress"):
			parent.game_manager.emit_objective_progress(objective_text)
		else:
			parent.game_manager.objective_progress.emit(objective_text)

func _emit_objective_result(parent: Node, result: Dictionary) -> void:
	if parent.game_manager == null:
		return
	if not bool(result.get("changed", false)):
		return

	var state: String = str(result.get("state", "none"))
	var objective_text: String = str(result.get("text", ""))
	match state:
		"completed":
			if parent.game_manager.has_method("emit_objective_completed"):
				parent.game_manager.emit_objective_completed(objective_text)
			else:
				parent.game_manager.objective_completed.emit(objective_text)
		"failed":
			if parent.game_manager.has_method("emit_objective_failed"):
				parent.game_manager.emit_objective_failed(objective_text)
			else:
				parent.game_manager.objective_failed.emit(objective_text)
		_:
			if parent.game_manager.has_method("emit_objective_progress"):
				parent.game_manager.emit_objective_progress(objective_text)
			else:
				parent.game_manager.objective_progress.emit(objective_text)
