extends Control

## Set Complete Screen - Displayed when player completes all levels in a set
## Shows cumulative score, set high score, and perfect set clear bonus
const UI_THEME = preload("res://scripts/ui/ui_theme.gd")
const Helpers = preload("res://scripts/ui/score_breakdown_helpers.gd")

@onready var background = $Background
@onready var set_complete_label = $VBoxContainer/SetCompleteLabel
@onready var set_name_label = $VBoxContainer/SetNameLabel
@onready var score_label = $VBoxContainer/ScoreLabel
@onready var set_high_score_label = $VBoxContainer/SetHighScoreLabel
@onready var perfect_set_label = $VBoxContainer/PerfectSetLabel
@onready var breakdown_title_label = $VBoxContainer/BreakdownContainer/BreakdownTitleLabel
@onready var base_score_label = $VBoxContainer/BreakdownContainer/BaseScoreLabel
@onready var difficulty_bonus_label = $VBoxContainer/BreakdownContainer/DifficultyBonusLabel
@onready var combo_bonus_label = $VBoxContainer/BreakdownContainer/ComboBonusLabel
@onready var streak_bonus_label = $VBoxContainer/BreakdownContainer/StreakBonusLabel
@onready var double_bonus_label = $VBoxContainer/BreakdownContainer/DoubleBonusLabel
@onready var perfect_clear_bonus_label = $VBoxContainer/BreakdownContainer/PerfectClearBonusLabel
@onready var perfect_set_bonus_label = $VBoxContainer/BreakdownContainer/PerfectSetBonusLabel
@onready var total_score_label = $VBoxContainer/BreakdownContainer/TotalScoreLabel
@onready var time_label = $VBoxContainer/BreakdownContainer/TimeLabel
@onready var next_set_button = $VBoxContainer/ButtonsContainer/NextSetButton
@onready var set_select_button = $VBoxContainer/ButtonsContainer/SetSelectButton
@onready var menu_button = $VBoxContainer/ButtonsContainer/MenuButton

func _ready():
	"""Initialize set complete screen"""
	_apply_theme()
	# Grab focus for controller navigation
	await get_tree().process_frame

	# Get data from MenuController
	var final_score = MenuController.get_current_score()
	var set_id = MenuController.current_set_id
	var pack_id = MenuController.current_set_pack_id
	var set_display_name = ""
	if set_id != -1:
		set_display_name = PackLoader.get_legacy_set_name(set_id)
	else:
		set_display_name = str(PackLoader.get_pack(pack_id).get("name", "Custom Pack"))
	var breakdown = MenuController.get_set_breakdown()
	var set_time = MenuController.get_set_total_time_seconds()
	var set_bonus = MenuController.get_set_perfect_bonus()
	var challenge_mode = Helpers.get_active_challenge_mode()
	var challenge_mode_label = Helpers.get_challenge_mode_label(challenge_mode)
	var is_challenge_set_run = Helpers.is_challenge_set_run(challenge_mode)
	var displayed_time_seconds = int(floor(max(set_time, 0.0)))
	if challenge_mode == "time_attack":
		displayed_time_seconds = int(MenuController.get_time_attack_elapsed_base_seconds())
		if displayed_time_seconds < 0:
			displayed_time_seconds = 0
		if displayed_time_seconds <= 0:
			displayed_time_seconds = int(floor(max(set_time, 0.0)))

	# Display set name
	set_name_label.text = set_display_name.to_upper()
	if is_challenge_set_run:
		set_name_label.text += " - " + challenge_mode_label

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
	if is_challenge_set_run:
		breakdown_title_label.text = challenge_mode_label + " SET BREAKDOWN"
	base_score_label.text = "Base Score: " + str(base_points)

	# Hide zero-value bonus lines
	_set_bonus_line(difficulty_bonus_label, "Difficulty", difficulty_bonus)
	_set_bonus_line(combo_bonus_label, "Combo", combo_bonus)
	_set_bonus_line(streak_bonus_label, "Streak", streak_bonus)
	_set_bonus_line(double_bonus_label, "Power-Up", double_bonus)
	_set_bonus_line(perfect_clear_bonus_label, "Perfect Clear", perfect_clear_bonus)
	_set_bonus_line(perfect_set_bonus_label, "Perfect Set", set_bonus)

	total_score_label.text = "Total: " + str(final_score)
	if challenge_mode == "time_attack":
		time_label.text = "Time Attack Time: " + Helpers.format_time(float(displayed_time_seconds))
	else:
		time_label.text = "Set Time: " + Helpers.format_time(set_time)

	# Check if this was a set high score
	if challenge_mode == "time_attack":
		if MenuController.was_new_machine_best:
			set_high_score_label.text = "NEW MACHINE TIME ATTACK RECORD!"
			UI_THEME.style_title(set_high_score_label)
			set_high_score_label.add_theme_font_size_override("font_size", 22)
		elif MenuController.was_new_personal_best:
			set_high_score_label.text = "NEW PERSONAL TIME ATTACK BEST!"
			UI_THEME.style_warning(set_high_score_label, 22)
		else:
			var best_time = SaveManager.get_time_attack_set_high_score(pack_id)
			if best_time > 0:
				set_high_score_label.text = "Time Attack Best: " + Helpers.format_time(float(best_time))
				UI_THEME.style_subtitle(set_high_score_label)
			else:
				set_high_score_label.text = ""
	elif is_challenge_set_run:
		if MenuController.was_new_machine_best:
			set_high_score_label.text = "NEW MACHINE %s RECORD!" % challenge_mode_label
			UI_THEME.style_title(set_high_score_label)
			set_high_score_label.add_theme_font_size_override("font_size", 22)
		elif MenuController.was_new_personal_best:
			set_high_score_label.text = "NEW PERSONAL %s BEST!" % challenge_mode_label
			UI_THEME.style_warning(set_high_score_label, 22)
		else:
			var challenge_personal_best = SaveManager.get_challenge_set_high_score(pack_id, challenge_mode)
			if challenge_personal_best > 0:
				set_high_score_label.text = "%s Best: %d" % [challenge_mode_label, challenge_personal_best]
				UI_THEME.style_subtitle(set_high_score_label)
			else:
				set_high_score_label.text = ""
	else:
		var personal_best = SaveManager.get_set_pack_high_score(pack_id)
		if personal_best > 0:
			set_high_score_label.text = "Set Personal Best: " + str(personal_best)
			UI_THEME.style_subtitle(set_high_score_label)
		else:
			set_high_score_label.text = ""

	# Check if there's a next set
	var next_set_id = set_id + 1
	if set_id != -1 and PackLoader.legacy_set_exists(next_set_id) and SaveManager.is_set_unlocked(next_set_id):
		next_set_button.disabled = false
		var next_set_name = PackLoader.get_legacy_set_name(next_set_id)
		next_set_button.text = "NEXT SET: " + next_set_name.to_upper()
		next_set_button.grab_focus()
	else:
		next_set_button.disabled = true
		next_set_button.text = "NO MORE PACKS"

func _apply_theme() -> void:
	UI_THEME.apply_to(self)
	UI_THEME.style_background(background, true)
	UI_THEME.style_title_large(set_complete_label)
	set_complete_label.add_theme_color_override("font_color", UI_THEME.SUCCESS)
	UI_THEME.style_title(set_name_label)
	set_name_label.add_theme_font_size_override("font_size", 24)
	UI_THEME.style_value(score_label, 28)
	UI_THEME.style_subtitle(set_high_score_label)
	UI_THEME.style_warning(perfect_set_label, 20)
	UI_THEME.style_section_title(breakdown_title_label)
	UI_THEME.style_stat_label(base_score_label)
	UI_THEME.style_meta(difficulty_bonus_label)
	UI_THEME.style_meta(combo_bonus_label)
	UI_THEME.style_meta(streak_bonus_label)
	UI_THEME.style_meta(double_bonus_label)
	UI_THEME.style_warning(perfect_clear_bonus_label, 14)
	UI_THEME.style_warning(perfect_set_bonus_label, 14)
	UI_THEME.style_value(total_score_label, 20)
	UI_THEME.style_meta(time_label)
	UI_THEME.style_primary_button(next_set_button)
	UI_THEME.style_muted_button(set_select_button)
	UI_THEME.style_muted_button(menu_button)

func _set_bonus_line(label: Label, name: String, value: int) -> void:
	"""Show bonus line only if non-zero."""
	if value > 0:
		label.text = name + " Bonus: " + Helpers.format_bonus(value)
		label.visible = true
	else:
		label.visible = false

func _unhandled_input(event: InputEvent) -> void:
	"""Handle B button to return to menu"""
	if event.is_action_pressed("ui_cancel"):
		_on_menu_button_pressed()
		get_viewport().set_input_as_handled()

func _on_next_set_button_pressed():
	"""Start the next set"""
	if MenuController.current_set_id == -1:
		return
	var next_set_id = MenuController.current_set_id + 1
	MenuController.start_set(next_set_id)

func _on_set_select_button_pressed():
	"""Return to set select"""
	MenuController.show_set_select()

func _on_menu_button_pressed():
	"""Return to main menu"""
	MenuController.show_main_menu()
