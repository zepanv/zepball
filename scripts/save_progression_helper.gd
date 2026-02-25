class_name SaveProgressionHelper
extends RefCounted

func is_level_unlocked(parent: Node, level_id: int) -> bool:
	var ref: Dictionary = _legacy_ref_for_level(parent, level_id)
	if ref.is_empty():
		return false
	return is_level_key_unlocked(parent, "%s:%d" % [str(ref.get("pack_id", "")), int(ref.get("level_index", -1))])

func is_level_completed(parent: Node, level_id: int) -> bool:
	var ref: Dictionary = _legacy_ref_for_level(parent, level_id)
	if ref.is_empty():
		return false
	return is_level_key_completed(parent, "%s:%d" % [str(ref.get("pack_id", "")), int(ref.get("level_index", -1))])

func unlock_level(parent: Node, level_id: int) -> void:
	var ref: Dictionary = _legacy_ref_for_level(parent, level_id)
	if ref.is_empty():
		push_warning("Cannot unlock unknown legacy level %d" % level_id)
		return
	unlock_level_key(parent, "%s:%d" % [str(ref.get("pack_id", "")), int(ref.get("level_index", -1))])

func mark_level_completed(parent: Node, level_id: int) -> void:
	var ref: Dictionary = _legacy_ref_for_level(parent, level_id)
	if ref.is_empty():
		return
	mark_level_key_completed(parent, "%s:%d" % [str(ref.get("pack_id", "")), int(ref.get("level_index", -1))])

func get_high_score(parent: Node, level_id: int) -> int:
	var ref: Dictionary = _legacy_ref_for_level(parent, level_id)
	if ref.is_empty():
		return 0
	return parent.high_scores_helper.get_level_key_high_score(parent, "%s:%d" % [str(ref.get("pack_id", "")), int(ref.get("level_index", -1))])

func update_high_score(parent: Node, level_id: int, score: int) -> bool:
	var ref: Dictionary = _legacy_ref_for_level(parent, level_id)
	if ref.is_empty():
		return false
	return parent.high_scores_helper.update_level_key_high_score(parent, "%s:%d" % [str(ref.get("pack_id", "")), int(ref.get("level_index", -1))], score)

func is_level_key_unlocked(parent: Node, level_key: String) -> bool:
	var parsed := _parse_level_key(parent, level_key)
	if parsed.is_empty():
		return false
	var pack_id := str(parsed.get("pack_id", ""))
	var level_index := int(parsed.get("level_index", -1))
	if pack_id.is_empty() or level_index < 0:
		return false

	if level_index == 0:
		return true

	var entry: Dictionary = parent.save_data.get("pack_progression", {}).get(pack_id, {})
	var highest_unlocked := int(entry.get("highest_unlocked_level_index", -1))
	return level_index <= highest_unlocked

func is_level_key_completed(parent: Node, level_key: String) -> bool:
	var parsed := _parse_level_key(parent, level_key)
	if parsed.is_empty():
		return false
	var pack_id := str(parsed.get("pack_id", ""))
	var entry: Dictionary = parent.save_data.get("pack_progression", {}).get(pack_id, {})
	var completed: Array = entry.get("levels_completed", [])
	return level_key in completed

func unlock_level_key(parent: Node, level_key: String) -> void:
	var parsed := _parse_level_key(parent, level_key)
	if parsed.is_empty():
		return
	var pack_id := str(parsed.get("pack_id", ""))
	var level_index := int(parsed.get("level_index", -1))
	var entry: Dictionary = parent.save_data["pack_progression"].get(pack_id, {
		"highest_unlocked_level_index": -1,
		"levels_completed": [],
		"stars": {}
	})
	var highest_unlocked := int(entry.get("highest_unlocked_level_index", -1))
	if level_index > highest_unlocked:
		entry["highest_unlocked_level_index"] = level_index
		parent.save_data["pack_progression"][pack_id] = entry
		var legacy_level_id := _legacy_level_id_for(parent, pack_id, level_index)
		if legacy_level_id != -1 and legacy_level_id > int(parent.save_data["progression"].get("highest_unlocked_level", 1)):
			parent.save_data["progression"]["highest_unlocked_level"] = legacy_level_id
		parent.save_to_disk()
		if legacy_level_id != -1:
			parent.level_unlocked.emit(legacy_level_id)

func mark_level_key_completed(parent: Node, level_key: String) -> void:
	var parsed := _parse_level_key(parent, level_key)
	if parsed.is_empty():
		return
	var pack_id := str(parsed.get("pack_id", ""))
	var level_index := int(parsed.get("level_index", -1))
	var entry: Dictionary = parent.save_data["pack_progression"].get(pack_id, {
		"highest_unlocked_level_index": -1,
		"levels_completed": [],
		"stars": {}
	})
	var completed: Array = entry.get("levels_completed", [])
	if not level_key in completed:
		completed.append(level_key)
		entry["levels_completed"] = completed
		parent.save_data["pack_progression"][pack_id] = entry
		var legacy_level_id := _legacy_level_id_for(parent, pack_id, level_index)
		if legacy_level_id != -1 and not legacy_level_id in parent.save_data["progression"]["levels_completed"]:
			parent.save_data["progression"]["levels_completed"].append(legacy_level_id)
		parent.save_to_disk()

func get_level_key_stars(parent: Node, level_key: String) -> int:
	var parsed := _parse_level_key(parent, level_key)
	if parsed.is_empty():
		return 0
	var pack_id := str(parsed.get("pack_id", ""))
	var entry: Dictionary = parent.save_data.get("pack_progression", {}).get(pack_id, {})
	var stars: Dictionary = entry.get("stars", {})
	return int(stars.get(level_key, 0))

func update_level_key_stars(parent: Node, level_key: String, stars_value: int) -> bool:
	var parsed := _parse_level_key(parent, level_key)
	if parsed.is_empty():
		return false
	var pack_id := str(parsed.get("pack_id", ""))
	var clamped_stars := clampi(stars_value, 0, 3)
	var entry: Dictionary = parent.save_data["pack_progression"].get(pack_id, {
		"highest_unlocked_level_index": -1,
		"levels_completed": [],
		"stars": {}
	})
	var stars: Dictionary = entry.get("stars", {})
	var current := int(stars.get(level_key, 0))
	if clamped_stars <= current:
		return false
	stars[level_key] = clamped_stars
	entry["stars"] = stars
	parent.save_data["pack_progression"][pack_id] = entry
	parent.save_to_disk()
	return true

func calculate_level_stars(parent: Node, level_key: String, final_score: int, perfect_clear: bool) -> int:
	var parsed := _parse_level_key(parent, level_key)
	if parsed.is_empty():
		return 0
	var pack_id := str(parsed.get("pack_id", ""))
	var level_index := int(parsed.get("level_index", -1))
	var max_base_score := PackLoader.get_level_max_base_score(pack_id, level_index)
	if max_base_score <= 0:
		if final_score > 0:
			return 1
		return 0

	var stars := 1
	var silver_threshold := int(ceil(max_base_score * 0.5))
	var gold_threshold := int(ceil(max_base_score * 0.8))
	if final_score >= silver_threshold:
		stars = max(stars, 2)
	if final_score >= gold_threshold or perfect_clear:
		stars = max(stars, 3)
	return stars

func get_unlocked_level_count(parent: Node) -> int:
	return parent.save_data["progression"]["highest_unlocked_level"]

func get_completed_level_count(parent: Node) -> int:
	return parent.save_data["progression"]["levels_completed"].size()

func get_pack_completed_count(parent: Node, pack_id: String) -> int:
	var entry: Dictionary = parent.save_data.get("pack_progression", {}).get(pack_id, {})
	var completed: Array = entry.get("levels_completed", [])
	return completed.size()

func get_pack_total_stars(parent: Node, pack_id: String) -> int:
	var total := 0
	var entry: Dictionary = parent.save_data.get("pack_progression", {}).get(pack_id, {})
	var stars: Dictionary = entry.get("stars", {})
	for key in stars.keys():
		total += int(stars[key])
	return total

func is_set_pack_unlocked(parent: Node, _pack_id: String) -> bool:
	return true

func is_set_pack_completed(parent: Node, pack_id: String) -> bool:
	var completed_packs: Array = parent.save_data.get("pack_set_progression", {}).get("packs_completed", [])
	return pack_id in completed_packs

func mark_set_pack_completed(parent: Node, pack_id: String) -> void:
	var completed_packs: Array = parent.save_data.get("pack_set_progression", {}).get("packs_completed", [])
	if not pack_id in completed_packs:
		completed_packs.append(pack_id)
		parent.save_data["pack_set_progression"]["packs_completed"] = completed_packs

	var set_id := _legacy_set_id_for_pack(parent, pack_id)
	if set_id != -1 and not set_id in parent.save_data["set_progression"]["sets_completed"]:
		parent.save_data["set_progression"]["sets_completed"].append(set_id)
	parent.save_to_disk()

func _ensure_pack_progression_defaults(parent: Node) -> void:
	if not parent.save_data.has("pack_progression"):
		parent.save_data["pack_progression"] = {}

	var pack_progression: Dictionary = parent.save_data["pack_progression"]

	if PackLoader:
		var all_packs: Array[Dictionary] = PackLoader.get_all_packs()
		for pack in all_packs:
			var pack_id := str(pack.get("pack_id", ""))
			if pack_id.is_empty():
				continue

			var default_unlock := -1
			if pack_id == "classic-challenge":
				default_unlock = 0

			if not pack_progression.has(pack_id):
				pack_progression[pack_id] = {
					"highest_unlocked_level_index": default_unlock,
					"levels_completed": [],
					"stars": {}
				}

			var entry: Dictionary = pack_progression[pack_id]
			if not entry.has("highest_unlocked_level_index"):
				entry["highest_unlocked_level_index"] = default_unlock
			if not entry.has("levels_completed"):
				entry["levels_completed"] = []
			if not entry.has("stars"):
				entry["stars"] = {}
			pack_progression[pack_id] = entry

	parent.save_data["pack_progression"] = pack_progression

	if not parent.save_data.has("pack_high_scores"):
		parent.save_data["pack_high_scores"] = {}
	if not parent.save_data.has("pack_set_progression"):
		parent.save_data["pack_set_progression"] = {"packs_completed": []}
	if not parent.save_data.has("pack_set_high_scores"):
		parent.save_data["pack_set_high_scores"] = {}
	if not parent.save_data.has("iron_ball_set_high_scores"):
		parent.save_data["iron_ball_set_high_scores"] = {}
	if not parent.save_data.has("one_life_set_high_scores"):
		parent.save_data["one_life_set_high_scores"] = {}
	if not parent.save_data.has("time_attack_set_high_scores"):
		parent.save_data["time_attack_set_high_scores"] = {}
	if not parent.save_data.has("iron_ball_set_high_score_timestamps"):
		parent.save_data["iron_ball_set_high_score_timestamps"] = {}
	if not parent.save_data.has("one_life_set_high_score_timestamps"):
		parent.save_data["one_life_set_high_score_timestamps"] = {}
	if not parent.save_data.has("time_attack_set_high_score_timestamps"):
		parent.save_data["time_attack_set_high_score_timestamps"] = {}
	if not parent.save_data.has("survival_top_runs"):
		parent.save_data["survival_top_runs"] = []
	elif not (parent.save_data["survival_top_runs"] is Array):
		parent.save_data["survival_top_runs"] = []
	else:
		parent.save_data["survival_top_runs"] = _sanitize_survival_runs(parent, parent.save_data["survival_top_runs"])
	if not parent.save_data.has("last_played"):
		parent.save_data["last_played"] = {
			"level_id": 0,
			"pack_id": "classic-challenge",
			"level_index": 0,
			"level_key": "classic-challenge:0",
			"set_id": -1,
			"set_pack_id": "",
			"mode": "individual",
			"challenge_mode": parent.CHALLENGE_MODE_NORMAL,
			"in_progress": false
		}
	elif not parent.save_data["last_played"].has("challenge_mode"):
		parent.save_data["last_played"]["challenge_mode"] = parent.CHALLENGE_MODE_NORMAL
	else:
		parent.save_data["last_played"]["challenge_mode"] = _normalize_challenge_mode(parent, str(parent.save_data["last_played"].get("challenge_mode", parent.CHALLENGE_MODE_NORMAL)))

func _perform_migrations(parent: Node) -> void:
	var did_migrate = false
	var loaded_version := int(parent.save_data.get("version", 0))
	if loaded_version < 2:
		did_migrate = _migrate_to_v2_pack_data(parent) or did_migrate
	if loaded_version < 3:
		did_migrate = _migrate_to_v3_challenge_data(parent) or did_migrate
	if loaded_version < 4:
		did_migrate = _migrate_to_v4_new_game_modes(parent) or did_migrate
	if loaded_version < parent.SAVE_VERSION:
		parent.save_data["version"] = parent.SAVE_VERSION
		did_migrate = true

	if not parent.save_data.has("statistics"):
		parent.save_data["statistics"] = {
			"total_bricks_broken": 0,
			"total_power_ups_collected": 0,
			"total_levels_completed": 0,
			"total_playtime": 0.0,
			"highest_combo": 0,
			"highest_score": 0,
			"total_games_played": 0,
			"perfect_clears": 0
		}
		did_migrate = true

	if not parent.save_data.has("achievements"):
		parent.save_data["achievements"] = []
		did_migrate = true

	if not parent.save_data.has("high_score_timestamps"):
		parent.save_data["high_score_timestamps"] = {}
		var now = Time.get_datetime_string_from_system()
		for key in parent.save_data.get("pack_high_scores", {}).keys():
			parent.save_data["high_score_timestamps"][key] = now
		did_migrate = true
	
	if not parent.save_data.has("set_high_score_timestamps"):
		parent.save_data["set_high_score_timestamps"] = {}
		var now = Time.get_datetime_string_from_system()
		for key in parent.save_data.get("pack_set_high_scores", {}).keys():
			parent.save_data["set_high_score_timestamps"][key] = now
		did_migrate = true

	if not parent.save_data.has("set_progression"):
		parent.save_data["set_progression"] = {
			"highest_unlocked_set": 1,
			"sets_completed": []
		}
		did_migrate = true

	if not parent.save_data.has("set_high_scores"):
		parent.save_data["set_high_scores"] = {}
		did_migrate = true

	if not parent.save_data.has("pack_progression"):
		parent.save_data["pack_progression"] = {}
		did_migrate = true

	if not parent.save_data.has("pack_high_scores"):
		parent.save_data["pack_high_scores"] = {}
		did_migrate = true

	if not parent.save_data.has("pack_set_progression"):
		parent.save_data["pack_set_progression"] = {"packs_completed": []}
		did_migrate = true

	if not parent.save_data.has("pack_set_high_scores"):
		parent.save_data["pack_set_high_scores"] = {}
		did_migrate = true

	if not parent.save_data.has("last_played"):
		parent.save_data["last_played"] = {
			"level_id": 0,
			"pack_id": "classic-challenge",
			"level_index": 0,
			"level_key": "classic-challenge:0",
			"set_id": -1,
			"set_pack_id": "",
			"mode": "individual",
			"in_progress": false
		}
		did_migrate = true

	if not parent.save_data["last_played"].has("pack_id"):
		parent.save_data["last_played"]["pack_id"] = "classic-challenge"
		did_migrate = true
	if not parent.save_data["last_played"].has("level_index"):
		parent.save_data["last_played"]["level_index"] = 0
		did_migrate = true
	if not parent.save_data["last_played"].has("level_key"):
		parent.save_data["last_played"]["level_key"] = "classic-challenge:0"
		did_migrate = true
	if not parent.save_data["last_played"].has("set_pack_id"):
		parent.save_data["last_played"]["set_pack_id"] = ""
		did_migrate = true
	if not parent.save_data["last_played"].has("challenge_mode"):
		parent.save_data["last_played"]["challenge_mode"] = parent.CHALLENGE_MODE_NORMAL
		did_migrate = true
	var normalized_challenge := _normalize_challenge_mode(parent, str(parent.save_data["last_played"].get("challenge_mode", parent.CHALLENGE_MODE_NORMAL)))
	if normalized_challenge != str(parent.save_data["last_played"].get("challenge_mode", "")):
		parent.save_data["last_played"]["challenge_mode"] = normalized_challenge
		did_migrate = true

	if not parent.save_data.has("iron_ball_set_high_scores"):
		parent.save_data["iron_ball_set_high_scores"] = {}
		did_migrate = true
	if not parent.save_data.has("one_life_set_high_scores"):
		parent.save_data["one_life_set_high_scores"] = {}
		did_migrate = true
	if not parent.save_data.has("iron_ball_set_high_score_timestamps"):
		parent.save_data["iron_ball_set_high_score_timestamps"] = {}
		did_migrate = true
	if not parent.save_data.has("one_life_set_high_score_timestamps"):
		parent.save_data["one_life_set_high_score_timestamps"] = {}
		did_migrate = true
	if not parent.save_data.has("time_attack_set_high_scores"):
		parent.save_data["time_attack_set_high_scores"] = {}
		did_migrate = true
	if not parent.save_data.has("time_attack_set_high_score_timestamps"):
		parent.save_data["time_attack_set_high_score_timestamps"] = {}
		did_migrate = true
	if not parent.save_data.has("survival_top_runs"):
		parent.save_data["survival_top_runs"] = []
		did_migrate = true
	elif not (parent.save_data["survival_top_runs"] is Array):
		parent.save_data["survival_top_runs"] = []
		did_migrate = true
	else:
		var normalized_survival_runs := _sanitize_survival_runs(parent, parent.save_data["survival_top_runs"])
		if normalized_survival_runs != parent.save_data["survival_top_runs"]:
			parent.save_data["survival_top_runs"] = normalized_survival_runs
			did_migrate = true

	_ensure_pack_progression_defaults(parent)
	
	var _disk_cb = parent.save_to_disk
	parent.statistics_helper.migrate_statistics(parent.save_data, _disk_cb)
	parent.settings_helper.migrate_settings(parent.save_data, _disk_cb)

	if did_migrate:
		parent.save_to_disk()

func _migrate_to_v2_pack_data(parent: Node) -> bool:
	var did_change := false

	if not parent.save_data.has("pack_progression"):
		parent.save_data["pack_progression"] = {}
	if not parent.save_data.has("pack_high_scores"):
		parent.save_data["pack_high_scores"] = {}
	if not parent.save_data.has("pack_set_progression"):
		parent.save_data["pack_set_progression"] = {"packs_completed": []}
	if not parent.save_data.has("pack_set_high_scores"):
		parent.save_data["pack_set_high_scores"] = {}

	var highest_legacy = int(parent.save_data.get("progression", {}).get("highest_unlocked_level", 1))
	var legacy_completed: Array = parent.save_data.get("progression", {}).get("levels_completed", [])
	var legacy_scores: Dictionary = parent.save_data.get("high_scores", {})

	for level_id in range(1, max(parent.TOTAL_LEVELS, highest_legacy) + 1):
		var level_ref: Dictionary = _legacy_ref_for_level(parent, level_id)
		if level_ref.is_empty():
			continue
		var pack_id := str(level_ref.get("pack_id", ""))
		var level_index := int(level_ref.get("level_index", -1))
		if pack_id.is_empty() or level_index < 0:
			continue
		var level_key := "%s:%d" % [pack_id, level_index]
		var entry: Dictionary = parent.save_data["pack_progression"].get(pack_id, {
			"highest_unlocked_level_index": -1,
			"levels_completed": [],
			"stars": {}
		})
		var current_unlock = int(entry.get("highest_unlocked_level_index", -1))
		if level_id <= highest_legacy and level_index > current_unlock:
			entry["highest_unlocked_level_index"] = level_index
			did_change = true
		if level_id in legacy_completed:
			var completed: Array = entry.get("levels_completed", [])
			if not level_key in completed:
				completed.append(level_key)
				entry["levels_completed"] = completed
				did_change = true
		parent.save_data["pack_progression"][pack_id] = entry

		var legacy_key := str(level_id)
		if legacy_scores.has(legacy_key):
			var score = int(legacy_scores[legacy_key])
			var current = int(parent.save_data["pack_high_scores"].get(level_key, 0))
			if score > current:
				parent.save_data["pack_high_scores"][level_key] = score
				did_change = true

	var set_scores: Dictionary = parent.save_data.get("set_high_scores", {})
	for set_id_variant in set_scores.keys():
		var set_id := int(set_id_variant)
		var pack_id := _legacy_set_pack_id(parent, set_id)
		if pack_id.is_empty():
			continue
		var new_score := int(set_scores[set_id_variant])
		var current_score := int(parent.save_data["pack_set_high_scores"].get(pack_id, 0))
		if new_score > current_score:
			parent.save_data["pack_set_high_scores"][pack_id] = new_score
			did_change = true

	var sets_completed: Array = parent.save_data.get("set_progression", {}).get("sets_completed", [])
	var pack_sets_completed: Array = parent.save_data["pack_set_progression"].get("packs_completed", [])
	for set_id in sets_completed:
		var pack_id := _legacy_set_pack_id(parent, int(set_id))
		if pack_id.is_empty():
			continue
		if not pack_id in pack_sets_completed:
			pack_sets_completed.append(pack_id)
			did_change = true
	parent.save_data["pack_set_progression"]["packs_completed"] = pack_sets_completed

	var last_played: Dictionary = parent.save_data.get("last_played", {})
	var last_level_id := int(last_played.get("level_id", 0))
	var last_played_ref: Dictionary = _legacy_ref_for_level(parent, last_level_id)
	if not last_played_ref.is_empty():
		var pack_id := str(last_played_ref.get("pack_id", "classic-challenge"))
		var level_index := int(last_played_ref.get("level_index", 0))
		last_played["pack_id"] = pack_id
		last_played["level_index"] = level_index
		last_played["level_key"] = "%s:%d" % [pack_id, level_index]
		did_change = true
	if not last_played.has("set_pack_id"):
		var set_id := int(last_played.get("set_id", -1))
		if set_id != -1:
			last_played["set_pack_id"] = _legacy_set_pack_id(parent, set_id)
		else:
			last_played["set_pack_id"] = ""
		did_change = true
	parent.save_data["last_played"] = last_played

	_ensure_pack_progression_defaults(parent)
	return did_change

func _migrate_to_v3_challenge_data(parent: Node) -> bool:
	var did_change := false

	if not parent.save_data.has("iron_ball_set_high_scores"):
		parent.save_data["iron_ball_set_high_scores"] = {}
		did_change = true
	if not parent.save_data.has("one_life_set_high_scores"):
		parent.save_data["one_life_set_high_scores"] = {}
		did_change = true
	if not parent.save_data.has("iron_ball_set_high_score_timestamps"):
		parent.save_data["iron_ball_set_high_score_timestamps"] = {}
		did_change = true
	if not parent.save_data.has("one_life_set_high_score_timestamps"):
		parent.save_data["one_life_set_high_score_timestamps"] = {}
		did_change = true
	if not parent.save_data.has("last_played"):
		parent.save_data["last_played"] = {
			"level_id": 0,
			"pack_id": "classic-challenge",
			"level_index": 0,
			"level_key": "classic-challenge:0",
			"set_id": -1,
			"set_pack_id": "",
			"mode": "individual",
			"challenge_mode": parent.CHALLENGE_MODE_NORMAL,
			"in_progress": false
		}
		did_change = true
	elif not parent.save_data["last_played"].has("challenge_mode"):
		parent.save_data["last_played"]["challenge_mode"] = parent.CHALLENGE_MODE_NORMAL
		did_change = true

	var normalized_challenge := _normalize_challenge_mode(parent, str(parent.save_data["last_played"].get("challenge_mode", parent.CHALLENGE_MODE_NORMAL)))
	if normalized_challenge != str(parent.save_data["last_played"].get("challenge_mode", "")):
		parent.save_data["last_played"]["challenge_mode"] = normalized_challenge
		did_change = true

	return did_change

func _migrate_to_v4_new_game_modes(parent: Node) -> bool:
	var did_change := false

	if not parent.save_data.has("time_attack_set_high_scores"):
		parent.save_data["time_attack_set_high_scores"] = {}
		did_change = true
	if not parent.save_data.has("time_attack_set_high_score_timestamps"):
		parent.save_data["time_attack_set_high_score_timestamps"] = {}
		did_change = true
	if not parent.save_data.has("survival_top_runs"):
		parent.save_data["survival_top_runs"] = []
		did_change = true

	if not (parent.save_data.get("survival_top_runs", []) is Array):
		parent.save_data["survival_top_runs"] = []
		did_change = true
	else:
		var normalized_runs := _sanitize_survival_runs(parent, parent.save_data["survival_top_runs"])
		if normalized_runs != parent.save_data["survival_top_runs"]:
			parent.save_data["survival_top_runs"] = normalized_runs
			did_change = true

	return did_change

func _normalize_challenge_mode(parent: Node, mode: String) -> String:
	var normalized := mode.strip_edges().to_lower()
	if parent.CHALLENGE_MODES.has(normalized):
		return normalized
	return parent.CHALLENGE_MODE_NORMAL

func _sanitize_survival_runs(parent: Node, raw_runs: Variant) -> Array:
	var sanitized: Array = []
	if raw_runs is Array:
		for run_variant in raw_runs:
			if not (run_variant is Dictionary):
				continue
			var run: Dictionary = run_variant
			sanitized.append({
				"score": max(0, int(run.get("score", 0))),
				"wave": max(1, int(run.get("wave", 1))),
				"date": str(run.get("date", "Unknown"))
			})

	sanitized.sort_custom(func(a, b):
		var score_a := int(a.get("score", 0))
		var score_b := int(b.get("score", 0))
		if score_a != score_b:
			return score_a > score_b
		var wave_a := int(a.get("wave", 0))
		var wave_b := int(b.get("wave", 0))
		if wave_a != wave_b:
			return wave_a > wave_b
		var date_a := str(a.get("date", "9999-12-31T23:59:59"))
		var date_b := str(b.get("date", "9999-12-31T23:59:59"))
		if date_a != date_b:
			return date_a < date_b
		return str(a.get("name", "")) < str(b.get("name", ""))
	)
	if sanitized.size() > 10:
		sanitized = sanitized.slice(0, 10)
	return sanitized

func _parse_level_key(parent: Node, level_key: String) -> Dictionary:
	var parts := level_key.split(":")
	if parts.size() != 2:
		return {}
	var pack_id := parts[0]
	if pack_id.is_empty():
		return {}
	var level_index := int(parts[1])
	return {"pack_id": pack_id, "level_index": level_index}

func _legacy_ref_for_level(parent: Node, level_id: int) -> Dictionary:
	if PackLoader and PackLoader.has_method("get_legacy_level_ref"):
		var ref: Dictionary = PackLoader.get_legacy_level_ref(level_id)
		if not ref.is_empty():
			return ref
	if level_id >= 1 and level_id <= 10:
		return {"pack_id": "classic-challenge", "level_index": level_id - 1}
	if level_id >= 11 and level_id <= 20:
		return {"pack_id": "prism-showcase", "level_index": level_id - 11}
	if level_id >= 21 and level_id <= 30:
		return {"pack_id": "nebula-ascend", "level_index": level_id - 21}
	return {}

func _legacy_level_id_for(parent: Node, pack_id: String, level_index: int) -> int:
	if PackLoader and PackLoader.has_method("get_legacy_level_id"):
		var level_id := PackLoader.get_legacy_level_id(pack_id, level_index)
		if level_id != -1:
			return level_id
	if pack_id == "classic-challenge":
		return level_index + 1
	if pack_id == "prism-showcase":
		return level_index + 11
	if pack_id == "nebula-ascend":
		return level_index + 21
	return -1

func _legacy_set_pack_id(parent: Node, set_id: int) -> String:
	if PackLoader and PackLoader.has_method("get_legacy_set_pack_id"):
		var pack_id := PackLoader.get_legacy_set_pack_id(set_id)
		if not pack_id.is_empty():
			return pack_id
	match set_id:
		1:
			return "classic-challenge"
		2:
			return "prism-showcase"
		3:
			return "nebula-ascend"
	return ""

func _legacy_set_id_for_pack(parent: Node, pack_id: String) -> int:
	if PackLoader and PackLoader.has_method("get_legacy_set_id_for_pack"):
		var set_id: int = PackLoader.get_legacy_set_id_for_pack(pack_id)
		if set_id != -1:
			return set_id
	if pack_id == "classic-challenge":
		return 1
	if pack_id == "prism-showcase":
		return 2
	if pack_id == "nebula-ascend":
		return 3
	return -1
