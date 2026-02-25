class_name EditorPackIOHelper
extends RefCounted

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

func _can_delete_current_pack(parent: Node) -> bool:
	var pack_id: String = str(parent.current_pack.get("pack_id", "")).strip_edges()
	if pack_id.is_empty():
		return false
	if not PackLoader.pack_exists(pack_id):
		return false
	var existing_pack: Dictionary = PackLoader.get_pack(pack_id)
	if existing_pack.is_empty():
		return false
	return str(existing_pack.get("source", "")) == "user"

func _update_delete_button_state(parent: Node) -> void:
	parent.delete_button.disabled = not _can_delete_current_pack(parent)

func _on_save_button_pressed(parent: Node) -> void:
	var normalized_pack_id: String = _sanitize_pack_id(parent.pack_id_input.text)
	if normalized_pack_id.is_empty():
		parent.status_label.text = "Pack ID is required"
		return
	if parent.pack_name_input.text.strip_edges().is_empty():
		parent.status_label.text = "Pack Name is required"
		return

	var is_builtin: bool = parent._editing_builtin_pack

	var persist_pack: Dictionary = _build_pack_payload(parent, normalized_pack_id)
	if persist_pack.is_empty():
		parent.status_label.text = "Save failed (invalid pack data)"
		return
	parent.current_pack = persist_pack.duplicate(true)
	var saved: bool
	var saved_as_builtin: bool = is_builtin and OS.is_debug_build()
	if saved_as_builtin:
		saved = PackLoader.save_builtin_pack(parent.current_pack)
	else:
		saved = PackLoader.save_user_pack(parent.current_pack)
	if not saved:
		parent.status_label.text = "Save failed (validation error)"
		return

	MenuController.current_editor_pack_id = normalized_pack_id
	if saved_as_builtin:
		parent.status_label.text = "Saved builtin pack: %s" % normalized_pack_id
	else:
		parent.status_label.text = "Saved pack: %s (reopen via OPEN SAVED PACKS -> EDIT)" % normalized_pack_id
	_update_delete_button_state(parent)

func _on_delete_button_pressed(parent: Node) -> void:
	var pack_id: String = str(parent.current_pack.get("pack_id", "")).strip_edges()
	if not _can_delete_current_pack(parent):
		parent.status_label.text = "Delete available only for saved custom packs"
		return
	parent.delete_confirm_dialog.dialog_text = "Delete pack "%s"?
This cannot be undone." % pack_id
	parent.delete_confirm_dialog.popup_centered()

func _on_delete_confirm_dialog_confirmed(parent: Node) -> void:
	var pack_id: String = str(parent.current_pack.get("pack_id", "")).strip_edges()
	if not _can_delete_current_pack(parent):
		parent.status_label.text = "Pack is not deletable"
		_update_delete_button_state(parent)
		return
	if not PackLoader.delete_user_pack(pack_id):
		parent.status_label.text = "Failed to delete pack"
		return
	MenuController.current_editor_pack_id = ""
	parent.status_label.text = "Deleted pack: %s" % pack_id
	MenuController.show_set_select()

func _on_export_button_pressed(parent: Node) -> void:
	var export_pack_id: String = _sanitize_pack_id(parent.pack_id_input.text)
	if export_pack_id.is_empty():
		export_pack_id = "export-pack"

	var export_pack: Dictionary = _build_pack_payload(parent, export_pack_id)
	if export_pack.is_empty():
		parent.status_label.text = "Export failed (invalid pack data)"
		return

	var root_dir: DirAccess = DirAccess.open("user://")
	if root_dir == null:
		parent.status_label.text = "Export failed (cannot access user://)"
		return
	if not root_dir.dir_exists("exports"):
		var mkdir_result: int = root_dir.make_dir_recursive("exports")
		if mkdir_result != OK:
			parent.status_label.text = "Export failed (cannot create exports folder)"
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
	var export_path: String = parent.EXPORTS_PATH + file_name

	var file: FileAccess = FileAccess.open(export_path, FileAccess.WRITE)
	if file == null:
		parent.status_label.text = "Export failed (cannot write file)"
		return
	file.store_string(JSON.stringify(export_pack, "	"))
	file.close()

	var full_path: String = ProjectSettings.globalize_path(export_path)
	parent.status_label.text = "Exported: %s" % full_path

func _on_test_button_pressed(parent: Node) -> void:
	var levels: Array = parent.current_pack.get("levels", [])
	if levels.is_empty():
		parent.status_label.text = "Add at least one level before testing"
		return
	var level_data: Dictionary = parent._normalize_level_to_play_area(parent._get_current_level())
	var level_name: String = str(level_data.get("name", "")).strip_edges()
	if level_name.is_empty():
		level_data["name"] = "Level %d" % (parent.selected_level_index + 1)
	var level_grid: Dictionary = level_data.get("grid", {})
	var limits: Dictionary = parent._get_grid_limits_for_play_area(level_grid)
	level_grid["rows"] = clampi(int(level_grid.get("rows", parent.DEFAULT_ROWS)), 1, int(limits.get("max_rows", 1)))
	level_grid["cols"] = clampi(int(level_grid.get("cols", parent.DEFAULT_COLS)), 1, int(limits.get("max_cols", 1)))
	level_data["grid"] = level_grid

	var test_pack: Dictionary = parent.current_pack.duplicate(true)
	var test_levels: Array = test_pack.get("levels", [])
	test_levels[parent.selected_level_index] = level_data
	test_pack["levels"] = test_levels
	test_pack["source"] = "user"
	if str(test_pack.get("pack_id", "")).strip_edges().is_empty():
		test_pack["pack_id"] = "editor-test-pack"
	if str(test_pack.get("name", "")).strip_edges().is_empty():
		test_pack["name"] = "Editor Test Pack"

	MenuController.start_editor_test(test_pack, parent.selected_level_index, parent._editing_builtin_pack)

func _on_open_exports_folder_button_pressed(parent: Node) -> void:
	var root_dir: DirAccess = DirAccess.open("user://")
	if root_dir == null:
		parent.status_label.text = "Cannot access user://"
		return
	if not root_dir.dir_exists("exports"):
		var mkdir_result: int = root_dir.make_dir_recursive("exports")
		if mkdir_result != OK:
			parent.status_label.text = "Cannot create exports folder"
			return

	var exports_global_path: String = ProjectSettings.globalize_path(parent.EXPORTS_PATH)
	var opened: Error = OS.shell_open(exports_global_path)
	if opened != OK:
		# Fallback URI form for desktop environments that prefer file scheme.
		opened = OS.shell_open("file://" + exports_global_path)
	if opened != OK:
		parent.status_label.text = "Failed to open export folder"
		return
	parent.status_label.text = "Opened export folder: %s" % exports_global_path

func _build_pack_payload(parent: Node, target_pack_id: String) -> Dictionary:
	var to_save: Dictionary = parent.current_pack.duplicate(true)
	var pack_id: String = _sanitize_pack_id(target_pack_id)
	if pack_id.is_empty():
		return {}
	var pack_name: String = parent.pack_name_input.text.strip_edges()
	if pack_name.is_empty():
		return {}

	to_save["pack_id"] = pack_id
	to_save["name"] = pack_name
	to_save["author"] = parent.author_input.text.strip_edges()
	to_save["description"] = parent.description_input.text.strip_edges()
	to_save["source"] = "user"
	to_save["updated_at"] = Time.get_datetime_string_from_system(true)
	if not to_save.has("created_at"):
		to_save["created_at"] = to_save["updated_at"]

	var levels: Array = to_save.get("levels", [])
	parent._reindex_levels(levels)
	for idx in range(levels.size()):
		if not (levels[idx] is Dictionary):
			continue
		var source_level: Dictionary = levels[idx]
		var level_data: Dictionary = parent._normalize_level_to_play_area(source_level)
		if str(level_data.get("name", "")).strip_edges().is_empty():
			level_data["name"] = "Level %d" % (idx + 1)
		levels[idx] = level_data
	to_save["levels"] = levels
	to_save["zeppack_version"] = 2 if _requires_pack_v2(to_save) else 1

	var errors: Array[String] = PackLoader.validate_pack(to_save)
	if not errors.is_empty():
		push_warning("LevelEditor export/save payload invalid: %s" % "; ".join(errors))
		return {}

	return to_save

func _requires_pack_v2(pack_data: Dictionary) -> bool:
	var levels: Array = pack_data.get("levels", [])
	for level_variant in levels:
		if not (level_variant is Dictionary):
			continue
		var level_data: Dictionary = level_variant
		var bricks: Array = level_data.get("bricks", [])
		for brick_variant in bricks:
			if not (brick_variant is Dictionary):
				continue
			var brick_data: Dictionary = brick_variant
			var brick_type: String = str(brick_data.get("type", ""))
			if brick_type == "FORCE_ARROW" or brick_type == "POWERUP_BRICK":
				return true
	return false
