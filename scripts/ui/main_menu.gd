extends Control

## Main Menu - Entry point for the game
## Allows player to start game, select difficulty, and quit
const PUBLIC_VERSION: String = "0.6.0"
const GITHUB_RELEASES_API = "https://api.github.com/repos/zepanv/zepball/releases/latest"

@onready var current_difficulty_label = $VBoxContainer/CurrentDifficultyLabel
@onready var easy_button = $VBoxContainer/DifficultyButtons/EasyButton
@onready var normal_button = $VBoxContainer/DifficultyButtons/NormalButton
@onready var hard_button = $VBoxContainer/DifficultyButtons/HardButton
@onready var play_button = $VBoxContainer/PlayButton
@onready var return_button = $VBoxContainer/ReturnButton
@onready var profile_dropdown = $VBoxContainer/ProfileContainer/ProfileDropdown
@onready var version_label = $VersionContainer/VersionLabel
@onready var update_button = $VersionContainer/UpdateButton
@onready var new_profile_dialog = $NewProfileDialog
@onready var profile_name_input = $NewProfileDialog/VBoxContainer/ProfileNameInput
@onready var rename_hint_label = $RenameHintLabel

var _update_http: HTTPRequest
var _pending_update_url: String = ""

func _ready():
	"""Initialize main menu"""
	version_label.text = "v%s" % PUBLIC_VERSION
	_update_http = HTTPRequest.new()
	add_child(_update_http)
	_update_http.request_completed.connect(_on_update_check_completed)

	# Unlock difficulty selection
	DifficultyManager.unlock_difficulty()

	# Connect signals
	DifficultyManager.difficulty_changed.connect(_on_difficulty_changed)
	SaveManager.save_loaded.connect(_on_save_loaded)
	
	new_profile_dialog.confirmed.connect(_on_new_profile_confirmed)
	new_profile_dialog.canceled.connect(_on_new_profile_canceled)

	profile_name_input.text_submitted.connect(func(_text):
		_on_new_profile_confirmed()
		new_profile_dialog.hide()
	)

	_refresh_full_ui()

	# Grab focus on the play button for controller navigation
	await get_tree().process_frame
	if return_button.visible:
		return_button.grab_focus()
	else:
		play_button.grab_focus()

func _refresh_full_ui():
	"""Update all UI elements based on current save/profile"""
	# Load saved difficulty preference
	var saved_difficulty = SaveManager.get_saved_difficulty()
	apply_saved_difficulty(saved_difficulty)

	# Update UI to show current difficulty
	update_difficulty_display()
	
	_update_return_button()
	_populate_profiles()

func _on_save_loaded():
	"""Called when save data is loaded or profile is switched"""
	_refresh_full_ui()

func _populate_profiles():
	"""Populate the profile dropdown"""
	profile_dropdown.clear()
	var profiles = SaveManager.get_profile_list()
	var current_id = SaveManager.get_current_profile_id()
	
	var select_index = 0
	var i = 0
	for id in profiles.keys():
		profile_dropdown.add_item(profiles[id])
		profile_dropdown.set_item_metadata(i, id)
		if id == current_id:
			select_index = i
		i += 1
	
	profile_dropdown.selected = select_index
	_update_rename_hint()

func _update_rename_hint():
	"""Show rename hint when the active profile still has a default 'Player N' name"""
	var current_name = SaveManager.get_current_profile_name()
	var regex = RegEx.new()
	regex.compile("^Player \\d+$")
	rename_hint_label.visible = regex.search(current_name) != null

func _on_profile_dropdown_item_selected(index: int):
	"""Handle profile selection from dropdown"""
	var profile_id = profile_dropdown.get_item_metadata(index)
	if profile_id != SaveManager.get_current_profile_id():
		SaveManager.switch_profile(profile_id)

func _on_add_profile_button_pressed():
	"""Open new profile dialog"""
	profile_name_input.text = SaveManager.get_next_default_name()
	new_profile_dialog.popup_centered()
	# For controller support, focus the OK button by default
	# This allows immediate "CREATE" via A button or navigating up to rename
	new_profile_dialog.get_ok_button().grab_focus()

func _on_new_profile_confirmed():
	"""Handle new profile creation"""
	var profile_name = profile_name_input.text.strip_edges()
	if profile_name == "":
		profile_name = "Player"

	SaveManager.create_profile(profile_name)

func _on_new_profile_canceled():
	"""Handle new profile dialog cancellation"""
	# Dialog already hides automatically, just ensure it's handled
	pass


func _process(_delta: float) -> void:
	# Poll joypad ui_cancel since dialogs (separate Windows) swallow joypad input
	if Input.is_action_just_pressed("ui_cancel") and new_profile_dialog.visible:
		new_profile_dialog.hide()

func _unhandled_input(event: InputEvent) -> void:
	"""Handle Esc/B to quit when no dialog is open"""
	if event.is_action_pressed("ui_cancel"):
		_on_quit_button_pressed()
		accept_event()

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

func _on_high_scores_button_pressed():
	"""Handle High Scores button - show leaderboards"""
	MenuController.show_high_scores()

func _on_editor_button_pressed():
	"""Handle Editor button - open pack editor"""
	MenuController.show_editor_from_main_menu()

func _on_survival_button_pressed():
	"""Handle Survival button - start endless survival mode"""
	MenuController.start_survival()

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
	var mode = str(last_played.get("mode", ""))
	var challenge = str(last_played.get("challenge_mode", SaveManager.CHALLENGE_MODE_NORMAL))
	return_button.visible = in_progress \
		and mode != "survival" \
		and challenge != SaveManager.CHALLENGE_MODE_TIME_ATTACK

func _on_update_button_pressed() -> void:
	"""Check for update, or open release page if one was already found"""
	if _pending_update_url != "":
		OS.shell_open(_pending_update_url)
		return
	update_button.disabled = true
	update_button.text = "..."
	_update_http.request(GITHUB_RELEASES_API)

func _on_update_check_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	"""Handle GitHub API response"""
	update_button.disabled = false
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		_flash_update_button("✕", Color(0.9, 0.3, 0.4, 1))
		return
	var json = JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		_flash_update_button("✕", Color(0.9, 0.3, 0.4, 1))
		return
	var data: Dictionary = json.get_data()
	var tag: String = data.get("tag_name", "")
	var remote_version: String = tag.lstrip("v")
	if remote_version.is_empty() or remote_version == PUBLIC_VERSION:
		_flash_update_button("✓", Color(0.5, 1, 0.5, 1))
	else:
		_pending_update_url = data.get("html_url", "")
		update_button.text = "↑ v%s" % remote_version
		update_button.add_theme_color_override("font_color", Color(0, 0.9, 1, 1))

func _flash_update_button(label: String, color: Color) -> void:
	"""Show a temporary status on the update button, then reset"""
	update_button.text = label
	update_button.add_theme_color_override("font_color", color)
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(update_button):
		_reset_update_button()

func _reset_update_button() -> void:
	_pending_update_url = ""
	update_button.text = "↻"
	update_button.remove_theme_color_override("font_color")
