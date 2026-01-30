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

# Play mode enum
enum PlayMode { INDIVIDUAL, SET }

# Current state
var current_level_id: int = 1
var current_score: int = 0
var is_in_gameplay: bool = false
var was_perfect_clear: bool = false

# Set mode state
var current_play_mode: PlayMode = PlayMode.INDIVIDUAL
var current_set_id: int = -1
var set_current_index: int = 0
var set_level_ids: Array = []

# Set mode saved game state (persists between level transitions)
var set_saved_score: int = 0
var set_saved_lives: int = 3
var set_saved_combo: int = 0
var set_saved_no_miss: int = 0
var set_saved_perfect: bool = true

# Signals
signal scene_changed(scene_path: String)

func _ready():
	"""Initialize MenuController"""
	pass

func show_main_menu() -> void:
	"""Load and show the main menu"""
	is_in_gameplay = false

	# Unlock difficulty for selection
	DifficultyManager.unlock_difficulty()

	# Change to main menu scene
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
	scene_changed.emit(MAIN_MENU_SCENE)

func show_level_select() -> void:
	"""Load and show the level selection screen"""
	is_in_gameplay = false

	# Difficulty should remain unlocked in menus
	DifficultyManager.unlock_difficulty()

	get_tree().change_scene_to_file(LEVEL_SELECT_SCENE)
	scene_changed.emit(LEVEL_SELECT_SCENE)

func show_set_select() -> void:
	"""Load and show the set selection screen"""
	is_in_gameplay = false

	# Reset set mode state when entering set select
	current_play_mode = PlayMode.INDIVIDUAL
	current_set_id = -1
	set_current_index = 0
	set_level_ids = []

	# Difficulty should remain unlocked in menus
	DifficultyManager.unlock_difficulty()

	get_tree().change_scene_to_file(SET_SELECT_SCENE)
	scene_changed.emit(SET_SELECT_SCENE)

func show_stats() -> void:
	"""Load and show the stats screen"""
	is_in_gameplay = false

	# Difficulty should remain unlocked in menus
	DifficultyManager.unlock_difficulty()

	get_tree().change_scene_to_file(STATS_SCENE)
	scene_changed.emit(STATS_SCENE)

func show_settings() -> void:
	"""Load and show the settings screen"""
	is_in_gameplay = false

	# Difficulty should remain unlocked in menus
	DifficultyManager.unlock_difficulty()

	get_tree().change_scene_to_file(SETTINGS_SCENE)
	scene_changed.emit(SETTINGS_SCENE)

func start_level(level_id: int) -> void:
	"""Start playing a specific level (individual mode by default)"""
	if not SaveManager.is_level_unlocked(level_id):
		return

	if not LevelLoader.level_exists(level_id):
		push_error("Level does not exist: ", level_id)
		return

	current_level_id = level_id
	is_in_gameplay = true

	# Track gameplay sessions (counts each level start)
	SaveManager.increment_stat("total_games_played")

	# If not already in set mode, switch to individual mode
	if current_play_mode != PlayMode.SET:
		current_play_mode = PlayMode.INDIVIDUAL

	# Lock difficulty during gameplay
	DifficultyManager.lock_difficulty()

	# Load gameplay scene
	get_tree().change_scene_to_file(GAMEPLAY_SCENE)
	scene_changed.emit(GAMEPLAY_SCENE)

func start_set(set_id: int) -> void:
	"""Start playing a set from the beginning"""
	if not SetLoader.set_exists(set_id):
		push_error("Set does not exist: ", set_id)
		return

	# Switch to set mode
	current_play_mode = PlayMode.SET
	current_set_id = set_id
	set_level_ids = SetLoader.get_set_level_ids(set_id)
	set_current_index = 0

	# Reset saved state for new set
	set_saved_score = 0
	set_saved_lives = 3
	set_saved_combo = 0
	set_saved_no_miss = 0
	set_saved_perfect = true

	# Start first level in the set
	if set_level_ids.size() > 0:
		start_level(set_level_ids[0])
	else:
		push_error("Set ", set_id, " has no levels!")

func continue_set_from_level(level_id: int) -> void:
	"""Resume set mode after game over continue (resets score/lives, continues from current level)"""
	# Find the index of this level in the set
	var level_index = set_level_ids.find(level_id)
	if level_index == -1:
		push_error("Level ", level_id, " not found in current set")
		return

	set_current_index = level_index

	# Mark that we used a continue (prevents perfect set bonus)
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		game_manager.had_continue = true

	# Start the level (score and lives will be reset by GameManager)
	start_level(level_id)

func restart_current_level() -> void:
	"""Restart the current level"""
	print("MenuController: Restarting level ", current_level_id)
	start_level(current_level_id)

func show_game_over(final_score: int) -> void:
	"""Show game over screen with final score"""
	current_score = final_score
	is_in_gameplay = false

	# Unlock difficulty when leaving gameplay
	DifficultyManager.unlock_difficulty()

	# Try to update high score
	SaveManager.update_high_score(current_level_id, final_score)

	get_tree().change_scene_to_file(GAME_OVER_SCENE)
	scene_changed.emit(GAME_OVER_SCENE)

func show_level_complete(final_score: int) -> void:
	"""Show level complete screen, unlock next level, and save progress"""
	current_score = final_score
	is_in_gameplay = false

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

	# Save game state for set mode (before scene changes)
	if current_play_mode == PlayMode.SET and game_manager:
		set_saved_score = current_score
		set_saved_lives = game_manager.lives
		set_saved_combo = game_manager.combo
		set_saved_no_miss = game_manager.no_miss_hits
		set_saved_perfect = game_manager.is_perfect_clear

	# Mark level as completed
	SaveManager.mark_level_completed(current_level_id)

	# Update high score (with perfect clear bonus if applicable)
	SaveManager.update_high_score(current_level_id, current_score)

	# Track level completion statistic
	SaveManager.increment_stat("total_levels_completed")

	# Track individual mode completion if applicable
	if current_play_mode == PlayMode.INDIVIDUAL:
		SaveManager.increment_stat("total_individual_levels_completed")

	# Check for achievements
	SaveManager.check_achievements()

	# Unlock next level (works in both modes)
	var next_level_id = LevelLoader.get_next_level_id(current_level_id)
	if next_level_id != -1:
		SaveManager.unlock_level(next_level_id)

	get_tree().change_scene_to_file(LEVEL_COMPLETE_SCENE)
	scene_changed.emit(LEVEL_COMPLETE_SCENE)

func continue_to_next_level() -> void:
	"""Load the next level after completion (handles both individual and set mode)"""
	if current_play_mode == PlayMode.SET:
		# In set mode, advance to next level in set
		set_current_index += 1
		if set_current_index < set_level_ids.size():
			# Continue to next level in set
			start_level(set_level_ids[set_current_index])
		else:
			# Completed all levels in set
			show_set_complete(current_score)
	else:
		# In individual mode, use normal next level logic
		var next_level_id = LevelLoader.get_next_level_id(current_level_id)

		if next_level_id == -1:
			show_level_select()
			return

		# Start next level
		start_level(next_level_id)

func show_set_complete(final_score: int) -> void:
	"""Show set complete screen with cumulative score and bonuses"""
	# Check for perfect set clear (3x bonus if all lives intact and no continues used)
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager and game_manager.lives == 3 and game_manager.is_perfect_clear and not game_manager.had_continue:
		current_score = final_score * 3
	else:
		current_score = final_score

	# Update set high score
	SaveManager.update_set_high_score(current_set_id, current_score)

	# Mark set as completed
	SaveManager.mark_set_completed(current_set_id)

	# Track set completion statistic
	SaveManager.increment_stat("total_set_runs_completed")

	# Check for achievements
	SaveManager.check_achievements()

	is_in_gameplay = false
	get_tree().change_scene_to_file(SET_COMPLETE_SCENE)
	scene_changed.emit(SET_COMPLETE_SCENE)

func quit_game() -> void:
	"""Quit the game application"""
	get_tree().quit()

func get_current_level_id() -> int:
	"""Get the ID of the currently selected/playing level"""
	return current_level_id

func get_current_score() -> int:
	"""Get the current/final score"""
	return current_score

func get_was_perfect_clear() -> bool:
	"""Check if the last completed level was a perfect clear"""
	return was_perfect_clear

func is_gameplay_active() -> bool:
	"""Check if we're currently in a gameplay scene"""
	return is_in_gameplay
