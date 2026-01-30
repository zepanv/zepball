extends Control

## Level Complete Screen - Displayed when player clears all bricks
## Shows score, high score status, and progression options

@onready var score_label = $VBoxContainer/ScoreLabel
@onready var high_score_label = $VBoxContainer/HighScoreLabel
@onready var perfect_clear_label = $VBoxContainer/PerfectClearLabel
@onready var unlocked_label = $VBoxContainer/UnlockedLabel
@onready var next_level_button = $VBoxContainer/NextLevelButton

func _ready():
	"""Initialize level complete screen"""
	print("Level Complete screen loaded")

	# Get data from MenuController
	var final_score = MenuController.get_current_score()
	var level_id = MenuController.get_current_level_id()
	var was_perfect = MenuController.get_was_perfect_clear()

	# Display score
	score_label.text = "Score: " + str(final_score)

	# Display perfect clear message if achieved
	if was_perfect:
		perfect_clear_label.text = "PERFECT CLEAR! (2x Score Bonus)"
		perfect_clear_label.visible = true
	else:
		perfect_clear_label.visible = false

	# Check if this was a high score
	var high_score = SaveManager.get_high_score(level_id)
	if final_score >= high_score:
		high_score_label.text = "NEW HIGH SCORE!"
		high_score_label.set("theme_override_colors/font_color", Color(1, 1, 0, 1))
	elif high_score > 0:
		high_score_label.text = "High Score: " + str(high_score)
		high_score_label.set("theme_override_colors/font_color", Color(0.7, 0.7, 0.7, 1))

	# Handle set mode vs individual mode
	if MenuController.current_play_mode == MenuController.PlayMode.SET:
		# In set mode, show continue button (no auto-advance - let player take a break)
		next_level_button.text = "CONTINUE SET"
		unlocked_label.text = "Ready for next level"
		next_level_button.disabled = false
	else:
		# In individual mode, show normal next level options
		if LevelLoader.has_next_level(level_id):
			var next_level_id = LevelLoader.get_next_level_id(level_id)
			var next_level_info = LevelLoader.get_level_info(next_level_id)
			unlocked_label.text = "Unlocked: " + next_level_info.get("name", "Next Level")
			next_level_button.disabled = false
		else:
			unlocked_label.text = "All Levels Complete!"
			unlocked_label.set("theme_override_colors/font_color", Color(1, 1, 0, 1))
			next_level_button.disabled = true
			next_level_button.text = "NO MORE LEVELS"

func _on_next_level_button_pressed():
	"""Continue to next level"""
	print("Next Level button pressed")
	MenuController.continue_to_next_level()

func _on_level_select_button_pressed():
	"""Return to level select"""
	print("Level Select button pressed")
	MenuController.show_level_select()

func _on_menu_button_pressed():
	"""Return to main menu"""
	print("Main Menu button pressed")
	MenuController.show_main_menu()
