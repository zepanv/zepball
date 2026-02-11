extends Node

## SaveManager - Autoload singleton for managing player save data
## Handles level progression, high scores, and settings persistence
## Facade: delegates to SaveSettingsHelper, SaveAchievementsHelper, SaveStatisticsHelper

const SAVE_FILE_PATH = "user://save_data.json"
const SAVE_VERSION = 1
const TOTAL_LEVELS = 20

const SETTINGS_HELPER_SCRIPT = preload("res://scripts/save_settings_helper.gd")
const ACHIEVEMENTS_HELPER_SCRIPT = preload("res://scripts/save_achievements_helper.gd")
const STATISTICS_HELPER_SCRIPT = preload("res://scripts/save_statistics_helper.gd")

# Re-export constants for external callers (e.g. stats.gd accesses SaveManager.ACHIEVEMENTS)
const DEFAULT_SETTINGS = SaveSettingsHelper.DEFAULT_SETTINGS
const ACHIEVEMENTS = SaveAchievementsHelper.ACHIEVEMENTS

var settings_helper: RefCounted = null
var achievements_helper: RefCounted = null
var statistics_helper: RefCounted = null

# Save data structure
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
	"set_progression": {
		"highest_unlocked_set": 1,
		"sets_completed": []
	},
	"set_high_scores": {},
	"last_played": {
		"level_id": 0,
		"set_id": -1,
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
	"""Load save data on startup"""
	settings_helper = SETTINGS_HELPER_SCRIPT.new()
	achievements_helper = ACHIEVEMENTS_HELPER_SCRIPT.new()
	statistics_helper = STATISTICS_HELPER_SCRIPT.new()
	settings_helper.capture_default_keybindings()
	load_save()
	settings_helper.apply_saved_keybindings(save_data)

func load_save() -> void:
	"""Load save data from disk, or create default if none exists"""
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		create_default_save()
		save_to_disk()
		save_loaded.emit()
		return

	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file == null:
		push_error("Failed to open save file: " + str(FileAccess.get_open_error()))
		create_default_save()
		save_to_disk()
		save_loaded.emit()
		return

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		push_error("Failed to parse save file JSON")
		create_default_save()
		save_to_disk()
		save_loaded.emit()
		return

	var loaded_data = json.data

	if not loaded_data.has("version"):
		push_warning("Old save format detected, migrating to default save data")
		create_default_save()
		save_to_disk()
		save_loaded.emit()
		return

	save_data = loaded_data

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
		save_to_disk()

	if not save_data.has("achievements"):
		save_data["achievements"] = []
		save_to_disk()

	if not save_data.has("set_progression"):
		save_data["set_progression"] = {
			"highest_unlocked_set": 1,
			"sets_completed": []
		}
		save_to_disk()

	if not save_data.has("set_high_scores"):
		save_data["set_high_scores"] = {}
		save_to_disk()

	if not save_data.has("last_played"):
		save_data["last_played"] = {
			"level_id": 0,
			"set_id": -1,
			"mode": "individual",
			"in_progress": false
		}
		save_to_disk()

	# Delegate migration to helpers
	var _disk_cb = save_to_disk
	statistics_helper.migrate_statistics(save_data, _disk_cb)
	settings_helper.migrate_settings(save_data, _disk_cb)

	save_loaded.emit()

func save_to_disk() -> void:
	"""Write current save data to disk"""
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Failed to create save file: " + str(FileAccess.get_open_error()))
		return

	var json_string = JSON.stringify(save_data, "\t")
	file.store_string(json_string)
	file.close()

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
		"set_progression": {
			"highest_unlocked_set": 1,
			"sets_completed": []
		},
		"set_high_scores": {},
		"last_played": {
			"level_id": 0,
			"set_id": -1,
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

# ============================================================================
# LEVEL PROGRESSION (stays inline - tightly coupled to signals)
# ============================================================================

func is_level_unlocked(level_id: int) -> bool:
	if MenuController.current_set_id != -1:
		var set_level_ids = SetLoader.get_set_level_ids(MenuController.current_set_id)
		if set_level_ids.size() > 0 and level_id == set_level_ids[0]:
			return true
	return level_id <= save_data["progression"]["highest_unlocked_level"]

func is_level_completed(level_id: int) -> bool:
	return level_id in save_data["progression"]["levels_completed"]

func unlock_level(level_id: int) -> void:
	if level_id > TOTAL_LEVELS:
		push_warning("Cannot unlock level %d - only %d levels exist" % [level_id, TOTAL_LEVELS])
		return
	var current_highest = save_data["progression"]["highest_unlocked_level"]
	if level_id > current_highest:
		save_data["progression"]["highest_unlocked_level"] = level_id
		save_to_disk()
		level_unlocked.emit(level_id)

func mark_level_completed(level_id: int) -> void:
	if not level_id in save_data["progression"]["levels_completed"]:
		save_data["progression"]["levels_completed"].append(level_id)
		save_to_disk()

func get_high_score(level_id: int) -> int:
	var key = str(level_id)
	if save_data["high_scores"].has(key):
		return save_data["high_scores"][key]
	return 0

func update_high_score(level_id: int, score: int) -> bool:
	var key = str(level_id)
	var current_high_score = get_high_score(level_id)
	if score > current_high_score:
		save_data["high_scores"][key] = score
		save_to_disk()
		high_score_updated.emit(level_id, score)
		return true
	return false

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
	save_data["set_progression"] = { "highest_unlocked_set": 1, "sets_completed": [] }
	save_data["set_high_scores"] = {}
	save_data["last_played"] = { "level_id": 0, "set_id": -1, "mode": "individual", "in_progress": false }
	save_data["statistics"] = {
		"total_bricks_broken": 0, "total_power_ups_collected": 0,
		"total_levels_completed": 0, "total_individual_levels_completed": 0,
		"total_set_runs_completed": 0, "total_playtime": 0.0,
		"highest_combo": 0, "highest_score": 0,
		"total_games_played": 0, "perfect_clears": 0
	}
	save_data["achievements"] = []
	save_data["settings"] = settings_copy
	save_to_disk()

func get_save_file_location() -> String:
	return ProjectSettings.globalize_path(SAVE_FILE_PATH)

# ============================================================================
# LAST PLAYED TRACKING (stays inline - small)
# ============================================================================

func set_last_played(level_id: int, mode: String, set_id: int = -1, in_progress: bool = true) -> void:
	save_data["last_played"]["level_id"] = level_id
	save_data["last_played"]["mode"] = mode
	save_data["last_played"]["set_id"] = set_id
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
	var key = str(set_id)
	if save_data["set_high_scores"].has(key):
		return save_data["set_high_scores"][key]
	return 0

func update_set_high_score(set_id: int, score: int) -> bool:
	var key = str(set_id)
	var current_high_score = get_set_high_score(set_id)
	if score > current_high_score:
		save_data["set_high_scores"][key] = score
		save_to_disk()
		return true
	return false

func mark_set_completed(set_id: int) -> void:
	if not set_id in save_data["set_progression"]["sets_completed"]:
		save_data["set_progression"]["sets_completed"].append(set_id)
		save_to_disk()

func is_set_unlocked(_set_id: int) -> bool:
	return true

func is_set_completed(set_id: int) -> bool:
	return set_id in save_data["set_progression"]["sets_completed"]

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

func save_short_level_intro(enabled: bool) -> void:
	settings_helper.save_short_level_intro(save_data, save_to_disk, enabled)

func get_short_level_intro() -> bool:
	return settings_helper.get_short_level_intro(save_data)

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
