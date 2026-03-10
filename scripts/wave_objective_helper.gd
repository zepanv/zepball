class_name WaveObjectiveHelper
extends RefCounted

const OBJECTIVE_NO_BALL_LOSS := "no_ball_loss"
const OBJECTIVE_SPEED_CLEAR := "speed_clear"
const OBJECTIVE_COMBO_STREAK := "combo_streak"
const OBJECTIVE_BOMB_CHAIN := "bomb_chain"
const OBJECTIVE_SPIN_MASTER := "spin_master"
const OBJECTIVE_OPENING_SALVO := "opening_salvo"

const DEFAULT_OBJECTIVE_ODDS := 0.65
const EARLY_WAVE_OBJECTIVE_ODDS := 0.85
const EARLY_WAVE_CUTOFF := 3
const OPENING_SALVO_WINDOW_SECONDS := 15.0

var current_objective: Dictionary = {}
var _objective_complete: bool = false
var _objective_failed: bool = false
var _wave_start_msec: int = 0
var _wave_start_score: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _init() -> void:
	_rng.randomize()

func has_active_objective() -> bool:
	return not current_objective.is_empty()

func is_objective_complete() -> bool:
	return has_active_objective() and _objective_complete

func is_objective_failed() -> bool:
	return has_active_objective() and _objective_failed

func get_wave_score(current_score: int) -> int:
	return max(0, current_score - _wave_start_score)

func assign_objective(wave_data: Dictionary, wave_number: int, current_score: int, current_combo: int = 0) -> Dictionary:
	current_objective = {}
	_objective_complete = false
	_objective_failed = false
	_wave_start_msec = Time.get_ticks_msec()
	_wave_start_score = current_score

	var objective_odds: float = EARLY_WAVE_OBJECTIVE_ODDS if wave_number <= EARLY_WAVE_CUTOFF else DEFAULT_OBJECTIVE_ODDS
	if _rng.randf() > objective_odds:
		return {}

	var candidates: Array[Dictionary] = _build_candidates(wave_data, wave_number)
	if candidates.is_empty():
		return {}

	var selected_index: int = _rng.randi_range(0, candidates.size() - 1)
	current_objective = candidates[selected_index].duplicate(true)
	var objective_id: String = str(current_objective.get("id", ""))
	if objective_id == OBJECTIVE_COMBO_STREAK:
		var combo_start: int = max(0, current_combo)
		var combo_gain_target: int = max(1, int(current_objective.get("target", 1)))
		var combo_absolute_target: int = combo_start + combo_gain_target
		current_objective["target"] = combo_absolute_target
		current_objective["progress"] = combo_start
		current_objective["label"] = "Combo x%d" % combo_absolute_target
	else:
		current_objective["progress"] = 0
	return current_objective.duplicate(true)

func check_objective_progress(event_type: String, event_data: Dictionary = {}) -> Dictionary:
	if not has_active_objective() or _objective_complete or _objective_failed:
		return _make_result(false, "none")

	var was_complete: bool = _objective_complete
	var was_failed: bool = _objective_failed
	var previous_progress: int = int(current_objective.get("progress", 0))
	var objective_id: String = str(current_objective.get("id", ""))
	var elapsed_seconds: float = _get_wave_elapsed_seconds()

	match objective_id:
		OBJECTIVE_NO_BALL_LOSS:
			if event_type == "ball_lost" and bool(event_data.get("is_life_loss", false)):
				_objective_failed = true
		OBJECTIVE_SPEED_CLEAR:
			var speed_target: float = float(current_objective.get("target_seconds", 0.0))
			if speed_target > 0.0 and elapsed_seconds > speed_target:
				_objective_failed = true
		OBJECTIVE_COMBO_STREAK:
			if event_type == "combo_updated":
				var combo_value: int = int(event_data.get("combo", 0))
				var capped_progress: int = max(previous_progress, combo_value)
				_set_progress(capped_progress)
				_complete_if_target_met()
		OBJECTIVE_BOMB_CHAIN:
			if event_type == "bomb_exploded":
				_increment_progress(int(event_data.get("count", 1)))
				_complete_if_target_met()
		OBJECTIVE_SPIN_MASTER:
			if event_type == "high_spin_hit":
				_increment_progress(int(event_data.get("count", 1)))
				_complete_if_target_met()
		OBJECTIVE_OPENING_SALVO:
			var opening_window: float = float(current_objective.get("window_seconds", OPENING_SALVO_WINDOW_SECONDS))
			if elapsed_seconds > opening_window and int(current_objective.get("progress", 0)) < int(current_objective.get("target", 0)):
				_objective_failed = true
			elif event_type == "brick_broken":
				_increment_progress(int(event_data.get("count", 1)))
				_complete_if_target_met()

	if not was_complete and _objective_complete:
		return _make_result(true, "completed")
	if not was_failed and _objective_failed:
		return _make_result(true, "failed")
	if int(current_objective.get("progress", 0)) != previous_progress:
		return _make_result(true, "progress")
	return _make_result(false, "none")

func poll_timed_objective() -> Dictionary:
	if not has_active_objective() or _objective_complete or _objective_failed:
		return _make_result(false, "none")

	var objective_id: String = str(current_objective.get("id", ""))
	if objective_id != OBJECTIVE_SPEED_CLEAR and objective_id != OBJECTIVE_OPENING_SALVO:
		return _make_result(false, "none")

	var text_before: String = get_display_text()
	var was_failed: bool = _objective_failed
	var elapsed_seconds: float = _get_wave_elapsed_seconds()

	match objective_id:
		OBJECTIVE_SPEED_CLEAR:
			var speed_target: float = float(current_objective.get("target_seconds", 0.0))
			if speed_target > 0.0 and elapsed_seconds > speed_target:
				_objective_failed = true
		OBJECTIVE_OPENING_SALVO:
			var opening_window: float = float(current_objective.get("window_seconds", OPENING_SALVO_WINDOW_SECONDS))
			if elapsed_seconds > opening_window and int(current_objective.get("progress", 0)) < int(current_objective.get("target", 0)):
				_objective_failed = true

	if not was_failed and _objective_failed:
		return _make_result(true, "failed")

	var text_after: String = get_display_text()
	if text_after != text_before:
		return _make_result(true, "progress")
	return _make_result(false, "none")

func finalize_wave(_current_score: int) -> Dictionary:
	if not has_active_objective():
		return {
			"active": false,
			"completed": false,
			"failed": false,
			"reward_points": 0,
			"text": ""
		}

	var objective_id: String = str(current_objective.get("id", ""))
	if not _objective_complete and not _objective_failed:
		match objective_id:
			OBJECTIVE_NO_BALL_LOSS:
				_objective_complete = true
			OBJECTIVE_SPEED_CLEAR:
				var speed_target: float = float(current_objective.get("target_seconds", 0.0))
				if speed_target > 0.0 and _get_wave_elapsed_seconds() <= speed_target:
					_objective_complete = true
				else:
					_objective_failed = true
			OBJECTIVE_OPENING_SALVO:
				var opening_window: float = float(current_objective.get("window_seconds", OPENING_SALVO_WINDOW_SECONDS))
				if _get_wave_elapsed_seconds() <= opening_window and int(current_objective.get("progress", 0)) >= int(current_objective.get("target", 0)):
					_objective_complete = true
				else:
					_objective_failed = true
			_:
				if int(current_objective.get("progress", 0)) >= int(current_objective.get("target", 0)):
					_objective_complete = true
				else:
					_objective_failed = true

	var reward_points: int = int(current_objective.get("reward_points", 0)) if _objective_complete else 0
	return {
		"active": true,
		"completed": _objective_complete,
		"failed": _objective_failed,
		"reward_points": reward_points,
		"text": get_display_text()
	}

func get_display_text() -> String:
	if not has_active_objective():
		return ""

	var objective_label: String = str(current_objective.get("label", "Objective"))
	var reward_points: int = int(current_objective.get("reward_points", 0))
	var reward_text: String = "+%d" % reward_points
	var target: int = int(current_objective.get("target", 0))
	var progress: int = int(current_objective.get("progress", 0))
	var show_progress: bool = bool(current_objective.get("show_progress", false))
	var objective_id: String = str(current_objective.get("id", ""))
	var timer_text: String = _get_timer_display_text(objective_id)

	if _objective_complete:
		return "%s COMPLETE | %s" % [objective_label, reward_text]
	if _objective_failed:
		return "%s FAILED | %s" % [objective_label, reward_text]
	if not timer_text.is_empty() and show_progress and target > 0:
		return "%s: %d/%d | %s | %s" % [objective_label, progress, target, timer_text, reward_text]
	if not timer_text.is_empty():
		return "%s | %s | %s" % [objective_label, timer_text, reward_text]
	if show_progress and target > 0:
		return "%s: %d/%d | %s" % [objective_label, progress, target, reward_text]
	return "%s | %s" % [objective_label, reward_text]

func _build_candidates(wave_data: Dictionary, wave_number: int) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	var wave: int = max(1, wave_number)
	var brick_rows: Array = wave_data.get("bricks", [])
	var bomb_count: int = 0

	for brick_variant in brick_rows:
		if not (brick_variant is Dictionary):
			continue
		var brick_entry: Dictionary = brick_variant
		var brick_type: String = str(brick_entry.get("type", ""))
		if brick_type == "BOMB":
			bomb_count += 1

	var no_loss_reward: int = 350 + min((wave - 1) * 35, 650)
	candidates.append({
		"id": OBJECTIVE_NO_BALL_LOSS,
		"label": "No Ball Loss",
		"target": 1,
		"reward_points": no_loss_reward,
		"show_progress": false
	})

	var speed_target_seconds: int = max(30, 54 - int(floor(float(wave - 1) * 1.3)))
	var speed_reward: int = 420 + min((wave - 1) * 28, 520)
	candidates.append({
		"id": OBJECTIVE_SPEED_CLEAR,
		"label": "Speed Clear < %ds" % speed_target_seconds,
		"target": 1,
		"target_seconds": float(speed_target_seconds),
		"reward_points": speed_reward,
		"show_progress": false
	})

	var combo_target: int = min(15, 4 + int(floor(float(wave - 1) / 2.0)))
	var combo_reward: int = 440 + min((wave - 1) * 30, 460)
	candidates.append({
		"id": OBJECTIVE_COMBO_STREAK,
		"label": "Combo x%d" % combo_target,
		"target": combo_target,
		"reward_points": combo_reward,
		"show_progress": true
	})

	if bomb_count >= 2:
		var bomb_target: int = min(3, max(2, 2 + int(floor(float(max(0, wave - 10)) / 10.0))))
		if bomb_count >= bomb_target:
			var bomb_reward: int = 460 + min((wave - 1) * 30, 520)
			candidates.append({
				"id": OBJECTIVE_BOMB_CHAIN,
				"label": "Bomb Chain %d" % bomb_target,
				"target": bomb_target,
				"reward_points": bomb_reward,
				"show_progress": true
			})

	var spin_target: int = min(5, 2 + int(floor(float(wave - 1) / 5.0)))
	var spin_reward: int = 430 + min((wave - 1) * 25, 420)
	candidates.append({
		"id": OBJECTIVE_SPIN_MASTER,
		"label": "Spin Master %d" % spin_target,
		"target": spin_target,
		"reward_points": spin_reward,
		"show_progress": true
	})

	var opening_target: int = min(12, 3 + int(floor(float(wave - 1) / 2.0)))
	var opening_reward: int = 420 + min((wave - 1) * 25, 420)
	candidates.append({
		"id": OBJECTIVE_OPENING_SALVO,
		"label": "Opening Salvo %d in 15s" % opening_target,
		"target": opening_target,
		"window_seconds": OPENING_SALVO_WINDOW_SECONDS,
		"reward_points": opening_reward,
		"show_progress": true
	})

	return candidates

func _complete_if_target_met() -> void:
	var target: int = int(current_objective.get("target", 0))
	if target > 0 and int(current_objective.get("progress", 0)) >= target:
		_objective_complete = true

func _increment_progress(amount: int) -> void:
	var current_progress: int = int(current_objective.get("progress", 0))
	current_objective["progress"] = max(0, current_progress + amount)

func _set_progress(progress_value: int) -> void:
	current_objective["progress"] = max(0, progress_value)

func _get_wave_elapsed_seconds() -> float:
	if _wave_start_msec <= 0:
		return 0.0
	var elapsed_msec: int = max(0, Time.get_ticks_msec() - _wave_start_msec)
	return float(elapsed_msec) / 1000.0

func _get_timer_display_text(objective_id: String) -> String:
	if _objective_complete or _objective_failed:
		return ""

	var time_limit: float = 0.0
	match objective_id:
		OBJECTIVE_SPEED_CLEAR:
			time_limit = float(current_objective.get("target_seconds", 0.0))
		OBJECTIVE_OPENING_SALVO:
			time_limit = float(current_objective.get("window_seconds", OPENING_SALVO_WINDOW_SECONDS))
		_:
			return ""

	if time_limit <= 0.0:
		return ""

	var remaining_seconds: int = int(max(0.0, ceil(time_limit - _get_wave_elapsed_seconds())))
	return "%ds LEFT" % remaining_seconds

func _make_result(changed: bool, state: String) -> Dictionary:
	return {
		"changed": changed,
		"state": state,
		"text": get_display_text()
	}
