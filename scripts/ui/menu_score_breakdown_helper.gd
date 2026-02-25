class_name MenuScoreBreakdownHelper
extends RefCounted

var last_level_breakdown: Dictionary = {}
var last_level_time_seconds: float = 0.0
var last_level_score_raw: int = 0
var last_level_score_final: int = 0
var set_breakdown: Dictionary = {}
var set_total_time_seconds: float = 0.0
var set_score_before_bonus: int = 0
var set_perfect_bonus: int = 0

func get_last_level_breakdown() -> Dictionary:
	return last_level_breakdown.duplicate()

func get_last_level_time_seconds() -> float:
	return last_level_time_seconds

func get_last_level_score_raw() -> int:
	return last_level_score_raw

func get_last_level_score_final() -> int:
	return last_level_score_final

func get_set_breakdown() -> Dictionary:
	return set_breakdown.duplicate()

func get_set_total_time_seconds() -> float:
	return set_total_time_seconds

func get_set_score_before_bonus() -> int:
	return set_score_before_bonus

func get_set_perfect_bonus() -> int:
	return set_perfect_bonus

func _create_empty_breakdown() -> Dictionary:
	return {
		"base_points": 0,
		"difficulty_bonus": 0,
		"combo_bonus": 0,
		"streak_bonus": 0,
		"double_bonus": 0,
		"perfect_clear_bonus": 0
	}

func _sum_breakdown(breakdown: Dictionary) -> int:
	return int(breakdown.get("base_points", 0)) \
		+ int(breakdown.get("difficulty_bonus", 0)) \
		+ int(breakdown.get("combo_bonus", 0)) \
		+ int(breakdown.get("streak_bonus", 0)) \
		+ int(breakdown.get("double_bonus", 0))

func _capture_level_breakdown(parent: Node, game_manager: Node) -> void:
	var breakdown = _create_empty_breakdown()
	var level_time = 0.0
	var level_score_raw = 0

	if game_manager:
		if game_manager.has_method("get_score_breakdown"):
			breakdown = game_manager.get_score_breakdown()
		if game_manager.has_method("get_level_time_seconds"):
			level_time = game_manager.get_level_time_seconds()

	level_score_raw = _sum_breakdown(breakdown)

	var previous_set_score = 0
	if parent.current_play_mode == parent.PlayMode.SET:
		previous_set_score = parent.set_mode_helper.set_saved_score

	var level_score_applied = parent.current_score - previous_set_score
	var perfect_clear_bonus = max(level_score_applied - level_score_raw, 0)

	last_level_breakdown = breakdown.duplicate()
	last_level_breakdown["perfect_clear_bonus"] = perfect_clear_bonus
	last_level_time_seconds = level_time
	last_level_score_raw = level_score_raw
	last_level_score_final = level_score_raw + perfect_clear_bonus

	if parent.current_play_mode == parent.PlayMode.SET:
		_accumulate_set_breakdown(last_level_breakdown, level_time)

func _accumulate_set_breakdown(level_breakdown: Dictionary, level_time: float) -> void:
	if set_breakdown.is_empty():
		set_breakdown = _create_empty_breakdown()

	set_breakdown["base_points"] += int(level_breakdown.get("base_points", 0))
	set_breakdown["difficulty_bonus"] += int(level_breakdown.get("difficulty_bonus", 0))
	set_breakdown["combo_bonus"] += int(level_breakdown.get("combo_bonus", 0))
	set_breakdown["streak_bonus"] += int(level_breakdown.get("streak_bonus", 0))
	set_breakdown["double_bonus"] += int(level_breakdown.get("double_bonus", 0))
	set_breakdown["perfect_clear_bonus"] += int(level_breakdown.get("perfect_clear_bonus", 0))
	set_total_time_seconds += level_time

func _reset_set_breakdown() -> void:
	set_breakdown = _create_empty_breakdown()
	set_total_time_seconds = 0.0
	set_score_before_bonus = 0
	set_perfect_bonus = 0
