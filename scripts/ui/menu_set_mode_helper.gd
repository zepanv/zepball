class_name MenuSetModeHelper
extends RefCounted

var set_current_index: int = 0
var set_level_ids: Array = []
var set_level_refs: Array[Dictionary] = []

var set_saved_score: int = 0
var set_saved_lives: int = 3
var set_saved_combo: int = 0
var set_saved_no_miss: int = 0
var set_saved_perfect: bool = true

func start_set(parent: Node, set_id: int) -> void:
	if not PackLoader.legacy_set_exists(set_id):
		push_error("Set does not exist: ", set_id)
		return

	parent.current_play_mode = parent.PlayMode.SET
	parent.current_set_id = set_id
	parent.current_set_pack_id = PackLoader.get_legacy_set_pack_id(set_id)
	set_level_ids = PackLoader.get_legacy_set_level_ids(set_id)
	set_level_refs = []
	var level_count := PackLoader.get_level_count(parent.current_set_pack_id)
	for level_index in range(level_count):
		set_level_refs.append({
			"pack_id": parent.current_set_pack_id,
			"level_index": level_index
		})
	set_current_index = 0

	set_saved_score = 0
	set_saved_lives = _get_starting_lives_for_challenge(parent)
	set_saved_combo = 0
	set_saved_no_miss = 0
	set_saved_perfect = true
	parent.time_attack_elapsed_base_seconds = 0
	parent.time_attack_final_seconds = 0
	parent._reset_set_breakdown()

	if set_level_refs.size() > 0:
		parent.start_level_ref(parent.current_set_pack_id, 0)
	else:
		push_error("Set ", set_id, " has no levels!")

func start_pack(parent: Node, pack_id: String) -> void:
	if not PackLoader.pack_exists(pack_id):
		push_error("Pack does not exist: %s" % pack_id)
		return

	parent.current_play_mode = parent.PlayMode.SET
	parent.current_set_pack_id = pack_id
	parent.current_set_id = _find_set_id_by_pack_id(pack_id)
	parent.current_browse_pack_id = pack_id
	set_level_ids = []
	set_level_refs = []

	var level_count := PackLoader.get_level_count(pack_id)
	for level_index in range(level_count):
		set_level_refs.append({"pack_id": pack_id, "level_index": level_index})
		var legacy_level_id := PackLoader.get_legacy_level_id(pack_id, level_index)
		if legacy_level_id != -1:
			set_level_ids.append(legacy_level_id)

	set_current_index = 0
	set_saved_score = 0
	set_saved_lives = _get_starting_lives_for_challenge(parent)
	set_saved_combo = 0
	set_saved_no_miss = 0
	set_saved_perfect = true
	parent.time_attack_elapsed_base_seconds = 0
	parent.time_attack_final_seconds = 0
	parent._reset_set_breakdown()

	if set_level_refs.is_empty():
		push_error("Pack %s has no levels!" % pack_id)
		return
	parent.start_level_ref(pack_id, 0)

func continue_set_from_level(parent: Node, level_id: int) -> void:
	var ref: Dictionary = PackLoader.get_legacy_level_ref(level_id)
	if ref.is_empty():
		push_error("Level ", level_id, " not found in current set")
		return
	continue_set_from_ref(parent, str(ref.get("pack_id", "")), int(ref.get("level_index", -1)))

func continue_set_from_ref(parent: Node, pack_id: String, level_index: int) -> void:
	var found_index := -1
	for i in range(set_level_refs.size()):
		var level_ref: Dictionary = set_level_refs[i]
		if str(level_ref.get("pack_id", "")) == pack_id and int(level_ref.get("level_index", -1)) == level_index:
			found_index = i
			break
	if found_index == -1:
		push_error("Level %s:%d not found in current set" % [pack_id, level_index])
		return

	set_current_index = found_index

	var game_manager = parent.get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		game_manager.had_continue = true
	if parent.get_challenge_mode() == parent.CHALLENGE_MODE_TIME_ATTACK:
		parent.time_attack_elapsed_base_seconds = 0
		parent.time_attack_final_seconds = 0

	parent.start_level_ref(pack_id, level_index)

func show_set_complete(parent: Node, final_score: int) -> void:
	var challenge_mode := parent.get_challenge_mode()
	var expected_perfect_lives := 1 if challenge_mode == parent.CHALLENGE_MODE_ONE_LIFE else 3

	var game_manager = parent.get_tree().get_first_node_in_group("game_manager")
	parent.score_breakdown_helper.set_score_before_bonus = final_score
	parent.score_breakdown_helper.set_perfect_bonus = 0
	if game_manager and game_manager.lives == expected_perfect_lives and game_manager.is_perfect_clear and not game_manager.had_continue:
		parent.current_score = final_score * 3
		parent.score_breakdown_helper.set_perfect_bonus = parent.current_score - final_score
	else:
		parent.current_score = final_score

	var completion_time_seconds: int = 0
	if challenge_mode == parent.CHALLENGE_MODE_TIME_ATTACK:
		completion_time_seconds = int(max(parent.time_attack_final_seconds, parent.time_attack_elapsed_base_seconds))
		if completion_time_seconds <= 0:
			completion_time_seconds = int(floor(max(parent.score_breakdown_helper.set_total_time_seconds, 0.0)))

	parent.was_new_personal_best = false
	parent.was_new_machine_best = false
	if challenge_mode == parent.CHALLENGE_MODE_TIME_ATTACK:
		var prev_pb_time := SaveManager.get_time_attack_set_high_score(parent.current_set_pack_id)
		var prev_global_time := SaveManager.get_global_time_attack_set_best_time(parent.current_set_pack_id)
		if completion_time_seconds > 0:
			parent.was_new_personal_best = (prev_pb_time == 0) or (completion_time_seconds < prev_pb_time)
			parent.was_new_machine_best = (prev_global_time == 0) or (completion_time_seconds < prev_global_time)
	elif challenge_mode != parent.CHALLENGE_MODE_NORMAL:
		var prev_pb_challenge := SaveManager.get_challenge_set_high_score(parent.current_set_pack_id, challenge_mode)
		var prev_global_challenge := SaveManager.get_global_challenge_set_high_score(parent.current_set_pack_id, challenge_mode)
		parent.was_new_personal_best = (parent.current_score > prev_pb_challenge) or (prev_pb_challenge == 0 and parent.current_score > 0)
		parent.was_new_machine_best = (parent.current_score > prev_global_challenge) or (prev_global_challenge == 0 and parent.current_score > 0)
	else:
		var prev_pb := SaveManager.get_set_pack_high_score(parent.current_set_pack_id)
		var prev_global := SaveManager.get_global_set_high_score(parent.current_set_pack_id)
		parent.was_new_personal_best = (parent.current_score > prev_pb) or (prev_pb == 0 and parent.current_score > 0)
		parent.was_new_machine_best = (parent.current_score > prev_global) or (prev_global == 0 and parent.current_score > 0)

	SaveManager.update_set_pack_high_score(parent.current_set_pack_id, parent.current_score)
	if challenge_mode == parent.CHALLENGE_MODE_TIME_ATTACK:
		if completion_time_seconds > 0:
			SaveManager.save_time_attack_set_high_score(parent.current_set_pack_id, completion_time_seconds)
	elif challenge_mode != parent.CHALLENGE_MODE_NORMAL:
		SaveManager.save_challenge_set_high_score(parent.current_set_pack_id, challenge_mode, parent.current_score)

	SaveManager.mark_set_pack_completed(parent.current_set_pack_id)
	SaveManager.increment_stat("total_set_runs_completed")
	SaveManager.check_achievements()

	parent.is_in_gameplay = false
	SaveManager.set_last_played_in_progress(false)
	parent.get_tree().change_scene_to_file(parent.SET_COMPLETE_SCENE)
	parent.scene_changed.emit(parent.SET_COMPLETE_SCENE)

func _find_set_id_by_pack_id(pack_id: String) -> int:
	for set_data in PackLoader.get_all_legacy_sets():
		if str(set_data.get("pack_id", "")) == pack_id:
			return int(set_data.get("set_id", -1))
	return -1

func _get_starting_lives_for_challenge(parent: Node) -> int:
	return 1 if parent.get_challenge_mode() == parent.CHALLENGE_MODE_ONE_LIFE else 3

func _get_next_level_ref(parent: Node) -> Dictionary:
	var next_level_index = parent.current_level_index + 1
	var level_count = PackLoader.get_level_count(parent.current_pack_id)

	if next_level_index < level_count:
		return {
			"pack_id": parent.current_pack_id,
			"level_index": next_level_index
		}

	var current_legacy_id := PackLoader.get_legacy_level_id(parent.current_pack_id, parent.current_level_index)
	if current_legacy_id == -1:
		return {}

	return PackLoader.get_legacy_level_ref(current_legacy_id + 1)
