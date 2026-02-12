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
	"POLYGON_GLOSSY"
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
@onready var grid_container: GridContainer = $VBoxContainer/Body/RightPanel/GridScroll/GridContainer
@onready var status_label: Label = $VBoxContainer/FooterRow/StatusLabel
@onready var delete_button: Button = $VBoxContainer/Body/RightPanel/RightControls/ActionRow/DeleteButton
@onready var delete_confirm_dialog: ConfirmationDialog = $DeleteConfirmDialog

var current_pack: Dictionary = {}
var selected_level_index: int = 0
var selected_brick_type: String = "NORMAL"
var undo_stack: Array[Dictionary] = []
var redo_stack: Array[Dictionary] = []
var is_refreshing_ui: bool = false

const MAX_UNDO_STATES: int = 50
const EXPORTS_PATH: String = "user://exports/"
const MAX_PLAYABLE_ROWS: int = 12
const MAX_PLAYABLE_COLS: int = 19

func _ready() -> void:
	_update_back_button_text()
	_initialize_palette()
	_initialize_editor_pack()
	_refresh_all_ui()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()
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

func _initialize_editor_pack() -> void:
	var draft_pack: Dictionary = MenuController.get_editor_draft_pack()
	if not draft_pack.is_empty():
		current_pack = draft_pack.duplicate(true)
		selected_level_index = clampi(MenuController.get_editor_draft_level_index(), 0, max(0, current_pack.get("levels", []).size() - 1))
		title_label.text = "LEVEL EDITOR - TEST DRAFT"
		status_label.text = "Restored draft after test run"
		return

	var requested_pack_id: String = MenuController.get_editor_pack_id()
	if not requested_pack_id.is_empty() and PackLoader.pack_exists(requested_pack_id):
		current_pack = PackLoader.get_pack(requested_pack_id)
		title_label.text = "LEVEL EDITOR - EDIT PACK"
		status_label.text = "Loaded pack: %s" % requested_pack_id
		return

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

func _snapshot_state() -> Dictionary:
	return {
		"pack": current_pack.duplicate(true),
		"selected_level_index": selected_level_index
	}

func _push_undo_state() -> void:
	undo_stack.append(_snapshot_state())
	if undo_stack.size() > MAX_UNDO_STATES:
		undo_stack.remove_at(0)
	redo_stack.clear()

func _restore_snapshot(snapshot: Dictionary) -> void:
	current_pack = snapshot.get("pack", {}).duplicate(true)
	var levels: Array = current_pack.get("levels", [])
	if levels.is_empty():
		current_pack["levels"] = [_create_default_level(0)]
		levels = current_pack.get("levels", [])
	selected_level_index = clampi(int(snapshot.get("selected_level_index", 0)), 0, max(0, levels.size() - 1))
	_refresh_all_ui()

func _reindex_levels(levels: Array) -> void:
	for idx in range(levels.size()):
		if not (levels[idx] is Dictionary):
			continue
		var level_data: Dictionary = levels[idx]
		level_data["level_index"] = idx
		levels[idx] = level_data

func _refresh_all_ui() -> void:
	_refresh_metadata_fields()
	_refresh_level_list()
	_refresh_level_details()
	_refresh_grid()
	_update_delete_button_state()

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
	return {
		"max_rows": MAX_PLAYABLE_ROWS,
		"max_cols": MAX_PLAYABLE_COLS
	}

func _normalize_level_to_play_area(level_data: Dictionary) -> Dictionary:
	if level_data.is_empty():
		return level_data
	var output: Dictionary = level_data.duplicate(true)
	var grid: Dictionary = output.get("grid", {}).duplicate(true)
	var max_rows: int = MAX_PLAYABLE_ROWS
	var max_cols: int = MAX_PLAYABLE_COLS
	var rows: int = clampi(int(grid.get("rows", DEFAULT_ROWS)), 1, max_rows)
	var cols: int = clampi(int(grid.get("cols", DEFAULT_COLS)), 1, max_cols)
	grid["rows"] = rows
	grid["cols"] = cols
	output["grid"] = grid

	var bricks: Array = output.get("bricks", [])
	var filtered: Array = []
	for brick_variant in bricks:
		if not (brick_variant is Dictionary):
			continue
		var brick_data: Dictionary = brick_variant
		var row: int = int(brick_data.get("row", -1))
		var col: int = int(brick_data.get("col", -1))
		if row >= 0 and row < rows and col >= 0 and col < cols:
			filtered.append(brick_data)
	output["bricks"] = filtered
	return output

func _can_delete_current_pack() -> bool:
	var pack_id: String = str(current_pack.get("pack_id", "")).strip_edges()
	if pack_id.is_empty():
		return false
	if not PackLoader.pack_exists(pack_id):
		return false
	var existing_pack: Dictionary = PackLoader.get_pack(pack_id)
	if existing_pack.is_empty():
		return false
	return str(existing_pack.get("source", "")) == "user"

func _update_delete_button_state() -> void:
	delete_button.disabled = not _can_delete_current_pack()

func _refresh_grid() -> void:
	for child in grid_container.get_children():
		child.queue_free()

	var level_data: Dictionary = _get_current_level()
	var grid: Dictionary = level_data.get("grid", {})
	var rows: int = int(grid.get("rows", DEFAULT_ROWS))
	var cols: int = int(grid.get("cols", DEFAULT_COLS))
	grid_container.columns = cols

	for row in range(rows):
		for col in range(cols):
			var button: Button = Button.new()
			button.custom_minimum_size = Vector2(32, 22)
			button.text = _get_cell_short_text(row, col)
			button.modulate = _get_cell_color(row, col)
			button.pressed.connect(_on_grid_cell_pressed.bind(row, col))
			button.gui_input.connect(_on_grid_cell_gui_input.bind(row, col))
			grid_container.add_child(button)

	status_label.text = "Level %d | Grid %dx%d | Bricks %d" % [
		selected_level_index + 1,
		rows,
		cols,
		_get_brick_count(level_data)
	]

func _get_brick_count(level_data: Dictionary) -> int:
	var bricks: Array = level_data.get("bricks", [])
	return bricks.size()

func _get_cell_short_text(row: int, col: int) -> String:
	var brick_type: String = _get_brick_type_at(row, col)
	if brick_type.is_empty():
		return ""
	return brick_type.substr(0, 1)

func _get_cell_color(row: int, col: int) -> Color:
	var brick_type: String = _get_brick_type_at(row, col)
	if brick_type.is_empty():
		return Color(0.16, 0.16, 0.2, 1.0)
	return BRICK_COLORS.get(brick_type, Color.WHITE)

func _get_brick_type_at(row: int, col: int) -> String:
	var level_data: Dictionary = _get_current_level()
	var bricks: Array = level_data.get("bricks", [])
	for brick_variant in bricks:
		if not (brick_variant is Dictionary):
			continue
		var brick_data: Dictionary = brick_variant
		if int(brick_data.get("row", -1)) == row and int(brick_data.get("col", -1)) == col:
			return str(brick_data.get("type", ""))
	return ""

func _set_brick_type_at(row: int, col: int, brick_type: String) -> bool:
	var level_data: Dictionary = _get_current_level()
	var bricks: Array = level_data.get("bricks", [])
	var index: int = -1

	for idx in range(bricks.size()):
		var brick_variant = bricks[idx]
		if not (brick_variant is Dictionary):
			continue
		var brick_data: Dictionary = brick_variant
		if int(brick_data.get("row", -1)) == row and int(brick_data.get("col", -1)) == col:
			index = idx
			break

	if brick_type.is_empty():
		if index != -1:
			bricks.remove_at(index)
		else:
			return false
	else:
		var entry: Dictionary = {
			"row": row,
			"col": col,
			"type": brick_type
		}
		if index == -1:
			bricks.append(entry)
		else:
			var existing: Dictionary = bricks[index]
			if int(existing.get("row", -1)) == row and int(existing.get("col", -1)) == col and str(existing.get("type", "")) == brick_type:
				return false
			bricks[index] = entry

	level_data["bricks"] = bricks
	_set_current_level(level_data)
	return true

func _sanitize_pack_id(raw_id: String) -> String:
	var value: String = raw_id.strip_edges().to_lower()
	value = value.replace(" ", "-")
	var output: String = ""
	for idx in range(value.length()):
		var c: String = value.substr(idx, 1)
		var is_valid: bool = (c >= "a" and c <= "z") or (c >= "0" and c <= "9") or c == "-" or c == "_"
		if is_valid:
			output += c
	while output.find("--") != -1:
		output = output.replace("--", "-")
	return output.trim_prefix("-").trim_suffix("-")

func _on_grid_cell_pressed(row: int, col: int) -> void:
	var target_type: String = "" if selected_brick_type == "ERASER" else selected_brick_type
	_push_undo_state()
	if _set_brick_type_at(row, col, target_type):
		_refresh_grid()
		return
	if not undo_stack.is_empty():
		undo_stack.remove_at(undo_stack.size() - 1)

func _on_grid_cell_gui_input(event: InputEvent, row: int, col: int) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_event: InputEventMouseButton = event
	if mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
		_push_undo_state()
		if _set_brick_type_at(row, col, ""):
			_refresh_grid()
			return
		if not undo_stack.is_empty():
			undo_stack.remove_at(undo_stack.size() - 1)

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
	status_label.text = "Brush: %s" % selected_brick_type

func _on_rows_input_value_changed(value: float) -> void:
	if is_refreshing_ui:
		return
	_update_grid_size(int(value), int(cols_input.value))

func _on_cols_input_value_changed(value: float) -> void:
	if is_refreshing_ui:
		return
	_update_grid_size(int(rows_input.value), int(value))

func _update_grid_size(rows: int, cols: int) -> void:
	var level_data: Dictionary = _get_current_level()
	var grid: Dictionary = level_data.get("grid", {})
	var limits: Dictionary = _get_grid_limits_for_play_area(grid)
	rows = clampi(rows, 1, int(limits.get("max_rows", 1)))
	cols = clampi(cols, 1, int(limits.get("max_cols", 1)))
	var current_rows: int = int(grid.get("rows", DEFAULT_ROWS))
	var current_cols: int = int(grid.get("cols", DEFAULT_COLS))
	if current_rows == rows and current_cols == cols:
		return
	_push_undo_state()
	grid["rows"] = rows
	grid["cols"] = cols
	level_data["grid"] = grid

	var bricks: Array = level_data.get("bricks", [])
	var filtered: Array = []
	for brick_variant in bricks:
		if not (brick_variant is Dictionary):
			continue
		var brick_data: Dictionary = brick_variant
		var row: int = int(brick_data.get("row", -1))
		var col: int = int(brick_data.get("col", -1))
		if row >= 0 and row < rows and col >= 0 and col < cols:
			filtered.append(brick_data)
	level_data["bricks"] = filtered
	_set_current_level(level_data)
	_refresh_grid()
	status_label.text = "Resized grid to %dx%d" % [rows, cols]

func _on_save_button_pressed() -> void:
	var normalized_pack_id: String = _sanitize_pack_id(pack_id_input.text)
	if normalized_pack_id.is_empty():
		status_label.text = "Pack ID is required"
		return
	if pack_name_input.text.strip_edges().is_empty():
		status_label.text = "Pack Name is required"
		return

	var persist_pack: Dictionary = _build_pack_payload(normalized_pack_id)
	if persist_pack.is_empty():
		status_label.text = "Save failed (invalid pack data)"
		return
	current_pack = persist_pack.duplicate(true)

	var saved: bool = PackLoader.save_user_pack(current_pack)
	if not saved:
		status_label.text = "Save failed (validation error)"
		return

	MenuController.current_editor_pack_id = normalized_pack_id
	status_label.text = "Saved pack: %s (reopen via OPEN SAVED PACKS -> EDIT)" % normalized_pack_id
	_update_delete_button_state()

func _on_delete_button_pressed() -> void:
	var pack_id: String = str(current_pack.get("pack_id", "")).strip_edges()
	if not _can_delete_current_pack():
		status_label.text = "Delete available only for saved custom packs"
		return
	delete_confirm_dialog.dialog_text = "Delete pack \"%s\"?\nThis cannot be undone." % pack_id
	delete_confirm_dialog.popup_centered()

func _on_delete_confirm_dialog_confirmed() -> void:
	var pack_id: String = str(current_pack.get("pack_id", "")).strip_edges()
	if not _can_delete_current_pack():
		status_label.text = "Pack is not deletable"
		_update_delete_button_state()
		return
	if not PackLoader.delete_user_pack(pack_id):
		status_label.text = "Failed to delete pack"
		return
	MenuController.current_editor_pack_id = ""
	status_label.text = "Deleted pack: %s" % pack_id
	MenuController.show_set_select()

func _on_export_button_pressed() -> void:
	var export_pack_id: String = _sanitize_pack_id(pack_id_input.text)
	if export_pack_id.is_empty():
		export_pack_id = "export-pack"

	var export_pack: Dictionary = _build_pack_payload(export_pack_id)
	if export_pack.is_empty():
		status_label.text = "Export failed (invalid pack data)"
		return

	var root_dir: DirAccess = DirAccess.open("user://")
	if root_dir == null:
		status_label.text = "Export failed (cannot access user://)"
		return
	if not root_dir.dir_exists("exports"):
		var mkdir_result: int = root_dir.make_dir_recursive("exports")
		if mkdir_result != OK:
			status_label.text = "Export failed (cannot create exports folder)"
			return

	var dt: Dictionary = Time.get_datetime_dict_from_system(true)
	var timestamp: String = "%04d%02d%02d-%02d%02d%02d" % [
		int(dt.get("year", 0)),
		int(dt.get("month", 0)),
		int(dt.get("day", 0)),
		int(dt.get("hour", 0)),
		int(dt.get("minute", 0)),
		int(dt.get("second", 0))
	]
	var file_name: String = "%s-%s.zeppack" % [export_pack_id, timestamp]
	var export_path: String = EXPORTS_PATH + file_name

	var file: FileAccess = FileAccess.open(export_path, FileAccess.WRITE)
	if file == null:
		status_label.text = "Export failed (cannot write file)"
		return
	file.store_string(JSON.stringify(export_pack, "\t"))
	file.close()

	var full_path: String = ProjectSettings.globalize_path(export_path)
	status_label.text = "Exported: %s" % full_path

func _on_test_button_pressed() -> void:
	var levels: Array = current_pack.get("levels", [])
	if levels.is_empty():
		status_label.text = "Add at least one level before testing"
		return
	var level_data: Dictionary = _normalize_level_to_play_area(_get_current_level())
	var level_name: String = str(level_data.get("name", "")).strip_edges()
	if level_name.is_empty():
		level_data["name"] = "Level %d" % (selected_level_index + 1)
	var level_grid: Dictionary = level_data.get("grid", {})
	var limits: Dictionary = _get_grid_limits_for_play_area(level_grid)
	level_grid["rows"] = clampi(int(level_grid.get("rows", DEFAULT_ROWS)), 1, int(limits.get("max_rows", 1)))
	level_grid["cols"] = clampi(int(level_grid.get("cols", DEFAULT_COLS)), 1, int(limits.get("max_cols", 1)))
	level_data["grid"] = level_grid

	var test_pack: Dictionary = current_pack.duplicate(true)
	var test_levels: Array = test_pack.get("levels", [])
	test_levels[selected_level_index] = level_data
	test_pack["levels"] = test_levels
	test_pack["source"] = "user"
	if str(test_pack.get("pack_id", "")).strip_edges().is_empty():
		test_pack["pack_id"] = "editor-test-pack"
	if str(test_pack.get("name", "")).strip_edges().is_empty():
		test_pack["name"] = "Editor Test Pack"

	MenuController.start_editor_test(test_pack, selected_level_index)

func _on_undo_button_pressed() -> void:
	if undo_stack.is_empty():
		status_label.text = "Nothing to undo"
		return
	redo_stack.append(_snapshot_state())
	if redo_stack.size() > MAX_UNDO_STATES:
		redo_stack.remove_at(0)
	var snapshot: Dictionary = undo_stack[undo_stack.size() - 1]
	undo_stack.remove_at(undo_stack.size() - 1)
	_restore_snapshot(snapshot)
	status_label.text = "Undo"

func _on_redo_button_pressed() -> void:
	if redo_stack.is_empty():
		status_label.text = "Nothing to redo"
		return
	undo_stack.append(_snapshot_state())
	if undo_stack.size() > MAX_UNDO_STATES:
		undo_stack.remove_at(0)
	var snapshot: Dictionary = redo_stack[redo_stack.size() - 1]
	redo_stack.remove_at(redo_stack.size() - 1)
	_restore_snapshot(snapshot)
	status_label.text = "Redo"

func _on_back_button_pressed() -> void:
	MenuController.return_from_editor()

func _on_open_saved_packs_button_pressed() -> void:
	MenuController.show_set_select()

func _on_open_exports_folder_button_pressed() -> void:
	var root_dir: DirAccess = DirAccess.open("user://")
	if root_dir == null:
		status_label.text = "Cannot access user://"
		return
	if not root_dir.dir_exists("exports"):
		var mkdir_result: int = root_dir.make_dir_recursive("exports")
		if mkdir_result != OK:
			status_label.text = "Cannot create exports folder"
			return

	var exports_global_path: String = ProjectSettings.globalize_path(EXPORTS_PATH)
	var opened: Error = OS.shell_open(exports_global_path)
	if opened != OK:
		# Fallback URI form for desktop environments that prefer file scheme.
		opened = OS.shell_open("file://" + exports_global_path)
	if opened != OK:
		status_label.text = "Failed to open export folder"
		return
	status_label.text = "Opened export folder: %s" % exports_global_path

func _build_pack_payload(target_pack_id: String) -> Dictionary:
	var to_save: Dictionary = current_pack.duplicate(true)
	var pack_id: String = _sanitize_pack_id(target_pack_id)
	if pack_id.is_empty():
		return {}
	var pack_name: String = pack_name_input.text.strip_edges()
	if pack_name.is_empty():
		return {}

	to_save["pack_id"] = pack_id
	to_save["name"] = pack_name
	to_save["author"] = author_input.text.strip_edges()
	to_save["description"] = description_input.text.strip_edges()
	to_save["source"] = "user"
	to_save["updated_at"] = Time.get_datetime_string_from_system(true)
	if not to_save.has("created_at"):
		to_save["created_at"] = to_save["updated_at"]

	var levels: Array = to_save.get("levels", [])
	_reindex_levels(levels)
	for idx in range(levels.size()):
		if not (levels[idx] is Dictionary):
			continue
		var source_level: Dictionary = levels[idx]
		var level_data: Dictionary = _normalize_level_to_play_area(source_level)
		if str(level_data.get("name", "")).strip_edges().is_empty():
			level_data["name"] = "Level %d" % (idx + 1)
		levels[idx] = level_data
	to_save["levels"] = levels

	var errors: Array[String] = PackLoader.validate_pack(to_save)
	if not errors.is_empty():
		push_warning("LevelEditor export/save payload invalid: %s" % "; ".join(errors))
		return {}

	return to_save
