class_name SaveHighScoresHelper
extends RefCounted

var _leaderboard_cache: Dictionary = {}
var _leaderboard_cache_dirty: bool = true

func _invalidate_leaderboard_cache(_parent: Node) -> void:
	_leaderboard_cache_dirty = true

func get_level_key_high_score(parent: Node, level_key: String) -> int:
	return int(parent.save_data.get("pack_high_scores", {}).get(level_key, 0))

func update_level_key_high_score(parent: Node, level_key: String, score: int) -> bool:
	var current_high_score = get_level_key_high_score(parent, level_key)
	if score <= current_high_score:
		return false

	if not parent.save_data.has("high_score_timestamps"):
		parent.save_data["high_score_timestamps"] = {}
	
	parent.save_data["pack_high_scores"][level_key] = score
	parent.save_data["high_score_timestamps"][level_key] = Time.get_datetime_string_from_system()
	
	var parsed = parent.progression_helper._parse_level_key(parent, level_key)
	if not parsed.is_empty():
		var pack_id = str(parsed.get("pack_id", ""))
		var level_index = int(parsed.get("level_index", -1))
		var legacy_level_id = parent.progression_helper._legacy_level_id_for(parent, pack_id, level_index)
		if legacy_level_id != -1:
			parent.save_data["high_scores"][str(legacy_level_id)] = score
			parent._emit_high_score_updated(legacy_level_id, score)
	parent.save_to_disk()
	return true

func get_set_high_score(parent: Node, set_id: int) -> int:
	var pack_id = parent.progression_helper._legacy_set_pack_id(parent, set_id)
	if pack_id.is_empty():
		return 0
	return get_set_pack_high_score(parent, pack_id)

func update_set_high_score(parent: Node, set_id: int, score: int) -> bool:
	var pack_id = parent.progression_helper._legacy_set_pack_id(parent, set_id)
	if pack_id.is_empty():
		return false
	return update_set_pack_high_score(parent, pack_id, score)

func mark_set_completed(parent: Node, set_id: int) -> void:
	var pack_id = parent.progression_helper._legacy_set_pack_id(parent, set_id)
	if pack_id.is_empty():
		return
	parent.progression_helper.mark_set_pack_completed(parent, pack_id)

func is_set_unlocked(_parent: Node, _set_id: int) -> bool:
	return true

func is_set_completed(parent: Node, set_id: int) -> bool:
	var pack_id = parent.progression_helper._legacy_set_pack_id(parent, set_id)
	if pack_id.is_empty():
		return false
	return parent.progression_helper.is_set_pack_completed(parent, pack_id)

func get_set_pack_high_score(parent: Node, pack_id: String) -> int:
	return int(parent.save_data.get("pack_set_high_scores", {}).get(pack_id, 0))

func update_set_pack_high_score(parent: Node, pack_id: String, score: int) -> bool:
	var current_high_score = get_set_pack_high_score(parent, pack_id)
	if score <= current_high_score:
		return false

	if not parent.save_data.has("set_high_score_timestamps"):
		parent.save_data["set_high_score_timestamps"] = {}

	parent.save_data["pack_set_high_scores"][pack_id] = score
	parent.save_data["set_high_score_timestamps"][pack_id] = Time.get_datetime_string_from_system()
	
	var set_id = parent.progression_helper._legacy_set_id_for_pack(parent, pack_id)
	if set_id != -1:
		parent.save_data["set_high_scores"][str(set_id)] = score
	parent.save_to_disk()
	return true

func _get_challenge_set_scores_key(parent: Node, challenge_mode: String) -> String:
	match parent.progression_helper._normalize_challenge_mode(parent, challenge_mode):
		parent.CHALLENGE_MODE_IRON_BALL:
			return "iron_ball_set_high_scores"
		parent.CHALLENGE_MODE_ONE_LIFE:
			return "one_life_set_high_scores"
		_:
			return ""

func _get_challenge_set_timestamps_key(parent: Node, challenge_mode: String) -> String:
	match parent.progression_helper._normalize_challenge_mode(parent, challenge_mode):
		parent.CHALLENGE_MODE_IRON_BALL:
			return "iron_ball_set_high_score_timestamps"
		parent.CHALLENGE_MODE_ONE_LIFE:
			return "one_life_set_high_score_timestamps"
		_:
			return ""

func get_challenge_set_high_score(parent: Node, pack_id: String, challenge_mode: String) -> int:
	var scores_key = _get_challenge_set_scores_key(parent, challenge_mode)
	if scores_key.is_empty():
		return 0
	return int(parent.save_data.get(scores_key, {}).get(pack_id, 0))

func save_challenge_set_high_score(parent: Node, pack_id: String, challenge_mode: String, score: int) -> bool:
	var scores_key = _get_challenge_set_scores_key(parent, challenge_mode)
	var timestamps_key = _get_challenge_set_timestamps_key(parent, challenge_mode)
	if scores_key.is_empty() or timestamps_key.is_empty():
		return false

	var current_high_score = get_challenge_set_high_score(parent, pack_id, challenge_mode)
	if score <= current_high_score:
		return false

	if not parent.save_data.has(scores_key):
		parent.save_data[scores_key] = {}
	if not parent.save_data.has(timestamps_key):
		parent.save_data[timestamps_key] = {}

	parent.save_data[scores_key][pack_id] = score
	parent.save_data[timestamps_key][pack_id] = Time.get_datetime_string_from_system()
	parent.save_to_disk()
	return true

func get_time_attack_set_high_score(parent: Node, pack_id: String) -> int:
	return int(parent.save_data.get("time_attack_set_high_scores", {}).get(pack_id, 0))

func save_time_attack_set_high_score(parent: Node, pack_id: String, time_seconds: int) -> bool:
	if time_seconds <= 0:
		return false

	var current_best = get_time_attack_set_high_score(parent, pack_id)
	if current_best > 0 and time_seconds >= current_best:
		return false

	if not parent.save_data.has("time_attack_set_high_scores"):
		parent.save_data["time_attack_set_high_scores"] = {}
	if not parent.save_data.has("time_attack_set_high_score_timestamps"):
		parent.save_data["time_attack_set_high_score_timestamps"] = {}

	parent.save_data["time_attack_set_high_scores"][pack_id] = time_seconds
	parent.save_data["time_attack_set_high_score_timestamps"][pack_id] = Time.get_datetime_string_from_system()
	parent.save_to_disk()
	return true

func get_survival_top_runs(parent: Node) -> Array:
	if not parent.save_data.has("survival_top_runs"):
		parent.save_data["survival_top_runs"] = []
		parent.save_to_disk()
	return parent.progression_helper._sanitize_survival_runs(parent, parent.save_data.get("survival_top_runs", []))

func save_survival_run(parent: Node, score: int, wave: int) -> void:
	if not parent.save_data.has("survival_top_runs"):
		parent.save_data["survival_top_runs"] = []

	var runs = parent.progression_helper._sanitize_survival_runs(parent, parent.save_data.get("survival_top_runs", []))
	runs.append({
		"score": max(0, score),
		"wave": max(1, wave),
		"date": Time.get_datetime_string_from_system()
	})
	parent.save_data["survival_top_runs"] = parent.progression_helper._sanitize_survival_runs(parent, runs)
	parent.save_to_disk()

func get_blitz_top_runs(parent: Node) -> Array:
	if not parent.save_data.has("blitz_top_runs"):
		parent.save_data["blitz_top_runs"] = []
		parent.save_to_disk()
	return parent.progression_helper._sanitize_blitz_runs(parent, parent.save_data.get("blitz_top_runs", []))

func save_blitz_run(parent: Node, score: int, rows: int = 1) -> void:
	if not parent.save_data.has("blitz_top_runs"):
		parent.save_data["blitz_top_runs"] = []

	var runs = parent.progression_helper._sanitize_blitz_runs(parent, parent.save_data.get("blitz_top_runs", []))
	runs.append({
		"score": max(0, score),
		"rows": max(1, rows),
		"date": Time.get_datetime_string_from_system()
	})
	parent.save_data["blitz_top_runs"] = parent.progression_helper._sanitize_blitz_runs(parent, runs)
	parent.save_to_disk()

func get_all_leaderboards(parent: Node, use_cache: bool = true) -> Dictionary:
	if use_cache and not _leaderboard_cache_dirty and not _leaderboard_cache.is_empty():
		return _leaderboard_cache.duplicate(true)

	var leaderboards = {
		"levels": {},
		"sets": {},
		"iron_ball_sets": {},
		"one_life_sets": {},
		"time_attack_sets": {},
		"survival_runs": [],
		"blitz_runs": []
	}
	
	var profiles = parent.profile_helper.get_profile_list(parent)
	for profile_id in profiles.keys():
		var path = parent.profile_helper._get_profile_path(parent, profile_id)
		if not FileAccess.file_exists(path):
			continue
			
		var file = FileAccess.open(path, FileAccess.READ)
		if not file:
			continue
			
		var json_string = file.get_as_text()
		file.close()
		var json = JSON.new()
		if json.parse(json_string) != OK:
			continue
			
		var p_data = json.data
		var p_name = profiles[profile_id]
		
		var p_level_scores = p_data.get("pack_high_scores", {})
		var p_level_times = p_data.get("high_score_timestamps", {})
		for l_key in p_level_scores.keys():
			if not leaderboards["levels"].has(l_key):
				leaderboards["levels"][l_key] = []
			
			leaderboards["levels"][l_key].append({
				"name": p_name,
				"score": int(p_level_scores[l_key]),
				"date": str(p_level_times.get(l_key, "Unknown"))
			})
			
		var p_set_scores = p_data.get("pack_set_high_scores", {})
		var p_set_times = p_data.get("set_high_score_timestamps", {})
		for s_id in p_set_scores.keys():
			if not leaderboards["sets"].has(s_id):
				leaderboards["sets"][s_id] = []

			leaderboards["sets"][s_id].append({
				"name": p_name,
				"score": int(p_set_scores[s_id]),
				"date": str(p_set_times.get(s_id, "Unknown"))
			})

		var p_iron_scores = p_data.get("iron_ball_set_high_scores", {})
		var p_iron_times = p_data.get("iron_ball_set_high_score_timestamps", {})
		for pack_id in p_iron_scores.keys():
			if not leaderboards["iron_ball_sets"].has(pack_id):
				leaderboards["iron_ball_sets"][pack_id] = []
			leaderboards["iron_ball_sets"][pack_id].append({
				"name": p_name,
				"score": int(p_iron_scores[pack_id]),
				"date": str(p_iron_times.get(pack_id, "Unknown"))
			})

		var p_one_life_scores = p_data.get("one_life_set_high_scores", {})
		var p_one_life_times = p_data.get("one_life_set_high_score_timestamps", {})
		for pack_id in p_one_life_scores.keys():
			if not leaderboards["one_life_sets"].has(pack_id):
				leaderboards["one_life_sets"][pack_id] = []
			leaderboards["one_life_sets"][pack_id].append({
				"name": p_name,
				"score": int(p_one_life_scores[pack_id]),
				"date": str(p_one_life_times.get(pack_id, "Unknown"))
			})

		var p_time_attack_scores = p_data.get("time_attack_set_high_scores", {})
		var p_time_attack_times = p_data.get("time_attack_set_high_score_timestamps", {})
		for pack_id in p_time_attack_scores.keys():
			if not leaderboards["time_attack_sets"].has(pack_id):
				leaderboards["time_attack_sets"][pack_id] = []
			leaderboards["time_attack_sets"][pack_id].append({
				"name": p_name,
				"score": int(p_time_attack_scores[pack_id]),
				"date": str(p_time_attack_times.get(pack_id, "Unknown"))
			})

		var p_survival_runs = parent.progression_helper._sanitize_survival_runs(parent, p_data.get("survival_top_runs", []))
		for run_variant in p_survival_runs:
			if not (run_variant is Dictionary):
				continue
			var run: Dictionary = run_variant
			leaderboards["survival_runs"].append({
				"name": p_name,
				"score": int(run.get("score", 0)),
				"wave": int(run.get("wave", 1)),
				"date": str(run.get("date", "Unknown"))
			})

		var p_blitz_runs = parent.progression_helper._sanitize_blitz_runs(parent, p_data.get("blitz_top_runs", []))
		for run_variant in p_blitz_runs:
			if not (run_variant is Dictionary):
				continue
			var run: Dictionary = run_variant
			leaderboards["blitz_runs"].append({
				"name": p_name,
				"score": int(run.get("score", 0)),
				"rows": int(run.get("rows", 1)),
				"date": str(run.get("date", "Unknown"))
			})
			
	for l_key in leaderboards["levels"].keys():
		leaderboards["levels"][l_key].sort_custom(func(a, b): return a["score"] > b["score"])
		if leaderboards["levels"][l_key].size() > 10:
			leaderboards["levels"][l_key] = leaderboards["levels"][l_key].slice(0, 10)
			
	for s_id in leaderboards["sets"].keys():
		leaderboards["sets"][s_id].sort_custom(func(a, b): return a["score"] > b["score"])
		if leaderboards["sets"][s_id].size() > 10:
			leaderboards["sets"][s_id] = leaderboards["sets"][s_id].slice(0, 10)
	for pack_id in leaderboards["iron_ball_sets"].keys():
		leaderboards["iron_ball_sets"][pack_id].sort_custom(func(a, b): return a["score"] > b["score"])
		if leaderboards["iron_ball_sets"][pack_id].size() > 10:
			leaderboards["iron_ball_sets"][pack_id] = leaderboards["iron_ball_sets"][pack_id].slice(0, 10)
	for pack_id in leaderboards["one_life_sets"].keys():
		leaderboards["one_life_sets"][pack_id].sort_custom(func(a, b): return a["score"] > b["score"])
		if leaderboards["one_life_sets"][pack_id].size() > 10:
			leaderboards["one_life_sets"][pack_id] = leaderboards["one_life_sets"][pack_id].slice(0, 10)
	for pack_id in leaderboards["time_attack_sets"].keys():
		leaderboards["time_attack_sets"][pack_id].sort_custom(func(a, b):
			var score_a = int(a.get("score", 0))
			var score_b = int(b.get("score", 0))
			if score_a != score_b:
				return score_a < score_b
			var date_a = str(a.get("date", "9999-12-31T23:59:59"))
			var date_b = str(b.get("date", "9999-12-31T23:59:59"))
			if date_a != date_b:
				return date_a < date_b
			return str(a.get("name", "")) < str(b.get("name", ""))
		)
		if leaderboards["time_attack_sets"][pack_id].size() > 10:
			leaderboards["time_attack_sets"][pack_id] = leaderboards["time_attack_sets"][pack_id].slice(0, 10)

	leaderboards["survival_runs"].sort_custom(func(a, b):
		var score_a = int(a.get("score", 0))
		var score_b = int(b.get("score", 0))
		if score_a != score_b:
			return score_a > score_b
		var wave_a = int(a.get("wave", 0))
		var wave_b = int(b.get("wave", 0))
		if wave_a != wave_b:
			return wave_a > wave_b
		var date_a = str(a.get("date", "9999-12-31T23:59:59"))
		var date_b = str(b.get("date", "9999-12-31T23:59:59"))
		if date_a != date_b:
			return date_a < date_b
		return str(a.get("name", "")) < str(b.get("name", ""))
	)
	if leaderboards["survival_runs"].size() > 10:
		leaderboards["survival_runs"] = leaderboards["survival_runs"].slice(0, 10)

	leaderboards["blitz_runs"].sort_custom(func(a, b):
		var score_a = int(a.get("score", 0))
		var score_b = int(b.get("score", 0))
		if score_a != score_b:
			return score_a > score_b
		var date_a = str(a.get("date", "9999-12-31T23:59:59"))
		var date_b = str(b.get("date", "9999-12-31T23:59:59"))
		if date_a != date_b:
			return date_a < date_b
		return str(a.get("name", "")) < str(b.get("name", ""))
	)
	if leaderboards["blitz_runs"].size() > 10:
		leaderboards["blitz_runs"] = leaderboards["blitz_runs"].slice(0, 10)

	_leaderboard_cache = leaderboards.duplicate(true)
	_leaderboard_cache_dirty = false

	return leaderboards

func get_global_high_score(parent: Node, level_key: String) -> int:
	var leaderboards = get_all_leaderboards(parent)
	var scores = leaderboards["levels"].get(level_key, [])
	if scores.is_empty():
		return 0
	return int(scores[0]["score"])

func get_global_set_high_score(parent: Node, pack_id: String) -> int:
	var leaderboards = get_all_leaderboards(parent)
	var scores = leaderboards["sets"].get(pack_id, [])
	if scores.is_empty():
		return 0
	return int(scores[0]["score"])

func get_global_challenge_set_high_score(parent: Node, pack_id: String, challenge_mode: String) -> int:
	var leaderboard_key = ""
	match parent.progression_helper._normalize_challenge_mode(parent, challenge_mode):
		parent.CHALLENGE_MODE_IRON_BALL:
			leaderboard_key = "iron_ball_sets"
		parent.CHALLENGE_MODE_ONE_LIFE:
			leaderboard_key = "one_life_sets"
		_:
			return 0

	var leaderboards = get_all_leaderboards(parent)
	var scores = leaderboards.get(leaderboard_key, {}).get(pack_id, [])
	if scores.is_empty():
		return 0
	return int(scores[0].get("score", 0))

func get_global_time_attack_set_best_time(parent: Node, pack_id: String) -> int:
	var leaderboards = get_all_leaderboards(parent)
	var scores = leaderboards.get("time_attack_sets", {}).get(pack_id, [])
	if scores.is_empty():
		return 0
	return int(scores[0].get("score", 0))
