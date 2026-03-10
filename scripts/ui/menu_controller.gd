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
const HIGH_SCORES_SCENE = "res://scenes/ui/high_scores.tscn"
const SCREENSHOT_RES_DIR = "res://temp"
const SCREENSHOT_USER_DIR = "user://screenshots"

# Play mode enum
enum PlayMode { INDIVIDUAL, SET }
enum EditorReturnTarget { MAIN_MENU, SET_SELECT }
const CHALLENGE_MODE_NORMAL = "normal"
const CHALLENGE_MODE_IRON_BALL = "iron_ball"
const CHALLENGE_MODE_ONE_LIFE = "one_life"
const CHALLENGE_MODE_TIME_ATTACK = "time_attack"
const LAST_PLAYED_MODE_SURVIVAL = "survival"

# Current state
var current_level_id: int = 1
var current_pack_id: String = "classic-challenge"
var current_level_index: int = 0
var current_browse_pack_id: String = ""
var current_challenge_mode: String = "normal"
var current_score: int = 0
var is_in_gameplay: bool = false
var is_survival_mode: bool = false
var survival_wave_reached: int = 1
var time_attack_elapsed_base_seconds: int = 0
var time_attack_final_seconds: int = 0
var was_perfect_clear: bool = false
var was_new_personal_best: bool = false
var was_new_machine_best: bool = false
var settings_opened_from_pause: bool = false
var current_editor_pack_id: String = ""
var editor_return_target: EditorReturnTarget = EditorReturnTarget.SET_SELECT
var _quit_requested: bool = false
var _screenshot_capture_in_progress: bool = false

# Set mode state
var current_play_mode: PlayMode = PlayMode.INDIVIDUAL
var current_set_id: int = -1
var current_set_pack_id: String = ""


const MENU_EDITOR_TEST_HELPER_SCRIPT = preload("res://scripts/ui/menu_editor_test_helper.gd")
var editor_test_helper: RefCounted = null
const MENU_SCORE_BREAKDOWN_HELPER_SCRIPT = preload("res://scripts/ui/menu_score_breakdown_helper.gd")
var score_breakdown_helper: RefCounted = null
const MENU_SET_MODE_HELPER_SCRIPT = preload("res://scripts/ui/menu_set_mode_helper.gd")
var set_mode_helper: RefCounted = null

# Compatibility backings for pre-_ready reads/writes.
var _compat_is_editor_test_mode: bool = false
var _compat_editor_test_pack_data: Dictionary = {}
var _compat_editor_test_level_index: int = 0
var _compat_editor_draft_pack_data: Dictionary = {}
var _compat_editor_draft_level_index: int = 0
var _compat_editor_draft_is_builtin_edit: bool = false
var _compat_set_current_index: int = 0
var _compat_set_level_ids: Array = []
var _compat_set_level_refs: Array[Dictionary] = []
var _compat_set_saved_score: int = 0
var _compat_set_saved_lives: int = 3
var _compat_set_saved_combo: int = 0
var _compat_set_saved_no_miss: int = 0
var _compat_set_saved_perfect: bool = true
var _compat_last_level_breakdown: Dictionary = {}
var _compat_last_level_time_seconds: float = 0.0
var _compat_last_level_score_raw: int = 0
var _compat_last_level_score_final: int = 0
var _compat_set_breakdown: Dictionary = {}
var _compat_set_total_time_seconds: float = 0.0
var _compat_set_score_before_bonus: int = 0
var _compat_set_perfect_bonus: int = 0

# Public compatibility API preserved on MenuController while state is helper-owned.
var is_editor_test_mode: bool:
	get:
		if editor_test_helper != null:
			return editor_test_helper.is_editor_test_mode
		return _compat_is_editor_test_mode
	set(value):
		_compat_is_editor_test_mode = value
		if editor_test_helper != null:
			editor_test_helper.is_editor_test_mode = value

var editor_test_pack_data: Dictionary:
	get:
		if editor_test_helper != null:
			return editor_test_helper.editor_test_pack_data
		return _compat_editor_test_pack_data
	set(value):
		_compat_editor_test_pack_data = value
		if editor_test_helper != null:
			editor_test_helper.editor_test_pack_data = value

var editor_test_level_index: int:
	get:
		if editor_test_helper != null:
			return editor_test_helper.editor_test_level_index
		return _compat_editor_test_level_index
	set(value):
		_compat_editor_test_level_index = value
		if editor_test_helper != null:
			editor_test_helper.editor_test_level_index = value

var editor_draft_pack_data: Dictionary:
	get:
		if editor_test_helper != null:
			return editor_test_helper.editor_draft_pack_data
		return _compat_editor_draft_pack_data
	set(value):
		_compat_editor_draft_pack_data = value
		if editor_test_helper != null:
			editor_test_helper.editor_draft_pack_data = value

var editor_draft_level_index: int:
	get:
		if editor_test_helper != null:
			return editor_test_helper.editor_draft_level_index
		return _compat_editor_draft_level_index
	set(value):
		_compat_editor_draft_level_index = value
		if editor_test_helper != null:
			editor_test_helper.editor_draft_level_index = value

var editor_draft_is_builtin_edit: bool:
	get:
		if editor_test_helper != null:
			return editor_test_helper.editor_draft_is_builtin_edit
		return _compat_editor_draft_is_builtin_edit
	set(value):
		_compat_editor_draft_is_builtin_edit = value
		if editor_test_helper != null:
			editor_test_helper.editor_draft_is_builtin_edit = value

var set_current_index: int:
	get:
		if set_mode_helper != null:
			return set_mode_helper.set_current_index
		return _compat_set_current_index
	set(value):
		_compat_set_current_index = value
		if set_mode_helper != null:
			set_mode_helper.set_current_index = value

var set_level_ids: Array:
	get:
		if set_mode_helper != null:
			return set_mode_helper.set_level_ids
		return _compat_set_level_ids
	set(value):
		_compat_set_level_ids = value
		if set_mode_helper != null:
			set_mode_helper.set_level_ids = value

var set_level_refs: Array[Dictionary]:
	get:
		if set_mode_helper != null:
			return set_mode_helper.set_level_refs
		return _compat_set_level_refs
	set(value):
		_compat_set_level_refs = value
		if set_mode_helper != null:
			set_mode_helper.set_level_refs = value

var set_saved_score: int:
	get:
		if set_mode_helper != null:
			return set_mode_helper.set_saved_score
		return _compat_set_saved_score
	set(value):
		_compat_set_saved_score = value
		if set_mode_helper != null:
			set_mode_helper.set_saved_score = value

var set_saved_lives: int:
	get:
		if set_mode_helper != null:
			return set_mode_helper.set_saved_lives
		return _compat_set_saved_lives
	set(value):
		_compat_set_saved_lives = value
		if set_mode_helper != null:
			set_mode_helper.set_saved_lives = value

var set_saved_combo: int:
	get:
		if set_mode_helper != null:
			return set_mode_helper.set_saved_combo
		return _compat_set_saved_combo
	set(value):
		_compat_set_saved_combo = value
		if set_mode_helper != null:
			set_mode_helper.set_saved_combo = value

var set_saved_no_miss: int:
	get:
		if set_mode_helper != null:
			return set_mode_helper.set_saved_no_miss
		return _compat_set_saved_no_miss
	set(value):
		_compat_set_saved_no_miss = value
		if set_mode_helper != null:
			set_mode_helper.set_saved_no_miss = value

var set_saved_perfect: bool:
	get:
		if set_mode_helper != null:
			return set_mode_helper.set_saved_perfect
		return _compat_set_saved_perfect
	set(value):
		_compat_set_saved_perfect = value
		if set_mode_helper != null:
			set_mode_helper.set_saved_perfect = value

var last_level_breakdown: Dictionary:
	get:
		if score_breakdown_helper != null:
			return score_breakdown_helper.last_level_breakdown
		return _compat_last_level_breakdown
	set(value):
		_compat_last_level_breakdown = value
		if score_breakdown_helper != null:
			score_breakdown_helper.last_level_breakdown = value

var last_level_time_seconds: float:
	get:
		if score_breakdown_helper != null:
			return score_breakdown_helper.last_level_time_seconds
		return _compat_last_level_time_seconds
	set(value):
		_compat_last_level_time_seconds = value
		if score_breakdown_helper != null:
			score_breakdown_helper.last_level_time_seconds = value

var last_level_score_raw: int:
	get:
		if score_breakdown_helper != null:
			return score_breakdown_helper.last_level_score_raw
		return _compat_last_level_score_raw
	set(value):
		_compat_last_level_score_raw = value
		if score_breakdown_helper != null:
			score_breakdown_helper.last_level_score_raw = value

var last_level_score_final: int:
	get:
		if score_breakdown_helper != null:
			return score_breakdown_helper.last_level_score_final
		return _compat_last_level_score_final
	set(value):
		_compat_last_level_score_final = value
		if score_breakdown_helper != null:
			score_breakdown_helper.last_level_score_final = value

var set_breakdown: Dictionary:
	get:
		if score_breakdown_helper != null:
			return score_breakdown_helper.set_breakdown
		return _compat_set_breakdown
	set(value):
		_compat_set_breakdown = value
		if score_breakdown_helper != null:
			score_breakdown_helper.set_breakdown = value

var set_total_time_seconds: float:
	get:
		if score_breakdown_helper != null:
			return score_breakdown_helper.set_total_time_seconds
		return _compat_set_total_time_seconds
	set(value):
		_compat_set_total_time_seconds = value
		if score_breakdown_helper != null:
			score_breakdown_helper.set_total_time_seconds = value

var set_score_before_bonus: int:
	get:
		if score_breakdown_helper != null:
			return score_breakdown_helper.set_score_before_bonus
		return _compat_set_score_before_bonus
	set(value):
		_compat_set_score_before_bonus = value
		if score_breakdown_helper != null:
			score_breakdown_helper.set_score_before_bonus = value

var set_perfect_bonus: int:
	get:
		if score_breakdown_helper != null:
			return score_breakdown_helper.set_perfect_bonus
		return _compat_set_perfect_bonus
	set(value):
		_compat_set_perfect_bonus = value
		if score_breakdown_helper != null:
			score_breakdown_helper.set_perfect_bonus = value

# Signals
signal scene_changed(scene_path: String)

func _ready():
	editor_test_helper = MENU_EDITOR_TEST_HELPER_SCRIPT.new()
	score_breakdown_helper = MENU_SCORE_BREAKDOWN_HELPER_SCRIPT.new()
	set_mode_helper = MENU_SET_MODE_HELPER_SCRIPT.new()
	_sync_helper_state_from_compat()
	"""Initialize MenuController"""
	get_tree().set_auto_accept_quit(false)
	if SaveManager and SaveManager.has_method("get_last_challenge_mode"):
		current_challenge_mode = normalize_challenge_mode(str(SaveManager.get_last_challenge_mode()))

func _sync_helper_state_from_compat() -> void:
	# Preserve parent API behavior for any values assigned before _ready.
	is_editor_test_mode = _compat_is_editor_test_mode
	editor_test_pack_data = _compat_editor_test_pack_data
	editor_test_level_index = _compat_editor_test_level_index
	editor_draft_pack_data = _compat_editor_draft_pack_data
	editor_draft_level_index = _compat_editor_draft_level_index
	editor_draft_is_builtin_edit = _compat_editor_draft_is_builtin_edit
	set_current_index = _compat_set_current_index
	set_level_ids = _compat_set_level_ids
	set_level_refs = _compat_set_level_refs
	set_saved_score = _compat_set_saved_score
	set_saved_lives = _compat_set_saved_lives
	set_saved_combo = _compat_set_saved_combo
	set_saved_no_miss = _compat_set_saved_no_miss
	set_saved_perfect = _compat_set_saved_perfect
	last_level_breakdown = _compat_last_level_breakdown
	last_level_time_seconds = _compat_last_level_time_seconds
	last_level_score_raw = _compat_last_level_score_raw
	last_level_score_final = _compat_last_level_score_final
	set_breakdown = _compat_set_breakdown
	set_total_time_seconds = _compat_set_total_time_seconds
	set_score_before_bonus = _compat_set_score_before_bonus
	set_perfect_bonus = _compat_set_perfect_bonus

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_game()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("take_screenshot"):
		_request_screenshot()
		get_viewport().set_input_as_handled()

func show_main_menu() -> void:
	"""Load and show the main menu"""
	is_in_gameplay = false
	is_survival_mode = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Unlock difficulty for selection
	DifficultyManager.unlock_difficulty()

	# Change to main menu scene
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
	scene_changed.emit(MAIN_MENU_SCENE)

func _request_screenshot() -> void:
	if _screenshot_capture_in_progress:
		return
	_screenshot_capture_in_progress = true
	_capture_screenshot()

func _capture_screenshot() -> void:
	await RenderingServer.frame_post_draw
	var viewport_texture := get_viewport().get_texture()
	if viewport_texture == null:
		_screenshot_capture_in_progress = false
		push_warning("MenuController: screenshot skipped because viewport texture was unavailable")
		return

	var image := viewport_texture.get_image()
	if image == null or image.is_empty():
		_screenshot_capture_in_progress = false
		push_warning("MenuController: screenshot skipped because viewport image was empty")
		return

	var file_name := _build_screenshot_file_name()
	var saved_path := _save_screenshot_image(image, SCREENSHOT_RES_DIR, file_name)
	if saved_path.is_empty():
		saved_path = _save_screenshot_image(image, SCREENSHOT_USER_DIR, file_name)

	_screenshot_capture_in_progress = false
	if saved_path.is_empty():
		push_error("MenuController: failed to save screenshot")
		return

	print("Screenshot saved to: %s" % saved_path)

func _build_screenshot_file_name() -> String:
	var timestamp := Time.get_datetime_dict_from_system()
	return "Screenshot_%04d%02d%02d_%02d%02d%02d.png" % [
		int(timestamp.get("year", 0)),
		int(timestamp.get("month", 0)),
		int(timestamp.get("day", 0)),
		int(timestamp.get("hour", 0)),
		int(timestamp.get("minute", 0)),
		int(timestamp.get("second", 0))
	]

func _save_screenshot_image(image: Image, dir_path: String, file_name: String) -> String:
	var global_dir := ProjectSettings.globalize_path(dir_path)
	if not DirAccess.dir_exists_absolute(global_dir):
		var make_dir_error := DirAccess.make_dir_recursive_absolute(global_dir)
		if make_dir_error != OK:
			return ""

	var global_path := global_dir.path_join(file_name)
	if image.save_png(global_path) != OK:
		return ""
	return global_path

func show_level_select() -> void:
	"""Load and show the level selection screen"""
	is_in_gameplay = false
	is_survival_mode = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Difficulty should remain unlocked in menus
	DifficultyManager.unlock_difficulty()

	get_tree().change_scene_to_file(LEVEL_SELECT_SCENE)
	scene_changed.emit(LEVEL_SELECT_SCENE)

func show_set_select() -> void:
	"""Load and show the set selection screen"""
	is_in_gameplay = false
	is_survival_mode = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Reset set mode state when entering set select
	current_play_mode = PlayMode.INDIVIDUAL
	current_set_id = -1
	current_set_pack_id = ""
	current_browse_pack_id = ""
	set_current_index = 0
	set_level_ids.clear()
	set_level_refs.clear()

	# Difficulty should remain unlocked in menus
	DifficultyManager.unlock_difficulty()

	get_tree().change_scene_to_file(SET_SELECT_SCENE)
	scene_changed.emit(SET_SELECT_SCENE)

func show_stats() -> void:
	"""Load and show the stats screen"""
	is_in_gameplay = false
	is_survival_mode = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Difficulty should remain unlocked in menus
	DifficultyManager.unlock_difficulty()

	get_tree().change_scene_to_file(STATS_SCENE)
	scene_changed.emit(STATS_SCENE)

func show_high_scores() -> void:
	"""Load and show the high scores screen"""
	is_in_gameplay = false
	is_survival_mode = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	DifficultyManager.unlock_difficulty()

	get_tree().change_scene_to_file(HIGH_SCORES_SCENE)
	scene_changed.emit(HIGH_SCORES_SCENE)

func show_settings(from_pause: bool = false) -> void:
	"""Load and show the settings screen"""
	is_in_gameplay = false
	is_survival_mode = false
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
	is_survival_mode = false
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
	is_survival_mode = false
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
	is_survival_mode = false
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
	editor_draft_is_builtin_edit = false
	if editor_return_target == EditorReturnTarget.MAIN_MENU:
		show_main_menu()
		return
	show_set_select()

func start_editor_test(pack_data: Dictionary, level_index: int, draft_is_builtin_edit: bool = false) -> void:
	editor_test_helper.start_editor_test(self, pack_data, level_index, draft_is_builtin_edit)


func has_editor_test_data() -> bool:
	return editor_test_helper.has_editor_test_data()


func get_editor_test_level_data() -> Dictionary:
	return editor_test_helper.get_editor_test_level_data()


func get_editor_test_level_name() -> String:
	return editor_test_helper.get_editor_test_level_name()


func get_editor_test_level_description() -> String:
	return editor_test_helper.get_editor_test_level_description()


func get_editor_draft_pack() -> Dictionary:
	return editor_test_helper.get_editor_draft_pack()


func get_editor_draft_level_index() -> int:
	return editor_test_helper.get_editor_draft_level_index()


func get_editor_draft_is_builtin_edit() -> bool:
	return editor_test_helper.get_editor_draft_is_builtin_edit()


func clear_editor_test_state() -> void:
	editor_test_helper.clear_editor_test_state()


func return_to_editor_from_test() -> void:
	editor_test_helper.return_to_editor_from_test(self)


func start_level(level_id: int) -> void:
	"""Start playing a specific level (individual mode by default)"""
	var ref: Dictionary = PackLoader.get_legacy_level_ref(level_id)
	if ref.is_empty():
		push_error("Level does not exist: ", level_id)
		return

	start_level_ref(str(ref.get("pack_id", "")), int(ref.get("level_index", -1)))

func start_level_ref(pack_id: String, level_index: int) -> void:
	"""Start playing a specific level using pack-native addressing."""
	var level_key = PackLoader.get_level_key(pack_id, level_index)
	if not SaveManager.is_level_key_unlocked(level_key):
		return

	var level_data = PackLoader.get_level_data(pack_id, level_index)
	if level_data.is_empty():
		push_error("Level does not exist: %s:%d" % [pack_id, level_index])
		return

	current_pack_id = pack_id
	current_level_index = level_index
	is_survival_mode = false
	var legacy_level_id = PackLoader.get_legacy_level_id(pack_id, level_index)
	current_level_id = legacy_level_id if legacy_level_id != -1 else 0
	is_in_gameplay = true
	var mode_name = "set" if current_play_mode == PlayMode.SET else "individual"
	var score_to_save = set_saved_score if current_play_mode == PlayMode.SET else 0
	SaveManager.set_last_played_ref(pack_id, level_index, mode_name, current_set_pack_id, true, current_challenge_mode, score_to_save)

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
	set_mode_helper.start_set(self, set_id)

func start_pack(pack_id: String) -> void:
	"""Start playing a pack from the beginning (supports built-in and user packs)."""
	set_mode_helper.start_pack(self, pack_id)

func continue_set_from_level(level_id: int) -> void:
	"""Resume set mode after game over continue (resets score/lives, continues from current level)"""
	set_mode_helper.continue_set_from_level(self, level_id)

func continue_set_from_ref(pack_id: String, level_index: int) -> void:
	"""Resume set mode from pack-native level reference."""
	set_mode_helper.continue_set_from_ref(self, pack_id, level_index)

func start_survival() -> void:
	"""Start a standalone survival run."""
	current_play_mode = PlayMode.INDIVIDUAL
	current_set_id = -1
	current_set_pack_id = ""
	current_browse_pack_id = ""
	set_current_index = 0
	set_level_ids.clear()
	set_level_refs.clear()
	_reset_set_breakdown()
	time_attack_elapsed_base_seconds = 0
	time_attack_final_seconds = 0

	is_survival_mode = true
	survival_wave_reached = 1
	current_score = 0
	current_pack_id = ""
	current_level_index = 0
	current_level_id = 0
	is_in_gameplay = true
	was_perfect_clear = false
	was_new_personal_best = false
	was_new_machine_best = false
	if SaveManager and SaveManager.has_method("set_last_played_survival"):
		SaveManager.set_last_played_survival()
	else:
		SaveManager.set_last_played_in_progress(false)

	SaveManager.increment_stat("total_games_played")
	DifficultyManager.lock_difficulty()
	PowerUpManager.clear_all_effects()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file(GAMEPLAY_SCENE)
	scene_changed.emit(GAMEPLAY_SCENE)

func restart_current_level() -> void:
	"""Restart the current level"""
	if is_editor_test_mode:
		start_editor_test(editor_draft_pack_data, editor_draft_level_index, editor_draft_is_builtin_edit)
		return
	start_level_ref(current_pack_id, current_level_index)

func show_game_over(final_score: int) -> void:
	"""Show game over screen with final score"""
	if is_survival_mode:
		show_survival_over(final_score, survival_wave_reached)
		return
	current_score = final_score
	is_in_gameplay = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if not is_editor_test_mode:
		SaveManager.set_last_played_in_progress(false)
	if current_play_mode == PlayMode.SET and get_challenge_mode() == CHALLENGE_MODE_TIME_ATTACK:
		time_attack_elapsed_base_seconds = 0
		time_attack_final_seconds = 0

	# Unlock difficulty when leaving gameplay
	DifficultyManager.unlock_difficulty()

	# Try to update high score
	if not is_editor_test_mode:
		SaveManager.update_level_key_high_score(get_current_level_key(), final_score)

	get_tree().change_scene_to_file(GAME_OVER_SCENE)
	scene_changed.emit(GAME_OVER_SCENE)

func show_survival_over(final_score: int, wave: int) -> void:
	"""Show game over screen for Survival mode and persist the run."""
	current_score = final_score
	survival_wave_reached = max(1, wave)
	is_in_gameplay = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	DifficultyManager.unlock_difficulty()
	if SaveManager:
		if SaveManager.has_method("set_last_played_survival"):
			SaveManager.set_last_played_survival()
		else:
			SaveManager.set_last_played_in_progress(false)
		if not is_editor_test_mode and SaveManager.has_method("save_survival_run"):
			SaveManager.save_survival_run(final_score, survival_wave_reached)

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
	if current_play_mode == PlayMode.SET and get_challenge_mode() == CHALLENGE_MODE_TIME_ATTACK and game_manager and game_manager.has_method("stop_time_attack_timer"):
		time_attack_elapsed_base_seconds = int(game_manager.stop_time_attack_timer())
		if set_current_index >= (set_level_refs.size() - 1):
			time_attack_final_seconds = time_attack_elapsed_base_seconds

	if is_editor_test_mode:
		get_tree().change_scene_to_file(LEVEL_COMPLETE_SCENE)
		scene_changed.emit(LEVEL_COMPLETE_SCENE)
		return

	# Determine high score status BEFORE saving
	var level_key = get_current_level_key()
	var prev_pb = SaveManager.get_level_key_high_score(level_key)
	var prev_global = SaveManager.get_global_high_score(level_key)
	
	was_new_personal_best = (current_score > prev_pb) or (prev_pb == 0 and current_score > 0)
	was_new_machine_best = (current_score > prev_global) or (prev_global == 0 and current_score > 0)

	# Save game state for set mode (before scene changes)
	if current_play_mode == PlayMode.SET and game_manager:
		set_saved_score = current_score
		set_saved_lives = game_manager.lives
		set_saved_perfect = game_manager.is_perfect_clear
		set_saved_combo = game_manager.combo
		set_saved_no_miss = game_manager.no_miss_hits

	# Mark level as completed
	SaveManager.mark_level_key_completed(get_current_level_key())

	# Update high score (with perfect clear bonus if applicable)
	SaveManager.update_level_key_high_score(get_current_level_key(), current_score)
	var earned_stars = SaveManager.calculate_level_stars(get_current_level_key(), current_score, was_perfect_clear)
	SaveManager.update_level_key_stars(get_current_level_key(), earned_stars)

	# Track level completion statistic
	SaveManager.increment_stat("total_levels_completed")

	# Track individual mode completion if applicable
	if current_play_mode == PlayMode.INDIVIDUAL:
		SaveManager.increment_stat("total_individual_levels_completed")

	# Check for achievements
	SaveManager.check_achievements()

	# Unlock next level (works in both modes)
	var next_level_ref = _get_next_level_ref()
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
		var next_level_ref = _get_next_level_ref()
		if next_level_ref.is_empty():
			show_level_select()
			return

		# Start next level
		start_level_ref(str(next_level_ref.get("pack_id", "")), int(next_level_ref.get("level_index", -1)))

func show_set_complete(final_score: int) -> void:
	"""Show set complete screen with cumulative score and bonuses"""
	set_mode_helper.show_set_complete(self, final_score)

func resume_last_level() -> void:
	"""Resume the last played level if it was left in progress"""
	var last_played = SaveManager.get_last_played()
	if not last_played.get("in_progress", false):
		return
	if str(last_played.get("mode", "")) == LAST_PLAYED_MODE_SURVIVAL:
		return
	var saved_challenge = normalize_challenge_mode(str(last_played.get("challenge_mode", CHALLENGE_MODE_NORMAL)))
	if saved_challenge == CHALLENGE_MODE_TIME_ATTACK:
		return
	var pack_id = str(last_played.get("pack_id", ""))
	var level_index = int(last_played.get("level_index", -1))
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
	var set_pack_id = str(last_played.get("set_pack_id", ""))
	var challenge_mode = normalize_challenge_mode(str(last_played.get("challenge_mode", "normal")))

	if mode == "set" and not set_pack_id.is_empty():
		current_play_mode = PlayMode.SET
		current_challenge_mode = challenge_mode
		current_set_pack_id = set_pack_id
		current_set_id = _find_set_id_by_pack_id(set_pack_id)
		set_level_ids = PackLoader.get_legacy_set_level_ids(current_set_id) if current_set_id != -1 else []
		set_level_refs.clear()
		var level_count = PackLoader.get_level_count(set_pack_id)
		for idx in range(level_count):
			set_level_refs.append({"pack_id": set_pack_id, "level_index": idx})
		set_current_index = level_index
		set_saved_score = int(last_played.get("set_score", 0))
		set_saved_lives = _get_starting_lives_for_challenge()
		set_saved_combo = 0
		set_saved_no_miss = 0
		set_saved_perfect = true
	else:
		current_play_mode = PlayMode.INDIVIDUAL
		current_set_id = -1
		current_set_pack_id = ""
		set_current_index = 0
		set_level_ids.clear()
		set_level_refs.clear()

	start_level_ref(pack_id, level_index)

func quit_game() -> void:
	"""Quit the game application"""
	if _quit_requested:
		return
	_quit_requested = true
	if AudioManager != null and AudioManager.has_method("prepare_for_quit"):
		await AudioManager.prepare_for_quit()
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

func get_survival_wave_reached() -> int:
	return survival_wave_reached

func get_time_attack_elapsed_base_seconds() -> int:
	return time_attack_elapsed_base_seconds

func get_was_perfect_clear() -> bool:
	"""Check if the last completed level was a perfect clear"""
	return was_perfect_clear

func get_last_level_breakdown() -> Dictionary:
	return score_breakdown_helper.get_last_level_breakdown()


func get_last_level_time_seconds() -> float:
	return score_breakdown_helper.get_last_level_time_seconds()


func get_last_level_score_raw() -> int:
	return score_breakdown_helper.get_last_level_score_raw()


func get_last_level_score_final() -> int:
	return score_breakdown_helper.get_last_level_score_final()


func get_set_breakdown() -> Dictionary:
	return score_breakdown_helper.get_set_breakdown()


func get_set_total_time_seconds() -> float:
	return score_breakdown_helper.get_set_total_time_seconds()


func get_set_score_before_bonus() -> int:
	return score_breakdown_helper.get_set_score_before_bonus()


func get_set_perfect_bonus() -> int:
	return score_breakdown_helper.get_set_perfect_bonus()


func _create_empty_breakdown() -> Dictionary:
	return score_breakdown_helper._create_empty_breakdown()


func _sum_breakdown(breakdown: Dictionary) -> int:
	return score_breakdown_helper._sum_breakdown(breakdown)


func _capture_level_breakdown(game_manager: Node) -> void:
	score_breakdown_helper._capture_level_breakdown(self, game_manager)


func _accumulate_set_breakdown(level_breakdown: Dictionary, level_time: float) -> void:
	score_breakdown_helper._accumulate_set_breakdown(level_breakdown, level_time)


func _reset_set_breakdown() -> void:
	score_breakdown_helper._reset_set_breakdown()


func _get_next_level_ref() -> Dictionary:
	return set_mode_helper._get_next_level_ref(self)

func _find_set_id_by_pack_id(pack_id: String) -> int:
	return set_mode_helper._find_set_id_by_pack_id(pack_id)

func set_challenge_mode(mode: String) -> void:
	current_challenge_mode = normalize_challenge_mode(mode)
	if SaveManager and SaveManager.has_method("set_last_challenge_mode"):
		SaveManager.set_last_challenge_mode(current_challenge_mode)

func get_challenge_mode() -> String:
	if current_play_mode != PlayMode.SET:
		return "normal"
	return normalize_challenge_mode(current_challenge_mode)

func normalize_challenge_mode(mode: String) -> String:
	var normalized = mode.strip_edges().to_lower()
	if normalized == CHALLENGE_MODE_IRON_BALL:
		return CHALLENGE_MODE_IRON_BALL
	if normalized == CHALLENGE_MODE_ONE_LIFE:
		return CHALLENGE_MODE_ONE_LIFE
	if normalized == CHALLENGE_MODE_TIME_ATTACK:
		return CHALLENGE_MODE_TIME_ATTACK
	return CHALLENGE_MODE_NORMAL

func _get_starting_lives_for_challenge() -> int:
	return set_mode_helper._get_starting_lives_for_challenge(self)

func is_gameplay_active() -> bool:
	"""Check if we're currently in a gameplay scene"""
	return is_in_gameplay
