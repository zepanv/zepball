extends Control

## Pack Select Screen - Displays available built-in and user packs
const UI_THEME = preload("res://scripts/ui/ui_theme.gd")

# Filter and Sort modes
enum FilterMode { ALL, OFFICIAL, CUSTOM }
enum SortMode { BY_ORDER, BY_PROGRESSION }

const CHALLENGE_MODE_DESCRIPTIONS: Dictionary = {
	"normal": "Standard gameplay with all power-ups active.",
	"iron_ball": "No power-ups spawn. Pure skill and precision only.",
	"one_life": "One life. No continues. Complete the pack or start over.",
	"time_attack": "Complete the pack as fast as possible. Time is the only ranked metric."
}

var current_filter_mode: FilterMode = FilterMode.ALL
var current_sort_mode: SortMode = SortMode.BY_ORDER
var level_buttons: Array[Button] = []

@onready var sets_container: VBoxContainer = $VBoxContainer/ContentContainer/PackListContainer/ScrollContainer/SetsContainer
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var toolbar_container: MarginContainer = $VBoxContainer/ToolbarContainer
@onready var back_button: Button = $VBoxContainer/FooterRow/BackButton
@onready var challenge_dropdown: OptionButton = $VBoxContainer/ContentContainer/ChallengePanel/ChallengeMargin/ChallengeVBox/ChallengeDropdown
@onready var challenge_description_label: Label = $VBoxContainer/ContentContainer/ChallengePanel/ChallengeMargin/ChallengeVBox/ChallengeDescription
@onready var challenge_mode_note_label: Label = $VBoxContainer/ContentContainer/ChallengePanel/ChallengeMargin/ChallengeVBox/ChallengeModeNote

func _ready() -> void:
	UI_THEME.apply_to(self)
	UI_THEME.style_title_large(title_label)
	UI_THEME.style_muted_button(back_button)
	title_label.text = "SELECT PACK"
	_create_toolbar()
	_initialize_challenge_mode_controls()
	populate_packs()

	# Grab focus on first button for controller navigation
	await get_tree().process_frame
	_grab_first_button_focus()

func _initialize_challenge_mode_controls() -> void:
	if challenge_dropdown and not challenge_dropdown.item_selected.is_connected(_on_challenge_dropdown_item_selected):
		challenge_dropdown.item_selected.connect(_on_challenge_dropdown_item_selected)

	# MenuController already loaded the last challenge mode from SaveManager in _ready()
	var initial_mode = MenuController.normalize_challenge_mode(MenuController.current_challenge_mode)
	MenuController.set_challenge_mode(initial_mode)

	if challenge_dropdown:
		challenge_dropdown.select(_challenge_mode_to_index(initial_mode))
	_update_challenge_mode_ui(initial_mode)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()
		accept_event()

func populate_packs() -> void:
	for child in sets_container.get_children():
		child.queue_free()
	level_buttons.clear()

	var packs: Array[Dictionary] = PackLoader.get_all_packs()

	# Apply filter
	packs = _apply_filter(packs)

	# Apply sort
	packs = _apply_sort(packs)

	for pack_data in packs:
		create_pack_card(pack_data)
	_create_new_pack_card()
	_apply_challenge_mode_to_level_buttons()

func create_pack_card(pack_data: Dictionary) -> void:
	var pack_id = str(pack_data.get("pack_id", ""))
	var pack_name = str(pack_data.get("name", "Unknown Pack"))
	var description = str(pack_data.get("description", ""))
	var author = str(pack_data.get("author", "Unknown"))
	var source = str(pack_data.get("source", "user"))
	var level_count = int(pack_data.get("levels", []).size())
	var is_official = source == "builtin"

	var completed_count = _get_completed_count(pack_id)
	var stars_total = _get_total_stars(pack_id)
	var max_stars = level_count * 3
	var set_high_score = SaveManager.get_set_pack_high_score(pack_id)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(780, 110)

	# Apply accent row — cyan for official, gold for custom
	var bg := Color(UI_THEME.PANEL_BACKGROUND_SOFT.r, UI_THEME.PANEL_BACKGROUND_SOFT.g, UI_THEME.PANEL_BACKGROUND_SOFT.b, 0.7)
	var accent := UI_THEME.PRIMARY if is_official else UI_THEME.GOLD
	UI_THEME.style_accent_row(panel, accent, bg)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var hbox_main = HBoxContainer.new()
	hbox_main.add_theme_constant_override("separation", 12)
	margin.add_child(hbox_main)

	# Left side: Pack info
	var info_vbox = VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 3)
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox_main.add_child(info_vbox)

	# Title row with badge
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	info_vbox.add_child(header)

	var name_label = Label.new()
	name_label.text = pack_name.to_upper()
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", UI_THEME.PRIMARY if is_official else UI_THEME.TEXT_PRIMARY)
	header.add_child(name_label)

	var badge = Label.new()
	badge.text = "[OFFICIAL]" if is_official else "[CUSTOM]"
	badge.add_theme_font_size_override("font_size", 11)
	badge.add_theme_color_override("font_color", UI_THEME.SUCCESS if is_official else UI_THEME.GOLD)
	header.add_child(badge)

	# Description + Author line
	var desc_text = ""
	if description != "":
		desc_text = description + "  •  "
	desc_text += "By " + author

	var desc_label = Label.new()
	desc_label.text = desc_text
	desc_label.add_theme_font_size_override("font_size", 13)
	desc_label.add_theme_color_override("font_color", UI_THEME.TEXT_MUTED)
	desc_label.clip_text = true
	info_vbox.add_child(desc_label)

	# Stats row - more compact
	var info_row = HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 14)
	info_vbox.add_child(info_row)

	var levels_label = Label.new()
	levels_label.text = "%d Levels" % level_count
	levels_label.add_theme_font_size_override("font_size", 13)
	levels_label.add_theme_color_override("font_color", UI_THEME.TEXT_MUTED)
	info_row.add_child(levels_label)

	var progress_label = Label.new()
	var progress_color = UI_THEME.PRIMARY_SOFT if completed_count < level_count else UI_THEME.SUCCESS
	progress_label.text = "Progress: %d/%d" % [completed_count, level_count]
	progress_label.add_theme_font_size_override("font_size", 13)
	progress_label.add_theme_color_override("font_color", progress_color)
	info_row.add_child(progress_label)

	var stars_label = Label.new()
	stars_label.text = "★ %d/%d" % [stars_total, max_stars]
	stars_label.add_theme_font_size_override("font_size", 13)
	stars_label.add_theme_color_override("font_color", UI_THEME.GOLD)
	info_row.add_child(stars_label)

	if set_high_score > 0:
		var score_label = Label.new()
		score_label.text = "Best: %d" % set_high_score
		score_label.add_theme_font_size_override("font_size", 13)
		score_label.add_theme_color_override("font_color", UI_THEME.SUCCESS)
		info_row.add_child(score_label)

	# Right side: Buttons (vertical stack)
	var button_vbox = VBoxContainer.new()
	button_vbox.add_theme_constant_override("separation", 4)
	hbox_main.add_child(button_vbox)

	var play_button = Button.new()
	play_button.text = "PLAY"
	play_button.custom_minimum_size = Vector2(110, 30)
	play_button.add_theme_font_size_override("font_size", 16)
	play_button.add_theme_color_override("font_color", UI_THEME.PRIMARY)
	play_button.pressed.connect(_on_play_pack_pressed.bind(pack_id))
	button_vbox.add_child(play_button)

	var view_button = Button.new()
	view_button.text = "LEVELS"
	view_button.custom_minimum_size = Vector2(110, 28)
	view_button.add_theme_font_size_override("font_size", 14)
	view_button.add_theme_color_override("font_color", UI_THEME.TEXT_SECONDARY)
	view_button.pressed.connect(_on_view_levels_pressed.bind(pack_id))
	button_vbox.add_child(view_button)
	level_buttons.append(view_button)

	if not is_official:
		var edit_button = Button.new()
		edit_button.text = "EDIT"
		edit_button.custom_minimum_size = Vector2(110, 24)
		edit_button.add_theme_font_size_override("font_size", 13)
		edit_button.add_theme_color_override("font_color", UI_THEME.GOLD)
		edit_button.pressed.connect(_on_edit_pack_pressed.bind(pack_id))
		button_vbox.add_child(edit_button)
	elif OS.is_debug_build():
		var edit_button = Button.new()
		edit_button.text = "EDIT [DEV]"
		edit_button.custom_minimum_size = Vector2(110, 24)
		edit_button.add_theme_font_size_override("font_size", 13)
		edit_button.add_theme_color_override("font_color", UI_THEME.DANGER)
		edit_button.pressed.connect(_on_edit_pack_pressed.bind(pack_id))
		button_vbox.add_child(edit_button)

	sets_container.add_child(panel)

func _create_new_pack_card() -> void:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(780, 50)

	var bg := Color(UI_THEME.PANEL_BACKGROUND_SOFT.r, UI_THEME.PANEL_BACKGROUND_SOFT.g, UI_THEME.PANEL_BACKGROUND_SOFT.b, 0.4)
	UI_THEME.style_accent_row(panel, UI_THEME.SUCCESS, bg)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	var button: Button = Button.new()
	button.text = "+ CREATE NEW PACK"
	button.custom_minimum_size = Vector2(0, 32)
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", UI_THEME.SUCCESS)
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
	if _is_challenge_mode_active():
		return
	MenuController.current_browse_pack_id = pack_id
	MenuController.show_level_select()

func _on_edit_pack_pressed(pack_id: String) -> void:
	MenuController.show_editor_for_pack(pack_id)

func _on_create_pack_pressed() -> void:
	MenuController.show_editor_from_set_select()

func _on_back_button_pressed() -> void:
	MenuController.show_main_menu()

func _on_challenge_dropdown_item_selected(index: int) -> void:
	var mode = _challenge_mode_from_index(index)
	MenuController.set_challenge_mode(mode)
	_update_challenge_mode_ui(mode)
	_apply_challenge_mode_to_level_buttons()
	_grab_first_button_focus()

func _update_challenge_mode_ui(mode: String) -> void:
	var normalized_mode = MenuController.normalize_challenge_mode(mode)
	if challenge_description_label:
		challenge_description_label.text = str(CHALLENGE_MODE_DESCRIPTIONS.get(normalized_mode, CHALLENGE_MODE_DESCRIPTIONS[MenuController.CHALLENGE_MODE_NORMAL]))
	if challenge_mode_note_label:
		challenge_mode_note_label.visible = normalized_mode != MenuController.CHALLENGE_MODE_NORMAL

func _apply_challenge_mode_to_level_buttons() -> void:
	var challenge_enabled = _is_challenge_mode_active()
	for view_button in level_buttons:
		if not is_instance_valid(view_button):
			continue
		view_button.disabled = challenge_enabled
		view_button.tooltip_text = "Challenge modes are pack-run only." if challenge_enabled else ""

func _challenge_mode_from_index(index: int) -> String:
	match index:
		1:
			return MenuController.CHALLENGE_MODE_IRON_BALL
		2:
			return MenuController.CHALLENGE_MODE_ONE_LIFE
		3:
			return MenuController.CHALLENGE_MODE_TIME_ATTACK
		_:
			return MenuController.CHALLENGE_MODE_NORMAL

func _challenge_mode_to_index(mode: String) -> int:
	match MenuController.normalize_challenge_mode(mode):
		MenuController.CHALLENGE_MODE_IRON_BALL:
			return 1
		MenuController.CHALLENGE_MODE_ONE_LIFE:
			return 2
		MenuController.CHALLENGE_MODE_TIME_ATTACK:
			return 3
		_:
			return 0

func _is_challenge_mode_active() -> bool:
	return MenuController.current_challenge_mode != MenuController.CHALLENGE_MODE_NORMAL

func _create_toolbar() -> void:
	"""Create the filter and sort toolbar"""
	if not toolbar_container:
		return

	var toolbar_hbox = HBoxContainer.new()
	toolbar_hbox.add_theme_constant_override("separation", 16)
	toolbar_hbox.alignment = BoxContainer.ALIGNMENT_CENTER

	# Filter label
	var filter_label = Label.new()
	filter_label.text = "FILTER:"
	filter_label.add_theme_font_size_override("font_size", 14)
	filter_label.add_theme_color_override("font_color", UI_THEME.TEXT_MUTED)
	toolbar_hbox.add_child(filter_label)

	# Filter buttons
	var filter_all_btn = Button.new()
	filter_all_btn.text = "ALL"
	filter_all_btn.custom_minimum_size = Vector2(80, 30)
	filter_all_btn.add_theme_font_size_override("font_size", 13)
	filter_all_btn.pressed.connect(_on_filter_changed.bind(FilterMode.ALL))
	toolbar_hbox.add_child(filter_all_btn)

	var filter_official_btn = Button.new()
	filter_official_btn.text = "OFFICIAL"
	filter_official_btn.custom_minimum_size = Vector2(80, 30)
	filter_official_btn.add_theme_font_size_override("font_size", 13)
	filter_official_btn.pressed.connect(_on_filter_changed.bind(FilterMode.OFFICIAL))
	toolbar_hbox.add_child(filter_official_btn)

	var filter_custom_btn = Button.new()
	filter_custom_btn.text = "CUSTOM"
	filter_custom_btn.custom_minimum_size = Vector2(80, 30)
	filter_custom_btn.add_theme_font_size_override("font_size", 13)
	filter_custom_btn.pressed.connect(_on_filter_changed.bind(FilterMode.CUSTOM))
	toolbar_hbox.add_child(filter_custom_btn)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(30, 0)
	toolbar_hbox.add_child(spacer)

	# Sort label
	var sort_label = Label.new()
	sort_label.text = "SORT:"
	sort_label.add_theme_font_size_override("font_size", 14)
	sort_label.add_theme_color_override("font_color", UI_THEME.TEXT_MUTED)
	toolbar_hbox.add_child(sort_label)

	# Sort buttons
	var sort_order_btn = Button.new()
	sort_order_btn.text = "BY ORDER"
	sort_order_btn.custom_minimum_size = Vector2(100, 30)
	sort_order_btn.add_theme_font_size_override("font_size", 13)
	sort_order_btn.pressed.connect(_on_sort_changed.bind(SortMode.BY_ORDER))
	toolbar_hbox.add_child(sort_order_btn)

	var sort_progression_btn = Button.new()
	sort_progression_btn.text = "BY PROGRESSION"
	sort_progression_btn.custom_minimum_size = Vector2(140, 30)
	sort_progression_btn.add_theme_font_size_override("font_size", 13)
	sort_progression_btn.pressed.connect(_on_sort_changed.bind(SortMode.BY_PROGRESSION))
	toolbar_hbox.add_child(sort_progression_btn)

	toolbar_container.add_child(toolbar_hbox)

func _on_filter_changed(mode: FilterMode) -> void:
	"""Handle filter mode change"""
	current_filter_mode = mode
	populate_packs()
	await get_tree().process_frame
	_grab_first_button_focus()

func _on_sort_changed(mode: SortMode) -> void:
	"""Handle sort mode change"""
	current_sort_mode = mode
	populate_packs()
	await get_tree().process_frame
	_grab_first_button_focus()

func _apply_filter(packs: Array[Dictionary]) -> Array[Dictionary]:
	"""Apply current filter to pack list"""
	if current_filter_mode == FilterMode.ALL:
		return packs

	var filtered: Array[Dictionary] = []
	for pack in packs:
		var source = str(pack.get("source", "user"))
		var is_official = source == "builtin"

		if current_filter_mode == FilterMode.OFFICIAL and is_official:
			filtered.append(pack)
		elif current_filter_mode == FilterMode.CUSTOM and not is_official:
			filtered.append(pack)

	return filtered

func _apply_sort(packs: Array[Dictionary]) -> Array[Dictionary]:
	"""Apply current sort to pack list"""
	var sorted_packs = packs.duplicate()

	if current_sort_mode == SortMode.BY_ORDER:
		# Sort: Custom packs first (A-Z), then official packs (legacy order)
		sorted_packs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			var a_source = str(a.get("source", "user"))
			var b_source = str(b.get("source", "user"))
			var a_official = a_source == "builtin"
			var b_official = b_source == "builtin"

			# Custom packs before official
			if not a_official and b_official:
				return true
			if a_official and not b_official:
				return false

			# Both custom: alphabetical by name
			if not a_official and not b_official:
				return str(a.get("name", "")).to_lower() < str(b.get("name", "")).to_lower()

			# Both official: use legacy order
			var a_id = str(a.get("pack_id", ""))
			var b_id = str(b.get("pack_id", ""))
			var a_idx = PackLoader.LEGACY_PACK_ORDER.find(a_id)
			var b_idx = PackLoader.LEGACY_PACK_ORDER.find(b_id)

			if a_idx == -1:
				a_idx = 999
			if b_idx == -1:
				b_idx = 999

			return a_idx < b_idx
		)
	elif current_sort_mode == SortMode.BY_PROGRESSION:
		# Sort by completion percentage (descending)
		sorted_packs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			var a_pack_id = str(a.get("pack_id", ""))
			var b_pack_id = str(b.get("pack_id", ""))
			var a_count = int(a.get("levels", []).size())
			var b_count = int(b.get("levels", []).size())
			var a_completed = SaveManager.get_pack_completed_count(a_pack_id)
			var b_completed = SaveManager.get_pack_completed_count(b_pack_id)

			var a_pct = 0.0 if a_count == 0 else float(a_completed) / float(a_count)
			var b_pct = 0.0 if b_count == 0 else float(b_completed) / float(b_count)

			# Higher percentage first (descending)
			return a_pct > b_pct
		)

	return sorted_packs

func _grab_first_button_focus() -> void:
	"""Grab focus on the first available button for controller navigation"""
	if sets_container:
		for child in sets_container.get_children():
			if child is PanelContainer and child.is_visible_in_tree():
				# Look for the first button inside the panel
				var buttons = _find_buttons_recursive(child)
				if not buttons.is_empty():
					buttons[0].grab_focus()
					return

	if back_button and back_button.is_visible_in_tree() and not back_button.disabled:
		back_button.grab_focus()

func _find_buttons_recursive(node: Node) -> Array[Button]:
	"""Recursively find all buttons in a node"""
	var buttons: Array[Button] = []
	for child in node.get_children():
		if child is Button and child.is_visible_in_tree() and not child.disabled:
			buttons.append(child)
		buttons.append_array(_find_buttons_recursive(child))
	return buttons
