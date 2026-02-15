extends Node

## SaveManager - Autoload singleton for managing player save data
## Handles level progression, high scores, and settings persistence
## Facade: delegates to SaveSettingsHelper, SaveAchievementsHelper, SaveStatisticsHelper

const METADATA_PATH = "user://metadata.json"
const PROFILES_DIR = "user://profiles/"
const LEGACY_SAVE_PATH = "user://save_data.json"
const SAVE_VERSION = 2
const TOTAL_LEVELS = 30

const SETTINGS_HELPER_SCRIPT = preload("res://scripts/save_settings_helper.gd")
const ACHIEVEMENTS_HELPER_SCRIPT = preload("res://scripts/save_achievements_helper.gd")
const STATISTICS_HELPER_SCRIPT = preload("res://scripts/save_statistics_helper.gd")

# Re-export constants for external callers (e.g. stats.gd accesses SaveManager.ACHIEVEMENTS)
const DEFAULT_SETTINGS = SaveSettingsHelper.DEFAULT_SETTINGS
const ACHIEVEMENTS = SaveAchievementsHelper.ACHIEVEMENTS

var settings_helper: RefCounted = null
var achievements_helper: RefCounted = null
var statistics_helper: RefCounted = null

# Metadata for tracking all profiles
var metadata = {
	"last_selected_id": "",
	"profiles": {} # id: name
}
var current_profile_id: String = ""

# Save data structure (Current Profile)
var save_data = {
	"version": SAVE_VERSION,
	"profile": {
		"player_name": "Player",
		"total_score": 0
	},
	"progression": {
		"highest_unlocked_level": 1,
		"levels_completed": []
	},
	"high_scores": {},
	"pack_progression": {},
	"pack_high_scores": {},
	"set_progression": {
		"highest_unlocked_set": 1,
		"sets_completed": []
	},
	"set_high_scores": {},
	"pack_set_progression": {
		"packs_completed": []
	},
	"pack_set_high_scores": {},
	"last_played": {
		"level_id": 0,
		"pack_id": "classic-challenge",
		"level_index": 0,
		"level_key": "classic-challenge:0",
		"set_id": -1,
		"set_pack_id": "",
		"mode": "individual",
		"in_progress": false
	},
	"statistics": {
		"total_bricks_broken": 0,
		"total_power_ups_collected": 0,
		"total_levels_completed": 0,
		"total_individual_levels_completed": 0,
		"total_set_runs_completed": 0,
		"total_playtime": 0.0,
		"highest_combo": 0,
		"highest_score": 0,
		"total_games_played": 0,
		"perfect_clears": 0
	},
	"achievements": [],
	"settings": SaveSettingsHelper.DEFAULT_SETTINGS.duplicate(true)
}

# Signals
signal save_loaded()
signal level_unlocked(level_id: int)
signal high_score_updated(level_id: int, new_score: int)
signal achievement_unlocked(achievement_id: String, achievement_name: String)

func _ready():
	"""Initialize helpers and load profiles"""
	settings_helper = SETTINGS_HELPER_SCRIPT.new()
	achievements_helper = ACHIEVEMENTS_HELPER_SCRIPT.new()
	statistics_helper = STATISTICS_HELPER_SCRIPT.new()
	settings_helper.capture_default_keybindings()
	
	_ensure_dir_exists(PROFILES_DIR)
	load_save()

func _ensure_dir_exists(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		DirAccess.make_dir_recursive_absolute(path)

func load_save() -> void:
	"""Load metadata and the current profile"""
	load_metadata()
	
	# Check for legacy migration
	if metadata["profiles"].is_empty() and FileAccess.file_exists(LEGACY_SAVE_PATH):
		_migrate_legacy_save()
	
	if metadata["profiles"].is_empty():
		# No profiles found, create a default one
		create_profile("Player 1")
	else:
		# Load the last selected profile, or the first one available
		var profile_id = metadata.get("last_selected_id", "")
		if profile_id == "" or not metadata["profiles"].has(profile_id):
			profile_id = metadata["profiles"].keys()[0]
			metadata["last_selected_id"] = profile_id
			save_metadata()
		
		load_profile(profile_id)

func load_metadata() -> void:
	"""Load profile metadata from disk"""
	if not FileAccess.file_exists(METADATA_PATH):
		metadata = {
			"last_selected_id": "",
			"profiles": {}
		}
		return

	var file = FileAccess.open(METADATA_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		var json = JSON.new()
		if json.parse(json_string) == OK:
			metadata = json.data
		else:
			push_error("Failed to parse metadata JSON")

func save_metadata() -> void:
	"""Save profile metadata to disk"""
	var file = FileAccess.open(METADATA_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(metadata, "\t"))
		file.close()

func _migrate_legacy_save() -> void:
	"""Move legacy save_data.json to a new profile"""
	print("Migrating legacy save data to Player 1 profile...")
	
	var file = FileAccess.open(LEGACY_SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		var json = JSON.new()
		if json.parse(json_string) == OK:
			var legacy_data = json.data
			
			# Create Player 1 profile with legacy data
			var profile_id = "player_1"
			metadata["profiles"][profile_id] = "Player 1"
			metadata["last_selected_id"] = profile_id
			save_metadata()
			
			current_profile_id = profile_id
			save_data = legacy_data
			save_to_disk()
			
			# Rename/Backup legacy file
			var dir = DirAccess.open("user://")
			dir.rename(LEGACY_SAVE_PATH, "user://save_data.json.bak")
			print("Migration complete.")
			save_loaded.emit()
			return
	
	# If migration fails for some reason, just create a default
	create_profile("Player 1")

func create_profile(profile_name: String) -> String:
	"""Create a new profile with the given name. Returns the profile_id."""
	var sanitized_name = sanitize_name(profile_name)
	if sanitized_name == "":
		sanitized_name = "Player"
		
	# Generate a unique ID based on the name
	var base_id = sanitized_name.to_lower().replace(" ", "_")
	var profile_id = base_id
	var counter = 1
	while metadata["profiles"].has(profile_id) or FileAccess.file_exists(_get_profile_path(profile_id)):
		profile_id = base_id + "_" + str(counter)
		counter += 1
	
	# Create default data
	create_default_save()
	save_data["profile"]["player_name"] = profile_name
	
	# Register in metadata
	metadata["profiles"][profile_id] = profile_name
	metadata["last_selected_id"] = profile_id
	save_metadata()
	
	current_profile_id = profile_id
	save_to_disk()
	
	_apply_profile_settings()
	return profile_id

func load_profile(profile_id: String) -> void:
	"""Load a specific profile by ID"""
	if not metadata["profiles"].has(profile_id):
		push_error("Attempted to load non-existent profile: " + profile_id)
		return
		
	var path = _get_profile_path(profile_id)
	if not FileAccess.file_exists(path):
		push_error("Profile file missing: " + path)
		# Fallback: create default if file missing
		create_default_save()
		save_data["profile"]["player_name"] = metadata["profiles"][profile_id]
		current_profile_id = profile_id
		save_to_disk()
		_apply_profile_settings()
		return

	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		var json = JSON.new()
		if json.parse(json_string) == OK:
			save_data = json.data
			current_profile_id = profile_id
			metadata["last_selected_id"] = profile_id
			save_metadata()
			
			# Perform migrations if needed
			_perform_migrations()
			
			_apply_profile_settings()
		else:
			push_error("Failed to parse profile JSON: " + path)

func delete_profile(profile_id: String) -> void:
	"""Delete a profile and its associated file"""
	if not metadata["profiles"].has(profile_id):
		return
		
	print("Deleting profile: ", profile_id)
	# Delete the file
	var path = _get_profile_path(profile_id)
	if FileAccess.file_exists(path):
		var err = DirAccess.remove_absolute(path)
		if err != OK:
			push_error("Failed to delete profile file: " + path)
		else:
			print("Deleted profile file: ", path)
	
	# Remove from metadata
	metadata["profiles"].erase(profile_id)
	
	if current_profile_id == profile_id:
		print("Deleted active profile, reloading...")
		current_profile_id = ""
		metadata["last_selected_id"] = ""
		save_metadata() # CRITICAL: Save to disk before reload
		# Reload to catch a new profile or create default
		load_save()
	else:
		save_metadata()

func rename_current_profile(new_name: String) -> void:
	"""Rename the currently active profile"""
	if current_profile_id == "" or not metadata["profiles"].has(current_profile_id):
		return
	
	metadata["profiles"][current_profile_id] = new_name
	save_metadata()
	
	save_data["profile"]["player_name"] = new_name
	save_to_disk()

func _get_profile_path(profile_id: String) -> String:
	return PROFILES_DIR + profile_id + ".json"

func sanitize_name(profile_name: String) -> String:
	"""Sanitize name to be safe for filenames (alphanumeric and spaces only)"""
	var regex = RegEx.new()
	regex.compile("[^a-zA-Z0-9 ]")
	return regex.sub(profile_name, "", true).strip_edges()

func _perform_migrations() -> void:
	"""Consolidated migration logic for the currently loaded save_data"""
	var did_migrate = false
	if int(save_data.get("version", 0)) < SAVE_VERSION:
		did_migrate = _migrate_to_v2_pack_data()
		save_data["version"] = SAVE_VERSION

	# Migrate old saves that don't have statistics
	if not save_data.has("statistics"):
		save_data["statistics"] = {
			"total_bricks_broken": 0,
			"total_power_ups_collected": 0,
			"total_levels_completed": 0,
			"total_playtime": 0.0,
			"highest_combo": 0,
			"highest_score": 0,
			"total_games_played": 0,
			"perfect_clears": 0
		}
		did_migrate = true

	if not save_data.has("achievements"):
		save_data["achievements"] = []
		did_migrate = true

	if not save_data.has("high_score_timestamps"):
		save_data["high_score_timestamps"] = {}
		# Set current time for migrated scores so they aren't "Unknown"
		var now = Time.get_datetime_string_from_system()
		for key in save_data.get("pack_high_scores", {}).keys():
			save_data["high_score_timestamps"][key] = now
		did_migrate = true
	
	if not save_data.has("set_high_score_timestamps"):
		save_data["set_high_score_timestamps"] = {}
		var now = Time.get_datetime_string_from_system()
		for key in save_data.get("pack_set_high_scores", {}).keys():
			save_data["set_high_score_timestamps"][key] = now
		did_migrate = true

	if not save_data.has("set_progression"):
		save_data["set_progression"] = {
			"highest_unlocked_set": 1,
			"sets_completed": []
		}
		did_migrate = true

	if not save_data.has("set_high_scores"):
		save_data["set_high_scores"] = {}
		did_migrate = true

	if not save_data.has("pack_progression"):
		save_data["pack_progression"] = {}
		did_migrate = true

	if not save_data.has("pack_high_scores"):
		save_data["pack_high_scores"] = {}
		did_migrate = true

	if not save_data.has("pack_set_progression"):
		save_data["pack_set_progression"] = {"packs_completed": []}
		did_migrate = true

	if not save_data.has("pack_set_high_scores"):
		save_data["pack_set_high_scores"] = {}
		did_migrate = true

	if not save_data.has("last_played"):
		save_data["last_played"] = {
			"level_id": 0,
			"pack_id": "classic-challenge",
			"level_index": 0,
			"level_key": "classic-challenge:0",
			"set_id": -1,
			"set_pack_id": "",
			"mode": "individual",
			"in_progress": false
		}
		did_migrate = true

	if not save_data["last_played"].has("pack_id"):
		save_data["last_played"]["pack_id"] = "classic-challenge"
		did_migrate = true
	if not save_data["last_played"].has("level_index"):
		save_data["last_played"]["level_index"] = 0
		did_migrate = true
	if not save_data["last_played"].has("level_key"):
		save_data["last_played"]["level_key"] = "classic-challenge:0"
		did_migrate = true
	if not save_data["last_played"].has("set_pack_id"):
		save_data["last_played"]["set_pack_id"] = ""
		did_migrate = true

	_ensure_pack_progression_defaults()
	
	# Delegate migration to helpers
	var _disk_cb = save_to_disk
	statistics_helper.migrate_statistics(save_data, _disk_cb)
	settings_helper.migrate_settings(save_data, _disk_cb)

	if did_migrate:
		save_to_disk()

func save_to_disk() -> void:
	"""Write current save data to its specific profile file"""
	if current_profile_id == "":
		return
		
	var path = _get_profile_path(current_profile_id)
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to create profile file: " + str(FileAccess.get_open_error()))
		return

	var json_string = JSON.stringify(save_data, "\t")
	file.store_string(json_string)
	file.close()

func get_profile_list() -> Dictionary:
	"""Return the list of profiles (id: name)"""
	return metadata["profiles"].duplicate()

func get_current_profile_id() -> String:
	return current_profile_id

func get_current_profile_name() -> String:
	if current_profile_id != "" and metadata["profiles"].has(current_profile_id):
		return metadata["profiles"][current_profile_id]
	return "Unknown"

func switch_profile(profile_id: String) -> void:
	"""Switch to a different profile"""
	if profile_id == current_profile_id:
		return
	load_profile(profile_id)

func _apply_profile_settings() -> void:
	"""Apply engine-level settings from the current save_data (Audio, Keybindings)"""
	if settings_helper:
		settings_helper.apply_saved_keybindings(save_data)
	
	if AudioManager and AudioManager.has_method("refresh_from_save"):
		AudioManager.refresh_from_save()
	
	# Notify UI and game systems
	save_loaded.emit()

func get_next_default_name() -> String:
	"""Get the next available default name like Player 1, Player 2, etc."""
	var counter = 1
	var base_name = "Player "
	while true:
		var name_candidate = base_name + str(counter)
		var already_exists = false
		for p_name in metadata["profiles"].values():
			if p_name == name_candidate:
				already_exists = true
				break
		if not already_exists:
			return name_candidate
		counter += 1
	return "Player"

func create_default_save() -> void:
	"""Reset to default save data"""
	save_data = {
		"version": SAVE_VERSION,
		"profile": {
			"player_name": "Player",
			"total_score": 0
		},
		"progression": {
			"highest_unlocked_level": 1,
			"levels_completed": []
		},
		"high_scores": {},
		"pack_progression": {},
		"pack_high_scores": {},
		"set_progression": {
			"highest_unlocked_set": 1,
			"sets_completed": []
		},
		"set_high_scores": {},
		"pack_set_progression": {
			"packs_completed": []
		},
		"pack_set_high_scores": {},
		"last_played": {
			"level_id": 0,
			"pack_id": "classic-challenge",
			"level_index": 0,
			"level_key": "classic-challenge:0",
			"set_id": -1,
			"set_pack_id": "",
			"mode": "individual",
			"in_progress": false
		},
		"statistics": {
			"total_bricks_broken": 0,
			"total_power_ups_collected": 0,
			"total_levels_completed": 0,
			"total_individual_levels_completed": 0,
			"total_set_runs_completed": 0,
			"total_playtime": 0.0,
			"highest_combo": 0,
			"highest_score": 0,
			"total_games_played": 0,
			"perfect_clears": 0
		},
		"achievements": [],
		"settings": SaveSettingsHelper.DEFAULT_SETTINGS.duplicate(true)
	}
	_ensure_pack_progression_defaults()

func _ensure_pack_progression_defaults() -> void:
	if not save_data.has("pack_progression"):
		save_data["pack_progression"] = {}

	var pack_progression: Dictionary = save_data["pack_progression"]

	# Dynamically initialize all available packs (built-in and user-created)
	if PackLoader:
		var all_packs: Array[Dictionary] = PackLoader.get_all_packs()
		for pack in all_packs:
			var pack_id := str(pack.get("pack_id", ""))
			if pack_id.is_empty():
				continue

			# Determine default unlock state: classic-challenge starts with level 0 unlocked, others start locked
			var default_unlock := -1
			if pack_id == "classic-challenge":
				default_unlock = 0

			if not pack_progression.has(pack_id):
				pack_progression[pack_id] = {
					"highest_unlocked_level_index": default_unlock,
					"levels_completed": [],
					"stars": {}
				}

			# Ensure all required fields exist in the entry
			var entry: Dictionary = pack_progression[pack_id]
			if not entry.has("highest_unlocked_level_index"):
				entry["highest_unlocked_level_index"] = default_unlock
			if not entry.has("levels_completed"):
				entry["levels_completed"] = []
			if not entry.has("stars"):
				entry["stars"] = {}
			pack_progression[pack_id] = entry

	save_data["pack_progression"] = pack_progression

	if not save_data.has("pack_high_scores"):
		save_data["pack_high_scores"] = {}
	if not save_data.has("pack_set_progression"):
		save_data["pack_set_progression"] = {"packs_completed": []}
	if not save_data.has("pack_set_high_scores"):
		save_data["pack_set_high_scores"] = {}

func _migrate_to_v2_pack_data() -> bool:
	var did_change := false

	if not save_data.has("pack_progression"):
		save_data["pack_progression"] = {}
	if not save_data.has("pack_high_scores"):
		save_data["pack_high_scores"] = {}
	if not save_data.has("pack_set_progression"):
		save_data["pack_set_progression"] = {"packs_completed": []}
	if not save_data.has("pack_set_high_scores"):
		save_data["pack_set_high_scores"] = {}

	var highest_legacy = int(save_data.get("progression", {}).get("highest_unlocked_level", 1))
	var legacy_completed: Array = save_data.get("progression", {}).get("levels_completed", [])
	var legacy_scores: Dictionary = save_data.get("high_scores", {})

	for level_id in range(1, max(TOTAL_LEVELS, highest_legacy) + 1):
		var level_ref: Dictionary = _legacy_ref_for_level(level_id)
		if level_ref.is_empty():
			continue
		var pack_id := str(level_ref.get("pack_id", ""))
		var level_index := int(level_ref.get("level_index", -1))
		if pack_id.is_empty() or level_index < 0:
			continue
		var level_key := "%s:%d" % [pack_id, level_index]
		var entry: Dictionary = save_data["pack_progression"].get(pack_id, {
			"highest_unlocked_level_index": -1,
			"levels_completed": [],
			"stars": {}
		})
		var current_unlock = int(entry.get("highest_unlocked_level_index", -1))
		if level_id <= highest_legacy and level_index > current_unlock:
			entry["highest_unlocked_level_index"] = level_index
			did_change = true
		if level_id in legacy_completed:
			var completed: Array = entry.get("levels_completed", [])
			if not level_key in completed:
				completed.append(level_key)
				entry["levels_completed"] = completed
				did_change = true
		save_data["pack_progression"][pack_id] = entry

		var legacy_key := str(level_id)
		if legacy_scores.has(legacy_key):
			var score = int(legacy_scores[legacy_key])
			var current = int(save_data["pack_high_scores"].get(level_key, 0))
			if score > current:
				save_data["pack_high_scores"][level_key] = score
				did_change = true

	var set_scores: Dictionary = save_data.get("set_high_scores", {})
	for set_id_variant in set_scores.keys():
		var set_id := int(set_id_variant)
		var pack_id := _legacy_set_pack_id(set_id)
		if pack_id.is_empty():
			continue
		var new_score := int(set_scores[set_id_variant])
		var current_score := int(save_data["pack_set_high_scores"].get(pack_id, 0))
		if new_score > current_score:
			save_data["pack_set_high_scores"][pack_id] = new_score
			did_change = true

	var sets_completed: Array = save_data.get("set_progression", {}).get("sets_completed", [])
	var pack_sets_completed: Array = save_data["pack_set_progression"].get("packs_completed", [])
	for set_id in sets_completed:
		var pack_id := _legacy_set_pack_id(int(set_id))
		if pack_id.is_empty():
			continue
		if not pack_id in pack_sets_completed:
			pack_sets_completed.append(pack_id)
			did_change = true
	save_data["pack_set_progression"]["packs_completed"] = pack_sets_completed

	var last_played: Dictionary = save_data.get("last_played", {})
	var last_level_id := int(last_played.get("level_id", 0))
	var last_played_ref: Dictionary = _legacy_ref_for_level(last_level_id)
	if not last_played_ref.is_empty():
		var pack_id := str(last_played_ref.get("pack_id", "classic-challenge"))
		var level_index := int(last_played_ref.get("level_index", 0))
		last_played["pack_id"] = pack_id
		last_played["level_index"] = level_index
		last_played["level_key"] = "%s:%d" % [pack_id, level_index]
		did_change = true
	if not last_played.has("set_pack_id"):
		var set_id := int(last_played.get("set_id", -1))
		if set_id != -1:
			last_played["set_pack_id"] = _legacy_set_pack_id(set_id)
		else:
			last_played["set_pack_id"] = ""
		did_change = true
	save_data["last_played"] = last_played

	_ensure_pack_progression_defaults()
	return did_change

func _parse_level_key(level_key: String) -> Dictionary:
	var parts := level_key.split(":")
	if parts.size() != 2:
		return {}
	var pack_id := parts[0]
	if pack_id.is_empty():
		return {}
	var level_index := int(parts[1])
	return {"pack_id": pack_id, "level_index": level_index}

func _legacy_ref_for_level(level_id: int) -> Dictionary:
	if PackLoader and PackLoader.has_method("get_legacy_level_ref"):
		var ref: Dictionary = PackLoader.get_legacy_level_ref(level_id)
		if not ref.is_empty():
			return ref
	if level_id >= 1 and level_id <= 10:
		return {"pack_id": "classic-challenge", "level_index": level_id - 1}
	if level_id >= 11 and level_id <= 20:
		return {"pack_id": "prism-showcase", "level_index": level_id - 11}
	if level_id >= 21 and level_id <= 30:
		return {"pack_id": "nebula-ascend", "level_index": level_id - 21}
	return {}

func _legacy_level_id_for(pack_id: String, level_index: int) -> int:
	if PackLoader and PackLoader.has_method("get_legacy_level_id"):
		var level_id := PackLoader.get_legacy_level_id(pack_id, level_index)
		if level_id != -1:
			return level_id
	if pack_id == "classic-challenge":
		return level_index + 1
	if pack_id == "prism-showcase":
		return level_index + 11
	if pack_id == "nebula-ascend":
		return level_index + 21
	return -1

func _legacy_set_pack_id(set_id: int) -> String:
	if PackLoader and PackLoader.has_method("get_legacy_set_pack_id"):
		var pack_id := PackLoader.get_legacy_set_pack_id(set_id)
		if not pack_id.is_empty():
			return pack_id
	match set_id:
		1:
			return "classic-challenge"
		2:
			return "prism-showcase"
		3:
			return "nebula-ascend"
	return ""

func _legacy_set_id_for_pack(pack_id: String) -> int:
	if PackLoader and PackLoader.has_method("get_legacy_set_id_for_pack"):
		var set_id: int = PackLoader.get_legacy_set_id_for_pack(pack_id)
		if set_id != -1:
			return set_id
	if pack_id == "classic-challenge":
		return 1
	if pack_id == "prism-showcase":
		return 2
	if pack_id == "nebula-ascend":
		return 3
	return -1

# ============================================================================
# LEVEL PROGRESSION (stays inline - tightly coupled to signals)
# ============================================================================

func is_level_unlocked(level_id: int) -> bool:
	var ref: Dictionary = _legacy_ref_for_level(level_id)
	if ref.is_empty():
		return false
	return is_level_key_unlocked("%s:%d" % [str(ref.get("pack_id", "")), int(ref.get("level_index", -1))])

func is_level_completed(level_id: int) -> bool:
	var ref: Dictionary = _legacy_ref_for_level(level_id)
	if ref.is_empty():
		return false
	return is_level_key_completed("%s:%d" % [str(ref.get("pack_id", "")), int(ref.get("level_index", -1))])

func unlock_level(level_id: int) -> void:
	var ref: Dictionary = _legacy_ref_for_level(level_id)
	if ref.is_empty():
		push_warning("Cannot unlock unknown legacy level %d" % level_id)
		return
	unlock_level_key("%s:%d" % [str(ref.get("pack_id", "")), int(ref.get("level_index", -1))])

func mark_level_completed(level_id: int) -> void:
	var ref: Dictionary = _legacy_ref_for_level(level_id)
	if ref.is_empty():
		return
	mark_level_key_completed("%s:%d" % [str(ref.get("pack_id", "")), int(ref.get("level_index", -1))])

func get_high_score(level_id: int) -> int:
	var ref: Dictionary = _legacy_ref_for_level(level_id)
	if ref.is_empty():
		return 0
	return get_level_key_high_score("%s:%d" % [str(ref.get("pack_id", "")), int(ref.get("level_index", -1))])

func update_high_score(level_id: int, score: int) -> bool:
	var ref: Dictionary = _legacy_ref_for_level(level_id)
	if ref.is_empty():
		return false
	return update_level_key_high_score("%s:%d" % [str(ref.get("pack_id", "")), int(ref.get("level_index", -1))], score)

func is_level_key_unlocked(level_key: String) -> bool:
	var parsed := _parse_level_key(level_key)
	if parsed.is_empty():
		return false
	var pack_id := str(parsed.get("pack_id", ""))
	var level_index := int(parsed.get("level_index", -1))
	if pack_id.is_empty() or level_index < 0:
		return false

	if level_index == 0:
		return true

	var entry: Dictionary = save_data.get("pack_progression", {}).get(pack_id, {})
	var highest_unlocked := int(entry.get("highest_unlocked_level_index", -1))
	return level_index <= highest_unlocked

func is_level_key_completed(level_key: String) -> bool:
	var parsed := _parse_level_key(level_key)
	if parsed.is_empty():
		return false
	var pack_id := str(parsed.get("pack_id", ""))
	var entry: Dictionary = save_data.get("pack_progression", {}).get(pack_id, {})
	var completed: Array = entry.get("levels_completed", [])
	return level_key in completed

func unlock_level_key(level_key: String) -> void:
	var parsed := _parse_level_key(level_key)
	if parsed.is_empty():
		return
	var pack_id := str(parsed.get("pack_id", ""))
	var level_index := int(parsed.get("level_index", -1))
	var entry: Dictionary = save_data["pack_progression"].get(pack_id, {
		"highest_unlocked_level_index": -1,
		"levels_completed": [],
		"stars": {}
	})
	var highest_unlocked := int(entry.get("highest_unlocked_level_index", -1))
	if level_index > highest_unlocked:
		entry["highest_unlocked_level_index"] = level_index
		save_data["pack_progression"][pack_id] = entry
		var legacy_level_id := _legacy_level_id_for(pack_id, level_index)
		if legacy_level_id != -1 and legacy_level_id > int(save_data["progression"].get("highest_unlocked_level", 1)):
			save_data["progression"]["highest_unlocked_level"] = legacy_level_id
		save_to_disk()
		if legacy_level_id != -1:
			level_unlocked.emit(legacy_level_id)

func mark_level_key_completed(level_key: String) -> void:
	var parsed := _parse_level_key(level_key)
	if parsed.is_empty():
		return
	var pack_id := str(parsed.get("pack_id", ""))
	var level_index := int(parsed.get("level_index", -1))
	var entry: Dictionary = save_data["pack_progression"].get(pack_id, {
		"highest_unlocked_level_index": -1,
		"levels_completed": [],
		"stars": {}
	})
	var completed: Array = entry.get("levels_completed", [])
	if not level_key in completed:
		completed.append(level_key)
		entry["levels_completed"] = completed
		save_data["pack_progression"][pack_id] = entry
		var legacy_level_id := _legacy_level_id_for(pack_id, level_index)
		if legacy_level_id != -1 and not legacy_level_id in save_data["progression"]["levels_completed"]:
			save_data["progression"]["levels_completed"].append(legacy_level_id)
		save_to_disk()

func get_level_key_high_score(level_key: String) -> int:
	return int(save_data.get("pack_high_scores", {}).get(level_key, 0))

func update_level_key_high_score(level_key: String, score: int) -> bool:
	var current_high_score = get_level_key_high_score(level_key)
	if score <= current_high_score:
		return false

	if not save_data.has("high_score_timestamps"):
		save_data["high_score_timestamps"] = {}
	
	save_data["pack_high_scores"][level_key] = score
	save_data["high_score_timestamps"][level_key] = Time.get_datetime_string_from_system()
	
	var parsed := _parse_level_key(level_key)
	if not parsed.is_empty():
		var pack_id := str(parsed.get("pack_id", ""))
		var level_index := int(parsed.get("level_index", -1))
		var legacy_level_id := _legacy_level_id_for(pack_id, level_index)
		if legacy_level_id != -1:
			save_data["high_scores"][str(legacy_level_id)] = score
			high_score_updated.emit(legacy_level_id, score)
	save_to_disk()
	return true

func get_level_key_stars(level_key: String) -> int:
	var parsed := _parse_level_key(level_key)
	if parsed.is_empty():
		return 0
	var pack_id := str(parsed.get("pack_id", ""))
	var entry: Dictionary = save_data.get("pack_progression", {}).get(pack_id, {})
	var stars: Dictionary = entry.get("stars", {})
	return int(stars.get(level_key, 0))

func get_all_leaderboards() -> Dictionary:
	"""Scan all profile files and return aggregated leaderboards"""
	var leaderboards = {
		"levels": {}, # level_key: [ {name, score, date}, ... ]
		"sets": {}    # pack_id: [ {name, score, date}, ... ]
	}
	
	var profiles = get_profile_list()
	for profile_id in profiles.keys():
		var path = _get_profile_path(profile_id)
		if not FileAccess.file_exists(path):
			continue
			
		var file = FileAccess.open(path, FileAccess.READ)
		if not file:
			continue
			
		var json_string = file.get_as_text()
		file.close()
		var json = JSON.new()
		if json.parse(json_string) != OK:
			continue
			
		var p_data = json.data
		var p_name = profiles[profile_id]
		
		# Process level high scores
		var p_level_scores = p_data.get("pack_high_scores", {})
		var p_level_times = p_data.get("high_score_timestamps", {})
		for l_key in p_level_scores.keys():
			if not leaderboards["levels"].has(l_key):
				leaderboards["levels"][l_key] = []
			
			leaderboards["levels"][l_key].append({
				"name": p_name,
				"score": int(p_level_scores[l_key]),
				"date": str(p_level_times.get(l_key, "Unknown"))
			})
			
		# Process set high scores
		var p_set_scores = p_data.get("pack_set_high_scores", {})
		var p_set_times = p_data.get("set_high_score_timestamps", {})
		for s_id in p_set_scores.keys():
			if not leaderboards["sets"].has(s_id):
				leaderboards["sets"][s_id] = []
				
			leaderboards["sets"][s_id].append({
				"name": p_name,
				"score": int(p_set_scores[s_id]),
				"date": str(p_set_times.get(s_id, "Unknown"))
			})
			
	# Sort all lists by score descending
	for l_key in leaderboards["levels"].keys():
		leaderboards["levels"][l_key].sort_custom(func(a, b): return a["score"] > b["score"])
		# Keep only top 10
		if leaderboards["levels"][l_key].size() > 10:
			leaderboards["levels"][l_key] = leaderboards["levels"][l_key].slice(0, 10)
			
	for s_id in leaderboards["sets"].keys():
		leaderboards["sets"][s_id].sort_custom(func(a, b): return a["score"] > b["score"])
		# Keep only top 10
		if leaderboards["sets"][s_id].size() > 10:
			leaderboards["sets"][s_id] = leaderboards["sets"][s_id].slice(0, 10)
			
	return leaderboards

func get_global_high_score(level_key: String) -> int:
	"""Find the highest score for a level across all profiles"""
	var leaderboards = get_all_leaderboards()
	var scores = leaderboards["levels"].get(level_key, [])
	if scores.is_empty():
		return 0
	return int(scores[0]["score"])

func get_global_set_high_score(pack_id: String) -> int:
	"""Find the highest score for a set/pack across all profiles"""
	var leaderboards = get_all_leaderboards()
	var scores = leaderboards["sets"].get(pack_id, [])
	if scores.is_empty():
		return 0
	return int(scores[0]["score"])

func update_level_key_stars(level_key: String, stars_value: int) -> bool:
	var parsed := _parse_level_key(level_key)
	if parsed.is_empty():
		return false
	var pack_id := str(parsed.get("pack_id", ""))
	var clamped_stars := clampi(stars_value, 0, 3)
	var entry: Dictionary = save_data["pack_progression"].get(pack_id, {
		"highest_unlocked_level_index": -1,
		"levels_completed": [],
		"stars": {}
	})
	var stars: Dictionary = entry.get("stars", {})
	var current := int(stars.get(level_key, 0))
	if clamped_stars <= current:
		return false
	stars[level_key] = clamped_stars
	entry["stars"] = stars
	save_data["pack_progression"][pack_id] = entry
	save_to_disk()
	return true

func calculate_level_stars(level_key: String, final_score: int, perfect_clear: bool) -> int:
	var parsed := _parse_level_key(level_key)
	if parsed.is_empty():
		return 0
	var pack_id := str(parsed.get("pack_id", ""))
	var level_index := int(parsed.get("level_index", -1))
	var max_base_score := PackLoader.get_level_max_base_score(pack_id, level_index)
	if max_base_score <= 0:
		if final_score > 0:
			return 1
		return 0

	var stars := 1
	var silver_threshold := int(ceil(max_base_score * 0.5))
	var gold_threshold := int(ceil(max_base_score * 0.8))
	if final_score >= silver_threshold:
		stars = max(stars, 2)
	if final_score >= gold_threshold or perfect_clear:
		stars = max(stars, 3)
	return stars

func get_unlocked_level_count() -> int:
	return save_data["progression"]["highest_unlocked_level"]

func get_completed_level_count() -> int:
	return save_data["progression"]["levels_completed"].size()

# ============================================================================
# RESET
# ============================================================================

func reset_save_data() -> void:
	reset_progress_data()

func reset_progress_data() -> void:
	var settings_copy = save_data.get("settings", SaveSettingsHelper.DEFAULT_SETTINGS.duplicate(true)).duplicate(true)
	var player_name = save_data.get("profile", {}).get("player_name", "Player")
	save_data["version"] = SAVE_VERSION
	save_data["profile"] = { "player_name": player_name, "total_score": 0 }
	save_data["progression"] = { "highest_unlocked_level": 1, "levels_completed": [] }
	save_data["high_scores"] = {}
	save_data["pack_progression"] = {}
	save_data["pack_high_scores"] = {}
	save_data["set_progression"] = { "highest_unlocked_set": 1, "sets_completed": [] }
	save_data["set_high_scores"] = {}
	save_data["pack_set_progression"] = { "packs_completed": [] }
	save_data["pack_set_high_scores"] = {}
	save_data["last_played"] = {
		"level_id": 0,
		"pack_id": "classic-challenge",
		"level_index": 0,
		"level_key": "classic-challenge:0",
		"set_id": -1,
		"set_pack_id": "",
		"mode": "individual",
		"in_progress": false
	}
	save_data["statistics"] = {
		"total_bricks_broken": 0, "total_power_ups_collected": 0,
		"total_levels_completed": 0, "total_individual_levels_completed": 0,
		"total_set_runs_completed": 0, "total_playtime": 0.0,
		"highest_combo": 0, "highest_score": 0,
		"total_games_played": 0, "perfect_clears": 0
	}
	save_data["achievements"] = []
	save_data["settings"] = settings_copy
	_ensure_pack_progression_defaults()
	save_to_disk()

func get_save_file_location() -> String:
	if current_profile_id == "":
		return ""
	return ProjectSettings.globalize_path(_get_profile_path(current_profile_id))

# ============================================================================
# LAST PLAYED TRACKING (stays inline - small)
# ============================================================================

func set_last_played(level_id: int, mode: String, set_id: int = -1, in_progress: bool = true) -> void:
	var ref: Dictionary = _legacy_ref_for_level(level_id)
	if ref.is_empty():
		return
	var pack_id := str(ref.get("pack_id", "classic-challenge"))
	var level_index := int(ref.get("level_index", 0))
	var set_pack_id := ""
	if set_id != -1:
		set_pack_id = _legacy_set_pack_id(set_id)
	set_last_played_ref(pack_id, level_index, mode, set_pack_id, in_progress)

func set_last_played_ref(pack_id: String, level_index: int, mode: String, set_pack_id: String = "", in_progress: bool = true) -> void:
	var level_key := "%s:%d" % [pack_id, level_index]
	var legacy_level_id := _legacy_level_id_for(pack_id, level_index)
	if legacy_level_id == -1:
		legacy_level_id = 0

	var legacy_set_id := -1
	if not set_pack_id.is_empty():
		legacy_set_id = _legacy_set_id_for_pack(set_pack_id)

	save_data["last_played"]["level_id"] = legacy_level_id
	save_data["last_played"]["pack_id"] = pack_id
	save_data["last_played"]["level_index"] = level_index
	save_data["last_played"]["level_key"] = level_key
	save_data["last_played"]["mode"] = mode
	save_data["last_played"]["set_id"] = legacy_set_id
	save_data["last_played"]["set_pack_id"] = set_pack_id
	save_data["last_played"]["in_progress"] = in_progress
	save_to_disk()

func set_last_played_in_progress(in_progress: bool) -> void:
	save_data["last_played"]["in_progress"] = in_progress
	save_to_disk()

func get_last_played() -> Dictionary:
	return save_data["last_played"].duplicate()

# ============================================================================
# SET SYSTEM (stays inline - small)
# ============================================================================

func get_set_high_score(set_id: int) -> int:
	var pack_id := _legacy_set_pack_id(set_id)
	if pack_id.is_empty():
		return 0
	return get_set_pack_high_score(pack_id)

func update_set_high_score(set_id: int, score: int) -> bool:
	var pack_id := _legacy_set_pack_id(set_id)
	if pack_id.is_empty():
		return false
	return update_set_pack_high_score(pack_id, score)

func mark_set_completed(set_id: int) -> void:
	var pack_id := _legacy_set_pack_id(set_id)
	if pack_id.is_empty():
		return
	mark_set_pack_completed(pack_id)

func is_set_unlocked(_set_id: int) -> bool:
	return true

func is_set_completed(set_id: int) -> bool:
	var pack_id := _legacy_set_pack_id(set_id)
	if pack_id.is_empty():
		return false
	return is_set_pack_completed(pack_id)

func get_set_pack_high_score(pack_id: String) -> int:
	return int(save_data.get("pack_set_high_scores", {}).get(pack_id, 0))

func update_set_pack_high_score(pack_id: String, score: int) -> bool:
	var current_high_score := get_set_pack_high_score(pack_id)
	if score <= current_high_score:
		return false

	if not save_data.has("set_high_score_timestamps"):
		save_data["set_high_score_timestamps"] = {}

	save_data["pack_set_high_scores"][pack_id] = score
	save_data["set_high_score_timestamps"][pack_id] = Time.get_datetime_string_from_system()
	
	var set_id := _legacy_set_id_for_pack(pack_id)
	if set_id != -1:
		save_data["set_high_scores"][str(set_id)] = score
	save_to_disk()
	return true

func mark_set_pack_completed(pack_id: String) -> void:
	var completed_packs: Array = save_data.get("pack_set_progression", {}).get("packs_completed", [])
	if not pack_id in completed_packs:
		completed_packs.append(pack_id)
		save_data["pack_set_progression"]["packs_completed"] = completed_packs

	var set_id := _legacy_set_id_for_pack(pack_id)
	if set_id != -1 and not set_id in save_data["set_progression"]["sets_completed"]:
		save_data["set_progression"]["sets_completed"].append(set_id)
	save_to_disk()

func is_set_pack_unlocked(_pack_id: String) -> bool:
	return true

func is_set_pack_completed(pack_id: String) -> bool:
	var completed_packs: Array = save_data.get("pack_set_progression", {}).get("packs_completed", [])
	return pack_id in completed_packs

func get_pack_completed_count(pack_id: String) -> int:
	var entry: Dictionary = save_data.get("pack_progression", {}).get(pack_id, {})
	var completed: Array = entry.get("levels_completed", [])
	return completed.size()

func get_pack_total_stars(pack_id: String) -> int:
	var total := 0
	var entry: Dictionary = save_data.get("pack_progression", {}).get(pack_id, {})
	var stars: Dictionary = entry.get("stars", {})
	for key in stars.keys():
		total += int(stars[key])
	return total

# ============================================================================
# SETTINGS FACADE - thin wrappers delegating to SaveSettingsHelper
# ============================================================================

func save_difficulty(difficulty_name: String) -> void:
	settings_helper.save_difficulty(save_data, save_to_disk, difficulty_name)

func get_saved_difficulty() -> String:
	return settings_helper.get_saved_difficulty(save_data)

func save_audio_settings(music_volume_db: float, sfx_volume_db: float) -> void:
	settings_helper.save_audio_settings(save_data, save_to_disk, music_volume_db, sfx_volume_db)

func get_music_volume() -> float:
	return settings_helper.get_music_volume(save_data)

func get_sfx_volume() -> float:
	return settings_helper.get_sfx_volume(save_data)

func save_music_playback_mode(mode: String) -> void:
	settings_helper.save_music_playback_mode(save_data, save_to_disk, mode)

func get_music_playback_mode() -> String:
	return settings_helper.get_music_playback_mode(save_data)

func save_music_track_id(track_id: String) -> void:
	settings_helper.save_music_track_id(save_data, save_to_disk, track_id)

func get_music_track_id() -> String:
	return settings_helper.get_music_track_id(save_data)

func save_screen_shake_intensity(intensity: String) -> void:
	settings_helper.save_screen_shake_intensity(save_data, save_to_disk, intensity)

func get_screen_shake_intensity() -> String:
	return settings_helper.get_screen_shake_intensity(save_data)

func save_particle_effects(enabled: bool) -> void:
	settings_helper.save_particle_effects(save_data, save_to_disk, enabled)

func get_particle_effects() -> bool:
	return settings_helper.get_particle_effects(save_data)

func save_ball_trail(enabled: bool) -> void:
	settings_helper.save_ball_trail(save_data, save_to_disk, enabled)

func get_ball_trail() -> bool:
	return settings_helper.get_ball_trail(save_data)

func save_combo_flash_enabled(enabled: bool) -> void:
	settings_helper.save_combo_flash_enabled(save_data, save_to_disk, enabled)

func get_combo_flash_enabled() -> bool:
	return settings_helper.get_combo_flash_enabled(save_data)

func save_skip_level_intro(enabled: bool) -> void:
	settings_helper.save_skip_level_intro(save_data, save_to_disk, enabled)

func get_skip_level_intro() -> bool:
	return settings_helper.get_skip_level_intro(save_data)

func save_show_fps(enabled: bool) -> void:
	settings_helper.save_show_fps(save_data, save_to_disk, enabled)

func get_show_fps() -> bool:
	return settings_helper.get_show_fps(save_data)

func save_paddle_sensitivity(sensitivity: float) -> void:
	settings_helper.save_paddle_sensitivity(save_data, save_to_disk, sensitivity)

func get_paddle_sensitivity() -> float:
	return settings_helper.get_paddle_sensitivity(save_data)

func reset_settings_to_default() -> void:
	settings_helper.reset_settings_to_default(save_data, save_to_disk)

# ============================================================================
# KEYBINDINGS FACADE
# ============================================================================

func get_rebind_actions() -> Array:
	return settings_helper.get_rebind_actions()

func capture_keybindings(actions: Array = SaveSettingsHelper.REBIND_ACTIONS) -> Dictionary:
	return settings_helper.capture_keybindings(actions)

func save_keybindings(keybindings: Dictionary) -> void:
	settings_helper.save_keybindings(save_data, save_to_disk, keybindings)

func get_keybindings() -> Dictionary:
	return settings_helper.get_keybindings(save_data)

func apply_keybindings(keybindings: Dictionary) -> void:
	settings_helper.apply_keybindings(keybindings)

func reset_keybindings_to_default() -> void:
	settings_helper.reset_keybindings_to_default(save_data, save_to_disk)

# ============================================================================
# STATISTICS FACADE
# ============================================================================

func increment_stat(stat_name: String, amount: float = 1.0) -> void:
	statistics_helper.increment_stat(save_data, save_to_disk, stat_name, amount)

func get_stat(stat_name: String) -> float:
	return statistics_helper.get_stat(save_data, stat_name)

func update_stat_if_higher(stat_name: String, new_value: float) -> void:
	statistics_helper.update_stat_if_higher(save_data, save_to_disk, stat_name, new_value)

func get_all_statistics() -> Dictionary:
	return statistics_helper.get_all_statistics(save_data)

# ============================================================================
# ACHIEVEMENTS FACADE
# ============================================================================

func check_achievements() -> void:
	var newly_unlocked = achievements_helper.check_achievements(save_data, get_stat)
	for entry in newly_unlocked:
		unlock_achievement(entry["id"])

func unlock_achievement(achievement_id: String) -> void:
	var achievement_name = achievements_helper.unlock(save_data, save_to_disk, achievement_id)
	if achievement_name != "":
		achievement_unlocked.emit(achievement_id, achievement_name)

func is_achievement_unlocked(achievement_id: String) -> bool:
	return achievements_helper.is_unlocked(save_data, achievement_id)

func get_unlocked_achievements() -> Array:
	return achievements_helper.get_unlocked(save_data)

func get_achievement_progress(achievement_id: String) -> Dictionary:
	return achievements_helper.get_progress(save_data, get_stat, achievement_id)
