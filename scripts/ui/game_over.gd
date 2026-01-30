extends Control

## Game Over Screen - Displayed when player loses all lives
## Shows final score and options to retry or return to menu

@onready var score_label = $VBoxContainer/ScoreLabel
@onready var high_score_label = $VBoxContainer/HighScoreLabel
@onready var retry_button = $VBoxContainer/RetryButton
@onready var menu_button = $VBoxContainer/MenuButton
@onready var vbox_container = $VBoxContainer

var continue_set_button: Button = null

func _ready():
	"""Initialize game over screen"""
	print("Game Over screen loaded")

	# Get score from MenuController
	var final_score = MenuController.get_current_score()
	var level_id = MenuController.get_current_level_id()

	# Display final score
	score_label.text = "Final Score: " + str(final_score)

	# Check if this was a high score
	var high_score = SaveManager.get_high_score(level_id)
	if high_score > 0:
		if final_score >= high_score:
			high_score_label.text = "NEW HIGH SCORE!"
			high_score_label.set("theme_override_colors/font_color", Color(1, 1, 0, 1))
		else:
			high_score_label.text = "High Score: " + str(high_score)
			high_score_label.set("theme_override_colors/font_color", Color(0.5, 1, 0.5, 1))
	else:
		high_score_label.text = ""

	# Add "Continue Set" button if in set mode
	if MenuController.current_play_mode == MenuController.PlayMode.SET:
		add_continue_set_button()

func add_continue_set_button():
	"""Add Continue Set button between Retry and Menu buttons"""
	# Create the button
	continue_set_button = Button.new()
	continue_set_button.name = "ContinueSetButton"
	continue_set_button.text = "CONTINUE SET"
	continue_set_button.custom_minimum_size = Vector2(0, 55)
	continue_set_button.set("theme_override_colors/font_color", Color(1, 0.8, 0, 1))
	continue_set_button.set("theme_override_colors/font_hover_color", Color(0, 0.9, 1, 1))
	continue_set_button.set("theme_override_font_sizes/font_size", 30)

	# Insert between RetryButton and MenuButton
	var retry_index = retry_button.get_index()
	vbox_container.add_child(continue_set_button)
	vbox_container.move_child(continue_set_button, retry_index + 1)

	# Connect signal
	continue_set_button.pressed.connect(_on_continue_set_button_pressed)

func _on_retry_button_pressed():
	"""Restart the same level"""
	print("Retry button pressed")
	MenuController.restart_current_level()

func _on_continue_set_button_pressed():
	"""Continue set from current level with reset score/lives"""
	print("Continue Set button pressed")
	var level_id = MenuController.get_current_level_id()

	# Set had_continue flag
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		game_manager.had_continue = true

	# Continue the set from current level
	MenuController.continue_set_from_level(level_id)

func _on_menu_button_pressed():
	"""Return to main menu"""
	print("Menu button pressed")
	MenuController.show_main_menu()
