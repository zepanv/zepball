extends Control

## Main Menu - Entry point for the game
## Allows player to start game, select difficulty, and quit
const PUBLIC_VERSION: String = "0.6.1"
const GITHUB_RELEASES_API = "https://api.github.com/repos/zepanv/zepball/releases/latest"
const UI_THEME = preload("res://scripts/ui/ui_theme.gd")

var _pending_update_url: String = ""
var _background_anim_time: float = 0.0

@onready var background = $Background
@onready var title_label = $VBoxContainer/TitleLabel
@onready var profile_panel = $VBoxContainer/ProfilePanel
@onready var profile_tag_label = $VBoxContainer/ProfilePanel/MarginContainer/ProfileVBox/ProfileTag
@onready var profile_label = $VBoxContainer/ProfilePanel/MarginContainer/ProfileVBox/ProfileContainer/ProfileLabel
@onready var profile_dropdown = $VBoxContainer/ProfilePanel/MarginContainer/ProfileVBox/ProfileContainer/ProfileDropdown
@onready var add_profile_button = $VBoxContainer/ProfilePanel/MarginContainer/ProfileVBox/ProfileContainer/AddProfileButton
@onready var play_button = $VBoxContainer/PlayButton
@onready var return_button = $VBoxContainer/ReturnButton
@onready var endless_waves_button = $VBoxContainer/SurvivalButton
@onready var difficulty_title = $VBoxContainer/DifficultyContainer/DifficultyTitle
@onready var difficulty_dropdown = $VBoxContainer/DifficultyContainer/DifficultyDropdown
@onready var editor_button = $VBoxContainer/SecondaryHBox/EditorButton
@onready var stats_button = $VBoxContainer/StatsHBox/StatsButton
@onready var high_scores_button = $VBoxContainer/StatsHBox/HighScoresButton
@onready var settings_button = $VBoxContainer/SecondaryHBox/SettingsButton
@onready var quit_button = $VBoxContainer/QuitButton
@onready var version_label = $VersionContainer/VersionLabel
@onready var update_button = $VersionContainer/UpdateButton
@onready var new_profile_dialog = $NewProfileDialog
@onready var profile_name_input = $NewProfileDialog/VBoxContainer/ProfileNameInput
@onready var rename_hint_label = $RenameHintLabel

func _ready():
	"""Initialize main menu"""
	version_label.text = "v" + PUBLIC_VERSION
	_reset_update_button()

	# Apply styling
	_apply_theme()

	SaveManager.save_loaded.connect(_on_save_loaded)
	
	new_profile_dialog.confirmed.connect(_on_new_profile_confirmed)
	new_profile_dialog.canceled.connect(_on_new_profile_canceled)
	# Also connect text submission (Enter key)
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

func _apply_theme() -> void:
	UI_THEME.apply_to(self)
	UI_THEME.style_background(background)
	UI_THEME.style_title_large(title_label)
	profile_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	UI_THEME.style_meta(profile_tag_label)
	UI_THEME.style_subtitle(profile_label)
	UI_THEME.style_subtitle(difficulty_title)
	UI_THEME.style_meta(version_label)
	UI_THEME.style_meta(rename_hint_label)
	difficulty_title.add_theme_color_override("font_color", UI_THEME.TEXT_MUTED)
	
	UI_THEME.style_primary_button(play_button)
	UI_THEME.style_success_button(return_button)
	return_button.add_theme_font_size_override("font_size", 22)
	UI_THEME.style_primary_button(endless_waves_button)
	endless_waves_button.add_theme_color_override("font_color", UI_THEME.GOLD)
	endless_waves_button.add_theme_font_size_override("font_size", 22)
	
	UI_THEME.style_muted_button(editor_button)
	UI_THEME.style_muted_button(stats_button)
	UI_THEME.style_muted_button(high_scores_button)
	UI_THEME.style_muted_button(settings_button)
	UI_THEME.style_danger_button(quit_button)
	
	UI_THEME.style_option_button(profile_dropdown)
	UI_THEME.style_option_button(difficulty_dropdown)
	UI_THEME.style_success_button(add_profile_button)
	
	if OS.get_name() == "Web":
		quit_button.hide()

func _refresh_full_ui():
	"""Refresh all UI elements that depend on save state"""
	_populate_profiles()
	_populate_difficulty_dropdown()
	_update_rename_hint()
	_update_return_button()

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
		
	if profile_dropdown.item_count > 0:
		profile_dropdown.select(select_index)

func _update_rename_hint() -> void:
	"""Show a rename hint while the active profile still has a generated default name."""
	var current_name = SaveManager.get_current_profile_name()
	var regex = RegEx.new()
	regex.compile("^Player \\d+$")
	rename_hint_label.visible = regex.search(current_name) != null

func _populate_difficulty_dropdown():
	"""Populate the difficulty dropdown and select current"""
	difficulty_dropdown.clear()
	difficulty_dropdown.add_item("EASY", 0) # DifficultyManager.Difficulty.EASY
	difficulty_dropdown.add_item("NORMAL", 1) # DifficultyManager.Difficulty.NORMAL
	difficulty_dropdown.add_item("HARD", 2) # DifficultyManager.Difficulty.HARD
	
	# Select current
	var current = DifficultyManager.get_difficulty()
	difficulty_dropdown.select(current)

func _on_profile_dropdown_item_selected(index: int):
	"""Handle profile selection"""
	var profile_id = profile_dropdown.get_item_metadata(index)
	SaveManager.switch_profile(profile_id)

func _on_add_profile_button_pressed():
	"""Show new profile dialog"""
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
	"""Handle profile creation cancellation"""
	pass

func _process(delta: float) -> void:
	_animate_background(delta)
	# Dialog windows swallow joypad cancel, so poll it explicitly.
	if Input.is_action_just_pressed("ui_cancel") and new_profile_dialog.visible:
		new_profile_dialog.hide()

func _unhandled_input(event: InputEvent) -> void:
	"""Allow controller/keyboard cancel to exit from the menu when no dialog is open."""
	if new_profile_dialog.visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_on_quit_button_pressed()
		accept_event()

func _on_difficulty_dropdown_item_selected(index: int):
	"""Handle difficulty change from dropdown"""
	match index:
		0: 
			DifficultyManager.set_difficulty(DifficultyManager.Difficulty.EASY)
			SaveManager.save_difficulty("Easy")
		1: 
			DifficultyManager.set_difficulty(DifficultyManager.Difficulty.NORMAL)
			SaveManager.save_difficulty("Normal")
		2: 
			DifficultyManager.set_difficulty(DifficultyManager.Difficulty.HARD)
			SaveManager.save_difficulty("Hard")

func _on_play_button_pressed():
	"""Handle Play button - go to set selection"""
	MenuController.show_set_select()

func _on_return_button_pressed():
	"""Handle Return button - jump back into the last played level"""
	MenuController.resume_last_level()

func _on_endless_waves_pressed():
	"""Handle Endless Waves button - go to endless mode hub"""
	MenuController.show_endless_waves()

func _on_stats_button_pressed():
	"""Handle Stats button - show stats screen"""
	MenuController.show_stats()

func _on_high_scores_button_pressed():
	"""Handle High Scores button - show leaderboards"""
	MenuController.show_high_scores()

func _on_editor_button_pressed():
	"""Handle Editor button - go to level editor"""
	# Check if we should return to an existing test run
	if MenuController.is_editor_test_mode:
		MenuController.return_to_editor_from_test()
	else:
		MenuController.show_editor_from_main_menu()

func _on_settings_button_pressed():
	"""Handle Settings button"""
	MenuController.show_settings()

func _on_quit_button_pressed():
	"""Handle Quit button"""
	MenuController.quit_game()

func _update_return_button():
	"""Show return button only if there's a valid saved game in progress"""
	var last_played = SaveManager.get_last_played()
	var in_progress = last_played.get("in_progress", false)
	var mode = str(last_played.get("mode", ""))
	var challenge = str(last_played.get("challenge_mode", SaveManager.CHALLENGE_MODE_NORMAL))
	return_button.visible = in_progress \
		and mode != "survival" \
		and challenge != SaveManager.CHALLENGE_MODE_TIME_ATTACK
	_refresh_focus_chain()

func _animate_background(delta: float) -> void:
	_background_anim_time += delta
	var pulse = (sin(_background_anim_time * 0.42) + 1.0) * 0.5
	var blend = 0.16 + pulse * 0.10
	background.color = UI_THEME.SCREEN_BACKGROUND.lerp(UI_THEME.SCREEN_BACKGROUND_ALT, blend)

func _refresh_focus_chain() -> void:
	_set_focus_neighbors(profile_dropdown, null, play_button, null, add_profile_button)
	_set_focus_neighbors(add_profile_button, null, play_button, profile_dropdown, null)

	if return_button.visible:
		_set_focus_neighbors(play_button, profile_dropdown, return_button, null, null)
		_set_focus_neighbors(return_button, play_button, endless_waves_button, null, null)
		_set_focus_neighbors(endless_waves_button, return_button, difficulty_dropdown, null, null)
	else:
		_set_focus_neighbors(play_button, profile_dropdown, endless_waves_button, null, null)
		_set_focus_neighbors(return_button, null, null, null, null)
		_set_focus_neighbors(endless_waves_button, play_button, difficulty_dropdown, null, null)

	_set_focus_neighbors(difficulty_dropdown, endless_waves_button, stats_button, null, null)
	_set_focus_neighbors(stats_button, difficulty_dropdown, editor_button, null, high_scores_button)
	_set_focus_neighbors(high_scores_button, difficulty_dropdown, settings_button, stats_button, null)

	var row_down_target: Control = quit_button if quit_button.visible else profile_dropdown
	_set_focus_neighbors(editor_button, stats_button, row_down_target, null, settings_button)
	_set_focus_neighbors(settings_button, high_scores_button, row_down_target, editor_button, null)
	if quit_button.visible:
		_set_focus_neighbors(quit_button, settings_button, null, editor_button, settings_button)
	else:
		_set_focus_neighbors(quit_button, null, null, null, null)

func _set_focus_neighbors(control: Control, top: Control, bottom: Control, left: Control, right: Control) -> void:
	if not control:
		return
	control.focus_neighbor_top = _relative_path(control, top)
	control.focus_neighbor_bottom = _relative_path(control, bottom)
	control.focus_neighbor_left = _relative_path(control, left)
	control.focus_neighbor_right = _relative_path(control, right)

func _relative_path(from: Control, target: Control) -> NodePath:
	if not from or not target:
		return NodePath("")
	return from.get_path_to(target)

func _check_for_updates() -> void:
	"""Fetch latest release info from GitHub API"""
	if OS.get_name() == "Web":
		update_button.hide()
		return
		
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_github_api_response.bind(http_request))
	var headers = ["User-Agent: ZepBall-Game-Client"]
	var error = http_request.request(GITHUB_RELEASES_API, headers)
	if error != OK:
		http_request.queue_free()
		_flash_update_button("✗", Color(0.9, 0.3, 0.4, 1))

func _on_update_button_pressed() -> void:
	"""Check for update, or open release page if one was already found"""
	if _pending_update_url != "":
		OS.shell_open(_pending_update_url)
		return
	update_button.disabled = true
	update_button.text = "..."
	_check_for_updates()

func _on_github_api_response(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, http_request: HTTPRequest) -> void:
	"""Handle the JSON response from GitHub Releases"""
	http_request.queue_free()
	update_button.disabled = false
	
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		_flash_update_button("✗", Color(0.9, 0.3, 0.4, 1))
		return
		
	var json = JSON.new()
	var error = json.parse(body.get_string_from_utf8())
	if error != OK:
		_flash_update_button("✗", Color(0.9, 0.3, 0.4, 1))
		return
		
	var data = json.get_data()
	var remote_version = data.get("tag_name", "").replace("v", "")
	
	if remote_version == "" or remote_version == PUBLIC_VERSION:
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
