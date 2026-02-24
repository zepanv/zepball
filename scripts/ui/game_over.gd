extends Control

## Game Over Screen - Displayed when player loses all lives
## Shows final score and options to retry or return to menu

@onready var score_label = $VBoxContainer/ScoreLabel
@onready var high_score_label = $VBoxContainer/HighScoreLabel
@onready var survival_label = $VBoxContainer/SurvivalLabel
@onready var retry_button = $VBoxContainer/RetryButton
@onready var menu_button = $VBoxContainer/MenuButton
@onready var vbox_container = $VBoxContainer

var continue_set_button: Button = null
var _ready_time: float = 0.0

func _ready():
	"""Initialize game over screen"""
	_ready_time = Time.get_ticks_msec()
	# Get score from MenuController
	var final_score = MenuController.get_current_score()
	var level_key = MenuController.get_current_level_key()
	var in_survival = MenuController.is_survival_mode

	# Display final score
	score_label.text = "Final Score: " + str(final_score)

	if in_survival:
		retry_button.text = "PLAY AGAIN"
		if survival_label:
			survival_label.visible = true
			survival_label.text = "Wave Reached: " + str(max(1, int(MenuController.get_survival_wave_reached())))
		high_score_label.text = "SURVIVAL RUN COMPLETE"
		high_score_label.set("theme_override_colors/font_color", Color(0.9, 0.8, 0.35, 1))
		_show_survival_comparison()
	else:
		if survival_label:
			survival_label.visible = false
		# Check if this was a high score
		var high_score = SaveManager.get_level_key_high_score(level_key)
		if high_score > 0:
			if final_score >= high_score:
				high_score_label.text = "NEW HIGH SCORE!"
				high_score_label.set("theme_override_colors/font_color", Color(1, 1, 0, 1))
			else:
				high_score_label.text = "High Score: " + str(high_score)
				high_score_label.set("theme_override_colors/font_color", Color(0.5, 1, 0.5, 1))
		else:
			high_score_label.text = ""

	# Add "Continue Set" button if in set mode (hidden for One Life challenge runs)
	if not in_survival and MenuController.current_play_mode == MenuController.PlayMode.SET and MenuController.get_challenge_mode() != "one_life":
		add_continue_set_button()

	if MenuController.is_editor_test_mode:
		high_score_label.text = "EDITOR TEST"
		high_score_label.set("theme_override_colors/font_color", Color(0.75, 0.9, 1.0, 1))
		retry_button.text = "RETEST LEVEL"
		menu_button.text = "RETURN TO EDITOR"

	# Grab focus for controller navigation
	await get_tree().process_frame
	retry_button.grab_focus()

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

func _unhandled_input(event: InputEvent) -> void:
	if Time.get_ticks_msec() - _ready_time < 500:
		return
	if event.is_action_pressed("restart_game") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_on_retry_button_pressed()
	elif event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_menu_button_pressed()

func _on_retry_button_pressed():
	"""Restart the same level"""
	if MenuController.is_survival_mode:
		MenuController.start_survival()
		return
	MenuController.restart_current_level()

func _on_continue_set_button_pressed():
	"""Continue set from current level with reset score/lives"""
	var level_ref = MenuController.get_current_level_ref()
	var level_id = PackLoader.get_legacy_level_id(str(level_ref.get("pack_id", "")), int(level_ref.get("level_index", 0)))

	# Set had_continue flag
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		game_manager.had_continue = true

	# Continue the set from current level
	if level_id != -1:
		MenuController.continue_set_from_level(level_id)
	else:
		MenuController.continue_set_from_ref(str(level_ref.get("pack_id", "")), int(level_ref.get("level_index", 0)))

func _on_menu_button_pressed():
	"""Return to main menu"""
	if MenuController.is_editor_test_mode:
		MenuController.return_to_editor_from_test()
		return
	MenuController.show_main_menu()

func _show_survival_comparison() -> void:
	var personal_runs: Array = SaveManager.get_survival_top_runs()
	var machine_runs: Array = SaveManager.get_all_leaderboards().get("survival_runs", [])

	var personal_line := "Your best: No runs yet"
	if not personal_runs.is_empty():
		var best_personal: Dictionary = personal_runs[0]
		personal_line = "Your best: " + _format_survival_run(best_personal)

	var machine_line := "Machine best: No runs yet"
	if not machine_runs.is_empty():
		var best_machine: Dictionary = machine_runs[0]
		machine_line = "Machine best: " + _format_survival_run(best_machine)

	if survival_label:
		survival_label.text += "\n" + personal_line + "\n" + machine_line

func _format_survival_run(run: Dictionary) -> String:
	var wave := int(run.get("wave", 1))
	var score := int(run.get("score", 0))
	return "Wave %d, %d pts" % [wave, score]
