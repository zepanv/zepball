extends Control

## High Scores Menu - Display cross-profile leaderboards

@onready var title_label = $Panel/VBoxContainer/TitleLabel
@onready var scores_container = $Panel/VBoxContainer/ScrollContainer/ScoresContainer
@onready var back_button = $BackButton
@onready var filter_tabs = $Panel/VBoxContainer/FilterTabs

var leaderboards: Dictionary = {}
var current_filter: String = "overall" # overall | sets | levels

func _ready():
	leaderboards = SaveManager.get_all_leaderboards()
	
	back_button.pressed.connect(_on_back_pressed)
	filter_tabs.tab_changed.connect(_on_filter_changed)
	
	_refresh_display()
	
	# Grab focus for controller
	await get_tree().process_frame
	filter_tabs.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		accept_event()

func _on_back_pressed():
	MenuController.show_main_menu()

func _on_filter_changed(tab_index: int):
	match tab_index:
		0: current_filter = "overall"
		1: current_filter = "sets"
		2: current_filter = "levels"
	_refresh_display()

func _refresh_display():
	# Clear current items
	for child in scores_container.get_children():
		child.queue_free()
	
	_add_column_headers()
		
	match current_filter:
		"overall":
			_display_overall()
		"sets":
			_display_sets()
		"levels":
			_display_levels()

func _display_overall():
	_add_header("TOP SCORES (ANY LEVEL)")
	
	var all_scores = []
	for l_key in leaderboards["levels"].keys():
		for entry in leaderboards["levels"][l_key]:
			var new_entry = entry.duplicate()
			new_entry["context"] = _get_level_name(l_key)
			all_scores.append(new_entry)
			
	all_scores.sort_custom(func(a, b): return a["score"] > b["score"])
	
	var count = min(all_scores.size(), 20)
	for i in range(count):
		_add_score_entry(all_scores[i], i + 1)
		
	if all_scores.is_empty():
		_add_empty_message("No high scores recorded yet.")

func _display_sets():
	_add_header("SET COMPLETION RECORDS")
	
	var all_sets = []
	for s_id in leaderboards["sets"].keys():
		for entry in leaderboards["sets"][s_id]:
			var new_entry = entry.duplicate()
			new_entry["context"] = _get_set_name(s_id)
			all_sets.append(new_entry)
			
	all_sets.sort_custom(func(a, b): return a["score"] > b["score"])
	
	for i in range(all_sets.size()):
		_add_score_entry(all_sets[i], i + 1)
		
	if all_sets.is_empty():
		_add_empty_message("No sets completed yet.")

func _display_levels():
	# Grouped by level
	for l_key in leaderboards["levels"].keys():
		_add_header(_get_level_name(l_key))
		var level_scores = leaderboards["levels"][l_key]
		for i in range(level_scores.size()):
			_add_score_entry(level_scores[i], i + 1)
			
	if leaderboards["levels"].is_empty():
		_add_empty_message("No levels completed yet.")

func _add_column_headers():
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	scores_container.add_child(hbox)
	
	var rank_h = Label.new()
	rank_h.text = "RANK"
	rank_h.custom_minimum_size = Vector2(50, 0)
	rank_h.add_theme_font_size_override("font_size", 12)
	rank_h.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	hbox.add_child(rank_h)
	
	var name_h = Label.new()
	name_h.text = "PLAYER"
	name_h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_h.add_theme_font_size_override("font_size", 12)
	name_h.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	hbox.add_child(name_h)
	
	var context_h = Label.new()
	if current_filter != "levels":
		context_h.text = "LEVEL/SET"
	else:
		context_h.text = ""
	context_h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	context_h.add_theme_font_size_override("font_size", 12)
	context_h.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	context_h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox.add_child(context_h)
	
	var score_h = Label.new()
	score_h.text = "SCORE"
	score_h.custom_minimum_size = Vector2(120, 0)
	score_h.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_h.add_theme_font_size_override("font_size", 12)
	score_h.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	hbox.add_child(score_h)
	
	var date_h = Label.new()
	date_h.text = "DATE"
	date_h.custom_minimum_size = Vector2(110, 0)
	date_h.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	date_h.add_theme_font_size_override("font_size", 12)
	date_h.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	hbox.add_child(date_h)
	
	var scroll_spacer = Control.new()
	scroll_spacer.custom_minimum_size = Vector2(20, 0)
	hbox.add_child(scroll_spacer)

func _add_header(text: String):
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0, 0.9, 1, 1))
	scores_container.add_child(label)
	
	var sep = HSeparator.new()
	scores_container.add_child(sep)

func _add_score_entry(entry: Dictionary, rank: int):
	var hbox = HBoxContainer.new()
	hbox.custom_minimum_size = Vector2(0, 35)
	hbox.add_theme_constant_override("separation", 15)
	scores_container.add_child(hbox)
	
	var rank_label = Label.new()
	rank_label.text = "#" + str(rank)
	rank_label.custom_minimum_size = Vector2(50, 0)
	rank_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	hbox.add_child(rank_label)
	
	var name_label = Label.new()
	name_label.text = entry["name"]
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	hbox.add_child(name_label)
	
	if entry.has("context"):
		var context_label = Label.new()
		context_label.text = entry["context"]
		context_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		context_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		context_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		context_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		hbox.add_child(context_label)
	
	var score_label = Label.new()
	score_label.text = str(entry["score"])
	score_label.custom_minimum_size = Vector2(120, 0)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	hbox.add_child(score_label)
	
	var date_label = Label.new()
	# Format date: 2026-02-15T12:00:00 -> 2026-02-15
	var date_val = entry["date"]
	var date_str = "---"
	if date_val != "Unknown":
		date_str = date_val.split("T")[0]
		
	date_label.text = date_str
	date_label.custom_minimum_size = Vector2(110, 0)
	date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	date_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	date_label.add_theme_font_size_override("font_size", 14)
	hbox.add_child(date_label)
	
	# Spacer for scrollbar
	var scroll_spacer = Control.new()
	scroll_spacer.custom_minimum_size = Vector2(20, 0)
	hbox.add_child(scroll_spacer)

func _add_empty_message(text: String):
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(0, 100)
	label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	scores_container.add_child(label)

func _get_level_name(level_key: String) -> String:
	var parts = level_key.split(":")
	if parts.size() != 2: return level_key
	var info = PackLoader.get_level_info(parts[0], int(parts[1]))
	return str(info.get("name", level_key))

func _get_set_name(pack_id: String) -> String:
	var pack = PackLoader.get_pack(pack_id)
	return str(pack.get("name", pack_id))
