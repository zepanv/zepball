extends Node

## SaveManager - Autoload singleton for managing player save data
## Handles level progression, high scores, and settings persistence
## Facade: delegates to SaveSettingsHelper, SaveAchievementsHelper, SaveStatisticsHelper

const METADATA_PATH = "user://metadata.json"
const PROFILES_DIR = "user://profiles/"
const LEGACY_SAVE_PATH = "user://save_data.json"
const SAVE_VERSION = 4
const TOTAL_LEVELS = 30
const CHALLENGE_MODE_NORMAL = "normal"
const CHALLENGE_MODE_IRON_BALL = "iron_ball"
const CHALLENGE_MODE_ONE_LIFE = "one_life"
const CHALLENGE_MODE_TIME_ATTACK = "time_attack"
const CHALLENGE_MODES = [
	CHALLENGE_MODE_NORMAL,
	CHALLENGE_MODE_IRON_BALL,
	CHALLENGE_MODE_ONE_LIFE,
	CHALLENGE_MODE_TIME_ATTACK
]

const SETTINGS_HELPER_SCRIPT = preload("res://scripts/save_settings_helper.gd")
const ACHIEVEMENTS_HELPER_SCRIPT = preload("res://scripts/save_achievements_helper.gd")
const STATISTICS_HELPER_SCRIPT = preload("res://scripts/save_statistics_helper.gd")

# Re-export constants for external callers (e.g. stats.gd accesses SaveManager.ACHIEVEMENTS)
const DEFAULT_SETTINGS = SaveSettingsHelper.DEFAULT_SETTINGS
const ACHIEVEMENTS = SaveAchievementsHelper.ACHIEVEMENTS

var settings_helper: RefCounted = null
var achievements_helper: RefCounted = null
var statistics_helper: RefCounted = null
const PROGRESSION_HELPER_SCRIPT = preload("res://scripts/save_progression_helper.gd")
const HIGH_SCORES_HELPER_SCRIPT = preload("res://scripts/save_high_scores_helper.gd")
const PROFILE_HELPER_SCRIPT = preload("res://scripts/save_profile_helper.gd")

var progression_helper: RefCounted = null
var high_scores_helper: RefCounted = null
var profile_helper: RefCounted = null

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
	"iron_ball_set_high_scores": {},
	"one_life_set_high_scores": {},
	"time_attack_set_high_scores": {},
	"pack_set_progression": {
		"packs_completed": []
	},
	"pack_set_high_scores": {},
	"iron_ball_set_high_score_timestamps": {},
	"one_life_set_high_score_timestamps": {},
	"time_attack_set_high_score_timestamps": {},
	"survival_top_runs": [],
	"blitz_top_runs": [],
	"last_played": {
		"level_id": 0,
		"pack_id": "classic-challenge",
		"level_index": 0,
		"level_key": "classic-challenge:0",
		"set_id": -1,
		"set_pack_id": "",
		"mode": "individual",
		"challenge_mode": CHALLENGE_MODE_NORMAL,
		"in_progress": false,
		"set_score": 0
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
		"perfect_clears": 0,
		"blitz_games_played": 0,
		"wave_objectives_completed": 0
	},
	"achievements": [],
	"settings": SaveSettingsHelper.DEFAULT_SETTINGS.duplicate(true)
}

# Signals
signal save_loaded()
signal level_unlocked(level_id: int)
signal high_score_updated(level_id: int, new_score: int)
signal achievement_unlocked(achievement_id: String, achievement_name: String)

func _emit_save_loaded() -> void:
	save_loaded.emit()

func _emit_level_unlocked(level_id: int) -> void:
	level_unlocked.emit(level_id)

func _emit_high_score_updated(level_id: int, new_score: int) -> void:
	high_score_updated.emit(level_id, new_score)

func _ready():
	"""Initialize helpers and load profiles"""
	settings_helper = SETTINGS_HELPER_SCRIPT.new()
	achievements_helper = ACHIEVEMENTS_HELPER_SCRIPT.new()
	statistics_helper = STATISTICS_HELPER_SCRIPT.new()
	progression_helper = PROGRESSION_HELPER_SCRIPT.new()
	high_scores_helper = HIGH_SCORES_HELPER_SCRIPT.new()
	profile_helper = PROFILE_HELPER_SCRIPT.new()
	settings_helper.capture_default_keybindings()
	
	_ensure_dir_exists(PROFILES_DIR)
	load_save()

func _ensure_dir_exists(path: String) -> void:
	profile_helper._ensure_dir_exists(self, path)

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
	profile_helper.load_metadata(self)

func save_metadata() -> void:
	profile_helper.save_metadata(self)

func _migrate_legacy_save() -> void:
	profile_helper._migrate_legacy_save(self)

func _invalidate_leaderboard_cache() -> void:
	high_scores_helper._invalidate_leaderboard_cache(self)

func create_profile(profile_name: String) -> String:
	return profile_helper.create_profile(self, profile_name)

func load_profile(profile_id: String) -> void:
	profile_helper.load_profile(self, profile_id)

func delete_profile(profile_id: String) -> void:
	profile_helper.delete_profile(self, profile_id)

func rename_current_profile(new_name: String) -> void:
	profile_helper.rename_current_profile(self, new_name)

func _get_profile_path(profile_id: String) -> String:
	return profile_helper._get_profile_path(self, profile_id)

func sanitize_name(profile_name: String) -> String:
	return profile_helper.sanitize_name(self, profile_name)

func _profile_name_exists(profile_name: String) -> bool:
	return profile_helper._profile_name_exists(self, profile_name)

func _perform_migrations() -> void:
	progression_helper._perform_migrations(self)

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

	# Invalidate leaderboard cache when profile data changes
	_invalidate_leaderboard_cache()

func get_profile_list() -> Dictionary:
	return profile_helper.get_profile_list(self)

func get_current_profile_id() -> String:
	return profile_helper.get_current_profile_id(self)

func get_current_profile_name() -> String:
	return profile_helper.get_current_profile_name(self)

func switch_profile(profile_id: String) -> void:
	profile_helper.switch_profile(self, profile_id)

func _apply_profile_settings() -> void:
	profile_helper._apply_profile_settings(self)

func get_next_default_name() -> String:
	return profile_helper.get_next_default_name(self)

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
		"iron_ball_set_high_scores": {},
		"one_life_set_high_scores": {},
		"time_attack_set_high_scores": {},
		"pack_set_progression": {
			"packs_completed": []
		},
		"pack_set_high_scores": {},
		"iron_ball_set_high_score_timestamps": {},
		"one_life_set_high_score_timestamps": {},
		"time_attack_set_high_score_timestamps": {},
		"survival_top_runs": [],
		"blitz_top_runs": [],
		"last_played": {
			"level_id": 0,
			"pack_id": "classic-challenge",
			"level_index": 0,
			"level_key": "classic-challenge:0",
			"set_id": -1,
			"set_pack_id": "",
			"mode": "individual",
			"challenge_mode": CHALLENGE_MODE_NORMAL,
			"in_progress": false,
			"set_score": 0
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
			"perfect_clears": 0,
			"blitz_games_played": 0,
			"wave_objectives_completed": 0
		},
		"achievements": [],
		"settings": SaveSettingsHelper.DEFAULT_SETTINGS.duplicate(true)
	}
	_ensure_pack_progression_defaults()

func _ensure_pack_progression_defaults() -> void:
	progression_helper._ensure_pack_progression_defaults(self)

func _migrate_to_v2_pack_data() -> bool:
	return progression_helper._migrate_to_v2_pack_data(self)

func _migrate_to_v3_challenge_data() -> bool:
	return progression_helper._migrate_to_v3_challenge_data(self)

func _migrate_to_v4_new_game_modes() -> bool:
	return progression_helper._migrate_to_v4_new_game_modes(self)

func _normalize_challenge_mode(mode: String) -> String:
	return progression_helper._normalize_challenge_mode(self, mode)

func _sanitize_survival_runs(raw_runs: Variant) -> Array:
	return progression_helper._sanitize_survival_runs(self, raw_runs)

func _sanitize_blitz_runs(raw_runs: Variant) -> Array:
	return progression_helper._sanitize_blitz_runs(self, raw_runs)

func _parse_level_key(level_key: String) -> Dictionary:
	return progression_helper._parse_level_key(self, level_key)

func _legacy_ref_for_level(level_id: int) -> Dictionary:
	return progression_helper._legacy_ref_for_level(self, level_id)

func _legacy_level_id_for(pack_id: String, level_index: int) -> int:
	return progression_helper._legacy_level_id_for(self, pack_id, level_index)

func _legacy_set_pack_id(set_id: int) -> String:
	return progression_helper._legacy_set_pack_id(self, set_id)

func _legacy_set_id_for_pack(pack_id: String) -> int:
	return progression_helper._legacy_set_id_for_pack(self, pack_id)

# ============================================================================
# LEVEL PROGRESSION (stays inline - tightly coupled to signals)
# ============================================================================

func is_level_unlocked(level_id: int) -> bool:
	return progression_helper.is_level_unlocked(self, level_id)

func is_level_completed(level_id: int) -> bool:
	return progression_helper.is_level_completed(self, level_id)

func unlock_level(level_id: int) -> void:
	progression_helper.unlock_level(self, level_id)

func mark_level_completed(level_id: int) -> void:
	progression_helper.mark_level_completed(self, level_id)

func get_high_score(level_id: int) -> int:
	return progression_helper.get_high_score(self, level_id)

func update_high_score(level_id: int, score: int) -> bool:
	return progression_helper.update_high_score(self, level_id, score)

func is_level_key_unlocked(level_key: String) -> bool:
	return progression_helper.is_level_key_unlocked(self, level_key)

func is_level_key_completed(level_key: String) -> bool:
	return progression_helper.is_level_key_completed(self, level_key)

func unlock_level_key(level_key: String) -> void:
	progression_helper.unlock_level_key(self, level_key)

func mark_level_key_completed(level_key: String) -> void:
	progression_helper.mark_level_key_completed(self, level_key)

func get_level_key_high_score(level_key: String) -> int:
	return high_scores_helper.get_level_key_high_score(self, level_key)

func update_level_key_high_score(level_key: String, score: int) -> bool:
	return high_scores_helper.update_level_key_high_score(self, level_key, score)

func get_level_key_stars(level_key: String) -> int:
	return progression_helper.get_level_key_stars(self, level_key)

func get_all_leaderboards(use_cache: bool = true) -> Dictionary:
	return high_scores_helper.get_all_leaderboards(self, use_cache)

func get_global_high_score(level_key: String) -> int:
	return high_scores_helper.get_global_high_score(self, level_key)

func get_global_set_high_score(pack_id: String) -> int:
	return high_scores_helper.get_global_set_high_score(self, pack_id)

func get_global_challenge_set_high_score(pack_id: String, challenge_mode: String) -> int:
	return high_scores_helper.get_global_challenge_set_high_score(self, pack_id, challenge_mode)

func get_global_time_attack_set_best_time(pack_id: String) -> int:
	return high_scores_helper.get_global_time_attack_set_best_time(self, pack_id)

func update_level_key_stars(level_key: String, stars_value: int) -> bool:
	return progression_helper.update_level_key_stars(self, level_key, stars_value)

func calculate_level_stars(level_key: String, final_score: int, perfect_clear: bool) -> int:
	return progression_helper.calculate_level_stars(self, level_key, final_score, perfect_clear)

func get_unlocked_level_count() -> int:
	return progression_helper.get_unlocked_level_count(self)

func get_completed_level_count() -> int:
	return progression_helper.get_completed_level_count(self)

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
	save_data["iron_ball_set_high_scores"] = {}
	save_data["one_life_set_high_scores"] = {}
	save_data["time_attack_set_high_scores"] = {}
	save_data["iron_ball_set_high_score_timestamps"] = {}
	save_data["one_life_set_high_score_timestamps"] = {}
	save_data["time_attack_set_high_score_timestamps"] = {}
	save_data["survival_top_runs"] = []
	save_data["blitz_top_runs"] = []
	save_data["last_played"] = {
		"level_id": 0,
		"pack_id": "classic-challenge",
		"level_index": 0,
		"level_key": "classic-challenge:0",
		"set_id": -1,
		"set_pack_id": "",
		"mode": "individual",
		"challenge_mode": CHALLENGE_MODE_NORMAL,
		"in_progress": false,
		"set_score": 0
	}
	save_data["statistics"] = {
		"total_bricks_broken": 0, "total_power_ups_collected": 0,
		"total_levels_completed": 0, "total_individual_levels_completed": 0,
		"total_set_runs_completed": 0, "total_playtime": 0.0,
		"highest_combo": 0, "highest_score": 0,
		"total_games_played": 0, "perfect_clears": 0,
		"blitz_games_played": 0, "wave_objectives_completed": 0
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

func set_last_played(level_id: int, mode: String, set_id: int = -1, in_progress: bool = true, challenge_mode: String = CHALLENGE_MODE_NORMAL) -> void:
	var ref: Dictionary = _legacy_ref_for_level(level_id)
	if ref.is_empty():
		return
	var pack_id = str(ref.get("pack_id", "classic-challenge"))
	var level_index = int(ref.get("level_index", 0))
	var set_pack_id = ""
	if set_id != -1:
		set_pack_id = _legacy_set_pack_id(set_id)
	set_last_played_ref(pack_id, level_index, mode, set_pack_id, in_progress, challenge_mode)

func set_last_played_ref(pack_id: String, level_index: int, mode: String, set_pack_id: String = "", in_progress: bool = true, challenge_mode: String = CHALLENGE_MODE_NORMAL, set_score: int = 0) -> void:
	var level_key = "%s:%d" % [pack_id, level_index]
	var legacy_level_id = _legacy_level_id_for(pack_id, level_index)
	if legacy_level_id == -1:
		legacy_level_id = 0
	var normalized_challenge = _normalize_challenge_mode(challenge_mode)

	var legacy_set_id = -1
	if not set_pack_id.is_empty():
		legacy_set_id = _legacy_set_id_for_pack(set_pack_id)

	save_data["last_played"]["level_id"] = legacy_level_id
	save_data["last_played"]["pack_id"] = pack_id
	save_data["last_played"]["level_index"] = level_index
	save_data["last_played"]["level_key"] = level_key
	save_data["last_played"]["mode"] = mode
	save_data["last_played"]["set_id"] = legacy_set_id
	save_data["last_played"]["set_pack_id"] = set_pack_id
	save_data["last_played"]["challenge_mode"] = normalized_challenge
	save_data["last_played"]["in_progress"] = in_progress
	save_data["last_played"]["set_score"] = set_score
	save_to_disk()

func set_last_played_in_progress(in_progress: bool) -> void:
	save_data["last_played"]["in_progress"] = in_progress
	save_to_disk()

func get_last_played() -> Dictionary:
	return save_data["last_played"].duplicate()

func set_last_played_survival() -> void:
	if not save_data.has("last_played"):
		save_data["last_played"] = {}
	save_data["last_played"]["level_id"] = 0
	save_data["last_played"]["pack_id"] = "classic-challenge"
	save_data["last_played"]["level_index"] = 0
	save_data["last_played"]["level_key"] = "classic-challenge:0"
	save_data["last_played"]["mode"] = "survival"
	save_data["last_played"]["set_id"] = -1
	save_data["last_played"]["set_pack_id"] = ""
	save_data["last_played"]["challenge_mode"] = CHALLENGE_MODE_NORMAL
	save_data["last_played"]["in_progress"] = false
	save_to_disk()

func set_last_played_blitz() -> void:
	if not save_data.has("last_played"):
		save_data["last_played"] = {}
	save_data["last_played"]["level_id"] = 0
	save_data["last_played"]["pack_id"] = "classic-challenge"
	save_data["last_played"]["level_index"] = 0
	save_data["last_played"]["level_key"] = "classic-challenge:0"
	save_data["last_played"]["mode"] = "blitz"
	save_data["last_played"]["set_id"] = -1
	save_data["last_played"]["set_pack_id"] = ""
	save_data["last_played"]["challenge_mode"] = CHALLENGE_MODE_NORMAL
	save_data["last_played"]["in_progress"] = false
	save_to_disk()

func set_last_challenge_mode(challenge_mode: String) -> void:
	save_data["last_played"]["challenge_mode"] = _normalize_challenge_mode(challenge_mode)
	save_to_disk()

func get_last_challenge_mode() -> String:
	var last_played: Dictionary = save_data.get("last_played", {})
	return _normalize_challenge_mode(str(last_played.get("challenge_mode", CHALLENGE_MODE_NORMAL)))

# ============================================================================
# SET SYSTEM (stays inline - small)
# ============================================================================

func get_set_high_score(set_id: int) -> int:
	return high_scores_helper.get_set_high_score(self, set_id)

func update_set_high_score(set_id: int, score: int) -> bool:
	return high_scores_helper.update_set_high_score(self, set_id, score)

func mark_set_completed(set_id: int) -> void:
	high_scores_helper.mark_set_completed(self, set_id)

func is_set_unlocked(_set_id: int) -> bool:
	return high_scores_helper.is_set_unlocked(self, _set_id)

func is_set_completed(set_id: int) -> bool:
	return high_scores_helper.is_set_completed(self, set_id)

func get_set_pack_high_score(pack_id: String) -> int:
	return high_scores_helper.get_set_pack_high_score(self, pack_id)

func _get_challenge_set_scores_key(challenge_mode: String) -> String:
	return high_scores_helper._get_challenge_set_scores_key(self, challenge_mode)

func _get_challenge_set_timestamps_key(challenge_mode: String) -> String:
	return high_scores_helper._get_challenge_set_timestamps_key(self, challenge_mode)

func get_challenge_set_high_score(pack_id: String, challenge_mode: String) -> int:
	return high_scores_helper.get_challenge_set_high_score(self, pack_id, challenge_mode)

func save_challenge_set_high_score(pack_id: String, challenge_mode: String, score: int) -> bool:
	return high_scores_helper.save_challenge_set_high_score(self, pack_id, challenge_mode, score)

func get_time_attack_set_high_score(pack_id: String) -> int:
	return high_scores_helper.get_time_attack_set_high_score(self, pack_id)

func save_time_attack_set_high_score(pack_id: String, time_seconds: int) -> bool:
	return high_scores_helper.save_time_attack_set_high_score(self, pack_id, time_seconds)

func get_survival_top_runs() -> Array:
	return high_scores_helper.get_survival_top_runs(self)

func save_survival_run(score: int, wave: int) -> void:
	high_scores_helper.save_survival_run(self, score, wave)

func get_blitz_top_runs() -> Array:
	return high_scores_helper.get_blitz_top_runs(self)

func save_blitz_run(score: int, rows: int = 1) -> void:
	high_scores_helper.save_blitz_run(self, score, rows)

func update_set_pack_high_score(pack_id: String, score: int) -> bool:
	return high_scores_helper.update_set_pack_high_score(self, pack_id, score)

func mark_set_pack_completed(pack_id: String) -> void:
	progression_helper.mark_set_pack_completed(self, pack_id)

func is_set_pack_unlocked(pack_id: String) -> bool:
	return progression_helper.is_set_pack_unlocked(self, pack_id)

func is_set_pack_completed(pack_id: String) -> bool:
	return progression_helper.is_set_pack_completed(self, pack_id)

func get_pack_completed_count(pack_id: String) -> int:
	return progression_helper.get_pack_completed_count(self, pack_id)

func get_pack_total_stars(pack_id: String) -> int:
	return progression_helper.get_pack_total_stars(self, pack_id)

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

func save_wall_color(color_name: String) -> void:
	settings_helper.save_wall_color(save_data, save_to_disk, color_name)

func get_wall_color() -> String:
	return settings_helper.get_wall_color(save_data)

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
