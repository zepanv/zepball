class_name PackLegacyHelper
extends RefCounted

func get_legacy_level_ref(parent: Node, level_id: int) -> Dictionary:
	if level_id <= 0:
		return {}

	var running_start: int = 1
	for legacy_pack_id in parent.LEGACY_PACK_ORDER:
		var count: int = parent.get_level_count(legacy_pack_id)
		if count <= 0:
			continue
		var running_end: int = running_start + count - 1
		if level_id >= running_start and level_id <= running_end:
			return {
				"pack_id": legacy_pack_id,
				"level_index": level_id - running_start
			}
		running_start = running_end + 1

	return {}

func get_legacy_total_level_count(parent: Node) -> int:
	var total: int = 0
	for legacy_pack_id in parent.LEGACY_PACK_ORDER:
		total += parent.get_level_count(legacy_pack_id)
	return total

func get_legacy_level_id(parent: Node, pack_id: String, level_index: int) -> int:
	var running_start: int = 1
	for legacy_pack_id in parent.LEGACY_PACK_ORDER:
		var count: int = parent.get_level_count(legacy_pack_id)
		if legacy_pack_id == pack_id:
			if level_index < 0 or level_index >= count:
				return -1
			return running_start + level_index
		running_start += count
	return -1

func get_all_legacy_sets(parent: Node) -> Array[Dictionary]:
	var sets: Array[Dictionary] = []
	for idx in range(parent.LEGACY_PACK_ORDER.size()):
		var set_id: int = idx + 1
		var set_data: Dictionary = get_legacy_set_data(parent, set_id)
		if not set_data.is_empty():
			sets.append(set_data)
	return sets

func get_legacy_set_data(parent: Node, set_id: int) -> Dictionary:
	if set_id <= 0 or set_id > parent.LEGACY_PACK_ORDER.size():
		return {}
	var pack_id: String = parent.LEGACY_PACK_ORDER[set_id - 1]
	if not parent.pack_exists(pack_id):
		return {}
	var pack: Dictionary = parent.get_pack(pack_id)
	return {
		"set_id": set_id,
		"pack_id": pack_id,
		"name": str(pack.get("name", "Unknown Set")),
		"description": str(pack.get("description", "")),
		"level_ids": get_legacy_set_level_ids(parent, set_id),
		"unlock_condition": "default"
	}

func legacy_set_exists(parent: Node, set_id: int) -> bool:
	return not get_legacy_set_data(parent, set_id).is_empty()

func get_legacy_set_pack_id(parent: Node, set_id: int) -> String:
	if set_id <= 0 or set_id > parent.LEGACY_PACK_ORDER.size():
		return ""
	return parent.LEGACY_PACK_ORDER[set_id - 1]

func get_legacy_set_level_ids(parent: Node, set_id: int) -> Array:
	var pack_id: String = get_legacy_set_pack_id(parent, set_id)
	if pack_id.is_empty():
		return []
	var ids: Array[int] = []
	var level_count: int = parent.get_level_count(pack_id)
	for level_index in range(level_count):
		var legacy_level_id: int = get_legacy_level_id(parent, pack_id, level_index)
		if legacy_level_id != -1:
			ids.append(legacy_level_id)
	return ids

func get_legacy_set_name(parent: Node, set_id: int) -> String:
	var set_data: Dictionary = get_legacy_set_data(parent, set_id)
	return str(set_data.get("name", "Unknown Set"))

func get_legacy_set_description(parent: Node, set_id: int) -> String:
	var set_data: Dictionary = get_legacy_set_data(parent, set_id)
	return str(set_data.get("description", ""))

func get_legacy_set_id_for_pack(parent: Node, pack_id: String) -> int:
	for idx in range(parent.LEGACY_PACK_ORDER.size()):
		if parent.LEGACY_PACK_ORDER[idx] == pack_id:
			return idx + 1
	return -1
