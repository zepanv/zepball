extends Control

## Game Over Screen - Displayed when player loses all lives
## Shows final score and options to retry or return to menu

@onready var score_label = $VBoxContainer/ScoreLabel
@onready var high_score_label = $VBoxContainer/HighScoreLabel

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

func _on_retry_button_pressed():
	"""Restart the same level"""
	print("Retry button pressed")
	MenuController.restart_current_level()

func _on_menu_button_pressed():
	"""Return to main menu"""
	print("Menu button pressed")
	MenuController.show_main_menu()
