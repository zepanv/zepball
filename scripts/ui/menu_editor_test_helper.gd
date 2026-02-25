class_name MenuEditorTestHelper
extends RefCounted

var is_editor_test_mode: bool = false
var editor_test_pack_data: Dictionary = {}
var editor_test_level_index: int = 0
var editor_draft_pack_data: Dictionary = {}
var editor_draft_level_index: int = 0
var editor_draft_is_builtin_edit: bool = false

func start_editor_test(parent: Node, pack_data: Dictionary, level_index: int, draft_is_builtin_edit: bool = false) -> void:
	if not (pack_data.get("levels", []) is Array):
		push_error("Editor test failed: pack has invalid levels")
		return
	var levels: Array = pack_data.get("levels", [])
	if levels.is_empty():
		push_error("Editor test failed: pack has no levels")
		return
	var clamped_level_index: int = clampi(level_index, 0, levels.size() - 1)

	editor_draft_pack_data = pack_data.duplicate(true)
	editor_draft_level_index = clamped_level_index
	editor_draft_is_builtin_edit = draft_is_builtin_edit
	editor_test_pack_data = pack_data.duplicate(true)
	editor_test_level_index = clamped_level_index
	is_editor_test_mode = true

	parent.current_play_mode = parent.PlayMode.INDIVIDUAL
	parent.current_set_id = -1
	parent.current_set_pack_id = ""
	parent.set_mode_helper.set_current_index = 0
	parent.set_mode_helper.set_level_ids.clear()
	parent.set_mode_helper.set_level_refs.clear()
	parent._reset_set_breakdown()

	parent.current_pack_id = "__editor_test__"
	parent.current_level_index = clamped_level_index
	parent.current_level_id = clamped_level_index + 1
	parent.is_in_gameplay = true
	parent.current_score = 0
	parent.was_perfect_clear = false

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	DifficultyManager.lock_difficulty()
	parent.get_tree().change_scene_to_file(parent.GAMEPLAY_SCENE)
	parent.scene_changed.emit(parent.GAMEPLAY_SCENE)

func has_editor_test_data() -> bool:
	return is_editor_test_mode and not editor_test_pack_data.is_empty()

func get_editor_test_level_data() -> Dictionary:
	if not has_editor_test_data():
		return {}
	var levels: Array = editor_test_pack_data.get("levels", [])
	if editor_test_level_index < 0 or editor_test_level_index >= levels.size():
		return {}
	if not (levels[editor_test_level_index] is Dictionary):
		return {}
	return (levels[editor_test_level_index] as Dictionary).duplicate(true)

func get_editor_test_level_name() -> String:
	var level_data: Dictionary = get_editor_test_level_data()
	return str(level_data.get("name", "Editor Test"))

func get_editor_test_level_description() -> String:
	var level_data: Dictionary = get_editor_test_level_data()
	return str(level_data.get("description", ""))

func get_editor_draft_pack() -> Dictionary:
	return editor_draft_pack_data.duplicate(true)

func get_editor_draft_level_index() -> int:
	return editor_draft_level_index

func get_editor_draft_is_builtin_edit() -> bool:
	return editor_draft_is_builtin_edit

func clear_editor_test_state() -> void:
	is_editor_test_mode = false
	editor_test_pack_data = {}
	editor_test_level_index = 0

func return_to_editor_from_test(parent: Node) -> void:
	parent.is_in_gameplay = false
	clear_editor_test_state()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	DifficultyManager.unlock_difficulty()
	parent.get_tree().change_scene_to_file(parent.LEVEL_EDITOR_SCENE)
	parent.scene_changed.emit(parent.LEVEL_EDITOR_SCENE)
