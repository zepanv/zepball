extends Control

## Level Complete Screen - Displayed when player clears all bricks
## Shows score, high score status, and progression options

@onready var score_label = $VBoxContainer/ScoreLabel
@onready var high_score_label = $VBoxContainer/HighScoreLabel
@onready var perfect_clear_label = $VBoxContainer/PerfectClearLabel
@onready var breakdown_title_label = $VBoxContainer/HBoxContainer/BreakdownContainer/BreakdownTitleLabel
@onready var base_score_label = $VBoxContainer/HBoxContainer/BreakdownContainer/BaseScoreLabel
@onready var difficulty_bonus_label = $VBoxContainer/HBoxContainer/BreakdownContainer/DifficultyBonusLabel
@onready var combo_bonus_label = $VBoxContainer/HBoxContainer/BreakdownContainer/ComboBonusLabel
@onready var streak_bonus_label = $VBoxContainer/HBoxContainer/BreakdownContainer/StreakBonusLabel
@onready var double_bonus_label = $VBoxContainer/HBoxContainer/BreakdownContainer/DoubleBonusLabel
@onready var perfect_bonus_label = $VBoxContainer/HBoxContainer/BreakdownContainer/PerfectBonusLabel
@onready var total_score_label = $VBoxContainer/HBoxContainer/BreakdownContainer/TotalScoreLabel
@onready var time_label = $VBoxContainer/HBoxContainer/BreakdownContainer/TimeLabel
@onready var set_total_label = $VBoxContainer/HBoxContainer/BreakdownContainer/SetTotalLabel
@onready var unlocked_label = $VBoxContainer/HBoxContainer/ButtonsContainer/UnlockedLabel
@onready var play_again_button = $VBoxContainer/HBoxContainer/ButtonsContainer/PlayAgainButton
@onready var next_level_button = $VBoxContainer/HBoxContainer/ButtonsContainer/NextLevelButton

func _ready():
	"""Initialize level complete screen"""
	# Get data from MenuController
	var final_score = MenuController.get_current_score()
	var level_id = MenuController.get_current_level_id()
	var was_perfect = MenuController.get_was_perfect_clear()
	var breakdown = MenuController.get_last_level_breakdown()
	var level_time = MenuController.get_last_level_time_seconds()
	var level_score_raw = MenuController.get_last_level_score_raw()
	var level_score_final = MenuController.get_last_level_score_final()

	# Display score
	if MenuController.current_play_mode == MenuController.PlayMode.SET:
		score_label.text = "Level Score: " + str(level_score_final)
	else:
		score_label.text = "Score: " + str(level_score_final)

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

	# Populate score breakdown
	var base_points = int(breakdown.get("base_points", 0))
	var difficulty_bonus = int(breakdown.get("difficulty_bonus", 0))
	var combo_bonus = int(breakdown.get("combo_bonus", 0))
	var streak_bonus = int(breakdown.get("streak_bonus", 0))
	var double_bonus = int(breakdown.get("double_bonus", 0))
	var perfect_bonus = int(breakdown.get("perfect_clear_bonus", 0))

	breakdown_title_label.text = "SCORE BREAKDOWN"
	base_score_label.text = "Base Score: " + str(base_points)
	difficulty_bonus_label.text = "Difficulty Bonus: " + _format_bonus(difficulty_bonus)
	combo_bonus_label.text = "Combo Bonus: " + _format_bonus(combo_bonus)
	streak_bonus_label.text = "Streak Bonus: " + _format_bonus(streak_bonus)
	double_bonus_label.text = "Power-Up Bonus: " + _format_bonus(double_bonus)
	perfect_bonus_label.text = "Perfect Clear Bonus: " + _format_bonus(perfect_bonus)
	total_score_label.text = "Total: " + str(level_score_raw + perfect_bonus)
	time_label.text = "Time: " + _format_time(level_time)

	# Handle set mode vs individual mode
	if MenuController.current_play_mode == MenuController.PlayMode.SET:
		set_total_label.visible = true
		set_total_label.text = "Set Total: " + str(final_score)
		# In set mode, show continue button (no auto-advance - let player take a break)
		next_level_button.text = "CONTINUE SET"
		unlocked_label.text = "Ready for next level"
		next_level_button.disabled = false
	else:
		set_total_label.visible = false
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

	# Default focus on next level button (when available)
	if not next_level_button.disabled:
		next_level_button.grab_focus()

func _on_next_level_button_pressed():
	"""Continue to next level"""
	MenuController.continue_to_next_level()

func _on_play_again_button_pressed():
	"""Restart the current level"""
	MenuController.restart_current_level()

func _on_level_select_button_pressed():
	"""Return to level select"""
	MenuController.show_level_select()

func _on_menu_button_pressed():
	"""Return to main menu"""
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
