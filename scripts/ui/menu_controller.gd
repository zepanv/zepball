extends Node

## MenuController - Autoload singleton for managing scene transitions and game flow
## Handles navigation between menus and gameplay scenes

# Scene paths
const MAIN_MENU_SCENE = "res://scenes/ui/main_menu.tscn"
const LEVEL_SELECT_SCENE = "res://scenes/ui/level_select.tscn"
const GAMEPLAY_SCENE = "res://scenes/main/main.tscn"
const GAME_OVER_SCENE = "res://scenes/ui/game_over.tscn"
const LEVEL_COMPLETE_SCENE = "res://scenes/ui/level_complete.tscn"
const STATS_SCENE = "res://scenes/ui/stats.tscn"
const SETTINGS_SCENE = "res://scenes/ui/settings.tscn"

# Current state
var current_level_id: int = 1
var current_score: int = 0
var is_in_gameplay: bool = false
var was_perfect_clear: bool = false

# Signals
signal scene_changed(scene_path: String)

func _ready():
	"""Initialize MenuController"""
	print("MenuController ready")

func show_main_menu() -> void:
	"""Load and show the main menu"""
	print("MenuController: Showing main menu")
	is_in_gameplay = false

	# Unlock difficulty for selection
	DifficultyManager.unlock_difficulty()

	# Change to main menu scene
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
	scene_changed.emit(MAIN_MENU_SCENE)

func show_level_select() -> void:
	"""Load and show the level selection screen"""
	print("MenuController: Showing level select")
	is_in_gameplay = false

	# Difficulty should remain unlocked in menus
	DifficultyManager.unlock_difficulty()

	get_tree().change_scene_to_file(LEVEL_SELECT_SCENE)
	scene_changed.emit(LEVEL_SELECT_SCENE)

func show_stats() -> void:
	"""Load and show the stats screen"""
	print("MenuController: Showing stats")
	is_in_gameplay = false

	# Difficulty should remain unlocked in menus
	DifficultyManager.unlock_difficulty()

	get_tree().change_scene_to_file(STATS_SCENE)
	scene_changed.emit(STATS_SCENE)

func show_settings() -> void:
	"""Load and show the settings screen"""
	print("MenuController: Showing settings")
	is_in_gameplay = false

	# Difficulty should remain unlocked in menus
	DifficultyManager.unlock_difficulty()

	get_tree().change_scene_to_file(SETTINGS_SCENE)
	scene_changed.emit(SETTINGS_SCENE)

func start_level(level_id: int) -> void:
	"""Start playing a specific level"""
	if not SaveManager.is_level_unlocked(level_id):
		push_warning("Attempted to start locked level: ", level_id)
		return

	if not LevelLoader.level_exists(level_id):
		push_error("Level does not exist: ", level_id)
		return

	print("MenuController: Starting level ", level_id)
	current_level_id = level_id
	is_in_gameplay = true

	# Lock difficulty during gameplay
	DifficultyManager.lock_difficulty()

	# Load gameplay scene
	get_tree().change_scene_to_file(GAMEPLAY_SCENE)
	scene_changed.emit(GAMEPLAY_SCENE)

func restart_current_level() -> void:
	"""Restart the current level"""
	print("MenuController: Restarting level ", current_level_id)
	start_level(current_level_id)

func show_game_over(final_score: int) -> void:
	"""Show game over screen with final score"""
	print("MenuController: Game over - Score: ", final_score)
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
	print("MenuController: Level ", current_level_id, " complete - Score: ", final_score)
	current_score = final_score
	is_in_gameplay = false

	# Unlock difficulty when leaving gameplay
	DifficultyManager.unlock_difficulty()

	# Check for perfect clear bonus (2x score if no lives lost)
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	was_perfect_clear = false
	if game_manager and game_manager.check_perfect_clear():
		print("PERFECT CLEAR! 2x Score Bonus!")
		current_score = final_score * 2
		was_perfect_clear = true
		SaveManager.increment_stat("perfect_clears")
	else:
		current_score = final_score

	# Mark level as completed
	SaveManager.mark_level_completed(current_level_id)

	# Update high score (with perfect clear bonus if applicable)
	var is_new_high_score = SaveManager.update_high_score(current_level_id, current_score)
	if is_new_high_score:
		print("NEW HIGH SCORE!")

	# Track level completion statistic
	SaveManager.increment_stat("total_levels_completed")

	# Check for achievements
	SaveManager.check_achievements()

	# Unlock next level
	var next_level_id = LevelLoader.get_next_level_id(current_level_id)
	if next_level_id != -1:
		SaveManager.unlock_level(next_level_id)
		print("Unlocked level ", next_level_id)
	else:
		print("All levels completed!")

	get_tree().change_scene_to_file(LEVEL_COMPLETE_SCENE)
	scene_changed.emit(LEVEL_COMPLETE_SCENE)

func continue_to_next_level() -> void:
	"""Load the next level after completion"""
	var next_level_id = LevelLoader.get_next_level_id(current_level_id)

	if next_level_id == -1:
		print("No more levels - returning to level select")
		show_level_select()
		return

	# Start next level
	start_level(next_level_id)

func quit_game() -> void:
	"""Quit the game application"""
	print("MenuController: Quitting game")
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
