extends Control

## HUD - Heads-Up Display for score, lives, and game info
## Updates in response to GameManager signals

@onready var score_label = $TopBar/ScoreLabel
@onready var lives_label = $TopBar/LivesLabel
@onready var logo_label = $TopBar/LogoLabel
@onready var powerup_container = $PowerUpIndicators

var pause_menu: Control = null
var difficulty_label: Label = null
var game_over_label: Label = null
var level_complete_label: Label = null
var combo_label: Label = null
var multiplier_label: Label = null
var level_intro: Control = null
var debug_overlay: PanelContainer = null
var debug_visible: bool = false
var combo_flash: ColorRect = null
var combo_flash_enabled: bool = true
var short_level_intro: bool = false
var skip_level_intro: bool = false
var show_fps: bool = false
var settings_overlay: Control = null
var level_select_confirm: ConfirmationDialog = null

func _ready():
	# Allow UI to process even when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

	print("HUD ready")
	# Initial values will be connected via main.gd signals

	# Connect to PowerUpManager signals
	if PowerUpManager:
		PowerUpManager.effect_applied.connect(_on_effect_applied)
		PowerUpManager.effect_expired.connect(_on_effect_expired)

	# Create pause menu
	pause_menu = create_pause_menu()
	pause_menu.visible = false
	pause_menu.z_index = 100  # Ensure pause menu is always on top
	add_child(pause_menu)

	# Confirmation dialog for leaving to level select
	level_select_confirm = ConfirmationDialog.new()
	level_select_confirm.title = "Return to Level Select"
	level_select_confirm.dialog_text = "Return to level select and abandon this run?"
	level_select_confirm.confirmed.connect(_on_confirm_level_select)
	add_child(level_select_confirm)

	# Create level intro display
	level_intro = create_level_intro()
	level_intro.visible = false
	add_child(level_intro)

	# Create debug overlay
	debug_overlay = create_debug_overlay()
	debug_overlay.visible = false
	add_child(debug_overlay)

	# Create combo flash overlay
	combo_flash = ColorRect.new()
	combo_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	combo_flash.color = Color(1, 1, 1, 0)  # White, fully transparent initially
	combo_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(combo_flash)

	# Load HUD-related settings
	combo_flash_enabled = SaveManager.get_combo_flash_enabled()
	short_level_intro = SaveManager.get_short_level_intro()
	skip_level_intro = SaveManager.get_skip_level_intro()
	show_fps = SaveManager.get_show_fps()
	debug_visible = show_fps
	if debug_overlay:
		debug_overlay.visible = debug_visible

	_init_dynamic_elements()

func apply_settings_from_save() -> void:
	"""Refresh HUD settings while paused"""
	combo_flash_enabled = SaveManager.get_combo_flash_enabled()
	short_level_intro = SaveManager.get_short_level_intro()
	skip_level_intro = SaveManager.get_skip_level_intro()
	show_fps = SaveManager.get_show_fps()
	debug_visible = show_fps
	if debug_overlay:
		debug_overlay.visible = debug_visible
	_init_dynamic_elements()

func _init_dynamic_elements() -> void:
	"""Create and connect dynamic HUD elements once"""
	if difficulty_label == null:
		difficulty_label = Label.new()
		difficulty_label.text = "DIFFICULTY: " + DifficultyManager.get_difficulty_name()
		difficulty_label.add_theme_font_size_override("font_size", 14)
		difficulty_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
		difficulty_label.position = Vector2(10, 50)  # Below top bar
		difficulty_label.size = Vector2(200, 25)
		difficulty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		add_child(difficulty_label)

	if DifficultyManager and not DifficultyManager.difficulty_changed.is_connected(_on_difficulty_changed):
		DifficultyManager.difficulty_changed.connect(_on_difficulty_changed)

	if game_over_label == null:
		game_over_label = Label.new()
		game_over_label.text = "GAME OVER\n\nPress R to Restart"
		game_over_label.add_theme_font_size_override("font_size", 64)
		game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		game_over_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		game_over_label.set_anchors_preset(Control.PRESET_CENTER)
		game_over_label.position = Vector2(-300, -100)
		game_over_label.size = Vector2(600, 200)
		game_over_label.modulate = Color(1.0, 0.3, 0.3)  # Red tint
		game_over_label.visible = false
		add_child(game_over_label)

	if level_complete_label == null:
		level_complete_label = Label.new()
		level_complete_label.text = "LEVEL COMPLETE!\n\nPress R to Continue"
		level_complete_label.add_theme_font_size_override("font_size", 64)
		level_complete_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		level_complete_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		level_complete_label.set_anchors_preset(Control.PRESET_CENTER)
		level_complete_label.position = Vector2(-400, -100)
		level_complete_label.size = Vector2(800, 200)
		level_complete_label.modulate = Color(0.3, 1.0, 0.3)  # Green tint
		level_complete_label.visible = false
		add_child(level_complete_label)

	if combo_label == null:
		combo_label = Label.new()
		combo_label.text = ""  # Hidden until combo starts
		combo_label.add_theme_font_size_override("font_size", 32)
		combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		combo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		combo_label.set_anchors_preset(Control.PRESET_CENTER)
		combo_label.position = Vector2(-150, 150)  # Below center
		combo_label.size = Vector2(300, 50)
		combo_label.modulate = Color(1.0, 0.8, 0.2)  # Gold color
		combo_label.visible = false
		combo_label.z_index = 10  # Below pause menu but above game
		add_child(combo_label)

	if multiplier_label == null:
		multiplier_label = Label.new()
		multiplier_label.text = ""
		multiplier_label.add_theme_font_size_override("font_size", 16)
		multiplier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		multiplier_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		multiplier_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
		multiplier_label.position = Vector2(10, 75)  # Below difficulty label on left
		multiplier_label.size = Vector2(240, 100)
		multiplier_label.modulate = Color(1.0, 1.0, 1.0, 0.9)
		multiplier_label.visible = false
		add_child(multiplier_label)

	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		if not game_manager.state_changed.is_connected(_on_game_state_changed):
			game_manager.state_changed.connect(_on_game_state_changed)
		if not game_manager.combo_changed.is_connected(_on_combo_changed):
			game_manager.combo_changed.connect(_on_combo_changed)
		if not game_manager.combo_milestone.is_connected(_on_combo_milestone):
			game_manager.combo_milestone.connect(_on_combo_milestone)
		if not game_manager.no_miss_streak_changed.is_connected(_on_streak_changed):
			game_manager.no_miss_streak_changed.connect(_on_streak_changed)

func _on_game_state_changed(new_state):
	"""Show/hide overlays based on game state"""
	if pause_menu:
		pause_menu.visible = (new_state == 3)  # 3 = PAUSED
		if new_state == 3:
			_update_pause_menu_info()
	if game_over_label:
		game_over_label.visible = (new_state == 5)  # 5 = GAME_OVER
	if level_complete_label:
		level_complete_label.visible = (new_state == 4)  # 4 = LEVEL_COMPLETE

func _on_difficulty_changed(_new_difficulty):
	"""Update difficulty display when changed"""
	if difficulty_label:
		difficulty_label.text = "DIFFICULTY: " + DifficultyManager.get_difficulty_name()
	# Update multiplier display when difficulty changes
	_update_multiplier_display()

func _on_combo_changed(new_combo: int):
	"""Update combo display"""
	if not combo_label:
		return

	if new_combo >= 3:
		combo_label.visible = true
		combo_label.text = "COMBO x" + str(new_combo) + "!"
		# Scale effect for visual feedback
		combo_label.scale = Vector2(1.2, 1.2)
		var tween = create_tween()
		tween.tween_property(combo_label, "scale", Vector2(1.0, 1.0), 0.2)
		if combo_flash_enabled:
			_play_combo_flash()
	else:
		combo_label.visible = false

	# Update multiplier display when combo changes
	_update_multiplier_display()

func _on_combo_milestone(combo_value: int):
	"""Make combo text grow larger at milestones"""
	if not combo_label:
		return

	# Bigger scale animation for milestones
	# Scale increases with higher combos (1.8x to 2.5x)
	var milestone_scale = min(1.8 + (combo_value / 50.0), 2.5)

	# Animate: grow big, then return to normal size
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(combo_label, "scale", Vector2(milestone_scale, milestone_scale), 0.3)
	tween.tween_property(combo_label, "scale", Vector2(1.0, 1.0), 0.4)

func _on_score_changed(new_score: int):
	"""Update score display"""
	score_label.text = "SCORE: " + str(new_score)

func _on_lives_changed(new_lives: int):
	"""Update lives display"""
	lives_label.text = "LIVES: " + str(new_lives)

func _on_effect_applied(type):
	"""Show power-up indicator when effect is applied"""
	if not powerup_container:
		return

	# Remove existing indicator for this type if any
	_on_effect_expired(type)

	# Create new indicator
	var indicator = create_powerup_indicator(type)
	if indicator:
		powerup_container.add_child(indicator)

func _on_effect_expired(type):
	"""Remove power-up indicator when effect expires"""
	if not powerup_container:
		return

	# Find and remove indicator for this type
	for child in powerup_container.get_children():
		if child.has_meta("powerup_type") and child.get_meta("powerup_type") == type:
			child.queue_free()

func create_powerup_indicator(type) -> Control:
	"""Create a visual indicator for an active power-up"""
	var indicator = PanelContainer.new()
	indicator.set_meta("powerup_type", type)

	# Style the panel
	indicator.custom_minimum_size = Vector2(120, 40)

	# Create content
	var hbox = HBoxContainer.new()
	indicator.add_child(hbox)

	# Power-up name label
	var name_label = Label.new()
	match type:
		0:  # EXPAND
			name_label.text = "BIG PADDLE"
			name_label.modulate = Color(0.3, 0.8, 0.3)  # Green
		1:  # CONTRACT
			name_label.text = "SMALL PADDLE"
			name_label.modulate = Color(0.8, 0.3, 0.3)  # Red
		2:  # SPEED_UP
			name_label.text = "FAST BALL"
			name_label.modulate = Color(1.0, 0.8, 0.3)  # Yellow
		4:  # BIG_BALL
			name_label.text = "BIG BALL"
			name_label.modulate = Color(0.3, 0.8, 0.3)  # Green
		5:  # SMALL_BALL
			name_label.text = "SMALL BALL"
			name_label.modulate = Color(0.8, 0.3, 0.3)  # Red
		6:  # SLOW_DOWN
			name_label.text = "SLOW BALL"
			name_label.modulate = Color(0.3, 0.6, 1.0)  # Blue
		7:  # EXTRA_LIFE (instant, shouldn't show timer but just in case)
			name_label.text = "EXTRA LIFE"
			name_label.modulate = Color(0.3, 0.8, 0.3)  # Green
		8:  # GRAB
			name_label.text = "GRAB"
			name_label.modulate = Color(0.3, 0.8, 0.3)  # Green
		9:  # BRICK_THROUGH
			name_label.text = "BRICK THROUGH"
			name_label.modulate = Color(0.3, 0.8, 0.3)  # Green
		10:  # DOUBLE_SCORE
			name_label.text = "DOUBLE SCORE"
			name_label.modulate = Color(1.0, 0.8, 0.0)  # Gold
		11:  # MYSTERY (instant, shouldn't show timer)
			name_label.text = "MYSTERY"
			name_label.modulate = Color(1.0, 1.0, 0.3)  # Yellow
		12:  # BOMB_BALL
			name_label.text = "BOMB BALL"
			name_label.modulate = Color(1.0, 0.4, 0.1)  # Orange-red
		13:  # AIR_BALL
			name_label.text = "AIR BALL"
			name_label.modulate = Color(0.3, 0.8, 0.3)  # Green
		14:  # MAGNET
			name_label.text = "MAGNET"
			name_label.modulate = Color(0.3, 0.8, 0.3)  # Green
		15:  # BLOCK
			name_label.text = "BLOCK"
			name_label.modulate = Color(0.3, 0.8, 0.3)  # Green

	name_label.add_theme_font_size_override("font_size", 14)
	hbox.add_child(name_label)

	# Timer label (updated each frame)
	var timer_label = Label.new()
	timer_label.name = "TimerLabel"
	timer_label.add_theme_font_size_override("font_size", 14)
	hbox.add_child(timer_label)

	return indicator

func _process(_delta):
	"""Update power-up timer displays and debug overlay"""
	# Toggle debug overlay with backtick key (`) - Mac friendly
	if show_fps:
		if Input.is_physical_key_pressed(KEY_QUOTELEFT) and not Input.is_key_pressed(KEY_SHIFT):
			if not get_meta("debug_key_handled", false):
				debug_visible = !debug_visible
				if debug_overlay:
					debug_overlay.visible = debug_visible
				set_meta("debug_key_handled", true)
		else:
			set_meta("debug_key_handled", false)
	else:
		if debug_overlay and debug_overlay.visible:
			debug_overlay.visible = false
		debug_visible = false
		set_meta("debug_key_handled", false)

	# Update power-up timers
	if powerup_container:
		for child in powerup_container.get_children():
			if child.has_meta("powerup_type"):
				var type = child.get_meta("powerup_type")
				var time_remaining = PowerUpManager.get_time_remaining(type)

				# Update timer label
				var timer_label = child.find_child("TimerLabel", true, false)
				if timer_label:
					timer_label.text = " %.1fs" % time_remaining

	# Update debug overlay
	if show_fps and debug_visible and debug_overlay:
		update_debug_overlay()

	# Ensure pause menu is visible when paused and no settings overlay is open
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		if game_manager.game_state == game_manager.GameState.PAUSED:
			if pause_menu and settings_overlay == null and pause_menu.visible == false:
				pause_menu.visible = true
		elif pause_menu and pause_menu.visible:
			pause_menu.visible = false

func _play_combo_flash():
	"""Flash the screen subtly on combo gains"""
	if not combo_flash:
		return
	combo_flash.color = Color(1, 1, 1, 0.08)
	var tween = create_tween()
	tween.tween_property(combo_flash, "color", Color(1, 1, 1, 0.0), 0.25)

func create_pause_menu() -> Control:
	"""Create the enhanced pause menu panel"""
	# Container for entire pause menu
	var menu = Control.new()
	menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu.mouse_filter = Control.MOUSE_FILTER_STOP  # Block input to game when paused

	# Semi-transparent dark overlay
	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.7)
	menu.add_child(overlay)

	# Center panel
	var center_container = CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu.add_child(center_container)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(400, 560)
	center_container.add_child(panel)

	# VBox for menu contents
	var vbox = VBoxContainer.new()
	vbox.set("theme_override_constants/separation", 20)
	panel.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "PAUSED"
	title.set("theme_override_font_sizes/font_size", 56)
	title.set("theme_override_colors/font_color", Color(0, 0.9, 1, 1))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer1)

	# Level display
	var level_info = Label.new()
	level_info.name = "LevelInfo"
	level_info.text = "Level: 1"
	level_info.set("theme_override_font_sizes/font_size", 28)
	level_info.set("theme_override_colors/font_color", Color(0, 0.9, 1, 1))
	level_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(level_info)

	# Score display
	var score_info = Label.new()
	score_info.name = "ScoreInfo"
	score_info.text = "Score: 0"
	score_info.set("theme_override_font_sizes/font_size", 24)
	score_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(score_info)

	# Lives display
	var lives_info = Label.new()
	lives_info.name = "LivesInfo"
	lives_info.text = "Lives: 3"
	lives_info.set("theme_override_font_sizes/font_size", 24)
	lives_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lives_info)

	# Spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(spacer2)

	# Resume button
	var resume_btn = Button.new()
	resume_btn.text = "RESUME"
	resume_btn.custom_minimum_size = Vector2(0, 60)
	resume_btn.set("theme_override_font_sizes/font_size", 32)
	resume_btn.set("theme_override_colors/font_color", Color(0.5, 1, 0.5, 1))
	resume_btn.pressed.connect(_on_pause_resume_pressed)
	vbox.add_child(resume_btn)

	# Restart button
	var restart_btn = Button.new()
	restart_btn.text = "RESTART LEVEL"
	restart_btn.custom_minimum_size = Vector2(0, 50)
	restart_btn.set("theme_override_font_sizes/font_size", 28)
	restart_btn.set("theme_override_colors/font_color", Color(0, 0.9, 1, 1))
	restart_btn.pressed.connect(_on_pause_restart_pressed)
	vbox.add_child(restart_btn)

	# Settings button
	var settings_btn = Button.new()
	settings_btn.text = "SETTINGS"
	settings_btn.custom_minimum_size = Vector2(0, 50)
	settings_btn.set("theme_override_font_sizes/font_size", 28)
	settings_btn.set("theme_override_colors/font_color", Color(0.9, 0.9, 0.9, 1))
	settings_btn.pressed.connect(_on_pause_settings_pressed)
	vbox.add_child(settings_btn)

	# Level select button
	var level_select_btn = Button.new()
	level_select_btn.text = "LEVEL SELECT"
	level_select_btn.custom_minimum_size = Vector2(0, 50)
	level_select_btn.set("theme_override_font_sizes/font_size", 26)
	level_select_btn.set("theme_override_colors/font_color", Color(0.7, 0.7, 0.7, 1))
	level_select_btn.pressed.connect(_on_pause_level_select_pressed)
	vbox.add_child(level_select_btn)

	# Main Menu button
	var menu_btn = Button.new()
	menu_btn.text = "MAIN MENU"
	menu_btn.custom_minimum_size = Vector2(0, 50)
	menu_btn.set("theme_override_font_sizes/font_size", 28)
	menu_btn.set("theme_override_colors/font_color", Color(0.7, 0.7, 0.7, 1))
	menu_btn.pressed.connect(_on_pause_main_menu_pressed)
	vbox.add_child(menu_btn)

	# Spacer
	var spacer3 = Control.new()
	spacer3.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer3)

	# Controls hint
	var hint = Label.new()
	hint.text = "ESC to resume"
	hint.set("theme_override_font_sizes/font_size", 16)
	hint.set("theme_override_colors/font_color", Color(0.5, 0.5, 0.5, 1))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint)

	return menu

func _update_pause_menu_info():
	"""Update level, score and lives info in pause menu"""
	if not pause_menu:
		return

	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if not game_manager:
		return

	# Update level
	var level_info = pause_menu.find_child("LevelInfo", true, false)
	if level_info:
		var level_data = LevelLoader.get_level_info(game_manager.current_level)
		level_info.text = "Level " + str(game_manager.current_level) + ": " + level_data.get("name", "Unknown")

	# Update score
	var score_info = pause_menu.find_child("ScoreInfo", true, false)
	if score_info:
		score_info.text = "Score: " + str(game_manager.score)

	# Update lives
	var lives_info = pause_menu.find_child("LivesInfo", true, false)
	if lives_info:
		lives_info.text = "Lives: " + str(game_manager.lives)

func _on_pause_resume_pressed():
	"""Resume game from pause menu"""
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		game_manager.set_state(game_manager.last_state_before_pause)

func _on_pause_restart_pressed():
	"""Restart level from pause menu"""
	# Unpause first
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		game_manager.set_state(game_manager.GameState.PLAYING)

	# Restart via MenuController
	MenuController.restart_current_level()

func _on_pause_main_menu_pressed():
	"""Return to main menu from pause"""
	# Unpause first
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		game_manager.set_state(game_manager.GameState.PLAYING)

	# Go to main menu
	MenuController.show_main_menu()

func _on_pause_level_select_pressed():
	"""Prompt to return to level select from pause"""
	if settings_overlay:
		return
	if level_select_confirm:
		level_select_confirm.popup_centered()

func _on_confirm_level_select():
	"""Return to level select after confirmation"""
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		game_manager.set_state(game_manager.GameState.PLAYING)
	MenuController.show_level_select()

func _on_pause_settings_pressed():
	"""Open settings overlay while staying paused"""
	if settings_overlay:
		return
	var settings_scene = preload("res://scenes/ui/settings.tscn")
	settings_overlay = settings_scene.instantiate()
	settings_overlay.set_meta("opened_from_pause", true)
	settings_overlay.z_index = 200
	if settings_overlay.has_signal("closed_from_pause"):
		settings_overlay.closed_from_pause.connect(_on_settings_closed_from_pause)
	add_child(settings_overlay)
	if pause_menu:
		pause_menu.visible = false

func _on_settings_closed_from_pause():
	"""Return to pause menu after closing settings"""
	if settings_overlay:
		settings_overlay.queue_free()
		settings_overlay = null
	if pause_menu:
		pause_menu.visible = true

func create_level_intro() -> Control:
	"""Create the level intro display panel"""
	var intro = Control.new()
	intro.set_anchors_preset(Control.PRESET_FULL_RECT)
	intro.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Center panel
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-300, -150)
	panel.custom_minimum_size = Vector2(600, 300)
	intro.add_child(panel)

	# VBox for content
	var vbox = VBoxContainer.new()
	vbox.set("theme_override_constants/separation", 15)
	panel.add_child(vbox)

	# Spacer for centering
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 40)
	spacer1.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer1)

	# Level number
	var level_num = Label.new()
	level_num.name = "LevelNum"
	level_num.text = "LEVEL 1"
	level_num.set("theme_override_font_sizes/font_size", 32)
	level_num.set("theme_override_colors/font_color", Color(0.7, 0.7, 0.7, 1))
	level_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(level_num)

	# Level name
	var level_name = Label.new()
	level_name.name = "LevelName"
	level_name.text = "Level Name"
	level_name.set("theme_override_font_sizes/font_size", 48)
	level_name.set("theme_override_colors/font_color", Color(0, 0.9, 1, 1))
	level_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(level_name)

	# Level description
	var level_desc = Label.new()
	level_desc.name = "LevelDesc"
	level_desc.text = "Description"
	level_desc.set("theme_override_font_sizes/font_size", 20)
	level_desc.set("theme_override_colors/font_color", Color(0.8, 0.8, 0.8, 1))
	level_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(level_desc)

	# Spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 40)
	spacer2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer2)

	return intro

func show_level_intro(level_id: int, level_name: String, level_description: String):
	"""Show level intro with fade in/out animation"""
	if not level_intro:
		return
	if skip_level_intro:
		return

	# Update text
	var level_num_label = level_intro.find_child("LevelNum", true, false)
	if level_num_label:
		level_num_label.text = "LEVEL " + str(level_id)

	var level_name_label = level_intro.find_child("LevelName", true, false)
	if level_name_label:
		level_name_label.text = level_name

	var level_desc_label = level_intro.find_child("LevelDesc", true, false)
	if level_desc_label:
		level_desc_label.text = level_description

	# Fade in/out animation
	level_intro.modulate.a = 0.0
	level_intro.visible = true

	var tween = create_tween()
	var hold_duration = 1.0 if short_level_intro else 2.5
	tween.tween_property(level_intro, "modulate:a", 1.0, 0.5)  # Fade in
	tween.tween_interval(hold_duration)  # Hold duration
	tween.tween_property(level_intro, "modulate:a", 0.0, 0.5)  # Fade out
	tween.tween_callback(func(): level_intro.visible = false)  # Hide when done

func create_debug_overlay() -> PanelContainer:
	"""Create the FPS/Debug overlay"""
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	panel.position = Vector2(10, -170)  # Bottom-left corner
	panel.custom_minimum_size = Vector2(250, 150)
	panel.modulate.a = 0.8  # Semi-transparent

	var vbox = VBoxContainer.new()
	vbox.set("theme_override_constants/separation", 5)
	panel.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "DEBUG INFO (` to toggle)"
	title.set("theme_override_font_sizes/font_size", 12)
	title.set("theme_override_colors/font_color", Color(1, 1, 0, 1))
	vbox.add_child(title)

	# FPS
	var fps_label = Label.new()
	fps_label.name = "FPS"
	fps_label.text = "FPS: 0"
	fps_label.set("theme_override_font_sizes/font_size", 14)
	vbox.add_child(fps_label)

	# Ball count
	var ball_count_label = Label.new()
	ball_count_label.name = "BallCount"
	ball_count_label.text = "Balls: 0"
	ball_count_label.set("theme_override_font_sizes/font_size", 14)
	vbox.add_child(ball_count_label)

	# Ball velocity
	var velocity_label = Label.new()
	velocity_label.name = "Velocity"
	velocity_label.text = "Velocity: (0, 0)"
	velocity_label.set("theme_override_font_sizes/font_size", 14)
	vbox.add_child(velocity_label)

	# Ball speed
	var speed_label = Label.new()
	speed_label.name = "Speed"
	speed_label.text = "Speed: 0"
	speed_label.set("theme_override_font_sizes/font_size", 14)
	vbox.add_child(speed_label)

	# Combo
	var combo_label_debug = Label.new()
	combo_label_debug.name = "Combo"
	combo_label_debug.text = "Combo: 0"
	combo_label_debug.set("theme_override_font_sizes/font_size", 14)
	vbox.add_child(combo_label_debug)

	return panel

func update_debug_overlay():
	"""Update debug overlay with current game info"""
	if not debug_overlay:
		return

	# Update FPS
	var fps_label = debug_overlay.find_child("FPS", true, false)
	if fps_label:
		fps_label.text = "FPS: " + str(Engine.get_frames_per_second())

	# Get main ball
	var balls = get_tree().get_nodes_in_group("ball")
	var main_ball = null
	for ball in balls:
		if ball.is_main_ball:
			main_ball = ball
			break

	# Update ball count
	var ball_count_label = debug_overlay.find_child("BallCount", true, false)
	if ball_count_label:
		ball_count_label.text = "Balls: " + str(balls.size())

	# Update velocity and speed
	if main_ball:
		var velocity_label = debug_overlay.find_child("Velocity", true, false)
		if velocity_label:
			velocity_label.text = "Velocity: (%.0f, %.0f)" % [main_ball.velocity.x, main_ball.velocity.y]

		var speed_label = debug_overlay.find_child("Speed", true, false)
		if speed_label:
			speed_label.text = "Speed: %.0f" % main_ball.current_speed

	# Update combo
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		var combo_label_debug = debug_overlay.find_child("Combo", true, false)
		if combo_label_debug:
			combo_label_debug.text = "Combo: " + str(game_manager.combo)

func _on_streak_changed(_new_streak: int):
	"""Update multiplier display when streak changes"""
	_update_multiplier_display()

func _update_multiplier_display():
	"""Update the multiplier display with all active bonuses"""
	if not multiplier_label:
		return

	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if not game_manager:
		return

	var multipliers = []

	# Difficulty multiplier
	var difficulty_mult = DifficultyManager.get_score_multiplier()
	var difficulty_name = DifficultyManager.get_difficulty_name()
	if difficulty_mult != 1.0:
		multipliers.append(difficulty_name + ": " + str(difficulty_mult) + "x")

	# Combo multiplier (only if active)
	if game_manager.combo >= 3:
		var combo_mult = 1.0 + (game_manager.combo - 3 + 1) * 0.1
		multipliers.append("Combo: " + str(snapped(combo_mult, 0.01)) + "x")

	# No-miss streak multiplier (only if >= 5 hits)
	if game_manager.no_miss_hits >= 5:
		var streak_tiers = floorf(game_manager.no_miss_hits / 5.0)
		var streak_mult = 1.0 + (streak_tiers * 0.1)
		multipliers.append("Streak: " + str(snapped(streak_mult, 0.01)) + "x")

	# Double score power-up
	if PowerUpManager.is_double_score_active():
		multipliers.append("Power-up: 2.0x")

	# Update label
	if multipliers.size() > 0:
		multiplier_label.text = "MULTIPLIERS:\n" + "\n".join(multipliers)
		multiplier_label.visible = true

		# Color based on total multiplier value
		var total_mult = difficulty_mult
		if game_manager.combo >= 3:
			total_mult *= (1.0 + (game_manager.combo - 3 + 1) * 0.1)
		if game_manager.no_miss_hits >= 5:
			var streak_tiers = floorf(game_manager.no_miss_hits / 5.0)
			total_mult *= (1.0 + (streak_tiers * 0.1))
		if PowerUpManager.is_double_score_active():
			total_mult *= 2.0

		# Color coding
		if total_mult >= 1.5:
			multiplier_label.modulate = Color(1.0, 0.5, 0.0, 0.9)  # Orange for high
		elif total_mult >= 1.1:
			multiplier_label.modulate = Color(1.0, 1.0, 0.3, 0.9)  # Yellow for medium
		else:
			multiplier_label.modulate = Color(1.0, 1.0, 1.0, 0.9)  # White for base
	else:
		multiplier_label.visible = false
