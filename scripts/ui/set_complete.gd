extends Control

## Set Complete Screen - Displayed when player completes all levels in a set
## Shows cumulative score, set high score, and perfect set clear bonus

@onready var set_name_label = $VBoxContainer/SetNameLabel
@onready var score_label = $VBoxContainer/ScoreLabel
@onready var set_high_score_label = $VBoxContainer/SetHighScoreLabel
@onready var perfect_set_label = $VBoxContainer/PerfectSetLabel
@onready var breakdown_title_label = $VBoxContainer/HBoxContainer/BreakdownContainer/BreakdownTitleLabel
@onready var base_score_label = $VBoxContainer/HBoxContainer/BreakdownContainer/BaseScoreLabel
@onready var difficulty_bonus_label = $VBoxContainer/HBoxContainer/BreakdownContainer/DifficultyBonusLabel
@onready var combo_bonus_label = $VBoxContainer/HBoxContainer/BreakdownContainer/ComboBonusLabel
@onready var streak_bonus_label = $VBoxContainer/HBoxContainer/BreakdownContainer/StreakBonusLabel
@onready var double_bonus_label = $VBoxContainer/HBoxContainer/BreakdownContainer/DoubleBonusLabel
@onready var perfect_clear_bonus_label = $VBoxContainer/HBoxContainer/BreakdownContainer/PerfectClearBonusLabel
@onready var perfect_set_bonus_label = $VBoxContainer/HBoxContainer/BreakdownContainer/PerfectSetBonusLabel
@onready var total_score_label = $VBoxContainer/HBoxContainer/BreakdownContainer/TotalScoreLabel
@onready var time_label = $VBoxContainer/HBoxContainer/BreakdownContainer/TimeLabel
@onready var next_set_button = $VBoxContainer/HBoxContainer/ButtonsContainer/NextSetButton

func _ready():
	"""Initialize set complete screen"""
	print("Set Complete screen loaded")

	# Get data from MenuController
	var final_score = MenuController.get_current_score()
	var set_id = MenuController.current_set_id
	var set_display_name = SetLoader.get_set_name(set_id)
	var breakdown = MenuController.get_set_breakdown()
	var set_time = MenuController.get_set_total_time_seconds()
	var set_bonus = MenuController.get_set_perfect_bonus()

	# Display set name
	set_name_label.text = set_display_name.to_upper()

	# Display final score
	score_label.text = "Final Score: " + str(final_score)

	# Check for perfect set clear (3x bonus)
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager and game_manager.lives == 3 and game_manager.is_perfect_clear and not game_manager.had_continue:
		perfect_set_label.visible = true
	else:
		perfect_set_label.visible = false

	# Populate score breakdown
	var base_points = int(breakdown.get("base_points", 0))
	var difficulty_bonus = int(breakdown.get("difficulty_bonus", 0))
	var combo_bonus = int(breakdown.get("combo_bonus", 0))
	var streak_bonus = int(breakdown.get("streak_bonus", 0))
	var double_bonus = int(breakdown.get("double_bonus", 0))
	var perfect_clear_bonus = int(breakdown.get("perfect_clear_bonus", 0))

	breakdown_title_label.text = "SET SCORE BREAKDOWN"
	base_score_label.text = "Base Score: " + str(base_points)
	difficulty_bonus_label.text = "Difficulty Bonus: " + _format_bonus(difficulty_bonus)
	combo_bonus_label.text = "Combo Bonus: " + _format_bonus(combo_bonus)
	streak_bonus_label.text = "Streak Bonus: " + _format_bonus(streak_bonus)
	double_bonus_label.text = "Power-Up Bonus: " + _format_bonus(double_bonus)
	perfect_clear_bonus_label.text = "Perfect Clear Bonus: " + _format_bonus(perfect_clear_bonus)
	perfect_set_bonus_label.text = "Perfect Set Bonus: " + _format_bonus(set_bonus)
	total_score_label.text = "Total: " + str(final_score)
	time_label.text = "Set Time: " + _format_time(set_time)

	# Check if this was a set high score
	var set_high_score = SaveManager.get_set_high_score(set_id)
	if final_score >= set_high_score:
		set_high_score_label.text = "NEW SET HIGH SCORE!"
		set_high_score_label.set("theme_override_colors/font_color", Color(1, 1, 0, 1))
	elif set_high_score > 0:
		set_high_score_label.text = "Set High Score: " + str(set_high_score)
		set_high_score_label.set("theme_override_colors/font_color", Color(0.7, 0.7, 0.7, 1))
	else:
		set_high_score_label.text = ""

	# Check if there's a next set
	var next_set_id = set_id + 1
	if SetLoader.set_exists(next_set_id) and SaveManager.is_set_unlocked(next_set_id):
		next_set_button.disabled = false
		var next_set_name = SetLoader.get_set_name(next_set_id)
		next_set_button.text = "NEXT SET: " + next_set_name.to_upper()
	else:
		next_set_button.disabled = true
		next_set_button.text = "NO MORE SETS"

func _on_next_set_button_pressed():
	"""Start the next set"""
	print("Next Set button pressed")
	var next_set_id = MenuController.current_set_id + 1
	MenuController.start_set(next_set_id)

func _on_set_select_button_pressed():
	"""Return to set select"""
	print("Set Select button pressed")
	MenuController.show_set_select()

func _on_menu_button_pressed():
	"""Return to main menu"""
	print("Main Menu button pressed")
	MenuController.show_main_menu()

func _format_bonus(value: int) -> String:
	if value > 0:
		return "+" + str(value)
	return str(value)

func _format_time(seconds: float) -> String:
	var total_seconds = int(seconds)
	var minutes = int(total_seconds / 60.0)
	var secs = int(total_seconds % 60)
	return "%02d:%02d" % [minutes, secs]
