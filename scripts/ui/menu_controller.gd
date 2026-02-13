extends Node

## MenuController - Autoload singleton for managing scene transitions and game flow
## Handles navigation between menus and gameplay scenes

# Scene paths
const MAIN_MENU_SCENE = "res://scenes/ui/main_menu.tscn"
const LEVEL_SELECT_SCENE = "res://scenes/ui/level_select.tscn"
const SET_SELECT_SCENE = "res://scenes/ui/set_select.tscn"
const SET_COMPLETE_SCENE = "res://scenes/ui/set_complete.tscn"
const GAMEPLAY_SCENE = "res://scenes/main/main.tscn"
const GAME_OVER_SCENE = "res://scenes/ui/game_over.tscn"
const LEVEL_COMPLETE_SCENE = "res://scenes/ui/level_complete.tscn"
const STATS_SCENE = "res://scenes/ui/stats.tscn"
const SETTINGS_SCENE = "res://scenes/ui/settings.tscn"
const LEVEL_EDITOR_SCENE = "res://scenes/ui/level_editor.tscn"

# Play mode enum
enum PlayMode { INDIVIDUAL, SET }
enum EditorReturnTarget { MAIN_MENU, SET_SELECT }

# Current state
var current_level_id: int = 1
var current_pack_id: String = "classic-challenge"
var current_level_index: int = 0
var current_browse_pack_id: String = ""
var current_score: int = 0
var is_in_gameplay: bool = false
var was_perfect_clear: bool = false
var settings_opened_from_pause: bool = false
var current_editor_pack_id: String = ""
var editor_return_target: EditorReturnTarget = EditorReturnTarget.SET_SELECT
var is_editor_test_mode: bool = false
var editor_test_pack_data: Dictionary = {}
var editor_test_level_index: int = 0
var editor_draft_pack_data: Dictionary = {}
var editor_draft_level_index: int = 0

# Set mode state
var current_play_mode: PlayMode = PlayMode.INDIVIDUAL
var current_set_id: int = -1
var current_set_pack_id: String = ""
var set_current_index: int = 0
var set_level_ids: Array = []
var set_level_refs: Array[Dictionary] = []

# Set mode saved game state (persists between level transitions)
var set_saved_score: int = 0
var set_saved_lives: int = 3
var set_saved_combo: int = 0
var set_saved_no_miss: int = 0
var set_saved_perfect: bool = true

# Score breakdown state (level + set)
var last_level_breakdown: Dictionary = {}
var last_level_time_seconds: float = 0.0
var last_level_score_raw: int = 0
var last_level_score_final: int = 0
var set_breakdown: Dictionary = {}
var set_total_time_seconds: float = 0.0
var set_score_before_bonus: int = 0
var set_perfect_bonus: int = 0

# Signals
signal scene_changed(scene_path: String)

func _ready():
	"""Initialize MenuController"""
	pass

func show_main_menu() -> void:
	"""Load and show the main menu"""
	is_in_gameplay = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Unlock difficulty for selection
	DifficultyManager.unlock_difficulty()

	# Change to main menu scene
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
	scene_changed.emit(MAIN_MENU_SCENE)

func show_level_select() -> void:
	"""Load and show the level selection screen"""
	is_in_gameplay = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Difficulty should remain unlocked in menus
	DifficultyManager.unlock_difficulty()

	get_tree().change_scene_to_file(LEVEL_SELECT_SCENE)
	scene_changed.emit(LEVEL_SELECT_SCENE)

func show_set_select() -> void:
	"""Load and show the set selection screen"""
	is_in_gameplay = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Reset set mode state when entering set select
	current_play_mode = PlayMode.INDIVIDUAL
	current_set_id = -1
	current_set_pack_id = ""
	current_browse_pack_id = ""
	set_current_index = 0
	set_level_ids = []
	set_level_refs = []

	# Difficulty should remain unlocked in menus
	DifficultyManager.unlock_difficulty()

	get_tree().change_scene_to_file(SET_SELECT_SCENE)
	scene_changed.emit(SET_SELECT_SCENE)

func show_stats() -> void:
	"""Load and show the stats screen"""
	is_in_gameplay = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Difficulty should remain unlocked in menus
	DifficultyManager.unlock_difficulty()

	get_tree().change_scene_to_file(STATS_SCENE)
	scene_changed.emit(STATS_SCENE)

func show_settings(from_pause: bool = false) -> void:
	"""Load and show the settings screen"""
	is_in_gameplay = false
	settings_opened_from_pause = from_pause
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Difficulty should remain unlocked in menus
	DifficultyManager.unlock_difficulty()

	get_tree().change_scene_to_file(SETTINGS_SCENE)
	scene_changed.emit(SETTINGS_SCENE)

func show_editor() -> void:
	"""Backward-compatible editor entry (defaults to main menu return target)."""
	show_editor_from_main_menu()

func show_editor_from_main_menu() -> void:
	"""Open the level editor for creating a new user pack from Main Menu."""
	is_in_gameplay = false
	is_editor_test_mode = false
	current_editor_pack_id = ""
	editor_return_target = EditorReturnTarget.MAIN_MENU
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	DifficultyManager.unlock_difficulty()
	get_tree().change_scene_to_file(LEVEL_EDITOR_SCENE)
	scene_changed.emit(LEVEL_EDITOR_SCENE)

func show_editor_from_set_select() -> void:
	"""Open the level editor for creating a new user pack from Pack Select."""
	is_in_gameplay = false
	is_editor_test_mode = false
	current_editor_pack_id = ""
	editor_return_target = EditorReturnTarget.SET_SELECT
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	DifficultyManager.unlock_difficulty()
	get_tree().change_scene_to_file(LEVEL_EDITOR_SCENE)
	scene_changed.emit(LEVEL_EDITOR_SCENE)

func show_editor_for_pack(pack_id: String) -> void:
	"""Open the level editor with an existing pack loaded."""
	is_in_gameplay = false
	is_editor_test_mode = false
	current_editor_pack_id = pack_id
	editor_return_target = EditorReturnTarget.SET_SELECT
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	DifficultyManager.unlock_difficulty()
	get_tree().change_scene_to_file(LEVEL_EDITOR_SCENE)
	scene_changed.emit(LEVEL_EDITOR_SCENE)

func get_editor_pack_id() -> String:
	return current_editor_pack_id

func should_editor_return_to_main_menu() -> bool:
	return editor_return_target == EditorReturnTarget.MAIN_MENU

func return_from_editor() -> void:
	"""Return to the correct menu based on where editor was opened from."""
	editor_draft_pack_data = {}
	editor_draft_level_index = 0
	if editor_return_target == EditorReturnTarget.MAIN_MENU:
		show_main_menu()
		return
	show_set_select()

func start_editor_test(pack_data: Dictionary, level_index: int) -> void:
	"""Start a one-level editor test run without progression/high-score side effects."""
	if not (pack_data.get("levels", []) is Array):
		push_error("Editor test failed: pack has invalid levels")
		return
	var levels: Array = pack_data.get("levels", [])
	if levels.is_empty():
		push_error("Editor test failed: pack has no levels")
		return
	var clamped_level_index: int = clampi(level_index, 0, levels.size() - 1)

	editor_draft_pack_data = pack_data.duplicate(true)
	editor_draft_level_index = clamped_level_index
	editor_test_pack_data = pack_data.duplicate(true)
	editor_test_level_index = clamped_level_index
	is_editor_test_mode = true

	current_play_mode = PlayMode.INDIVIDUAL
	current_set_id = -1
	current_set_pack_id = ""
	set_current_index = 0
	set_level_ids = []
	set_level_refs = []
	_reset_set_breakdown()

	current_pack_id = "__editor_test__"
	current_level_index = clamped_level_index
	current_level_id = clamped_level_index + 1
	is_in_gameplay = true
	current_score = 0
	was_perfect_clear = false

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	DifficultyManager.lock_difficulty()
	get_tree().change_scene_to_file(GAMEPLAY_SCENE)
	scene_changed.emit(GAMEPLAY_SCENE)

func has_editor_test_data() -> bool:
	return is_editor_test_mode and not editor_test_pack_data.is_empty()

func get_editor_test_level_data() -> Dictionary:
	if not has_editor_test_data():
		return {}
	var levels: Array = editor_test_pack_data.get("levels", [])
	if editor_test_level_index < 0 or editor_test_level_index >= levels.size():
		return {}
	if not (levels[editor_test_level_index] is Dictionary):
		return {}
	return (levels[editor_test_level_index] as Dictionary).duplicate(true)

func get_editor_test_level_name() -> String:
	var level_data: Dictionary = get_editor_test_level_data()
	return str(level_data.get("name", "Editor Test"))

func get_editor_test_level_description() -> String:
	var level_data: Dictionary = get_editor_test_level_data()
	return str(level_data.get("description", ""))

func get_editor_draft_pack() -> Dictionary:
	return editor_draft_pack_data.duplicate(true)

func get_editor_draft_level_index() -> int:
	return editor_draft_level_index

func clear_editor_test_state() -> void:
	is_editor_test_mode = false
	editor_test_pack_data = {}
	editor_test_level_index = 0

func return_to_editor_from_test() -> void:
	"""Exit editor test flow and return to editor with draft restored."""
	is_in_gameplay = false
	clear_editor_test_state()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	DifficultyManager.unlock_difficulty()
	get_tree().change_scene_to_file(LEVEL_EDITOR_SCENE)
	scene_changed.emit(LEVEL_EDITOR_SCENE)

func start_level(level_id: int) -> void:
	"""Start playing a specific level (individual mode by default)"""
	var ref: Dictionary = PackLoader.get_legacy_level_ref(level_id)
	if ref.is_empty():
		push_error("Level does not exist: ", level_id)
		return

	start_level_ref(str(ref.get("pack_id", "")), int(ref.get("level_index", -1)))

func start_level_ref(pack_id: String, level_index: int) -> void:
	"""Start playing a specific level using pack-native addressing."""
	var level_key := PackLoader.get_level_key(pack_id, level_index)
	if not SaveManager.is_level_key_unlocked(level_key):
		return

	var level_data := PackLoader.get_level_data(pack_id, level_index)
	if level_data.is_empty():
		push_error("Level does not exist: %s:%d" % [pack_id, level_index])
		return

	current_pack_id = pack_id
	current_level_index = level_index
	var legacy_level_id := PackLoader.get_legacy_level_id(pack_id, level_index)
	current_level_id = legacy_level_id if legacy_level_id != -1 else 0
	is_in_gameplay = true
	var mode_name = "set" if current_play_mode == PlayMode.SET else "individual"
	SaveManager.set_last_played_ref(pack_id, level_index, mode_name, current_set_pack_id, true)

	# Track gameplay sessions (counts each level start)
	SaveManager.increment_stat("total_games_played")

	# If not already in set mode, switch to individual mode
	if current_play_mode != PlayMode.SET:
		current_play_mode = PlayMode.INDIVIDUAL

	# Lock difficulty during gameplay
	DifficultyManager.lock_difficulty()

	# Clear any active power-ups from previous level
	PowerUpManager.clear_all_effects()

	# Load gameplay scene
	get_tree().change_scene_to_file(GAMEPLAY_SCENE)
	scene_changed.emit(GAMEPLAY_SCENE)

func start_set(set_id: int) -> void:
	"""Start playing a set from the beginning"""
	if not PackLoader.legacy_set_exists(set_id):
		push_error("Set does not exist: ", set_id)
		return

	# Switch to set mode
	current_play_mode = PlayMode.SET
	current_set_id = set_id
	current_set_pack_id = PackLoader.get_legacy_set_pack_id(set_id)
	set_level_ids = PackLoader.get_legacy_set_level_ids(set_id)
	set_level_refs = []
	var level_count := PackLoader.get_level_count(current_set_pack_id)
	for level_index in range(level_count):
		set_level_refs.append({
			"pack_id": current_set_pack_id,
			"level_index": level_index
		})
	set_current_index = 0

	# Reset saved state for new set
	set_saved_score = 0
	set_saved_lives = 3
	set_saved_combo = 0
	set_saved_no_miss = 0
	set_saved_perfect = true
	_reset_set_breakdown()

	# Start first level in the set
	if set_level_refs.size() > 0:
		start_level_ref(current_set_pack_id, 0)
	else:
		push_error("Set ", set_id, " has no levels!")

func start_pack(pack_id: String) -> void:
	"""Start playing a pack from the beginning (supports built-in and user packs)."""
	if not PackLoader.pack_exists(pack_id):
		push_error("Pack does not exist: %s" % pack_id)
		return

	current_play_mode = PlayMode.SET
	current_set_pack_id = pack_id
	current_set_id = _find_set_id_by_pack_id(pack_id)
	current_browse_pack_id = pack_id
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
	set_saved_lives = 3
	set_saved_combo = 0
	set_saved_no_miss = 0
	set_saved_perfect = true
	_reset_set_breakdown()

	if set_level_refs.is_empty():
		push_error("Pack %s has no levels!" % pack_id)
		return
	start_level_ref(pack_id, 0)

func continue_set_from_level(level_id: int) -> void:
	"""Resume set mode after game over continue (resets score/lives, continues from current level)"""
	var ref: Dictionary = PackLoader.get_legacy_level_ref(level_id)
	if ref.is_empty():
		push_error("Level ", level_id, " not found in current set")
		return
	continue_set_from_ref(str(ref.get("pack_id", "")), int(ref.get("level_index", -1)))

func continue_set_from_ref(pack_id: String, level_index: int) -> void:
	"""Resume set mode from pack-native level reference."""
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

	# Mark that we used a continue (prevents perfect set bonus)
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		game_manager.had_continue = true

	# Start the level (score and lives will be reset by GameManager)
	start_level_ref(pack_id, level_index)

func restart_current_level() -> void:
	"""Restart the current level"""
	if is_editor_test_mode:
		start_editor_test(editor_draft_pack_data, editor_draft_level_index)
		return
	start_level_ref(current_pack_id, current_level_index)

func show_game_over(final_score: int) -> void:
	"""Show game over screen with final score"""
	current_score = final_score
	is_in_gameplay = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if not is_editor_test_mode:
		SaveManager.set_last_played_in_progress(false)

	# Unlock difficulty when leaving gameplay
	DifficultyManager.unlock_difficulty()

	# Try to update high score
	if not is_editor_test_mode:
		SaveManager.update_level_key_high_score(get_current_level_key(), final_score)

	get_tree().change_scene_to_file(GAME_OVER_SCENE)
	scene_changed.emit(GAME_OVER_SCENE)

func show_level_complete(final_score: int) -> void:
	"""Show level complete screen, unlock next level, and save progress"""
	current_score = final_score
	is_in_gameplay = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if not is_editor_test_mode:
		SaveManager.set_last_played_in_progress(false)

	# Unlock difficulty when leaving gameplay
	DifficultyManager.unlock_difficulty()

	# Check for perfect clear bonus (2x score if no lives lost)
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	was_perfect_clear = false
	if game_manager and game_manager.check_perfect_clear():
		current_score = final_score * 2
		was_perfect_clear = true
		SaveManager.increment_stat("perfect_clears")
	else:
		current_score = final_score

	# Capture per-level breakdown before leaving gameplay
	_capture_level_breakdown(game_manager)

	if is_editor_test_mode:
		get_tree().change_scene_to_file(LEVEL_COMPLETE_SCENE)
		scene_changed.emit(LEVEL_COMPLETE_SCENE)
		return

	# Save game state for set mode (before scene changes)
	if current_play_mode == PlayMode.SET and game_manager:
		set_saved_score = current_score
		set_saved_lives = game_manager.lives
		set_saved_combo = game_manager.combo
		set_saved_no_miss = game_manager.no_miss_hits
		set_saved_perfect = game_manager.is_perfect_clear

	# Mark level as completed
	SaveManager.mark_level_key_completed(get_current_level_key())

	# Update high score (with perfect clear bonus if applicable)
	SaveManager.update_level_key_high_score(get_current_level_key(), current_score)
	var earned_stars := SaveManager.calculate_level_stars(get_current_level_key(), current_score, was_perfect_clear)
	SaveManager.update_level_key_stars(get_current_level_key(), earned_stars)

	# Track level completion statistic
	SaveManager.increment_stat("total_levels_completed")

	# Track individual mode completion if applicable
	if current_play_mode == PlayMode.INDIVIDUAL:
		SaveManager.increment_stat("total_individual_levels_completed")

	# Check for achievements
	SaveManager.check_achievements()

	# Unlock next level (works in both modes)
	var next_level_ref := _get_next_level_ref()
	if not next_level_ref.is_empty():
		SaveManager.unlock_level_key(PackLoader.get_level_key(
			str(next_level_ref.get("pack_id", "")),
			int(next_level_ref.get("level_index", -1))
		))

	get_tree().change_scene_to_file(LEVEL_COMPLETE_SCENE)
	scene_changed.emit(LEVEL_COMPLETE_SCENE)

func continue_to_next_level() -> void:
	"""Load the next level after completion (handles both individual and set mode)"""
	if is_editor_test_mode:
		return_to_editor_from_test()
		return
	if current_play_mode == PlayMode.SET:
		# In set mode, advance to next level in set
		set_current_index += 1
		if set_current_index < set_level_refs.size():
			# Continue to next level in set
			var next_ref: Dictionary = set_level_refs[set_current_index]
			start_level_ref(str(next_ref.get("pack_id", "")), int(next_ref.get("level_index", -1)))
		else:
			# Completed all levels in set
			show_set_complete(current_score)
	else:
		# In individual mode, advance via legacy ordered pack mapping.
		var next_level_ref := _get_next_level_ref()
		if next_level_ref.is_empty():
			show_level_select()
			return

		# Start next level
		start_level_ref(str(next_level_ref.get("pack_id", "")), int(next_level_ref.get("level_index", -1)))

func show_set_complete(final_score: int) -> void:
	"""Show set complete screen with cumulative score and bonuses"""
	# Check for perfect set clear (3x bonus if all lives intact and no continues used)
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	set_score_before_bonus = final_score
	set_perfect_bonus = 0
	if game_manager and game_manager.lives == 3 and game_manager.is_perfect_clear and not game_manager.had_continue:
		current_score = final_score * 3
		set_perfect_bonus = current_score - final_score
	else:
		current_score = final_score

	# Update set high score
	SaveManager.update_set_pack_high_score(current_set_pack_id, current_score)

	# Mark set as completed
	SaveManager.mark_set_pack_completed(current_set_pack_id)

	# Track set completion statistic
	SaveManager.increment_stat("total_set_runs_completed")

	# Check for achievements
	SaveManager.check_achievements()

	is_in_gameplay = false
	SaveManager.set_last_played_in_progress(false)
	get_tree().change_scene_to_file(SET_COMPLETE_SCENE)
	scene_changed.emit(SET_COMPLETE_SCENE)

func resume_last_level() -> void:
	"""Resume the last played level if it was left in progress"""
	var last_played = SaveManager.get_last_played()
	if not last_played.get("in_progress", false):
		return
	var pack_id := str(last_played.get("pack_id", ""))
	var level_index := int(last_played.get("level_index", -1))
	if pack_id.is_empty() or level_index < 0:
		var legacy_level_id = int(last_played.get("level_id", 0))
		var fallback_ref: Dictionary = PackLoader.get_legacy_level_ref(legacy_level_id)
		if fallback_ref.is_empty():
			return
		pack_id = str(fallback_ref.get("pack_id", ""))
		level_index = int(fallback_ref.get("level_index", -1))
	if pack_id.is_empty() or level_index < 0:
		return
	var mode = str(last_played.get("mode", "individual"))
	var set_pack_id := str(last_played.get("set_pack_id", ""))

	if mode == "set" and not set_pack_id.is_empty():
		current_play_mode = PlayMode.SET
		current_set_pack_id = set_pack_id
		current_set_id = _find_set_id_by_pack_id(set_pack_id)
		set_level_ids = PackLoader.get_legacy_set_level_ids(current_set_id) if current_set_id != -1 else []
		set_level_refs = []
		var level_count := PackLoader.get_level_count(set_pack_id)
		for idx in range(level_count):
			set_level_refs.append({"pack_id": set_pack_id, "level_index": idx})
		set_current_index = level_index
		set_saved_score = 0
		set_saved_lives = 3
		set_saved_combo = 0
		set_saved_no_miss = 0
		set_saved_perfect = true
	else:
		current_play_mode = PlayMode.INDIVIDUAL
		current_set_id = -1
		current_set_pack_id = ""
		set_current_index = 0
		set_level_ids = []
		set_level_refs = []

	start_level_ref(pack_id, level_index)

func quit_game() -> void:
	"""Quit the game application"""
	get_tree().quit()

func get_current_level_id() -> int:
	"""Get the ID of the currently selected/playing level"""
	return current_level_id

func get_current_level_ref() -> Dictionary:
	"""Get the current level using pack-native addressing."""
	return {
		"pack_id": current_pack_id,
		"level_index": current_level_index
	}

func get_current_level_key() -> String:
	return PackLoader.get_level_key(current_pack_id, current_level_index)

func get_next_level_ref() -> Dictionary:
	"""Expose next-level lookup for UI screens."""
	return _get_next_level_ref()

func get_current_score() -> int:
	"""Get the current/final score"""
	return current_score

func get_was_perfect_clear() -> bool:
	"""Check if the last completed level was a perfect clear"""
	return was_perfect_clear

func get_last_level_breakdown() -> Dictionary:
	"""Return the last completed level's score breakdown"""
	return last_level_breakdown.duplicate()

func get_last_level_time_seconds() -> float:
	"""Return the elapsed time for the last completed level"""
	return last_level_time_seconds

func get_last_level_score_raw() -> int:
	"""Return the last completed level's raw score before perfect clear"""
	return last_level_score_raw

func get_last_level_score_final() -> int:
	"""Return the last completed level's final score after perfect clear"""
	return last_level_score_final

func get_set_breakdown() -> Dictionary:
	"""Return the accumulated set breakdown"""
	return set_breakdown.duplicate()

func get_set_total_time_seconds() -> float:
	"""Return the total elapsed time across the set"""
	return set_total_time_seconds

func get_set_score_before_bonus() -> int:
	"""Return the set score before perfect set bonus"""
	return set_score_before_bonus

func get_set_perfect_bonus() -> int:
	"""Return the perfect set bonus amount"""
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

func _capture_level_breakdown(game_manager: Node) -> void:
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
	if current_play_mode == PlayMode.SET:
		previous_set_score = set_saved_score

	var level_score_applied = current_score - previous_set_score
	var perfect_clear_bonus = max(level_score_applied - level_score_raw, 0)

	last_level_breakdown = breakdown.duplicate()
	last_level_breakdown["perfect_clear_bonus"] = perfect_clear_bonus
	last_level_time_seconds = level_time
	last_level_score_raw = level_score_raw
	last_level_score_final = level_score_raw + perfect_clear_bonus

	if current_play_mode == PlayMode.SET:
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

func _get_next_level_ref() -> Dictionary:
	# First check if there's a next level within the same pack
	var next_level_index = current_level_index + 1
	var level_count = PackLoader.get_level_count(current_pack_id)

	if next_level_index < level_count:
		# Next level exists in the same pack
		return {
			"pack_id": current_pack_id,
			"level_index": next_level_index
		}

	# No next level in current pack - check legacy system for cross-pack progression
	var current_legacy_id := PackLoader.get_legacy_level_id(current_pack_id, current_level_index)
	if current_legacy_id == -1:
		# Not a legacy pack and no more levels in this pack
		return {}

	# Legacy pack - try to get next level across packs
	return PackLoader.get_legacy_level_ref(current_legacy_id + 1)

func _find_set_id_by_pack_id(pack_id: String) -> int:
	for set_data in PackLoader.get_all_legacy_sets():
		if str(set_data.get("pack_id", "")) == pack_id:
			return int(set_data.get("set_id", -1))
	return -1

func is_gameplay_active() -> bool:
	"""Check if we're currently in a gameplay scene"""
	return is_in_gameplay
