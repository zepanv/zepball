extends RefCounted
class_name HudLevelIntroHelper

## HudLevelIntroHelper - Level intro display with number/name/description extracted from hud.gd.

var level_intro: Control = null
var level_intro_num_label: Label = null
var level_intro_name_label: Label = null
var level_intro_desc_label: Label = null

func create_level_intro() -> Control:
	var intro = Control.new()
	intro.set_anchors_preset(Control.PRESET_FULL_RECT)
	intro.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-300, -150)
	panel.custom_minimum_size = Vector2(600, 300)
	intro.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set("theme_override_constants/separation", 15)
	panel.add_child(vbox)

	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 40)
	spacer1.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer1)

	var level_num = Label.new()
	level_num.name = "LevelNum"
	level_num.text = "LEVEL 1"
	level_num.set("theme_override_font_sizes/font_size", 32)
	level_num.set("theme_override_colors/font_color", Color(0.7, 0.7, 0.7, 1))
	level_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(level_num)
	level_intro_num_label = level_num

	var level_name = Label.new()
	level_name.name = "LevelName"
	level_name.text = "Level Name"
	level_name.set("theme_override_font_sizes/font_size", 48)
	level_name.set("theme_override_colors/font_color", Color(0, 0.9, 1, 1))
	level_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(level_name)
	level_intro_name_label = level_name

	var level_desc = Label.new()
	level_desc.name = "LevelDesc"
	level_desc.text = "Description"
	level_desc.set("theme_override_font_sizes/font_size", 20)
	level_desc.set("theme_override_colors/font_color", Color(0.8, 0.8, 0.8, 1))
	level_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(level_desc)
	level_intro_desc_label = level_desc

	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 40)
	spacer2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer2)

	level_intro = intro
	return intro

var _active_tween: Tween = null
var _showing: bool = false

func show(hud: Control, level_id: int, level_name: String, level_description: String, skip: bool) -> void:
	if not level_intro:
		return
	if skip:
		return

	if level_intro_num_label:
		level_intro_num_label.text = "LEVEL " + str(level_id)
	if level_intro_name_label:
		level_intro_name_label.text = level_name
	if level_intro_desc_label:
		level_intro_desc_label.text = level_description

	level_intro.modulate.a = 0.0
	level_intro.visible = true
	_showing = true

	_active_tween = hud.create_tween()
	_active_tween.tween_property(level_intro, "modulate:a", 1.0, 0.5)
	_active_tween.tween_interval(1.0)
	_active_tween.tween_property(level_intro, "modulate:a", 0.0, 0.5)
	_active_tween.tween_callback(_on_intro_finished)

func skip_intro() -> void:
	if not _showing:
		return
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()
	_on_intro_finished()

func is_showing() -> bool:
	return _showing

func _on_intro_finished() -> void:
	_showing = false
	_active_tween = null
	if level_intro:
		level_intro.visible = false
