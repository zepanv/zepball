extends Control

## HUD - Heads-Up Display for score, lives, and game info
## Uses fixed layout regions so mode changes update content instead of rearranging UI.

const _GameManagerScript = preload("res://scripts/game_manager.gd")
const PAUSE_HELPER_SCRIPT = preload("res://scripts/hud_pause_menu_helper.gd")
const DEBUG_HELPER_SCRIPT = preload("res://scripts/hud_debug_overlay_helper.gd")
const INTRO_HELPER_SCRIPT = preload("res://scripts/hud_level_intro_helper.gd")
const POWERUP_HELPER_SCRIPT = preload("res://scripts/hud_power_up_timers_helper.gd")
const UI_THEME = preload("res://scripts/ui/ui_theme.gd")

@onready var top_bar_card: PanelContainer = $SafeMargin/HUDVBox/TopBarCard
@onready var info_row: HBoxContainer = $SafeMargin/HUDVBox/InfoRow
@onready var objective_card: PanelContainer = $SafeMargin/HUDVBox/InfoRow/ObjectiveCard
@onready var score_caption: Label = $SafeMargin/HUDVBox/TopBarCard/TopBarMargin/TopBar/ScoreBlock/ScoreCaption
@onready var score_label: Label = $SafeMargin/HUDVBox/TopBarCard/TopBarMargin/TopBar/ScoreBlock/ScoreLabel
@onready var mode_label: Label = $SafeMargin/HUDVBox/TopBarCard/TopBarMargin/TopBar/CenterBlock/ModeLabel
@onready var mode_detail_label: Label = $SafeMargin/HUDVBox/TopBarCard/TopBarMargin/TopBar/CenterBlock/ModeDetailLabel
@onready var lives_caption: Label = $SafeMargin/HUDVBox/TopBarCard/TopBarMargin/TopBar/LivesBlock/LivesCaption
@onready var lives_label: Label = $SafeMargin/HUDVBox/TopBarCard/TopBarMargin/TopBar/LivesBlock/LivesLabel
@onready var objective_label: Label = $SafeMargin/HUDVBox/InfoRow/ObjectiveCard/ObjectiveMargin/ObjectiveLabel
@onready var powerup_container: VBoxContainer = $PowerUpIndicators
@onready var multiplier_card: PanelContainer = $MultiplierCard
@onready var multiplier_title_label: Label = $MultiplierCard/MultiplierMargin/MultiplierVBox/MultiplierTitleLabel
@onready var multiplier_value_label: Label = $MultiplierCard/MultiplierMargin/MultiplierVBox/MultiplierValueLabel
@onready var multiplier_breakdown_label: Label = $MultiplierCard/MultiplierMargin/MultiplierVBox/MultiplierBreakdownLabel
@onready var state_overlay: PanelContainer = $StateOverlay
@onready var state_title_label: Label = $StateOverlay/StateOverlayMargin/StateOverlayVBox/StateTitleLabel
@onready var state_detail_label: Label = $StateOverlay/StateOverlayMargin/StateOverlayVBox/StateDetailLabel
@onready var combo_overlay: PanelContainer = $ComboOverlay
@onready var combo_label: Label = $ComboOverlay/ComboMargin/ComboLabel

var combo_flash: ColorRect = null
var combo_flash_enabled: bool = true
var skip_level_intro: bool = false
var show_fps: bool = false
var debug_visible: bool = false
var game_manager_ref: Node = null
var multiplier_lines: PackedStringArray = PackedStringArray()
var _last_total_multiplier: float = 1.0
var _last_objective_text: String = ""
var _bonus_message_until_msec: int = 0

var pause_helper: RefCounted = null
var debug_helper: RefCounted = null
var intro_helper: RefCounted = null
var powerup_helper: RefCounted = null
var default_player_name_text: String = "PLAYER"

func _make_empty_stylebox() -> StyleBoxEmpty:
	return StyleBoxEmpty.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UI_THEME.apply_to(self)
	_apply_hud_theme()

	if PowerUpManager:
		PowerUpManager.effect_applied.connect(_on_effect_applied)
		PowerUpManager.effect_expired.connect(_on_effect_expired)

	pause_helper = PAUSE_HELPER_SCRIPT.new()
	var pause_menu = pause_helper.create_pause_menu(self)
	pause_menu.visible = false
	pause_menu.z_index = 100
	add_child(pause_menu)
	pause_helper.create_level_select_confirm(self)

	intro_helper = INTRO_HELPER_SCRIPT.new()
	var level_intro = intro_helper.create_level_intro()
	level_intro.visible = false
	add_child(level_intro)

	debug_helper = DEBUG_HELPER_SCRIPT.new()
	var debug_overlay = debug_helper.create_overlay()
	debug_overlay.visible = false
	add_child(debug_overlay)

	powerup_helper = POWERUP_HELPER_SCRIPT.new()

	combo_flash = ColorRect.new()
	combo_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	combo_flash.color = Color(1, 1, 1, 0)
	combo_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(combo_flash)

	combo_flash_enabled = SaveManager.get_combo_flash_enabled()
	skip_level_intro = SaveManager.get_skip_level_intro()
	show_fps = SaveManager.get_show_fps()
	debug_visible = show_fps
	if debug_helper.debug_overlay:
		debug_helper.debug_overlay.visible = debug_visible

	default_player_name_text = SaveManager.get_current_profile_name().to_upper()
	clear_objective_text()
	_configure_topbar_mode()
	_init_dynamic_elements()
	_refresh_processing_state()

func apply_settings_from_save() -> void:
	combo_flash_enabled = SaveManager.get_combo_flash_enabled()
	skip_level_intro = SaveManager.get_skip_level_intro()
	show_fps = SaveManager.get_show_fps()
	debug_visible = show_fps
	if debug_helper and debug_helper.debug_overlay:
		debug_helper.debug_overlay.visible = debug_visible
	_apply_hud_theme()
	_update_difficulty_label()
	_configure_topbar_mode()
	_refresh_processing_state()

func set_objective_text(text: String, pulse_on_change: bool = true, color_override: Color = Color(-1.0, -1.0, -1.0, -1.0)) -> void:
	if not objective_card or not objective_label:
		return
	var normalized := text.strip_edges()
	if not normalized.is_empty() and not normalized.begins_with("★"):
		normalized = "★ " + normalized
	info_row.visible = not normalized.is_empty()
	objective_card.visible = not normalized.is_empty()
	if color_override.a >= 0.0:
		objective_label.add_theme_color_override("font_color", color_override)
	else:
		objective_label.add_theme_color_override("font_color", UI_THEME.GOLD)
	objective_label.text = normalized
	if pulse_on_change and normalized != _last_objective_text and not normalized.is_empty():
		_pulse_card(objective_card, UI_THEME.GOLD)
	_last_objective_text = normalized

func clear_objective_text() -> void:
	set_objective_text("")

func set_blitz_push_status(remaining_seconds: int, rows_survived: int, interval_seconds: float) -> void:
	var seconds_left: int = max(0, remaining_seconds)
	var rows_value: int = max(0, rows_survived)
	var safe_interval: float = max(0.001, interval_seconds)
	var ratio_left: float = clampf(float(seconds_left) / safe_interval, 0.0, 1.0)
	var status_color: Color = UI_THEME.SUCCESS
	if ratio_left <= 0.33:
		status_color = UI_THEME.DANGER
	elif ratio_left <= 0.66:
		status_color = UI_THEME.GOLD
	set_objective_text("BLITZ PUSH IN: %ds | ROWS %d" % [seconds_left, rows_value], false, status_color)

func show_blitz_all_clear_bonus(points: int) -> void:
	if combo_overlay == null or combo_label == null:
		return
	var display_points: int = max(0, points)
	_bonus_message_until_msec = Time.get_ticks_msec() + 1800
	combo_overlay.visible = true
	combo_label.text = "ALL CLEAR BONUS +%d" % display_points
	UI_THEME.style_success(combo_label, 18)
	combo_overlay.modulate = Color(1, 1, 1, 1)
	combo_overlay.scale = Vector2(1.12, 1.12)
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(combo_overlay, "scale", Vector2.ONE, 0.2)

func _apply_hud_theme() -> void:
	top_bar_card.add_theme_stylebox_override("panel", _make_empty_stylebox())
	objective_card.add_theme_stylebox_override("panel", _make_empty_stylebox())
	multiplier_card.add_theme_stylebox_override("panel", _make_empty_stylebox())
	state_overlay.add_theme_stylebox_override("panel", _make_empty_stylebox())
	combo_overlay.add_theme_stylebox_override("panel", _make_empty_stylebox())

	UI_THEME.style_meta(score_caption)
	score_caption.add_theme_font_size_override("font_size", 12)
	UI_THEME.style_accent_value(score_label, 22)
	UI_THEME.style_title(mode_label)
	mode_label.add_theme_font_size_override("font_size", 20)
	UI_THEME.style_subtitle(mode_detail_label)
	mode_detail_label.add_theme_font_size_override("font_size", 13)
	UI_THEME.style_meta(lives_caption)
	lives_caption.add_theme_font_size_override("font_size", 12)
	UI_THEME.style_success(lives_label, 22)
	UI_THEME.style_warning(objective_label, 14)
	objective_label.uppercase = true
	UI_THEME.style_meta(multiplier_title_label)
	multiplier_title_label.add_theme_font_size_override("font_size", 11)
	UI_THEME.style_accent_value(multiplier_value_label, 22)
	UI_THEME.style_meta(multiplier_breakdown_label)
	multiplier_breakdown_label.add_theme_font_size_override("font_size", 11)
	UI_THEME.style_title(state_title_label)
	state_title_label.add_theme_font_size_override("font_size", 34)
	UI_THEME.style_subtitle(state_detail_label)
	state_detail_label.add_theme_font_size_override("font_size", 18)
	UI_THEME.style_warning(combo_label, 18)

func _init_dynamic_elements() -> void:
	if DifficultyManager and not DifficultyManager.difficulty_changed.is_connected(_on_difficulty_changed):
		DifficultyManager.difficulty_changed.connect(_on_difficulty_changed)

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
			if game_manager.has_signal("time_attack_timer_updated") and not game_manager.time_attack_timer_updated.is_connected(_on_time_attack_timer_updated):
				game_manager.time_attack_timer_updated.connect(_on_time_attack_timer_updated)
			if game_manager.has_signal("survival_wave_changed") and not game_manager.survival_wave_changed.is_connected(_on_survival_wave_changed):
				game_manager.survival_wave_changed.connect(_on_survival_wave_changed)
			if game_manager.has_signal("objective_assigned") and not game_manager.objective_assigned.is_connected(_on_objective_assigned):
				game_manager.objective_assigned.connect(_on_objective_assigned)
			if game_manager.has_signal("objective_progress") and not game_manager.objective_progress.is_connected(_on_objective_progress):
				game_manager.objective_progress.connect(_on_objective_progress)
			if game_manager.has_signal("objective_completed") and not game_manager.objective_completed.is_connected(_on_objective_completed):
				game_manager.objective_completed.connect(_on_objective_completed)
			if game_manager.has_signal("objective_failed") and not game_manager.objective_failed.is_connected(_on_objective_failed):
				game_manager.objective_failed.connect(_on_objective_failed)
		var score_value: Variant = game_manager.get("score")
		if score_value != null:
			_on_score_changed(int(score_value))
		var lives_value: Variant = game_manager.get("lives")
		if lives_value != null:
			_on_lives_changed(int(lives_value))
		var state_value: Variant = game_manager.get("game_state")
		if state_value != null:
			_on_game_state_changed(int(state_value))
		if game_manager.has_method("get_time_attack_elapsed_seconds"):
			_on_time_attack_timer_updated(game_manager.get_time_attack_elapsed_seconds())
		var wave_value: Variant = game_manager.get("current_wave")
		if wave_value != null:
			_on_survival_wave_changed(int(wave_value))

	_update_difficulty_label()
	_update_multiplier_display()

func _on_game_state_changed(new_state: int) -> void:
	if pause_helper.pause_menu:
		pause_helper.pause_menu.visible = (new_state == _GameManagerScript.GameState.PAUSED)
		if new_state == _GameManagerScript.GameState.PAUSED:
			pause_helper.update_info(_get_game_manager())

	match new_state:
		_GameManagerScript.GameState.GAME_OVER:
			_show_state_overlay("GAME OVER", "Press R to restart", "danger")
		_GameManagerScript.GameState.LEVEL_COMPLETE:
			_show_state_overlay("LEVEL COMPLETE", "Press R to continue", "success")
		_:
			_hide_state_overlay()

	_refresh_processing_state()

func _on_difficulty_changed(_new_difficulty: int) -> void:
	_update_difficulty_label()
	_update_multiplier_display()

func _on_combo_changed(new_combo: int) -> void:
	if _is_bonus_message_active():
		_update_multiplier_display()
		return
	if new_combo >= 3:
		combo_overlay.visible = true
		combo_label.text = "COMBO x%d!" % new_combo
		UI_THEME.style_warning(combo_label, 18)
		combo_overlay.modulate = Color(1, 1, 1, 1)
		combo_overlay.scale = Vector2(1.08, 1.08)
		var tween = create_tween()
		tween.tween_property(combo_overlay, "scale", Vector2.ONE, 0.2)
		if combo_flash_enabled:
			_play_combo_flash()
	else:
		combo_overlay.visible = false

	_update_multiplier_display()

func _on_combo_milestone(combo_value: int) -> void:
	if _is_bonus_message_active():
		return
	if not combo_overlay.visible:
		return

	var milestone_scale = min(1.12 + (combo_value / 80.0), 1.35)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(combo_overlay, "scale", Vector2(milestone_scale, milestone_scale), 0.3)
	tween.tween_property(combo_overlay, "scale", Vector2.ONE, 0.4)

func _on_score_changed(new_score: int) -> void:
	score_label.text = str(new_score)

func _on_lives_changed(new_lives: int) -> void:
	lives_label.text = str(new_lives)

func _on_effect_applied(type: int) -> void:
	powerup_helper.on_effect_applied(type, powerup_container)
	_refresh_processing_state()

func _on_effect_expired(type: int) -> void:
	powerup_helper.on_effect_expired(type, powerup_container)
	_refresh_processing_state()

func show_level_intro(level_id: int, level_name: String, level_description: String) -> void:
	if MenuController and MenuController.is_survival_mode:
		return
	intro_helper.show(self, level_id, level_name, level_description, skip_level_intro)

func show_survival_wave_intro(wave_number: int) -> void:
	if not intro_helper or not intro_helper.level_intro:
		return
	_configure_topbar_mode()
	intro_helper.show(self, wave_number, "WAVE %d" % wave_number, "Survive as long as possible.", false)

func show_survival_wave_countdown(next_wave_number: int) -> void:
	if not intro_helper or not intro_helper.level_intro:
		await get_tree().create_timer(3.0).timeout
		return

	intro_helper.skip_intro()
	intro_helper.level_intro.visible = true
	intro_helper.level_intro.modulate.a = 1.0
	if intro_helper.level_intro_num_label:
		intro_helper.level_intro_num_label.text = "WAVE %d INCOMING" % next_wave_number
	if intro_helper.level_intro_desc_label:
		intro_helper.level_intro_desc_label.text = ""

	for count in [3, 2, 1]:
		if intro_helper.level_intro_name_label:
			intro_helper.level_intro_name_label.text = "%d..." % count
		await get_tree().create_timer(1.0).timeout

	intro_helper.level_intro.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if intro_helper and intro_helper.is_showing() and event.is_action_pressed("launch_ball"):
		intro_helper.skip_intro()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	var game_manager = _get_game_manager()
	var is_paused = game_manager and game_manager.game_state == game_manager.GameState.PAUSED

	if _bonus_message_until_msec > 0 and Time.get_ticks_msec() >= _bonus_message_until_msec:
		_bonus_message_until_msec = 0
		_restore_combo_overlay_state()

	if not show_fps:
		debug_visible = false
		if powerup_helper.powerup_indicators.is_empty() and not is_paused:
			if pause_helper.pause_menu and pause_helper.pause_menu.visible:
				pause_helper.pause_menu.visible = false
			_refresh_processing_state()
			return

	if show_fps:
		debug_visible = debug_helper.handle_toggle_key(show_fps)

	powerup_helper.update_timers(delta)

	if show_fps and debug_visible and debug_helper.debug_overlay:
		debug_helper.update(delta, game_manager)

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
	if not combo_flash:
		return
	combo_flash.color = Color(1, 1, 1, 0.08)
	var tween = create_tween()
	tween.tween_property(combo_flash, "color", Color(1, 1, 1, 0.0), 0.25)

func _on_streak_changed(_new_streak: int) -> void:
	_update_multiplier_display()

func _configure_topbar_mode() -> void:
	var mode_text := "ZEPBALL"
	var detail_text := _get_run_descriptor()

	if MenuController and MenuController.is_blitz_mode:
		mode_text = "BLITZ"
		detail_text = "ROWS %d" % max(0, int(MenuController.get_blitz_rows_survived()))
	elif MenuController and MenuController.is_survival_mode:
		mode_text = "SURVIVAL"
		detail_text = "WAVE %d" % max(1, int(MenuController.get_survival_wave_reached()))
	else:
		var challenge_mode := "normal"
		if MenuController and MenuController.has_method("get_challenge_mode"):
			challenge_mode = str(MenuController.get_challenge_mode())

		match challenge_mode:
			MenuController.CHALLENGE_MODE_IRON_BALL:
				mode_text = "IRON BALL"
			MenuController.CHALLENGE_MODE_ONE_LIFE:
				mode_text = "ONE LIFE"
			MenuController.CHALLENGE_MODE_TIME_ATTACK:
				mode_text = "TIME ATTACK"
				detail_text = _format_time_mm_ss(0)

	mode_label.text = mode_text
	mode_detail_label.text = detail_text
	score_caption.text = "SCORE  |  %s" % DifficultyManager.get_difficulty_name().to_upper()
	lives_caption.text = "%s  |  LIVES" % default_player_name_text

func _show_state_overlay(title: String, detail: String, palette: String) -> void:
	state_overlay.visible = true
	state_title_label.text = title
	state_detail_label.text = detail
	UI_THEME.style_subtitle(state_detail_label)
	state_detail_label.add_theme_font_size_override("font_size", 18)
	match palette:
		"danger":
			UI_THEME.style_danger(state_title_label, 34)
		"success":
			UI_THEME.style_success(state_title_label, 34)
		_:
			UI_THEME.style_title(state_title_label)
			state_title_label.add_theme_font_size_override("font_size", 34)

func _hide_state_overlay() -> void:
	state_overlay.visible = false

func _on_time_attack_timer_updated(elapsed_seconds: int) -> void:
	if not MenuController:
		return
	if not MenuController.has_method("get_challenge_mode"):
		return
	var challenge_mode = str(MenuController.get_challenge_mode())
	if challenge_mode != MenuController.CHALLENGE_MODE_TIME_ATTACK:
		return
	mode_label.text = "TIME ATTACK"
	mode_detail_label.text = _format_time_mm_ss(max(0, elapsed_seconds))

func _on_survival_wave_changed(new_wave: int) -> void:
	if not MenuController or not MenuController.is_survival_mode:
		return
	mode_label.text = "SURVIVAL"
	mode_detail_label.text = "WAVE %d" % max(1, new_wave)

func _on_objective_assigned(objective_text: String) -> void:
	set_objective_text(objective_text)

func _on_objective_progress(objective_text: String) -> void:
	set_objective_text(objective_text)

func _on_objective_completed(objective_text: String) -> void:
	set_objective_text(objective_text)
	_pulse_card(objective_card, UI_THEME.SUCCESS)

func _on_objective_failed(objective_text: String) -> void:
	set_objective_text(objective_text)

func _format_time_mm_ss(total_seconds: int) -> String:
	var minutes: int = int(floor(float(total_seconds) / 60.0))
	var seconds = int(total_seconds % 60)
	return "%02d:%02d" % [minutes, seconds]

func _get_run_descriptor() -> String:
	if MenuController and MenuController.is_editor_test_mode:
		return "EDITOR TEST"
	if MenuController and MenuController.current_play_mode == MenuController.PlayMode.SET:
		return "SET RUN"
	return "LEVEL RUN"

func _update_difficulty_label() -> void:
	score_caption.text = "SCORE  |  %s" % DifficultyManager.get_difficulty_name().to_upper()

func _update_multiplier_display() -> void:
	var game_manager = _get_game_manager()
	if not game_manager:
		return

	multiplier_lines.clear()

	var difficulty_mult = DifficultyManager.get_score_multiplier()
	var difficulty_name = DifficultyManager.get_difficulty_name().to_upper()
	if difficulty_mult != 1.0:
		multiplier_lines.append("%s %sx" % [difficulty_name, str(snapped(difficulty_mult, 0.01))])

	if game_manager.combo >= 3:
		var combo_mult = 1.0 + (game_manager.combo - 3 + 1) * 0.1
		multiplier_lines.append("COMBO %sx" % str(snapped(combo_mult, 0.01)))

	if game_manager.no_miss_hits >= 5:
		var streak_tiers = floorf(game_manager.no_miss_hits / 5.0)
		var streak_mult = 1.0 + (streak_tiers * 0.1)
		multiplier_lines.append("STREAK %sx" % str(snapped(streak_mult, 0.01)))

	if PowerUpManager.is_double_score_active():
		multiplier_lines.append("DOUBLE SCORE 2.0x")

	if multiplier_lines.is_empty():
		multiplier_card.visible = false
		_last_total_multiplier = 1.0
		return

	var total_mult = difficulty_mult
	if game_manager.combo >= 3:
		total_mult *= (1.0 + (game_manager.combo - 3 + 1) * 0.1)
	if game_manager.no_miss_hits >= 5:
		var streak_tiers = floorf(game_manager.no_miss_hits / 5.0)
		total_mult *= (1.0 + (streak_tiers * 0.1))
	if PowerUpManager.is_double_score_active():
		total_mult *= 2.0

	multiplier_card.visible = true
	var rounded_total = snapped(total_mult, 0.01)
	multiplier_value_label.text = "%.2fx" % rounded_total
	multiplier_breakdown_label.text = "  ·  ".join(multiplier_lines)
	if absf(rounded_total - _last_total_multiplier) > 0.001:
		var pulse_color = UI_THEME.GOLD if rounded_total >= 2.0 else UI_THEME.PRIMARY
		_pulse_card(multiplier_card, pulse_color)
	_last_total_multiplier = rounded_total

	if total_mult >= 2.0:
		UI_THEME.style_warning(multiplier_value_label, 22)
	elif total_mult >= 1.25:
		UI_THEME.style_accent_value(multiplier_value_label, 22)
	else:
		UI_THEME.style_value(multiplier_value_label, 22)

func _pulse_card(card: Control, accent: Color) -> void:
	if not card:
		return
	card.scale = Vector2.ONE
	var flash := Color(accent.r, accent.g, accent.b, 0.95)
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "modulate", flash, 0.08)
	tween.parallel().tween_property(card, "scale", Vector2(1.03, 1.03), 0.08)
	tween.tween_property(card, "modulate", Color.WHITE, 0.18)
	tween.parallel().tween_property(card, "scale", Vector2.ONE, 0.18)

func _is_bonus_message_active() -> bool:
	return _bonus_message_until_msec > Time.get_ticks_msec()

func _restore_combo_overlay_state() -> void:
	UI_THEME.style_warning(combo_label, 18)
	var game_manager = _get_game_manager()
	if game_manager and int(game_manager.combo) >= 3:
		_on_combo_changed(int(game_manager.combo))
	else:
		combo_overlay.visible = false

func _get_game_manager() -> Node:
	if game_manager_ref and is_instance_valid(game_manager_ref):
		return game_manager_ref
	game_manager_ref = get_tree().get_first_node_in_group("game_manager")
	if game_manager_ref and is_instance_valid(game_manager_ref):
		return game_manager_ref
	return null
