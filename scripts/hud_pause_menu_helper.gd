extends RefCounted
class_name HudPauseMenuHelper

## HudPauseMenuHelper - Pause menu UI builder and button handlers extracted from hud.gd.

var pause_menu: Control = null
var settings_overlay: Control = null
var level_select_confirm: ConfirmationDialog = null
var pause_level_info_label: Label = null
var pause_score_info_label: Label = null
var pause_lives_info_label: Label = null

func create_pause_menu(hud: Control) -> Control:
	var menu = Control.new()
	menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu.mouse_filter = Control.MOUSE_FILTER_STOP

	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.7)
	menu.add_child(overlay)

	var center_container = CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu.add_child(center_container)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(400, 560)
	center_container.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set("theme_override_constants/separation", 20)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "PAUSED"
	title.set("theme_override_font_sizes/font_size", 56)
	title.set("theme_override_colors/font_color", Color(0, 0.9, 1, 1))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer1)

	var level_info = Label.new()
	level_info.name = "LevelInfo"
	level_info.text = "Level: 1"
	level_info.set("theme_override_font_sizes/font_size", 28)
	level_info.set("theme_override_colors/font_color", Color(0, 0.9, 1, 1))
	level_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(level_info)
	pause_level_info_label = level_info

	var score_info = Label.new()
	score_info.name = "ScoreInfo"
	score_info.text = "Score: 0"
	score_info.set("theme_override_font_sizes/font_size", 24)
	score_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(score_info)
	pause_score_info_label = score_info

	var lives_info = Label.new()
	lives_info.name = "LivesInfo"
	lives_info.text = "Lives: 3"
	lives_info.set("theme_override_font_sizes/font_size", 24)
	lives_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lives_info)
	pause_lives_info_label = lives_info

	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(spacer2)

	var resume_btn = Button.new()
	resume_btn.text = "RESUME"
	resume_btn.custom_minimum_size = Vector2(0, 60)
	resume_btn.set("theme_override_font_sizes/font_size", 32)
	resume_btn.set("theme_override_colors/font_color", Color(0.5, 1, 0.5, 1))
	resume_btn.pressed.connect(_on_resume_pressed)
	vbox.add_child(resume_btn)

	var restart_btn = Button.new()
	restart_btn.text = "RESTART LEVEL"
	restart_btn.custom_minimum_size = Vector2(0, 50)
	restart_btn.set("theme_override_font_sizes/font_size", 28)
	restart_btn.set("theme_override_colors/font_color", Color(0, 0.9, 1, 1))
	restart_btn.pressed.connect(_on_restart_pressed)
	vbox.add_child(restart_btn)

	var settings_btn = Button.new()
	settings_btn.text = "SETTINGS"
	settings_btn.custom_minimum_size = Vector2(0, 50)
	settings_btn.set("theme_override_font_sizes/font_size", 28)
	settings_btn.set("theme_override_colors/font_color", Color(0.9, 0.9, 0.9, 1))
	settings_btn.pressed.connect(_on_settings_pressed.bind(hud))
	vbox.add_child(settings_btn)

	var level_select_btn = Button.new()
	level_select_btn.text = "LEVEL SELECT"
	level_select_btn.custom_minimum_size = Vector2(0, 50)
	level_select_btn.set("theme_override_font_sizes/font_size", 26)
	level_select_btn.set("theme_override_colors/font_color", Color(0.7, 0.7, 0.7, 1))
	level_select_btn.pressed.connect(_on_level_select_pressed)
	vbox.add_child(level_select_btn)

	var menu_btn = Button.new()
	menu_btn.text = "MAIN MENU"
	menu_btn.custom_minimum_size = Vector2(0, 50)
	menu_btn.set("theme_override_font_sizes/font_size", 28)
	menu_btn.set("theme_override_colors/font_color", Color(0.7, 0.7, 0.7, 1))
	menu_btn.pressed.connect(_on_main_menu_pressed)
	vbox.add_child(menu_btn)

	var spacer3 = Control.new()
	spacer3.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer3)

	var hint = Label.new()
	hint.text = "ESC to resume"
	hint.set("theme_override_font_sizes/font_size", 16)
	hint.set("theme_override_colors/font_color", Color(0.5, 0.5, 0.5, 1))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint)

	pause_menu = menu
	return menu

func create_level_select_confirm(hud: Control) -> ConfirmationDialog:
	level_select_confirm = ConfirmationDialog.new()
	level_select_confirm.title = "Return to Level Select"
	level_select_confirm.dialog_text = "Return to level select and abandon this run?"
	level_select_confirm.confirmed.connect(_on_confirm_level_select)
	hud.add_child(level_select_confirm)
	return level_select_confirm

func update_info(game_manager: Node) -> void:
	if not game_manager:
		return
	if pause_level_info_label:
		var level_data = LevelLoader.get_level_info(game_manager.current_level)
		pause_level_info_label.text = "Level " + str(game_manager.current_level) + ": " + level_data.get("name", "Unknown")
	if pause_score_info_label:
		pause_score_info_label.text = "Score: " + str(game_manager.score)
	if pause_lives_info_label:
		pause_lives_info_label.text = "Lives: " + str(game_manager.lives)

func _on_resume_pressed() -> void:
	var game_manager = _find_game_manager()
	if game_manager:
		game_manager.set_state(game_manager.last_state_before_pause)

func _on_restart_pressed() -> void:
	var game_manager = _find_game_manager()
	if game_manager:
		game_manager.set_state(game_manager.GameState.PLAYING)
	MenuController.restart_current_level()

func _on_main_menu_pressed() -> void:
	var game_manager = _find_game_manager()
	if game_manager:
		game_manager.set_state(game_manager.GameState.PLAYING)
	MenuController.show_main_menu()

func _on_level_select_pressed() -> void:
	if settings_overlay:
		return
	if level_select_confirm:
		level_select_confirm.popup_centered()

func _on_confirm_level_select() -> void:
	var game_manager = _find_game_manager()
	if game_manager:
		game_manager.set_state(game_manager.GameState.PLAYING)
	MenuController.show_level_select()

func _on_settings_pressed(hud: Control) -> void:
	if settings_overlay:
		return
	var settings_scene = preload("res://scenes/ui/settings.tscn")
	settings_overlay = settings_scene.instantiate()
	settings_overlay.set_meta("opened_from_pause", true)
	settings_overlay.z_index = 200
	if settings_overlay.has_signal("closed_from_pause"):
		settings_overlay.closed_from_pause.connect(_on_settings_closed.bind(hud))
	hud.add_child(settings_overlay)
	if pause_menu:
		pause_menu.visible = false

func _on_settings_closed(hud: Control) -> void:
	if settings_overlay:
		settings_overlay.queue_free()
		settings_overlay = null
	if pause_menu:
		pause_menu.visible = true
	if hud.has_method("apply_settings_from_save"):
		hud.apply_settings_from_save()

func _find_game_manager() -> Node:
	var tree = Engine.get_main_loop() as SceneTree
	if tree:
		return tree.get_first_node_in_group("game_manager")
	return null
