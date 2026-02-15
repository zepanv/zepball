extends Control

## HUD - Heads-Up Display for score, lives, and game info
## Updates in response to GameManager signals

const PAUSE_HELPER_SCRIPT = preload("res://scripts/hud_pause_menu_helper.gd")
const DEBUG_HELPER_SCRIPT = preload("res://scripts/hud_debug_overlay_helper.gd")
const INTRO_HELPER_SCRIPT = preload("res://scripts/hud_level_intro_helper.gd")
const POWERUP_HELPER_SCRIPT = preload("res://scripts/hud_power_up_timers_helper.gd")

@onready var score_label: Label = $TopBar/ScoreLabel
@onready var lives_label: Label = $TopBar/LivesLabel
@onready var logo_label: Label = $TopBar/LogoVBox/LogoLabel
@onready var player_name_label: Label = $TopBar/LogoVBox/PlayerNameLabel
@onready var powerup_container: VBoxContainer = $PowerUpIndicators

var difficulty_label: Label = null
var game_over_label: Label = null
var level_complete_label: Label = null
var combo_label: Label = null
var multiplier_label: Label = null
var combo_flash: ColorRect = null
var combo_flash_enabled: bool = true
var skip_level_intro: bool = false
var show_fps: bool = false
var debug_visible: bool = false
var game_manager_ref: Node = null
var multiplier_lines: PackedStringArray = PackedStringArray()

var pause_helper: RefCounted = null
var debug_helper: RefCounted = null
var intro_helper: RefCounted = null
var powerup_helper: RefCounted = null

func _ready() -> void:
	# Allow UI to process even when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Connect to PowerUpManager signals
	if PowerUpManager:
		PowerUpManager.effect_applied.connect(_on_effect_applied)
		PowerUpManager.effect_expired.connect(_on_effect_expired)

	# Create pause menu via helper
	pause_helper = PAUSE_HELPER_SCRIPT.new()
	var pause_menu = pause_helper.create_pause_menu(self)
	pause_menu.visible = false
	pause_menu.z_index = 100
	add_child(pause_menu)
	pause_helper.create_level_select_confirm(self)

	# Create level intro via helper
	intro_helper = INTRO_HELPER_SCRIPT.new()
	var level_intro = intro_helper.create_level_intro()
	level_intro.visible = false
	add_child(level_intro)

	# Create debug overlay via helper
	debug_helper = DEBUG_HELPER_SCRIPT.new()
	var debug_overlay = debug_helper.create_overlay()
	debug_overlay.visible = false
	add_child(debug_overlay)

	# Create power-up timer helper
	powerup_helper = POWERUP_HELPER_SCRIPT.new()

	# Create combo flash overlay
	combo_flash = ColorRect.new()
	combo_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	combo_flash.color = Color(1, 1, 1, 0)
	combo_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(combo_flash)

	# Load HUD-related settings
	combo_flash_enabled = SaveManager.get_combo_flash_enabled()
	skip_level_intro = SaveManager.get_skip_level_intro()
	show_fps = SaveManager.get_show_fps()
	debug_visible = show_fps
	if debug_helper.debug_overlay:
		debug_helper.debug_overlay.visible = debug_visible
	
	if player_name_label:
		player_name_label.text = "CURRENT PLAYER: " + SaveManager.get_current_profile_name().to_upper()

	_init_dynamic_elements()
	_refresh_processing_state()

func apply_settings_from_save() -> void:
	"""Refresh HUD settings while paused"""
	combo_flash_enabled = SaveManager.get_combo_flash_enabled()
	skip_level_intro = SaveManager.get_skip_level_intro()
	show_fps = SaveManager.get_show_fps()
	debug_visible = show_fps
	if debug_helper and debug_helper.debug_overlay:
		debug_helper.debug_overlay.visible = debug_visible
	_init_dynamic_elements()
	_refresh_processing_state()

func _init_dynamic_elements() -> void:
	"""Create and connect dynamic HUD elements once"""
	if difficulty_label == null:
		difficulty_label = Label.new()
		difficulty_label.text = "DIFFICULTY: " + DifficultyManager.get_difficulty_name()
		difficulty_label.add_theme_font_size_override("font_size", 14)
		difficulty_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
		difficulty_label.position = Vector2(10, 50)
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
		game_over_label.modulate = Color(1.0, 0.3, 0.3)
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
		level_complete_label.modulate = Color(0.3, 1.0, 0.3)
		level_complete_label.visible = false
		add_child(level_complete_label)

	if combo_label == null:
		combo_label = Label.new()
		combo_label.text = ""
		combo_label.add_theme_font_size_override("font_size", 32)
		combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		combo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		combo_label.set_anchors_preset(Control.PRESET_CENTER)
		combo_label.position = Vector2(-150, 150)
		combo_label.size = Vector2(300, 50)
		combo_label.modulate = Color(1.0, 0.8, 0.2)
		combo_label.visible = false
		combo_label.z_index = 10
		add_child(combo_label)

	if multiplier_label == null:
		multiplier_label = Label.new()
		multiplier_label.text = ""
		multiplier_label.add_theme_font_size_override("font_size", 16)
		multiplier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		multiplier_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		multiplier_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
		multiplier_label.position = Vector2(10, 75)
		multiplier_label.size = Vector2(240, 100)
		multiplier_label.modulate = Color(1.0, 1.0, 1.0, 0.9)
		multiplier_label.visible = false
		add_child(multiplier_label)

	var game_manager = _get_game_manager()
	if game_manager:
		if not game_manager.state_changed.is_connected(_on_game_state_changed):
			game_manager.state_changed.connect(_on_game_state_changed)
		if not game_manager.combo_changed.is_connected(_on_combo_changed):
			game_manager.combo_changed.connect(_on_combo_changed)
		if not game_manager.combo_milestone.is_connected(_on_combo_milestone):
			game_manager.combo_milestone.connect(_on_combo_milestone)
		if not game_manager.no_miss_streak_changed.is_connected(_on_streak_changed):
			game_manager.no_miss_streak_changed.connect(_on_streak_changed)

func _on_game_state_changed(new_state: int) -> void:
	"""Show/hide overlays based on game state"""
	if pause_helper.pause_menu:
		pause_helper.pause_menu.visible = (new_state == 3)  # 3 = PAUSED
		if new_state == 3:
			pause_helper.update_info(_get_game_manager())
	if game_over_label:
		game_over_label.visible = (new_state == 5)  # 5 = GAME_OVER
	if level_complete_label:
		level_complete_label.visible = (new_state == 4)  # 4 = LEVEL_COMPLETE
	_refresh_processing_state()

func _on_difficulty_changed(_new_difficulty: int) -> void:
	"""Update difficulty display when changed"""
	if difficulty_label:
		difficulty_label.text = "DIFFICULTY: " + DifficultyManager.get_difficulty_name()
	_update_multiplier_display()

func _on_combo_changed(new_combo: int) -> void:
	"""Update combo display"""
	if not combo_label:
		return

	if new_combo >= 3:
		combo_label.visible = true
		combo_label.text = "COMBO x" + str(new_combo) + "!"
		combo_label.scale = Vector2(1.2, 1.2)
		var tween = create_tween()
		tween.tween_property(combo_label, "scale", Vector2(1.0, 1.0), 0.2)
		if combo_flash_enabled:
			_play_combo_flash()
	else:
		combo_label.visible = false

	_update_multiplier_display()

func _on_combo_milestone(combo_value: int) -> void:
	"""Make combo text grow larger at milestones"""
	if not combo_label:
		return

	var milestone_scale = min(1.8 + (combo_value / 50.0), 2.5)

	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(combo_label, "scale", Vector2(milestone_scale, milestone_scale), 0.3)
	tween.tween_property(combo_label, "scale", Vector2(1.0, 1.0), 0.4)

func _on_score_changed(new_score: int) -> void:
	"""Update score display"""
	score_label.text = "SCORE: " + str(new_score)

func _on_lives_changed(new_lives: int) -> void:
	"""Update lives display"""
	lives_label.text = "LIVES: " + str(new_lives)

func _on_effect_applied(type: int) -> void:
	"""Show power-up indicator when effect is applied"""
	powerup_helper.on_effect_applied(type, powerup_container)
	_refresh_processing_state()

func _on_effect_expired(type: int) -> void:
	"""Remove power-up indicator when effect expires"""
	powerup_helper.on_effect_expired(type, powerup_container)
	_refresh_processing_state()

func show_level_intro(level_id: int, level_name: String, level_description: String):
	"""Show level intro with fade in/out animation"""
	intro_helper.show(self, level_id, level_name, level_description, skip_level_intro)

func _unhandled_input(event: InputEvent) -> void:
	if intro_helper and intro_helper.is_showing() and event.is_action_pressed("launch_ball"):
		intro_helper.skip_intro()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	"""Update power-up timer displays and debug overlay"""
	var game_manager = _get_game_manager()
	var is_paused = game_manager and game_manager.game_state == game_manager.GameState.PAUSED

	if not show_fps:
		debug_visible = false
		if powerup_helper.powerup_indicators.is_empty() and not is_paused:
			if pause_helper.pause_menu and pause_helper.pause_menu.visible:
				pause_helper.pause_menu.visible = false
			_refresh_processing_state()
			return

	# Toggle debug overlay with backtick key
	if show_fps:
		debug_visible = debug_helper.handle_toggle_key(show_fps)

	# Update power-up timers
	powerup_helper.update_timers(delta)

	# Update debug overlay
	if show_fps and debug_visible and debug_helper.debug_overlay:
		debug_helper.update(delta, game_manager)

	# Ensure pause menu is visible when paused and no settings overlay is open
	if is_paused:
		if pause_helper.pause_menu and pause_helper.settings_overlay == null and pause_helper.pause_menu.visible == false:
			pause_helper.pause_menu.visible = true
	elif pause_helper.pause_menu and pause_helper.pause_menu.visible:
		pause_helper.pause_menu.visible = false

func _refresh_processing_state() -> void:
	var game_manager = _get_game_manager()
	var is_paused = game_manager and game_manager.game_state == game_manager.GameState.PAUSED
	var should_process = show_fps or not powerup_helper.powerup_indicators.is_empty() or is_paused
	set_process(should_process)

func _play_combo_flash() -> void:
	"""Flash the screen subtly on combo gains"""
	if not combo_flash:
		return
	combo_flash.color = Color(1, 1, 1, 0.08)
	var tween = create_tween()
	tween.tween_property(combo_flash, "color", Color(1, 1, 1, 0.0), 0.25)

func _on_streak_changed(_new_streak: int) -> void:
	"""Update multiplier display when streak changes"""
	_update_multiplier_display()

func _update_multiplier_display() -> void:
	"""Update the multiplier display with all active bonuses"""
	if not multiplier_label:
		return

	var game_manager = _get_game_manager()
	if not game_manager:
		return

	multiplier_lines.clear()

	var difficulty_mult = DifficultyManager.get_score_multiplier()
	var difficulty_name = DifficultyManager.get_difficulty_name()
	if difficulty_mult != 1.0:
		multiplier_lines.append(difficulty_name + ": " + str(difficulty_mult) + "x")

	if game_manager.combo >= 3:
		var combo_mult = 1.0 + (game_manager.combo - 3 + 1) * 0.1
		multiplier_lines.append("Combo: " + str(snapped(combo_mult, 0.01)) + "x")

	if game_manager.no_miss_hits >= 5:
		var streak_tiers = floorf(game_manager.no_miss_hits / 5.0)
		var streak_mult = 1.0 + (streak_tiers * 0.1)
		multiplier_lines.append("Streak: " + str(snapped(streak_mult, 0.01)) + "x")

	if PowerUpManager.is_double_score_active():
		multiplier_lines.append("Power-up: 2.0x")

	if multiplier_lines.size() > 0:
		multiplier_label.text = "MULTIPLIERS:\n" + "\n".join(multiplier_lines)
		multiplier_label.visible = true

		var total_mult = difficulty_mult
		if game_manager.combo >= 3:
			total_mult *= (1.0 + (game_manager.combo - 3 + 1) * 0.1)
		if game_manager.no_miss_hits >= 5:
			var streak_tiers = floorf(game_manager.no_miss_hits / 5.0)
			total_mult *= (1.0 + (streak_tiers * 0.1))
		if PowerUpManager.is_double_score_active():
			total_mult *= 2.0

		if total_mult >= 1.5:
			multiplier_label.modulate = Color(1.0, 0.5, 0.0, 0.9)
		elif total_mult >= 1.1:
			multiplier_label.modulate = Color(1.0, 1.0, 0.3, 0.9)
		else:
			multiplier_label.modulate = Color(1.0, 1.0, 1.0, 0.9)
	else:
		multiplier_label.visible = false

func _get_game_manager() -> Node:
	if game_manager_ref and is_instance_valid(game_manager_ref):
		return game_manager_ref
	game_manager_ref = get_tree().get_first_node_in_group("game_manager")
	if game_manager_ref and is_instance_valid(game_manager_ref):
		return game_manager_ref
	return null
