extends Control

## Level Complete Screen - Displayed when player clears all bricks
## Shows score, high score status, and progression options
const UI_THEME = preload("res://scripts/ui/ui_theme.gd")

@onready var background = $Background
@onready var complete_label = $VBoxContainer/CompleteLabel
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
@onready var level_select_button = $VBoxContainer/HBoxContainer/ButtonsContainer/LevelSelectButton
@onready var menu_button = $VBoxContainer/HBoxContainer/ButtonsContainer/MenuButton

var _ready_time: float = 0.0

func _ready():
	"""Initialize level complete screen"""
	_apply_theme()
	_ready_time = Time.get_ticks_msec()
	# Get data from MenuController
	var final_score = MenuController.get_current_score()
	var level_ref = MenuController.get_current_level_ref()
	var level_key = MenuController.get_current_level_key()
	var level_index = int(level_ref.get("level_index", 0))
	var legacy_level_id = MenuController.get_current_level_id()
	var was_perfect = MenuController.get_was_perfect_clear()
	var breakdown = MenuController.get_last_level_breakdown()
	var level_time = MenuController.get_last_level_time_seconds()
	var level_score_raw = MenuController.get_last_level_score_raw()
	var level_score_final = MenuController.get_last_level_score_final()
	var challenge_mode = _get_active_challenge_mode()
	var challenge_mode_label = _get_challenge_mode_label(challenge_mode)
	var is_challenge_set_run = _is_challenge_set_run(challenge_mode)

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
	if MenuController.was_new_machine_best:
		high_score_label.text = "NEW MACHINE HIGH SCORE!"
		UI_THEME.style_title(high_score_label)
		high_score_label.add_theme_font_size_override("font_size", 24)
	elif MenuController.was_new_personal_best:
		high_score_label.text = "NEW PERSONAL BEST!"
		UI_THEME.style_warning(high_score_label, 24)
	else:
		var personal_best = SaveManager.get_level_key_high_score(level_key)
		if personal_best > 0:
			high_score_label.text = "Personal Best: " + str(personal_best)
			UI_THEME.style_subtitle(high_score_label)

	# Populate score breakdown
	var base_points = int(breakdown.get("base_points", 0))
	var difficulty_bonus = int(breakdown.get("difficulty_bonus", 0))
	var combo_bonus = int(breakdown.get("combo_bonus", 0))
	var streak_bonus = int(breakdown.get("streak_bonus", 0))
	var double_bonus = int(breakdown.get("double_bonus", 0))
	var perfect_bonus = int(breakdown.get("perfect_clear_bonus", 0))

	breakdown_title_label.text = "SCORE BREAKDOWN"
	if is_challenge_set_run:
		breakdown_title_label.text = challenge_mode_label + " LEVEL BREAKDOWN"
	base_score_label.text = "Base Score: " + str(base_points)
	difficulty_bonus_label.text = "Difficulty Bonus: " + _format_bonus(difficulty_bonus)
	combo_bonus_label.text = "Combo Bonus: " + _format_bonus(combo_bonus)
	streak_bonus_label.text = "Streak Bonus: " + _format_bonus(streak_bonus)
	double_bonus_label.text = "Power-Up Bonus: " + _format_bonus(double_bonus)
	perfect_bonus_label.text = "Perfect Clear Bonus: " + _format_bonus(perfect_bonus)
	total_score_label.text = "Total: " + str(level_score_raw + perfect_bonus)
	if challenge_mode == "time_attack" and is_challenge_set_run:
		var run_time_seconds: int = int(MenuController.get_time_attack_elapsed_base_seconds())
		if run_time_seconds < 0:
			run_time_seconds = 0
		if run_time_seconds > 0:
			time_label.text = "Run Time: " + _format_time(float(run_time_seconds))
		else:
			time_label.text = "Run Time: " + _format_time(level_time)
	else:
		time_label.text = "Time: " + _format_time(level_time)

	# Handle set mode vs individual mode
	if MenuController.is_editor_test_mode:
		set_total_label.visible = false
		perfect_clear_label.visible = false
		high_score_label.text = "EDITOR TEST RUN COMPLETE"
		UI_THEME.style_title(high_score_label)
		high_score_label.add_theme_font_size_override("font_size", 24)
		unlocked_label.text = "Return to editor to keep iterating"
		next_level_button.text = "RETURN TO EDITOR"
		next_level_button.disabled = false
		play_again_button.text = "RETEST LEVEL"
	elif MenuController.current_play_mode == MenuController.PlayMode.SET:
		set_total_label.visible = true
		if is_challenge_set_run:
			set_total_label.text = challenge_mode_label + " Total: " + str(final_score)
		else:
			set_total_label.text = "Set Total: " + str(final_score)
		# In set mode, show continue button (no auto-advance - let player take a break)
		next_level_button.text = "CONTINUE SET"
		unlocked_label.text = "Ready for next level"
		next_level_button.disabled = false
	else:
		set_total_label.visible = false
		# In individual mode, show normal next level options
		var next_ref = MenuController.get_next_level_ref()
		if not next_ref.is_empty():
			var next_level_info = PackLoader.get_level_info(str(next_ref.get("pack_id", "")), int(next_ref.get("level_index", -1)))
			unlocked_label.text = "Unlocked: " + str(next_level_info.get("name", "Next Level"))
			next_level_button.disabled = false
		else:
			unlocked_label.text = "All Levels Complete!"
			UI_THEME.style_warning(unlocked_label, 24)
			next_level_button.disabled = true
			next_level_button.text = "NO MORE LEVELS"

	# Default focus on next level button (when available)
	if not next_level_button.disabled:
		next_level_button.grab_focus()

	if legacy_level_id == 0:
		score_label.text = "Level %d Score: %d" % [level_index + 1, level_score_final]

func _apply_theme() -> void:
	UI_THEME.apply_to(self)
	UI_THEME.style_background(background, true)
	UI_THEME.style_success(complete_label, 42)
	UI_THEME.style_value(score_label, 30)
	UI_THEME.style_subtitle(high_score_label)
	UI_THEME.style_warning(perfect_clear_label, 22)
	UI_THEME.style_section_title(breakdown_title_label)
	UI_THEME.style_subtitle(base_score_label)
	UI_THEME.style_subtitle(difficulty_bonus_label)
	UI_THEME.style_subtitle(combo_bonus_label)
	UI_THEME.style_subtitle(streak_bonus_label)
	UI_THEME.style_subtitle(double_bonus_label)
	UI_THEME.style_warning(perfect_bonus_label, 20)
	UI_THEME.style_value(total_score_label, 22)
	UI_THEME.style_subtitle(time_label)
	UI_THEME.style_title(set_total_label)
	set_total_label.add_theme_font_size_override("font_size", 22)
	UI_THEME.style_title(unlocked_label)
	unlocked_label.add_theme_font_size_override("font_size", 24)
	UI_THEME.style_primary_button(play_again_button)
	UI_THEME.style_success_button(next_level_button)
	UI_THEME.style_muted_button(level_select_button)
	UI_THEME.style_muted_button(menu_button)

func _unhandled_input(event: InputEvent) -> void:
	if Time.get_ticks_msec() - _ready_time < 500:
		return
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		if not next_level_button.disabled:
			_on_next_level_button_pressed()
		else:
			_on_play_again_button_pressed()
	elif event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_play_again_button_pressed()

func _on_next_level_button_pressed():
	"""Continue to next level"""
	if MenuController.is_editor_test_mode:
		MenuController.return_to_editor_from_test()
		return
	MenuController.continue_to_next_level()

func _on_play_again_button_pressed():
	"""Restart the current level"""
	MenuController.restart_current_level()

func _on_level_select_button_pressed():
	"""Return to level select"""
	if MenuController.is_editor_test_mode:
		MenuController.return_to_editor_from_test()
		return
	MenuController.show_level_select()

func _on_menu_button_pressed():
	"""Return to main menu"""
	if MenuController.is_editor_test_mode:
		MenuController.return_to_editor_from_test()
		return
	MenuController.show_main_menu()

func _format_bonus(value: int) -> String:
	if value > 0:
		return "+" + str(value)
	return str(value)

func _format_time(seconds: float) -> String:
	var total_seconds = int(seconds)
	var minutes: int = int(floor(float(total_seconds) / 60.0))
	var secs: int = int(total_seconds % 60)
	return "%02d:%02d" % [minutes, secs]

func _get_active_challenge_mode() -> String:
	if MenuController and MenuController.has_method("get_challenge_mode"):
		return str(MenuController.get_challenge_mode())
	return "normal"

func _is_challenge_set_run(challenge_mode: String) -> bool:
	return MenuController.current_play_mode == MenuController.PlayMode.SET and challenge_mode != "normal"

func _get_challenge_mode_label(challenge_mode: String) -> String:
	match challenge_mode:
		"iron_ball":
			return "IRON BALL"
		"one_life":
			return "ONE LIFE"
		"time_attack":
			return "TIME ATTACK"
		_:
			return "NORMAL"
