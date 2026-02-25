class_name SaveProfileHelper
extends RefCounted

func _ensure_dir_exists(parent: Node, path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		DirAccess.make_dir_recursive_absolute(path)

func load_metadata(parent: Node) -> void:
	if not FileAccess.file_exists(parent.METADATA_PATH):
		parent.metadata = {
			"last_selected_id": "",
			"profiles": {}
		}
		return

	var file = FileAccess.open(parent.METADATA_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		var json = JSON.new()
		if json.parse(json_string) == OK:
			parent.metadata = json.data
		else:
			push_error("Failed to parse metadata JSON")

func save_metadata(parent: Node) -> void:
	var file = FileAccess.open(parent.METADATA_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(parent.metadata, "	"))
		file.close()

func _migrate_legacy_save(parent: Node) -> void:
	print("Migrating legacy save data to Player 1 profile...")
	
	var file = FileAccess.open(parent.LEGACY_SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		var json = JSON.new()
		if json.parse(json_string) == OK:
			var legacy_data = json.data
			
			var profile_id = "player_1"
			parent.metadata["profiles"][profile_id] = "Player 1"
			parent.metadata["last_selected_id"] = profile_id
			save_metadata(parent)
			
			parent.current_profile_id = profile_id
			parent.save_data = legacy_data
			parent.save_to_disk()
			
			var dir = DirAccess.open("user://")
			dir.rename(parent.LEGACY_SAVE_PATH, "user://save_data.json.bak")
			print("Migration complete.")
			parent.save_loaded.emit()
			return
	
	create_profile(parent, "Player 1")

func create_profile(parent: Node, profile_name: String) -> String:
	var sanitized_name = sanitize_name(parent, profile_name)
	if sanitized_name == "":
		sanitized_name = "Player"

	var final_name = profile_name
	var name_counter = 2
	while _profile_name_exists(parent, final_name):
		final_name = profile_name + " (" + str(name_counter) + ")"
		name_counter += 1

	var base_id = sanitized_name.to_lower().replace(" ", "_")
	var profile_id = base_id
	var id_counter = 1
	while parent.metadata["profiles"].has(profile_id) or FileAccess.file_exists(_get_profile_path(parent, profile_id)):
		profile_id = base_id + "_" + str(id_counter)
		id_counter += 1
	
	parent.create_default_save()
	parent.save_data["profile"]["player_name"] = final_name
	
	parent.metadata["profiles"][profile_id] = final_name
	parent.metadata["last_selected_id"] = profile_id
	save_metadata(parent)
	
	parent.current_profile_id = profile_id
	parent.save_to_disk()

	_apply_profile_settings(parent)
	parent.high_scores_helper._invalidate_leaderboard_cache(parent)
	return profile_id

func load_profile(parent: Node, profile_id: String) -> void:
	if not parent.metadata["profiles"].has(profile_id):
		push_error("Attempted to load non-existent profile: " + profile_id)
		return
		
	var path = _get_profile_path(parent, profile_id)
	if not FileAccess.file_exists(path):
		push_error("Profile file missing: " + path)
		parent.create_default_save()
		parent.save_data["profile"]["player_name"] = parent.metadata["profiles"][profile_id]
		parent.current_profile_id = profile_id
		parent.save_to_disk()
		_apply_profile_settings(parent)
		return

	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		var json = JSON.new()
		if json.parse(json_string) == OK:
			parent.save_data = json.data
			parent.current_profile_id = profile_id
			parent.metadata["last_selected_id"] = profile_id
			save_metadata(parent)
			
			parent.progression_helper._perform_migrations(parent)
			
			_apply_profile_settings(parent)
		else:
			push_error("Failed to parse profile JSON: " + path)

func delete_profile(parent: Node, profile_id: String) -> void:
	if not parent.metadata["profiles"].has(profile_id):
		return
		
	print("Deleting profile: ", profile_id)
	var path = _get_profile_path(parent, profile_id)
	if FileAccess.file_exists(path):
		var err = DirAccess.remove_absolute(path)
		if err != OK:
			push_error("Failed to delete profile file: " + path)
		else:
			print("Deleted profile file: ", path)
	
	parent.metadata["profiles"].erase(profile_id)
	parent.high_scores_helper._invalidate_leaderboard_cache(parent)

	if parent.current_profile_id == profile_id:
		print("Deleted active profile, reloading...")
		parent.current_profile_id = ""
		parent.metadata["last_selected_id"] = ""
		save_metadata(parent)
		parent.load_save()
	else:
		save_metadata(parent)

func rename_current_profile(parent: Node, new_name: String) -> void:
	if parent.current_profile_id == "" or not parent.metadata["profiles"].has(parent.current_profile_id):
		return

	parent.metadata["profiles"][parent.current_profile_id] = new_name
	save_metadata(parent)

	parent.save_data["profile"]["player_name"] = new_name
	parent.save_to_disk()

	parent.high_scores_helper._invalidate_leaderboard_cache(parent)

func switch_profile(parent: Node, profile_id: String) -> void:
	if profile_id == parent.current_profile_id:
		return
	load_profile(parent, profile_id)

func _get_profile_path(parent: Node, profile_id: String) -> String:
	return parent.PROFILES_DIR + profile_id + ".json"

func sanitize_name(parent: Node, profile_name: String) -> String:
	var regex = RegEx.new()
	regex.compile("[^a-zA-Z0-9 ]")
	return regex.sub(profile_name, "", true).strip_edges()

func _profile_name_exists(parent: Node, profile_name: String) -> bool:
	for existing_name in parent.metadata["profiles"].values():
		if existing_name == profile_name:
			return true
	return false

func _apply_profile_settings(parent: Node) -> void:
	if parent.settings_helper:
		parent.settings_helper.apply_saved_keybindings(parent.save_data)
	
	if AudioManager and AudioManager.has_method("refresh_from_save"):
		AudioManager.refresh_from_save()
	
	parent.save_loaded.emit()

func get_next_default_name(parent: Node) -> String:
	var counter = 1
	var base_name = "Player "
	while true:
		var name_candidate = base_name + str(counter)
		var already_exists = false
		for p_name in parent.metadata["profiles"].values():
			if p_name == name_candidate:
				already_exists = true
				break
		if not already_exists:
			return name_candidate
		counter += 1
	return "Player"

func get_profile_list(parent: Node) -> Dictionary:
	return parent.metadata["profiles"].duplicate()

func get_current_profile_id(parent: Node) -> String:
	return parent.current_profile_id

func get_current_profile_name(parent: Node) -> String:
	if parent.current_profile_id != "" and parent.metadata["profiles"].has(parent.current_profile_id):
		return parent.metadata["profiles"][parent.current_profile_id]
	return "Unknown"
