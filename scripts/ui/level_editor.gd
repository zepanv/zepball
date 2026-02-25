extends Control

const DEFAULT_ROWS: int = 10
const DEFAULT_COLS: int = 6
const BRICK_TYPE_OPTIONS: Array[String] = [
	"ERASER",
	"NORMAL",
	"STRONG",
	"UNBREAKABLE",
	"GOLD",
	"RED",
	"BLUE",
	"GREEN",
	"PURPLE",
	"ORANGE",
	"BOMB",
	"DIAMOND",
	"DIAMOND_GLOSSY",
	"POLYGON",
	"POLYGON_GLOSSY",
	"FORCE_ARROW",
	"POWERUP_BRICK"
]
const FORCE_ARROW_DIRECTIONS: Array[int] = [45, 0, 90, 135, 180, 225, 270, 315]
const POWERUP_TYPE_OPTIONS: Array[String] = [
	"EXPAND",
	"CONTRACT",
	"SPEED_UP",
	"TRIPLE_BALL",
	"BIG_BALL",
	"SMALL_BALL",
	"SLOW_DOWN",
	"EXTRA_LIFE",
	"GRAB",
	"BRICK_THROUGH",
	"DOUBLE_SCORE",
	"MYSTERY",
	"BOMB_BALL",
	"AIR_BALL",
	"MAGNET",
	"BLOCK"
]

var BRICK_COLORS: Dictionary:
	get: return PackLoader.BRICK_PREVIEW_COLOR_MAP

@onready var title_label: Label = $VBoxContainer/HeaderRow/TitleLabel
@onready var back_button: Button = $VBoxContainer/HeaderRow/BackButton
@onready var pack_id_input: LineEdit = $VBoxContainer/Body/LeftPanel/PackIdInput
@onready var pack_name_input: LineEdit = $VBoxContainer/Body/LeftPanel/PackNameInput
@onready var author_input: LineEdit = $VBoxContainer/Body/LeftPanel/AuthorInput
@onready var description_input: TextEdit = $VBoxContainer/Body/LeftPanel/DescriptionInput
@onready var level_list: ItemList = $VBoxContainer/Body/LeftPanel/LevelList
@onready var level_name_input: LineEdit = $VBoxContainer/Body/LeftPanel/LevelNameInput
@onready var level_description_input: TextEdit = $VBoxContainer/Body/LeftPanel/LevelDescriptionInput
@onready var rows_input: SpinBox = $VBoxContainer/Body/LeftPanel/GridConfig/RowsInput
@onready var cols_input: SpinBox = $VBoxContainer/Body/LeftPanel/GridConfig/ColsInput
@onready var palette_select: OptionButton = $VBoxContainer/Body/RightPanel/RightControls/PaletteSelect
@onready var direction_label: Label = $VBoxContainer/Body/RightPanel/RightControls/DirectionLabel
@onready var direction_select: OptionButton = $VBoxContainer/Body/RightPanel/RightControls/DirectionSelect
@onready var powerup_type_label: Label = $VBoxContainer/Body/RightPanel/RightControls/PowerupTypeLabel
@onready var powerup_type_select: OptionButton = $VBoxContainer/Body/RightPanel/RightControls/PowerupTypeSelect
@onready var grid_container: GridContainer = $VBoxContainer/Body/RightPanel/GridScroll/GridContainer
@onready var status_label: Label = $VBoxContainer/FooterRow/StatusLabel
@onready var delete_button: Button = $VBoxContainer/Body/RightPanel/RightControls/ActionRow/DeleteButton
@onready var delete_confirm_dialog: ConfirmationDialog = $DeleteConfirmDialog

var current_pack: Dictionary = {}
var _editing_builtin_pack: bool = false
var selected_level_index: int = 0
var selected_brick_type: String = "NORMAL"
var selected_direction: int = 45
var selected_powerup_type: String = "MYSTERY"
var is_refreshing_ui: bool = false

const EXPORTS_PATH: String = "user://exports/"
const MAX_PLAYABLE_ROWS: int = 12
const MAX_PLAYABLE_COLS: int = 19

const EDITOR_UNDO_HELPER_SCRIPT = preload("res://scripts/ui/editor_undo_helper.gd")
const EDITOR_GRID_HELPER_SCRIPT = preload("res://scripts/ui/editor_grid_helper.gd")
const EDITOR_PACK_IO_HELPER_SCRIPT = preload("res://scripts/ui/editor_pack_io_helper.gd")
var undo_helper: RefCounted = null
var grid_helper: RefCounted = null
var pack_io_helper: RefCounted = null

func _ready() -> void:
	undo_helper = EDITOR_UNDO_HELPER_SCRIPT.new()
	grid_helper = EDITOR_GRID_HELPER_SCRIPT.new()
	pack_io_helper = EDITOR_PACK_IO_HELPER_SCRIPT.new()
	_update_back_button_text()
	_initialize_palette()
	_initialize_editor_pack()
	_refresh_all_ui()

	# Grab focus on back button for controller navigation
	await get_tree().process_frame
	back_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()
		accept_event()
		return
	if event is InputEventKey:
		var key_event: InputEventKey = event
		if not key_event.pressed or key_event.echo:
			return
		var has_modifier: bool = key_event.ctrl_pressed or key_event.meta_pressed
		if not has_modifier:
			return
		if key_event.keycode == KEY_Z and not key_event.shift_pressed:
			_on_undo_button_pressed()
		elif key_event.keycode == KEY_Y or (key_event.keycode == KEY_Z and key_event.shift_pressed):
			_on_redo_button_pressed()

func _update_back_button_text() -> void:
	if MenuController.should_editor_return_to_main_menu():
		back_button.text = "BACK TO MENU"
	else:
		back_button.text = "BACK TO PACKS"

func _initialize_palette() -> void:
	palette_select.clear()
	for option in BRICK_TYPE_OPTIONS:
		palette_select.add_item(option)
	palette_select.select(1)
	selected_brick_type = "NORMAL"
	_initialize_special_option_pickers()
	_refresh_special_picker_visibility()

func _initialize_special_option_pickers() -> void:
	direction_select.clear()
	for direction in FORCE_ARROW_DIRECTIONS:
		direction_select.add_item(_get_direction_label(direction), direction)
	direction_select.select(0)
	selected_direction = FORCE_ARROW_DIRECTIONS[0]

	powerup_type_select.clear()
	for powerup_type in POWERUP_TYPE_OPTIONS:
		powerup_type_select.add_item(powerup_type)
	powerup_type_select.select(POWERUP_TYPE_OPTIONS.find("MYSTERY"))
	selected_powerup_type = "MYSTERY"

func _initialize_editor_pack() -> void:
	var draft_pack: Dictionary = MenuController.get_editor_draft_pack()
	if not draft_pack.is_empty():
		current_pack = draft_pack.duplicate(true)
		selected_level_index = clampi(MenuController.get_editor_draft_level_index(), 0, max(0, current_pack.get("levels", []).size() - 1))
		# Preserve edit intent through test round-trips even if pack_id changes during editing.
		_editing_builtin_pack = MenuController.get_editor_draft_is_builtin_edit()
		title_label.text = "LEVEL EDITOR - EDIT BUILTIN [DEV]" if _editing_builtin_pack else "LEVEL EDITOR - TEST DRAFT"
		status_label.text = "Restored draft after test run"
		return

	var requested_pack_id: String = MenuController.get_editor_pack_id()
	if not requested_pack_id.is_empty() and PackLoader.pack_exists(requested_pack_id):
		current_pack = PackLoader.get_pack(requested_pack_id)
		_editing_builtin_pack = bool(current_pack.get("_is_builtin", false))
		title_label.text = "LEVEL EDITOR - EDIT BUILTIN [DEV]" if _editing_builtin_pack else "LEVEL EDITOR - EDIT PACK"
		status_label.text = "Loaded pack: %s" % requested_pack_id
		return

	_editing_builtin_pack = false
	current_pack = _create_new_pack_template()
	title_label.text = "LEVEL EDITOR - NEW PACK"
	status_label.text = "Creating a new pack"

func _create_new_pack_template() -> Dictionary:
	return {
		"zeppack_version": 1,
		"pack_id": "new-pack",
		"name": "New Pack",
		"author": "",
		"description": "",
		"source": "user",
		"created_at": Time.get_datetime_string_from_system(true),
		"updated_at": Time.get_datetime_string_from_system(true),
		"levels": [_create_default_level(0)]
	}

func _create_default_level(level_index: int) -> Dictionary:
	return {
		"level_index": level_index,
		"name": "Level %d" % (level_index + 1),
		"description": "",
		"grid": {
			"rows": DEFAULT_ROWS,
			"cols": DEFAULT_COLS,
			"start_x": 200,
			"start_y": 106,
			"brick_size": 48,
			"spacing": 3
		},
		"bricks": []
	}

func _push_undo_state() -> void:
	undo_helper._push_undo_state(self)

func _reindex_levels(levels: Array) -> void:
	grid_helper._reindex_levels(levels)


func _refresh_all_ui() -> void:
	_refresh_metadata_fields()
	_refresh_level_list()
	_refresh_level_details()
	_refresh_grid()
	_update_delete_button_state()
	_refresh_special_picker_visibility()

func _refresh_special_picker_visibility() -> void:
	var is_force_arrow: bool = selected_brick_type == "FORCE_ARROW"
	var is_powerup_brick: bool = selected_brick_type == "POWERUP_BRICK"
	direction_label.visible = is_force_arrow
	direction_select.visible = is_force_arrow
	powerup_type_label.visible = is_powerup_brick
	powerup_type_select.visible = is_powerup_brick

func _get_direction_label(direction: int) -> String:
	return grid_helper._get_direction_label(direction)


func _get_direction_marker(direction: int) -> String:
	return grid_helper._get_direction_marker(direction)


func _get_powerup_abbreviation(powerup_type: String) -> String:
	return grid_helper._get_powerup_abbreviation(powerup_type)


func _refresh_metadata_fields() -> void:
	is_refreshing_ui = true
	pack_id_input.text = str(current_pack.get("pack_id", ""))
	pack_name_input.text = str(current_pack.get("name", ""))
	author_input.text = str(current_pack.get("author", ""))
	description_input.text = str(current_pack.get("description", ""))
	is_refreshing_ui = false

func _refresh_level_list() -> void:
	level_list.clear()
	var levels: Array = current_pack.get("levels", [])
	for idx in range(levels.size()):
		var level_data: Dictionary = levels[idx]
		var level_name: String = str(level_data.get("name", "Level %d" % (idx + 1)))
		level_list.add_item("%d. %s" % [idx + 1, level_name])
	if levels.is_empty():
		selected_level_index = 0
	else:
		selected_level_index = clampi(selected_level_index, 0, levels.size() - 1)
		level_list.select(selected_level_index)

func _refresh_level_details() -> void:
	var level_data: Dictionary = _get_current_level()
	var normalized_level_data: Dictionary = _normalize_level_to_play_area(level_data)
	if normalized_level_data != level_data:
		_set_current_level(normalized_level_data)
		level_data = normalized_level_data
		status_label.text = "Clamped grid to playable area limits"
	var grid: Dictionary = level_data.get("grid", {})
	var limits: Dictionary = _get_grid_limits_for_play_area(grid)
	is_refreshing_ui = true
	rows_input.max_value = float(int(limits.get("max_rows", 1)))
	cols_input.max_value = float(int(limits.get("max_cols", 1)))
	rows_input.value = int(grid.get("rows", DEFAULT_ROWS))
	cols_input.value = int(grid.get("cols", DEFAULT_COLS))
	level_name_input.text = str(level_data.get("name", "Level %d" % (selected_level_index + 1)))
	level_description_input.text = str(level_data.get("description", ""))
	is_refreshing_ui = false

func _get_current_level() -> Dictionary:
	var levels: Array = current_pack.get("levels", [])
	if levels.is_empty():
		var next_levels: Array = [_create_default_level(0)]
		current_pack["levels"] = next_levels
		levels = next_levels
		selected_level_index = 0
	return levels[selected_level_index]

func _set_current_level(level_data: Dictionary) -> void:
	var levels: Array = current_pack.get("levels", [])
	if levels.is_empty():
		levels = [_create_default_level(0)]
		selected_level_index = 0
	elif selected_level_index < 0 or selected_level_index >= levels.size():
		selected_level_index = clampi(selected_level_index, 0, levels.size() - 1)
	levels[selected_level_index] = level_data
	current_pack["levels"] = levels

func _get_grid_limits_for_play_area(_grid: Dictionary) -> Dictionary:
	return grid_helper._get_grid_limits_for_play_area(self, _grid)


func _normalize_level_to_play_area(level_data: Dictionary) -> Dictionary:
	return grid_helper._normalize_level_to_play_area(self, level_data)


func _can_delete_current_pack() -> bool:
	return pack_io_helper._can_delete_current_pack(self)


func _update_delete_button_state() -> void:
	pack_io_helper._update_delete_button_state(self)


func _refresh_grid() -> void:
	grid_helper._refresh_grid(self)


func _get_brick_count(level_data: Dictionary) -> int:
	return grid_helper._get_brick_count(level_data)


func _get_cell_short_text(row: int, col: int) -> String:
	return grid_helper._get_cell_short_text(self, row, col)


func _get_cell_color(row: int, col: int) -> Color:
	return grid_helper._get_cell_color(self, row, col)


func _get_brick_type_at(row: int, col: int) -> String:
	return grid_helper._get_brick_type_at(self, row, col)


func _get_brick_data_at(row: int, col: int) -> Dictionary:
	return grid_helper._get_brick_data_at(self, row, col)


func _set_brick_type_at(row: int, col: int, brick_type: String) -> bool:
	return grid_helper._set_brick_type_at(self, row, col, brick_type)


func _sanitize_pack_id(raw_id: String) -> String:
	return pack_io_helper._sanitize_pack_id(raw_id)


func _on_grid_cell_pressed(row: int, col: int) -> void:
	var target_type: String = "" if selected_brick_type == "ERASER" else selected_brick_type
	_push_undo_state()
	if _set_brick_type_at(row, col, target_type):
		_refresh_grid()
		return
	if not undo_helper.undo_stack.is_empty():
		undo_helper.undo_stack.remove_at(undo_helper.undo_stack.size() - 1)

func _on_grid_cell_gui_input(event: InputEvent, row: int, col: int) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_event: InputEventMouseButton = event
	if mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
		_push_undo_state()
		if _set_brick_type_at(row, col, ""):
			_refresh_grid()
			return
		if not undo_helper.undo_stack.is_empty():
			undo_helper.undo_stack.remove_at(undo_helper.undo_stack.size() - 1)

func _on_level_list_item_selected(index: int) -> void:
	selected_level_index = index
	_refresh_level_details()
	_refresh_grid()

func _on_level_name_input_text_changed(new_text: String) -> void:
	if is_refreshing_ui:
		return
	var trimmed: String = new_text.strip_edges()
	var level_data: Dictionary = _get_current_level()
	var existing_name: String = str(level_data.get("name", ""))
	if existing_name == trimmed:
		return
	_push_undo_state()
	level_data["name"] = trimmed
	_set_current_level(level_data)
	_refresh_level_list()
	status_label.text = "Updated level name"

func _on_level_description_input_text_changed() -> void:
	if is_refreshing_ui:
		return
	var level_data: Dictionary = _get_current_level()
	var new_desc: String = level_description_input.text
	var existing_desc: String = str(level_data.get("description", ""))
	if existing_desc == new_desc:
		return
	_push_undo_state()
	level_data["description"] = new_desc
	_set_current_level(level_data)
	status_label.text = "Updated level description"

func _on_duplicate_level_button_pressed() -> void:
	var levels: Array = current_pack.get("levels", [])
	if levels.is_empty():
		return
	_push_undo_state()
	var source_level: Dictionary = levels[selected_level_index].duplicate(true)
	var source_name: String = str(source_level.get("name", "Level %d" % (selected_level_index + 1)))
	source_level["name"] = source_name + " Copy"
	var insert_index: int = selected_level_index + 1
	levels.insert(insert_index, source_level)
	_reindex_levels(levels)
	current_pack["levels"] = levels
	selected_level_index = insert_index
	_refresh_level_list()
	_refresh_level_details()
	_refresh_grid()
	status_label.text = "Duplicated level %d" % selected_level_index

func _on_move_level_up_button_pressed() -> void:
	var levels: Array = current_pack.get("levels", [])
	if selected_level_index <= 0 or selected_level_index >= levels.size():
		return
	_push_undo_state()
	var moving: Variant = levels[selected_level_index]
	levels[selected_level_index] = levels[selected_level_index - 1]
	levels[selected_level_index - 1] = moving
	_reindex_levels(levels)
	current_pack["levels"] = levels
	selected_level_index -= 1
	_refresh_level_list()
	_refresh_level_details()
	_refresh_grid()
	status_label.text = "Moved level up"

func _on_move_level_down_button_pressed() -> void:
	var levels: Array = current_pack.get("levels", [])
	if levels.is_empty() or selected_level_index < 0 or selected_level_index >= levels.size() - 1:
		return
	_push_undo_state()
	var moving: Variant = levels[selected_level_index]
	levels[selected_level_index] = levels[selected_level_index + 1]
	levels[selected_level_index + 1] = moving
	_reindex_levels(levels)
	current_pack["levels"] = levels
	selected_level_index += 1
	_refresh_level_list()
	_refresh_level_details()
	_refresh_grid()
	status_label.text = "Moved level down"

func _on_add_level_button_pressed() -> void:
	_push_undo_state()
	var levels: Array = current_pack.get("levels", [])
	levels.append(_create_default_level(levels.size()))
	_reindex_levels(levels)
	current_pack["levels"] = levels
	selected_level_index = levels.size() - 1
	_refresh_level_list()
	_refresh_level_details()
	_refresh_grid()
	status_label.text = "Added level %d" % (selected_level_index + 1)

func _on_remove_level_button_pressed() -> void:
	var levels: Array = current_pack.get("levels", [])
	if levels.size() <= 1:
		status_label.text = "A pack needs at least one level"
		return
	_push_undo_state()
	levels.remove_at(selected_level_index)
	_reindex_levels(levels)
	current_pack["levels"] = levels
	selected_level_index = clampi(selected_level_index, 0, levels.size() - 1)
	_refresh_level_list()
	_refresh_level_details()
	_refresh_grid()
	status_label.text = "Removed level"

func _on_palette_select_item_selected(index: int) -> void:
	selected_brick_type = palette_select.get_item_text(index)
	_refresh_special_picker_visibility()
	status_label.text = "Brush: %s" % selected_brick_type

func _on_direction_select_item_selected(index: int) -> void:
	selected_direction = int(direction_select.get_item_id(index))
	status_label.text = "Arrow direction: %s" % _get_direction_label(selected_direction)

func _on_powerup_type_select_item_selected(index: int) -> void:
	selected_powerup_type = powerup_type_select.get_item_text(index)
	status_label.text = "Power-up brick: %s" % selected_powerup_type

func _on_rows_input_value_changed(value: float) -> void:
	if is_refreshing_ui:
		return
	_update_grid_size(int(value), int(cols_input.value))

func _on_cols_input_value_changed(value: float) -> void:
	if is_refreshing_ui:
		return
	_update_grid_size(int(rows_input.value), int(value))

func _update_grid_size(rows: int, cols: int) -> void:
	grid_helper._update_grid_size(self, rows, cols)


func _on_save_button_pressed() -> void:
	pack_io_helper._on_save_button_pressed(self)


func _on_delete_button_pressed() -> void:
	pack_io_helper._on_delete_button_pressed(self)


func _on_delete_confirm_dialog_confirmed() -> void:
	pack_io_helper._on_delete_confirm_dialog_confirmed(self)


func _on_export_button_pressed() -> void:
	pack_io_helper._on_export_button_pressed(self)


func _on_test_button_pressed() -> void:
	pack_io_helper._on_test_button_pressed(self)


func _on_undo_button_pressed() -> void:
	undo_helper._on_undo_button_pressed(self)

func _on_redo_button_pressed() -> void:
	undo_helper._on_redo_button_pressed(self)

func _on_back_button_pressed() -> void:
	MenuController.return_from_editor()

func _on_open_saved_packs_button_pressed() -> void:
	MenuController.show_set_select()

func _on_open_exports_folder_button_pressed() -> void:
	pack_io_helper._on_open_exports_folder_button_pressed(self)


func _build_pack_payload(target_pack_id: String) -> Dictionary:
	return pack_io_helper._build_pack_payload(self, target_pack_id)


func _requires_pack_v2(pack_data: Dictionary) -> bool:
	return pack_io_helper._requires_pack_v2(pack_data)

