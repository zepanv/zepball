extends Control

## Main Menu - Entry point for the game
## Allows player to start game, select difficulty, and quit

@onready var current_difficulty_label = $VBoxContainer/CurrentDifficultyLabel
@onready var easy_button = $VBoxContainer/DifficultyButtons/EasyButton
@onready var normal_button = $VBoxContainer/DifficultyButtons/NormalButton
@onready var hard_button = $VBoxContainer/DifficultyButtons/HardButton
@onready var return_button = $VBoxContainer/ReturnButton

func _ready():
	"""Initialize main menu"""
	# Unlock difficulty selection
	DifficultyManager.unlock_difficulty()

	# Load saved difficulty preference
	var saved_difficulty = SaveManager.get_saved_difficulty()
	apply_saved_difficulty(saved_difficulty)

	# Update UI to show current difficulty
	update_difficulty_display()

	# Connect difficulty change signal
	DifficultyManager.difficulty_changed.connect(_on_difficulty_changed)

	_update_return_button()

func apply_saved_difficulty(difficulty_name: String):
	"""Apply the saved difficulty setting"""
	match difficulty_name:
		"Easy":
			DifficultyManager.set_difficulty(DifficultyManager.Difficulty.EASY)
		"Normal":
			DifficultyManager.set_difficulty(DifficultyManager.Difficulty.NORMAL)
		"Hard":
			DifficultyManager.set_difficulty(DifficultyManager.Difficulty.HARD)
		_:
			# Default to Normal if unknown
			DifficultyManager.set_difficulty(DifficultyManager.Difficulty.NORMAL)

func update_difficulty_display():
	"""Update the current difficulty label and button states"""
	var difficulty_name = DifficultyManager.get_difficulty_name()
	current_difficulty_label.text = "Current: " + difficulty_name.to_upper()

	# Highlight selected difficulty button
	easy_button.modulate = Color.WHITE if difficulty_name == "Easy" else Color(0.6, 0.6, 0.6)
	normal_button.modulate = Color.WHITE if difficulty_name == "Normal" else Color(0.6, 0.6, 0.6)
	hard_button.modulate = Color.WHITE if difficulty_name == "Hard" else Color(0.6, 0.6, 0.6)

func _on_play_button_pressed():
	"""Handle Play button - go to set select"""
	MenuController.show_set_select()

func _on_return_button_pressed():
	"""Return to the last in-progress level"""
	MenuController.resume_last_level()

func _on_easy_button_pressed():
	"""Set difficulty to Easy"""
	DifficultyManager.set_difficulty(DifficultyManager.Difficulty.EASY)
	SaveManager.save_difficulty("Easy")
	update_difficulty_display()

func _on_normal_button_pressed():
	"""Set difficulty to Normal"""
	DifficultyManager.set_difficulty(DifficultyManager.Difficulty.NORMAL)
	SaveManager.save_difficulty("Normal")
	update_difficulty_display()

func _on_hard_button_pressed():
	"""Set difficulty to Hard"""
	DifficultyManager.set_difficulty(DifficultyManager.Difficulty.HARD)
	SaveManager.save_difficulty("Hard")
	update_difficulty_display()

func _on_stats_button_pressed():
	"""Handle Stats button - show stats screen"""
	MenuController.show_stats()

func _on_editor_button_pressed():
	"""Handle Editor button - open pack editor"""
	MenuController.show_editor_from_main_menu()

func _on_settings_button_pressed():
	"""Handle Settings button - show settings screen"""
	MenuController.show_settings()

func _on_quit_button_pressed():
	"""Handle Quit button - exit game"""
	MenuController.quit_game()


func _on_difficulty_changed(_new_difficulty):
	"""Handle difficulty change signal"""
	update_difficulty_display()

func _update_return_button():
	"""Show return button if a level is in progress"""
	var last_played = SaveManager.get_last_played()
	var in_progress = last_played.get("in_progress", false)
	return_button.visible = in_progress
