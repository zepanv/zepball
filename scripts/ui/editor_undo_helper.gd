class_name EditorUndoHelper
extends RefCounted

const MAX_UNDO_STATES: int = 50

var undo_stack: Array[Dictionary] = []
var redo_stack: Array[Dictionary] = []

func push_state(snapshot: Dictionary) -> void:
	undo_stack.append(snapshot)
	if undo_stack.size() > MAX_UNDO_STATES:
		undo_stack.remove_at(0)
	redo_stack.clear()

func undo(current_state: Dictionary) -> Variant:
	if undo_stack.is_empty():
		return null
	
	redo_stack.append(current_state)
	if redo_stack.size() > MAX_UNDO_STATES:
		redo_stack.remove_at(0)
		
	return undo_stack.pop_back()

func redo(current_state: Dictionary) -> Variant:
	if redo_stack.is_empty():
		return null
		
	undo_stack.append(current_state)
	if undo_stack.size() > MAX_UNDO_STATES:
		undo_stack.remove_at(0)
		
	return redo_stack.pop_back()

func _snapshot_state(parent: Node) -> Dictionary:
	return {
		"pack": parent.current_pack.duplicate(true),
		"selected_level_index": parent.selected_level_index
	}

func _push_undo_state(parent: Node) -> void:
	push_state(_snapshot_state(parent))

func _restore_snapshot(parent: Node, snapshot: Dictionary) -> void:
	parent.current_pack = snapshot.get("pack", {}).duplicate(true)
	var levels: Array = parent.current_pack.get("levels", [])
	if levels.is_empty():
		parent.current_pack["levels"] = [parent._create_default_level(0)]
		levels = parent.current_pack.get("levels", [])
	parent.selected_level_index = clampi(int(snapshot.get("selected_level_index", 0)), 0, max(0, levels.size() - 1))
	parent._refresh_all_ui()

func _on_undo_button_pressed(parent: Node) -> void:
	var snapshot = undo(_snapshot_state(parent))
	if snapshot != null:
		_restore_snapshot(parent, snapshot)
		parent.status_label.text = "Undo"
	else:
		parent.status_label.text = "Nothing to undo"

func _on_redo_button_pressed(parent: Node) -> void:
	var snapshot = redo(_snapshot_state(parent))
	if snapshot != null:
		_restore_snapshot(parent, snapshot)
		parent.status_label.text = "Redo"
	else:
		parent.status_label.text = "Nothing to redo"
