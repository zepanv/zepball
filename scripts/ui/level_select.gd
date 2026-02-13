extends Control

## Level Select Screen - pack-aware level browser with thumbnails, stars, and filter/sort

@onready var levels_grid = $VBoxContainer/LevelsGrid
@onready var vbox_container = $VBoxContainer
@onready var title_label = $VBoxContainer/TitleLabel

var filter_mode: String = "all" # all | completed | locked
var sort_mode: String = "order" # order | score

var toolbar_row: HBoxContainer = null
var header_desc_label: Label = null
var play_pack_button: Button = null

func _ready() -> void:
	build_toolbar()
	if not MenuController.current_browse_pack_id.is_empty():
		add_pack_context_ui(MenuController.current_browse_pack_id)
	populate_levels()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()

func build_toolbar() -> void:
	toolbar_row = HBoxContainer.new()
	toolbar_row.alignment = BoxContainer.ALIGNMENT_CENTER
	toolbar_row.add_theme_constant_override("separation", 8)
	vbox_container.add_child(toolbar_row)
	vbox_container.move_child(toolbar_row, 2)

	_create_toolbar_label("FILTER")
	_create_filter_button("ALL", "all")
	_create_filter_button("COMPLETED", "completed")
	_create_filter_button("LOCKED", "locked")

	_create_toolbar_label("SORT")
	_create_sort_button("BY ORDER", "order")
	_create_sort_button("BY SCORE", "score")

func add_pack_context_ui(pack_id: String) -> void:
	var pack = PackLoader.get_pack(pack_id)
	if pack.is_empty():
		return

	title_label.text = "SELECT LEVEL - " + str(pack.get("name", "PACK")).to_upper()
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if title_label.text.length() > 32:
		title_label.add_theme_font_size_override("font_size", 38)
	else:
		title_label.add_theme_font_size_override("font_size", 44)

	header_desc_label = Label.new()
	header_desc_label.text = str(pack.get("description", ""))
	header_desc_label.add_theme_font_size_override("font_size", 17)
	header_desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	header_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_container.add_child(header_desc_label)
	vbox_container.move_child(header_desc_label, 3)

	play_pack_button = Button.new()
	play_pack_button.text = "PLAY THIS PACK"
	play_pack_button.custom_minimum_size = Vector2(300, 50)
	play_pack_button.add_theme_font_size_override("font_size", 24)
	play_pack_button.add_theme_color_override("font_color", Color(0, 0.9, 1, 1))
	play_pack_button.pressed.connect(_on_play_pack_button_pressed)

	var button_row = HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_child(play_pack_button)
	vbox_container.add_child(button_row)
	vbox_container.move_child(button_row, 4)

func populate_levels() -> void:
	for child in levels_grid.get_children():
		child.queue_free()

	var entries = _build_level_entries()
	entries = _apply_filter(entries)
	_apply_sort(entries)

	for entry in entries:
		create_level_card(entry)

func _build_level_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var browse_pack_id := MenuController.current_browse_pack_id

	if not browse_pack_id.is_empty():
		_append_pack_entries(entries, browse_pack_id)
		return entries

	var packs: Array[Dictionary] = PackLoader.get_all_packs()
	for pack in packs:
		var pack_id := str(pack.get("pack_id", ""))
		if pack_id.is_empty():
			continue
		_append_pack_entries(entries, pack_id)
	return entries

func _append_pack_entries(entries: Array[Dictionary], pack_id: String) -> void:
	var level_count := PackLoader.get_level_count(pack_id)
	for level_index in range(level_count):
		var level_key := PackLoader.get_level_key(pack_id, level_index)
		var info := PackLoader.get_level_info(pack_id, level_index)
		var legacy_level_id := PackLoader.get_legacy_level_id(pack_id, level_index)
		var score := SaveManager.get_level_key_high_score(level_key)
		var stars := SaveManager.get_level_key_stars(level_key)
		var is_completed := SaveManager.is_level_key_completed(level_key)
		var is_unlocked := SaveManager.is_level_key_unlocked(level_key)
		entries.append({
			"pack_id": pack_id,
			"level_index": level_index,
			"legacy_level_id": legacy_level_id,
			"level_key": level_key,
			"name": str(info.get("name", "Unknown")),
			"description": str(info.get("description", "")),
			"score": score,
			"stars": stars,
			"is_completed": is_completed,
			"is_unlocked": is_unlocked,
			"preview": PackLoader.generate_level_preview(pack_id, level_index)
		})

func _apply_filter(entries: Array[Dictionary]) -> Array[Dictionary]:
	if filter_mode == "all":
		return entries

	var filtered: Array[Dictionary] = []
	for entry in entries:
		var unlocked := bool(entry.get("is_unlocked", false))
		var completed := bool(entry.get("is_completed", false))
		var score := int(entry.get("score", 0))
		# Match the same logic used in the card display (line 221)
		var is_visually_completed := completed or score > 0
		if filter_mode == "completed" and is_visually_completed:
			filtered.append(entry)
		elif filter_mode == "locked" and not unlocked:
			filtered.append(entry)
	return filtered

func _apply_sort(entries: Array[Dictionary]) -> void:
	if sort_mode == "score":
		entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			var sa := int(a.get("score", 0))
			var sb := int(b.get("score", 0))
			if sa == sb:
				if str(a.get("pack_id", "")) == str(b.get("pack_id", "")):
					return int(a.get("level_index", 0)) < int(b.get("level_index", 0))
				return str(a.get("pack_id", "")) < str(b.get("pack_id", ""))
			return sa > sb
		)
		return

	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if str(a.get("pack_id", "")) == str(b.get("pack_id", "")):
			return int(a.get("level_index", 0)) < int(b.get("level_index", 0))
		return str(a.get("pack_id", "")) < str(b.get("pack_id", ""))
	)

func create_level_card(entry: Dictionary) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(360, 130)

	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	panel.add_child(root)

	var preview := TextureRect.new()
	preview.custom_minimum_size = Vector2(120, 80)
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.texture = entry.get("preview")
	root.add_child(preview)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(vbox)

	var title := Label.new()
	var prefix := ""
	var legacy_level_id := int(entry.get("legacy_level_id", -1))
	if legacy_level_id != -1:
		prefix = "LEVEL %d: " % legacy_level_id
	title.text = prefix + str(entry.get("name", "Unknown"))
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0, 0.9, 1, 1))
	vbox.add_child(title)

	var desc := Label.new()
	desc.text = str(entry.get("description", ""))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 14)
	desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	vbox.add_child(desc)

	var meta := HBoxContainer.new()
	meta.add_theme_constant_override("separation", 8)
	vbox.add_child(meta)

	var stars_label := Label.new()
	stars_label.text = _stars_text(int(entry.get("stars", 0)))
	stars_label.add_theme_font_size_override("font_size", 15)
	stars_label.add_theme_color_override("font_color", Color(1, 0.9, 0.45, 1))
	meta.add_child(stars_label)

	var score_label := Label.new()
	score_label.text = "Best: %d" % int(entry.get("score", 0))
	score_label.add_theme_font_size_override("font_size", 15)
	score_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75, 1))
	meta.add_child(score_label)

	var status_label := Label.new()
	status_label.add_theme_font_size_override("font_size", 15)
	var is_unlocked := bool(entry.get("is_unlocked", false))
	var is_completed := bool(entry.get("is_completed", false))
	var score := int(entry.get("score", 0))

	if not is_unlocked:
		status_label.text = "LOCKED"
		status_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	elif is_completed or score > 0:
		status_label.text = "COMPLETED"
		status_label.add_theme_color_override("font_color", Color(0.55, 1.0, 0.55, 1))
	else:
		# NEW only for unlocked levels with no completion/high score.
		status_label.text = "NEW"
		status_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.55, 1))
	meta.add_child(status_label)

	if is_unlocked:
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		panel.set_meta("pack_id", str(entry.get("pack_id", "")))
		panel.set_meta("level_index", int(entry.get("level_index", 0)))
		panel.gui_input.connect(_on_level_panel_input.bind(panel))
		panel.mouse_entered.connect(_on_level_hover_start.bind(panel))
		panel.mouse_exited.connect(_on_level_hover_end.bind(panel))
	else:
		panel.modulate = Color(0.55, 0.55, 0.55, 1)

	levels_grid.add_child(panel)

func _stars_text(stars: int) -> String:
	var result := ""
	for i in range(3):
		if i < stars:
			result += "*"
		else:
			result += "-"
	return result

func _create_filter_button(label_text: String, value: String) -> void:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(118, 34)
	button.add_theme_font_size_override("font_size", 16)
	button.pressed.connect(func():
		filter_mode = value
		populate_levels()
	)
	toolbar_row.add_child(button)

func _create_toolbar_label(text_value: String) -> void:
	var label := Label.new()
	label.text = text_value + ":"
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	toolbar_row.add_child(label)

func _create_sort_button(label_text: String, value: String) -> void:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(118, 34)
	button.add_theme_font_size_override("font_size", 16)
	button.pressed.connect(func():
		sort_mode = value
		populate_levels()
	)
	toolbar_row.add_child(button)

func _on_play_pack_button_pressed() -> void:
	if MenuController.current_browse_pack_id.is_empty():
		return
	MenuController.start_pack(MenuController.current_browse_pack_id)

func _on_level_panel_input(event: InputEvent, panel: PanelContainer) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var pack_id := str(panel.get_meta("pack_id"))
		var level_index := int(panel.get_meta("level_index"))
		MenuController.start_level_ref(pack_id, level_index)

func _on_level_hover_start(panel: PanelContainer) -> void:
	panel.modulate = Color(1.12, 1.12, 1.12, 1)

func _on_level_hover_end(panel: PanelContainer) -> void:
	panel.modulate = Color.WHITE

func _on_back_button_pressed() -> void:
	if not MenuController.current_browse_pack_id.is_empty():
		MenuController.current_browse_pack_id = ""
		MenuController.show_set_select()
		return
	MenuController.show_main_menu()
