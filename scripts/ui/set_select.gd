extends Control

## Pack Select Screen - Displays available built-in and user packs

@onready var sets_container = $VBoxContainer/ScrollContainer/SetsContainer
@onready var title_label = $VBoxContainer/TitleLabel

func _ready() -> void:
	title_label.text = "SELECT PACK"
	populate_packs()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()

func populate_packs() -> void:
	for child in sets_container.get_children():
		child.queue_free()

	var packs: Array[Dictionary] = PackLoader.get_all_packs()
	for pack_data in packs:
		create_pack_card(pack_data)
	_create_new_pack_card()

func create_pack_card(pack_data: Dictionary) -> void:
	var pack_id := str(pack_data.get("pack_id", ""))
	var pack_name := str(pack_data.get("name", "Unknown Pack"))
	var description := str(pack_data.get("description", ""))
	var author := str(pack_data.get("author", "Unknown"))
	var source := str(pack_data.get("source", "user"))
	var level_count := int(pack_data.get("levels", []).size())
	var is_official := source == "builtin"

	var completed_count := _get_completed_count(pack_id)
	var stars_total := _get_total_stars(pack_id)
	var max_stars := level_count * 3
	var set_high_score := SaveManager.get_set_pack_high_score(pack_id)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(700, 190)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	vbox.add_child(header)

	var name_label := Label.new()
	name_label.text = pack_name.to_upper()
	name_label.add_theme_font_size_override("font_size", 30)
	if is_official:
		name_label.add_theme_color_override("font_color", Color(0, 0.9, 1, 1))
	else:
		name_label.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0, 1.0))
	header.add_child(name_label)

	var badge := Label.new()
	if is_official:
		badge.text = "OFFICIAL"
	else:
		badge.text = "CUSTOM"
	badge.add_theme_font_size_override("font_size", 14)
	if is_official:
		badge.add_theme_color_override("font_color", Color(0.15, 0.95, 0.65, 1))
	else:
		badge.add_theme_color_override("font_color", Color(1.0, 0.75, 0.25, 1))
	header.add_child(badge)

	var meta_label := Label.new()
	meta_label.text = "By %s" % author
	meta_label.add_theme_font_size_override("font_size", 16)
	meta_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	vbox.add_child(meta_label)

	var desc_label := Label.new()
	desc_label.text = description
	desc_label.add_theme_font_size_override("font_size", 17)
	desc_label.add_theme_color_override("font_color", Color(0.78, 0.78, 0.78, 1))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)

	var info_row := HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 20)
	vbox.add_child(info_row)

	var levels_label := Label.new()
	levels_label.text = "%d Levels" % level_count
	levels_label.add_theme_font_size_override("font_size", 16)
	levels_label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65, 1))
	info_row.add_child(levels_label)

	var progress_label := Label.new()
	progress_label.text = "Progress: %d/%d" % [completed_count, level_count]
	progress_label.add_theme_font_size_override("font_size", 16)
	progress_label.add_theme_color_override("font_color", Color(0.65, 0.85, 1.0, 1))
	info_row.add_child(progress_label)

	var stars_label := Label.new()
	stars_label.text = "Stars: %d/%d" % [stars_total, max_stars]
	stars_label.add_theme_font_size_override("font_size", 16)
	stars_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.45, 1))
	info_row.add_child(stars_label)

	if set_high_score > 0:
		var score_label := Label.new()
		score_label.text = "Best: %d" % set_high_score
		score_label.add_theme_font_size_override("font_size", 16)
		score_label.add_theme_color_override("font_color", Color(0.65, 1.0, 0.65, 1))
		info_row.add_child(score_label)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 14)
	vbox.add_child(button_row)

	var play_button := Button.new()
	play_button.text = "PLAY PACK"
	play_button.custom_minimum_size = Vector2(190, 42)
	play_button.add_theme_font_size_override("font_size", 22)
	play_button.add_theme_color_override("font_color", Color(0, 0.9, 1, 1))
	play_button.pressed.connect(_on_play_pack_pressed.bind(pack_id))
	button_row.add_child(play_button)

	var view_button := Button.new()
	view_button.text = "VIEW LEVELS"
	view_button.custom_minimum_size = Vector2(190, 42)
	view_button.add_theme_font_size_override("font_size", 20)
	view_button.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
	view_button.pressed.connect(_on_view_levels_pressed.bind(pack_id))
	button_row.add_child(view_button)

	if not is_official:
		var edit_button := Button.new()
		edit_button.text = "EDIT"
		edit_button.custom_minimum_size = Vector2(120, 42)
		edit_button.add_theme_font_size_override("font_size", 20)
		edit_button.add_theme_color_override("font_color", Color(1.0, 0.75, 0.25, 1))
		edit_button.pressed.connect(_on_edit_pack_pressed.bind(pack_id))
		button_row.add_child(edit_button)

	sets_container.add_child(panel)

func _create_new_pack_card() -> void:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(700, 80)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var button: Button = Button.new()
	button.text = "CREATE NEW PACK"
	button.custom_minimum_size = Vector2(0, 42)
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", Color(0.15, 0.95, 0.65, 1))
	button.pressed.connect(_on_create_pack_pressed)
	margin.add_child(button)

	sets_container.add_child(panel)

func _get_completed_count(pack_id: String) -> int:
	return SaveManager.get_pack_completed_count(pack_id)

func _get_total_stars(pack_id: String) -> int:
	return SaveManager.get_pack_total_stars(pack_id)

func _on_play_pack_pressed(pack_id: String) -> void:
	MenuController.start_pack(pack_id)

func _on_view_levels_pressed(pack_id: String) -> void:
	MenuController.current_browse_pack_id = pack_id
	MenuController.show_level_select()

func _on_edit_pack_pressed(pack_id: String) -> void:
	MenuController.show_editor_for_pack(pack_id)

func _on_create_pack_pressed() -> void:
	MenuController.show_editor_from_set_select()

func _on_back_button_pressed() -> void:
	MenuController.show_main_menu()
