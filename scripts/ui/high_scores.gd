extends Control

## High Scores Menu - Display cross-profile leaderboards with a shared layout contract
const UI_THEME = preload("res://scripts/ui/ui_theme.gd")
const ROW_SCENE = preload("res://scenes/ui/components/high_score_row.tscn")

const FILTER_TABS := [
	{"id": "overall", "title": "OVERALL"},
	{"id": "levels", "title": "LEVELS"},
	{"id": "sets", "title": "SETS"},
	{"id": "survival", "title": "SURVIVAL"},
	{"id": "blitz", "title": "BLITZ"}
]

const SET_FILTERS := [
	{
		"id": "normal",
		"title": "NORMAL",
		"leaderboard_key": "sets",
		"header": "SET COMPLETION RECORDS",
		"subtitle": "Best full-set runs.",
		"empty_title": "No set records yet.",
		"empty_hint": "Complete a full set to appear here.",
		"score_mode": "score"
	},
	{
		"id": "iron_ball",
		"title": "IRON BALL",
		"leaderboard_key": "iron_ball_sets",
		"header": "IRON BALL SET RECORDS",
		"subtitle": "No power-ups allowed.",
		"empty_title": "No Iron Ball runs yet.",
		"empty_hint": "Finish an Iron Ball set to claim this board.",
		"score_mode": "score"
	},
	{
		"id": "one_life",
		"title": "ONE LIFE",
		"leaderboard_key": "one_life_sets",
		"header": "ONE LIFE SET RECORDS",
		"subtitle": "One life, one chance.",
		"empty_title": "No One Life runs yet.",
		"empty_hint": "Finish a One Life set to appear here.",
		"score_mode": "score"
	},
	{
		"id": "time_attack",
		"title": "TIME ATTACK",
		"leaderboard_key": "time_attack_sets",
		"header": "TIME ATTACK SET RECORDS",
		"subtitle": "Fastest set completions.",
		"empty_title": "No Time Attack runs yet.",
		"empty_hint": "Finish a Time Attack set to post a time.",
		"score_mode": "time"
	}
]

@onready var background: ColorRect = $Background
@onready var panel: PanelContainer = $ScreenMargin/CenterContainer/Panel
@onready var title_label: Label = $ScreenMargin/CenterContainer/Panel/MarginContainer/VBoxContainer/HeaderContainer/TitleLabel
@onready var subtitle_label: Label = $ScreenMargin/CenterContainer/Panel/MarginContainer/VBoxContainer/HeaderContainer/SubtitleLabel
@onready var toolbar_panel: PanelContainer = $ScreenMargin/CenterContainer/Panel/MarginContainer/VBoxContainer/ToolbarPanel
@onready var filter_tabs: TabBar = $ScreenMargin/CenterContainer/Panel/MarginContainer/VBoxContainer/ToolbarPanel/MarginContainer/ToolbarRow/FilterTabs
@onready var set_filter_container: HBoxContainer = $ScreenMargin/CenterContainer/Panel/MarginContainer/VBoxContainer/ToolbarPanel/MarginContainer/ToolbarRow/SetFilterContainer
@onready var set_filter_label: Label = $ScreenMargin/CenterContainer/Panel/MarginContainer/VBoxContainer/ToolbarPanel/MarginContainer/ToolbarRow/SetFilterContainer/SetFilterLabel
@onready var set_filter_dropdown: OptionButton = $ScreenMargin/CenterContainer/Panel/MarginContainer/VBoxContainer/ToolbarPanel/MarginContainer/ToolbarRow/SetFilterContainer/SetFilterDropdown
@onready var column_header_panel: PanelContainer = $ScreenMargin/CenterContainer/Panel/MarginContainer/VBoxContainer/ColumnHeaderPanel
@onready var rank_header_label: Label = $ScreenMargin/CenterContainer/Panel/MarginContainer/VBoxContainer/ColumnHeaderPanel/MarginContainer/HeaderRow/RankHeaderLabel
@onready var player_header_label: Label = $ScreenMargin/CenterContainer/Panel/MarginContainer/VBoxContainer/ColumnHeaderPanel/MarginContainer/HeaderRow/PlayerHeaderLabel
@onready var context_header_label: Label = $ScreenMargin/CenterContainer/Panel/MarginContainer/VBoxContainer/ColumnHeaderPanel/MarginContainer/HeaderRow/ContextHeaderLabel
@onready var score_header_label: Label = $ScreenMargin/CenterContainer/Panel/MarginContainer/VBoxContainer/ColumnHeaderPanel/MarginContainer/HeaderRow/ScoreHeaderLabel
@onready var date_header_label: Label = $ScreenMargin/CenterContainer/Panel/MarginContainer/VBoxContainer/ColumnHeaderPanel/MarginContainer/HeaderRow/DateHeaderLabel
@onready var scroll_container: ScrollContainer = $ScreenMargin/CenterContainer/Panel/MarginContainer/VBoxContainer/ScrollContainer
@onready var scores_container: VBoxContainer = $ScreenMargin/CenterContainer/Panel/MarginContainer/VBoxContainer/ScrollContainer/ScoresContainer
@onready var footer_panel: PanelContainer = $ScreenMargin/CenterContainer/Panel/MarginContainer/VBoxContainer/FooterPanel
@onready var footer_hint_label: Label = $ScreenMargin/CenterContainer/Panel/MarginContainer/VBoxContainer/FooterPanel/MarginContainer/FooterRow/FooterHintLabel
@onready var back_button: Button = $ScreenMargin/CenterContainer/Panel/MarginContainer/VBoxContainer/FooterPanel/MarginContainer/FooterRow/BackButton

var leaderboards: Dictionary = {}
var current_filter: String = "overall"
var current_set_challenge_filter: String = "normal"

func _ready() -> void:
	_apply_theme()
	_configure_filter_tabs()
	_configure_set_filter_dropdown()
	leaderboards = SaveManager.get_all_leaderboards()

	back_button.pressed.connect(_on_back_pressed)
	filter_tabs.tab_changed.connect(_on_filter_changed)
	set_filter_dropdown.item_selected.connect(_on_set_filter_selected)

	_refresh_display()

	await get_tree().process_frame
	filter_tabs.grab_focus()

func _apply_theme() -> void:
	UI_THEME.apply_to(self)
	UI_THEME.style_background(background)
	UI_THEME.style_panel(panel, UI_THEME.PANEL_BORDER_ACCENT)
	UI_THEME.style_title_large(title_label)
	UI_THEME.style_subtitle(subtitle_label)
	UI_THEME.style_flush_panel(toolbar_panel)
	UI_THEME.style_flush_panel(column_header_panel)
	UI_THEME.style_flush_panel(footer_panel)
	_style_column_header(rank_header_label)
	_style_column_header(player_header_label)
	_style_column_header(context_header_label)
	_style_column_header(score_header_label)
	_style_column_header(date_header_label)
	UI_THEME.style_meta(set_filter_label)
	UI_THEME.style_option_button(set_filter_dropdown)
	UI_THEME.style_meta(footer_hint_label)
	UI_THEME.style_muted_button(back_button)

func _style_column_header(label: Label) -> void:
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", UI_THEME.TEXT_MUTED)
	label.uppercase = true

func _configure_filter_tabs() -> void:
	filter_tabs.clear_tabs()
	for tab_def in FILTER_TABS:
		filter_tabs.add_tab(str(tab_def.get("title", "")))
	filter_tabs.current_tab = _get_filter_index(current_filter)

func _configure_set_filter_dropdown() -> void:
	set_filter_dropdown.clear()
	for set_filter in SET_FILTERS:
		set_filter_dropdown.add_item(str(set_filter.get("title", "")))
	set_filter_dropdown.select(_get_set_filter_index(current_set_challenge_filter))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		accept_event()

func _on_back_pressed() -> void:
	MenuController.show_main_menu()

func _on_filter_changed(tab_index: int) -> void:
	current_filter = str(FILTER_TABS[_clamp_index(tab_index, FILTER_TABS.size())].get("id", "overall"))
	_refresh_display()

func _on_set_filter_selected(index: int) -> void:
	current_set_challenge_filter = str(SET_FILTERS[_clamp_index(index, SET_FILTERS.size())].get("id", "normal"))
	if current_filter == "sets":
		_refresh_display()

func _refresh_display() -> void:
	for child in scores_container.get_children():
		child.queue_free()

	_sync_filter_controls()
	scroll_container.scroll_vertical = 0

	match current_filter:
		"overall":
			_render_overall_view()
		"levels":
			_render_levels_view()
		"sets":
			_render_sets_view()
		"survival":
			_render_survival_view()
		"blitz":
			_render_blitz_view()
		_:
			_render_overall_view()

func _sync_filter_controls() -> void:
	var showing_set_filter := current_filter == "sets"
	set_filter_container.visible = showing_set_filter
	set_filter_dropdown.disabled = not showing_set_filter
	column_header_panel.visible = true

	filter_tabs.focus_neighbor_bottom = filter_tabs.get_path_to(back_button)
	back_button.focus_neighbor_top = back_button.get_path_to(filter_tabs)

	if showing_set_filter:
		filter_tabs.focus_neighbor_right = filter_tabs.get_path_to(set_filter_dropdown)
		set_filter_dropdown.focus_neighbor_left = set_filter_dropdown.get_path_to(filter_tabs)
		set_filter_dropdown.focus_neighbor_bottom = set_filter_dropdown.get_path_to(back_button)
		back_button.focus_neighbor_top = back_button.get_path_to(set_filter_dropdown)
	else:
		filter_tabs.focus_neighbor_right = NodePath("")

func _render_overall_view() -> void:
	_set_view_text(
		"Best scores across all profiles.",
		""
	)
	_set_column_headers("LEVEL", true, "SCORE")

	var all_scores: Array[Dictionary] = []
	for level_key in leaderboards.get("levels", {}).keys():
		for entry_variant in leaderboards.get("levels", {}).get(level_key, []):
			if not (entry_variant is Dictionary):
				continue
			var entry: Dictionary = (entry_variant as Dictionary).duplicate()
			entry["context"] = _get_level_name(str(level_key))
			all_scores.append(entry)

	all_scores.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("score", 0)) > int(b.get("score", 0))
	)

	if all_scores.is_empty():
		_add_empty_state("No high scores yet.", "Complete any level to start.")
		return

	var count: int = min(all_scores.size(), 20)
	for index in range(count):
		_add_score_row(all_scores[index], index + 1, true, "score", index % 2 == 1)

func _render_levels_view() -> void:
	_set_view_text(
		"Per-level leaderboards.",
		""
	)
	_set_column_headers("LEVEL", true, "SCORE")

	var level_boards: Dictionary = leaderboards.get("levels", {})
	if level_boards.is_empty():
		_add_empty_state("No levels completed yet.", "Play a level to get started.")
		return

	for level_key in _get_sorted_level_keys():
		var level_scores: Array = level_boards.get(level_key, [])
		if level_scores.is_empty():
			continue
		for index in range(level_scores.size()):
			var entry_variant = level_scores[index]
			if not (entry_variant is Dictionary):
				continue
			var entry: Dictionary = (entry_variant as Dictionary).duplicate()
			entry["context"] = _get_level_name(level_key)
			_add_score_row(entry, index + 1, true, "score", index % 2 == 1)

func _render_sets_view() -> void:
	var set_filter := _get_selected_set_filter()
	_set_view_text(
		str(set_filter.get("subtitle", "")),
		""
	)
	_set_column_headers("SET", true, "BEST TIME" if str(set_filter.get("score_mode", "score")) == "time" else "SCORE")

	var selected_leaderboard: Dictionary = leaderboards.get(str(set_filter.get("leaderboard_key", "sets")), {})
	var all_sets: Array[Dictionary] = []
	for pack_id in _get_sorted_pack_ids(selected_leaderboard):
		for entry_variant in selected_leaderboard.get(pack_id, []):
			if not (entry_variant is Dictionary):
				continue
			var entry: Dictionary = (entry_variant as Dictionary).duplicate()
			entry["context"] = _get_set_name(pack_id)
			all_sets.append(entry)

	var score_mode := str(set_filter.get("score_mode", "score"))
	if score_mode == "time":
		all_sets.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			var score_a := int(a.get("score", 0))
			var score_b := int(b.get("score", 0))
			if score_a != score_b:
				return score_a < score_b
			var date_a := str(a.get("date", "9999-12-31T23:59:59"))
			var date_b := str(b.get("date", "9999-12-31T23:59:59"))
			if date_a != date_b:
				return date_a < date_b
			return str(a.get("name", "")) < str(b.get("name", ""))
		)
	else:
		all_sets.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return int(a.get("score", 0)) > int(b.get("score", 0))
		)

	if all_sets.is_empty():
		_add_empty_state(str(set_filter.get("empty_title", "No runs yet.")), str(set_filter.get("empty_hint", "")))
		return

	for index in range(all_sets.size()):
		_add_score_row(all_sets[index], index + 1, true, score_mode, index % 2 == 1)

func _render_survival_view() -> void:
	_set_view_text(
		"Endless run high scores.",
		""
	)
	_set_column_headers("WAVE", true, "SCORE")

	var survival_runs: Array = leaderboards.get("survival_runs", [])
	if survival_runs.is_empty():
		_add_empty_state("No Survival runs yet.", "Start an Endless run to claim a spot.")
		return

	for index in range(survival_runs.size()):
		var run_variant = survival_runs[index]
		if not (run_variant is Dictionary):
			continue
		var run_entry: Dictionary = (run_variant as Dictionary).duplicate()
		run_entry["context"] = "WAVE %d" % int(run_entry.get("wave", 1))
		_add_score_row(run_entry, index + 1, true, "score", index % 2 == 1)

func _render_blitz_view() -> void:
	_set_view_text(
		"Endless push-mode high scores.",
		""
	)
	_set_column_headers("ROWS", true, "SCORE")

	var blitz_runs: Array = leaderboards.get("blitz_runs", [])
	if blitz_runs.is_empty():
		_add_empty_state("No Blitz runs yet.", "Start a Blitz run to claim a spot.")
		return

	for index in range(blitz_runs.size()):
		var run_variant = blitz_runs[index]
		if not (run_variant is Dictionary):
			continue
		var run_entry: Dictionary = (run_variant as Dictionary).duplicate()
		run_entry["context"] = "ROWS %d" % int(run_entry.get("rows", 1))
		_add_score_row(run_entry, index + 1, true, "score", index % 2 == 1)

func _set_view_text(subtitle_text: String, footer_text: String) -> void:
	subtitle_label.text = subtitle_text
	footer_hint_label.text = footer_text

func _set_column_headers(context_title: String, show_context: bool, score_title: String) -> void:
	rank_header_label.text = "RANK"
	player_header_label.text = "PLAYER"
	context_header_label.visible = show_context
	context_header_label.text = context_title
	score_header_label.text = score_title
	date_header_label.text = "DATE"

func _add_section_header(text_value: String) -> void:
	var label := Label.new()
	label.text = text_value.to_upper()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	UI_THEME.style_section_title(label)
	scores_container.add_child(label)

	var separator := HSeparator.new()
	scores_container.add_child(separator)

func _add_score_row(entry: Dictionary, rank: int, show_context: bool, score_mode: String, alternate: bool) -> void:
	var row = ROW_SCENE.instantiate()
	scores_container.add_child(row)

	var current_name := SaveManager.get_current_profile_name()
	var is_current_player := str(entry.get("name", "")) == current_name
	row.configure(entry, rank, show_context, score_mode, is_current_player, alternate)

func _add_empty_state(title_text: String, hint_text: String) -> void:
	var panel_container := PanelContainer.new()
	panel_container.custom_minimum_size = Vector2(0, 180)
	UI_THEME.style_soft_panel(panel_container)
	scores_container.add_child(panel_container)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel_container.add_child(margin)

	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 10)
	margin.add_child(content)

	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UI_THEME.style_subtitle(title)
	content.add_child(title)

	var hint := Label.new()
	hint.text = hint_text
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI_THEME.style_meta(hint)
	content.add_child(hint)

func _get_sorted_level_keys() -> Array[String]:
	var keys: Array[String] = []
	for level_key_variant in leaderboards.get("levels", {}).keys():
		keys.append(str(level_key_variant))
	keys.sort_custom(func(a: String, b: String) -> bool:
		var a_parts := a.split(":")
		var b_parts := b.split(":")
		var a_pack := a_parts[0] if a_parts.size() > 0 else a
		var b_pack := b_parts[0] if b_parts.size() > 0 else b
		var a_pack_name := _get_set_name(a_pack)
		var b_pack_name := _get_set_name(b_pack)
		if a_pack_name != b_pack_name:
			return a_pack_name < b_pack_name
		var a_index := int(a_parts[1]) if a_parts.size() > 1 else 0
		var b_index := int(b_parts[1]) if b_parts.size() > 1 else 0
		return a_index < b_index
	)
	return keys

func _get_sorted_pack_ids(source: Dictionary) -> Array[String]:
	var pack_ids: Array[String] = []
	for pack_id_variant in source.keys():
		pack_ids.append(str(pack_id_variant))
	pack_ids.sort_custom(func(a: String, b: String) -> bool:
		return _get_set_name(a) < _get_set_name(b)
	)
	return pack_ids

func _get_level_name(level_key: String) -> String:
	var parts := level_key.split(":")
	if parts.size() != 2:
		return level_key
	var info := PackLoader.get_level_info(parts[0], int(parts[1]))
	return str(info.get("name", level_key))

func _get_set_name(pack_id: String) -> String:
	var pack := PackLoader.get_pack(pack_id)
	return str(pack.get("name", pack_id))

func _get_selected_set_filter() -> Dictionary:
	for set_filter in SET_FILTERS:
		if str(set_filter.get("id", "")) == current_set_challenge_filter:
			return set_filter
	return SET_FILTERS[0]

func _get_filter_index(filter_id: String) -> int:
	for index in range(FILTER_TABS.size()):
		if str(FILTER_TABS[index].get("id", "")) == filter_id:
			return index
	return 0

func _get_set_filter_index(filter_id: String) -> int:
	for index in range(SET_FILTERS.size()):
		if str(SET_FILTERS[index].get("id", "")) == filter_id:
			return index
	return 0

func _clamp_index(index: int, item_count: int) -> int:
	if item_count <= 0:
		return 0
	if index < 0:
		return 0
	if index >= item_count:
		return item_count - 1
	return index
