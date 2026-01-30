extends Node

## SaveManager - Autoload singleton for managing player save data
## Handles level progression, high scores, and settings persistence

const SAVE_FILE_PATH = "user://save_data.json"
const SAVE_VERSION = 1
const TOTAL_LEVELS = 10  # Update this when adding more levels

# Achievement definitions
const ACHIEVEMENTS = {
	"first_blood": {
		"name": "First Blood",
		"description": "Break your first brick",
		"condition_stat": "total_bricks_broken",
		"condition_value": 1
	},
	"destroyer": {
		"name": "Destroyer",
		"description": "Break 1000 bricks",
		"condition_stat": "total_bricks_broken",
		"condition_value": 1000
	},
	"brick_master": {
		"name": "Brick Master",
		"description": "Break 5000 bricks",
		"condition_stat": "total_bricks_broken",
		"condition_value": 5000
	},
	"combo_starter": {
		"name": "Combo Starter",
		"description": "Reach a 5x combo",
		"condition_stat": "highest_combo",
		"condition_value": 5
	},
	"combo_master": {
		"name": "Combo Master",
		"description": "Reach a 20x combo",
		"condition_stat": "highest_combo",
		"condition_value": 20
	},
	"combo_god": {
		"name": "Combo God",
		"description": "Reach a 50x combo",
		"condition_stat": "highest_combo",
		"condition_value": 50
	},
	"power_collector": {
		"name": "Power Collector",
		"description": "Collect 100 power-ups",
		"condition_stat": "total_power_ups_collected",
		"condition_value": 100
	},
	"champion": {
		"name": "Champion",
		"description": "Complete all 10 levels",
		"condition_stat": "total_levels_completed",
		"condition_value": 10
	},
	"perfectionist": {
		"name": "Perfectionist",
		"description": "Complete a level without missing the ball",
		"condition_stat": "perfect_clears",
		"condition_value": 1
	},
	"flawless": {
		"name": "Flawless",
		"description": "Get 10 perfect clears",
		"condition_stat": "perfect_clears",
		"condition_value": 10
	},
	"high_roller": {
		"name": "High Roller",
		"description": "Score 10,000 points in a single game",
		"condition_stat": "highest_score",
		"condition_value": 10000
	},
	"dedicated": {
		"name": "Dedicated",
		"description": "Play for 1 hour total",
		"condition_stat": "total_playtime",
		"condition_value": 3600.0  # 1 hour in seconds
	}
}

# Save data structure
var save_data = {
	"version": SAVE_VERSION,
	"profile": {
		"player_name": "Player",
		"total_score": 0
	},
	"progression": {
		"highest_unlocked_level": 1,  # Start with level 1 unlocked
		"levels_completed": []  # Array of completed level IDs
	},
	"high_scores": {},  # Dictionary: level_id (String) -> score (int)
	"set_progression": {
		"highest_unlocked_set": 1,  # All sets unlocked by default
		"sets_completed": []  # Array of completed set IDs
	},
	"set_high_scores": {},  # Dictionary: set_id (String) -> cumulative_score (int)
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
	"achievements": [],  # Array of unlocked achievement IDs
	"settings": {
		"difficulty": "Normal",  # Easy, Normal, Hard
		"music_volume_db": 0.0,
		"sfx_volume_db": 0.0,
		"screen_shake_intensity": "Medium",  # Off, Low, Medium, High
		"particle_effects_enabled": true,
		"ball_trail_enabled": true,
		"paddle_sensitivity": 1.0  # Range: 0.5 to 2.0
	}
}

# Signals
signal save_loaded()
signal level_unlocked(level_id: int)
signal high_score_updated(level_id: int, new_score: int)
signal achievement_unlocked(achievement_id: String, achievement_name: String)

func _ready():
	"""Load save data on startup"""
	load_save()

func load_save() -> void:
	"""Load save data from disk, or create default if none exists"""
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("No save file found, creating default save data")
		create_default_save()
		save_to_disk()
		save_loaded.emit()
		return

	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file == null:
		push_error("Failed to open save file: " + str(FileAccess.get_open_error()))
		create_default_save()
		return

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		push_error("Failed to parse save file JSON")
		create_default_save()
		return

	var loaded_data = json.data

	# Validate and migrate if needed
	if not loaded_data.has("version"):
		print("Old save format detected, migrating...")
		create_default_save()
		return

	save_data = loaded_data

	# Migrate old saves that don't have statistics
	if not save_data.has("statistics"):
		print("Adding statistics section to save data...")
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

	# Migrate old saves that don't have achievements
	if not save_data.has("achievements"):
		print("Adding achievements section to save data...")
		save_data["achievements"] = []
		save_to_disk()

	# Migrate old saves that don't have set progression
	if not save_data.has("set_progression"):
		print("Adding set progression to save data...")
		save_data["set_progression"] = {
			"highest_unlocked_set": 1,
			"sets_completed": []
		}
		save_to_disk()

	# Migrate old saves that don't have set high scores
	if not save_data.has("set_high_scores"):
		print("Adding set high scores to save data...")
		save_data["set_high_scores"] = {}
		save_to_disk()

	# Migrate old saves that don't have new statistics
	var stats_updated = false
	if not save_data["statistics"].has("total_individual_levels_completed"):
		# Migrate old total_levels_completed to individual count
		save_data["statistics"]["total_individual_levels_completed"] = save_data["statistics"].get("total_levels_completed", 0)
		stats_updated = true
	if not save_data["statistics"].has("total_set_runs_completed"):
		save_data["statistics"]["total_set_runs_completed"] = 0
		stats_updated = true

	if stats_updated:
		print("Adding new statistics to save data...")
		save_to_disk()

	# Migrate old saves that don't have new settings
	var settings_updated = false
	if not save_data["settings"].has("screen_shake_intensity"):
		save_data["settings"]["screen_shake_intensity"] = "Medium"
		settings_updated = true
	if not save_data["settings"].has("particle_effects_enabled"):
		save_data["settings"]["particle_effects_enabled"] = true
		settings_updated = true
	if not save_data["settings"].has("ball_trail_enabled"):
		save_data["settings"]["ball_trail_enabled"] = true
		settings_updated = true
	if not save_data["settings"].has("paddle_sensitivity"):
		save_data["settings"]["paddle_sensitivity"] = 1.0
		settings_updated = true

	if settings_updated:
		print("Adding new settings to save data...")
		save_to_disk()

	print("Save data loaded successfully")
	print("Highest unlocked level: ", save_data["progression"]["highest_unlocked_level"])
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
	print("Save data written to disk")

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
		"settings": {
			"difficulty": "Normal",
			"music_volume_db": 0.0,
			"sfx_volume_db": 0.0,
			"screen_shake_intensity": "Medium",
			"particle_effects_enabled": true,
			"ball_trail_enabled": true,
			"paddle_sensitivity": 1.0
		}
	}
	print("Default save data created")

func is_level_unlocked(level_id: int) -> bool:
	"""Check if a level is unlocked"""
	return level_id <= save_data["progression"]["highest_unlocked_level"]

func is_level_completed(level_id: int) -> bool:
	"""Check if a level has been completed"""
	return level_id in save_data["progression"]["levels_completed"]

func unlock_level(level_id: int) -> void:
	"""Unlock a level (if not already unlocked)"""
	if level_id > TOTAL_LEVELS:
		print("Cannot unlock level ", level_id, " - only ", TOTAL_LEVELS, " levels exist")
		return

	var current_highest = save_data["progression"]["highest_unlocked_level"]
	if level_id > current_highest:
		save_data["progression"]["highest_unlocked_level"] = level_id
		print("Level ", level_id, " unlocked!")
		save_to_disk()
		level_unlocked.emit(level_id)

func mark_level_completed(level_id: int) -> void:
	"""Mark a level as completed"""
	if not level_id in save_data["progression"]["levels_completed"]:
		save_data["progression"]["levels_completed"].append(level_id)
		save_to_disk()
		print("Level ", level_id, " marked as completed")

func get_high_score(level_id: int) -> int:
	"""Get the high score for a level (returns 0 if no score exists)"""
	var key = str(level_id)
	if save_data["high_scores"].has(key):
		return save_data["high_scores"][key]
	return 0

func update_high_score(level_id: int, score: int) -> bool:
	"""Update high score if new score is higher. Returns true if high score was beaten."""
	var key = str(level_id)
	var current_high_score = get_high_score(level_id)

	if score > current_high_score:
		save_data["high_scores"][key] = score
		save_to_disk()
		print("New high score for level ", level_id, ": ", score)
		high_score_updated.emit(level_id, score)
		return true

	return false

func get_unlocked_level_count() -> int:
	"""Get the number of unlocked levels"""
	return save_data["progression"]["highest_unlocked_level"]

func get_completed_level_count() -> int:
	"""Get the number of completed levels"""
	return save_data["progression"]["levels_completed"].size()

func save_difficulty(difficulty_name: String) -> void:
	"""Save difficulty preference"""
	save_data["settings"]["difficulty"] = difficulty_name
	save_to_disk()

func get_saved_difficulty() -> String:
	"""Get saved difficulty preference"""
	return save_data["settings"]["difficulty"]

func save_audio_settings(music_volume_db: float, sfx_volume_db: float) -> void:
	"""Save audio volume settings"""
	save_data["settings"]["music_volume_db"] = music_volume_db
	save_data["settings"]["sfx_volume_db"] = sfx_volume_db
	save_to_disk()

func get_music_volume() -> float:
	"""Get saved music volume"""
	return save_data["settings"]["music_volume_db"]

func get_sfx_volume() -> float:
	"""Get saved SFX volume"""
	return save_data["settings"]["sfx_volume_db"]

func reset_save_data() -> void:
	"""Reset all save data to defaults (for testing or player request)"""
	create_default_save()
	save_to_disk()
	print("Save data has been reset")

func get_save_file_location() -> String:
	"""Get the absolute path to the save file for debugging"""
	return ProjectSettings.globalize_path(SAVE_FILE_PATH)

# ============================================================================
# STATISTICS TRACKING
# ============================================================================

func increment_stat(stat_name: String, amount: float = 1.0):
	"""Increment a statistic by the given amount"""
	if not save_data["statistics"].has(stat_name):
		push_warning("Statistic not found: " + stat_name)
		return

	save_data["statistics"][stat_name] += amount
	save_to_disk()

func get_stat(stat_name: String) -> float:
	"""Get the value of a statistic"""
	if not save_data["statistics"].has(stat_name):
		push_warning("Statistic not found: " + stat_name)
		return 0.0

	return save_data["statistics"][stat_name]

func update_stat_if_higher(stat_name: String, new_value: float):
	"""Update stat only if new value is higher (for records like highest_combo)"""
	if not save_data["statistics"].has(stat_name):
		push_warning("Statistic not found: " + stat_name)
		return

	if new_value > save_data["statistics"][stat_name]:
		save_data["statistics"][stat_name] = new_value
		save_to_disk()
		print("New record for ", stat_name, ": ", new_value)

func get_all_statistics() -> Dictionary:
	"""Get all statistics as a dictionary"""
	return save_data["statistics"].duplicate()

# ============================================================================
# ACHIEVEMENTS SYSTEM
# ============================================================================

func check_achievements():
	"""Check all achievements and unlock any that meet conditions"""
	for achievement_id in ACHIEVEMENTS:
		# Skip if already unlocked
		if is_achievement_unlocked(achievement_id):
			continue

		var achievement = ACHIEVEMENTS[achievement_id]
		var stat_name = achievement["condition_stat"]
		var required_value = achievement["condition_value"]
		var current_value = get_stat(stat_name)

		# Check if condition is met
		if current_value >= required_value:
			unlock_achievement(achievement_id)

func unlock_achievement(achievement_id: String):
	"""Unlock an achievement"""
	if is_achievement_unlocked(achievement_id):
		return  # Already unlocked

	if not ACHIEVEMENTS.has(achievement_id):
		push_warning("Unknown achievement: " + achievement_id)
		return

	# Add to unlocked list
	save_data["achievements"].append(achievement_id)
	save_to_disk()

	# Emit signal
	var achievement_name = ACHIEVEMENTS[achievement_id]["name"]
	achievement_unlocked.emit(achievement_id, achievement_name)
	print("🏆 ACHIEVEMENT UNLOCKED: ", achievement_name)

func is_achievement_unlocked(achievement_id: String) -> bool:
	"""Check if an achievement is unlocked"""
	return achievement_id in save_data["achievements"]

func get_unlocked_achievements() -> Array:
	"""Get list of unlocked achievement IDs"""
	return save_data["achievements"].duplicate()

func get_achievement_progress(achievement_id: String) -> Dictionary:
	"""Get progress toward an achievement"""
	if not ACHIEVEMENTS.has(achievement_id):
		return {}

	var achievement = ACHIEVEMENTS[achievement_id]
	var stat_name = achievement["condition_stat"]
	var required_value = achievement["condition_value"]
	var current_value = get_stat(stat_name)

	return {
		"current": current_value,
		"required": required_value,
		"percentage": (current_value / required_value) * 100.0,
		"unlocked": is_achievement_unlocked(achievement_id)
	}

# ============================================================================
# GAMEPLAY SETTINGS
# ============================================================================

func save_screen_shake_intensity(intensity: String) -> void:
	"""Save screen shake intensity preference"""
	if intensity not in ["Off", "Low", "Medium", "High"]:
		push_warning("Invalid screen shake intensity: " + intensity)
		return
	save_data["settings"]["screen_shake_intensity"] = intensity
	save_to_disk()

func get_screen_shake_intensity() -> String:
	"""Get screen shake intensity preference"""
	return save_data["settings"].get("screen_shake_intensity", "Medium")

func save_particle_effects(enabled: bool) -> void:
	"""Save particle effects preference"""
	save_data["settings"]["particle_effects_enabled"] = enabled
	save_to_disk()

func get_particle_effects() -> bool:
	"""Get particle effects preference"""
	return save_data["settings"].get("particle_effects_enabled", true)

func save_ball_trail(enabled: bool) -> void:
	"""Save ball trail preference"""
	save_data["settings"]["ball_trail_enabled"] = enabled
	save_to_disk()

func get_ball_trail() -> bool:
	"""Get ball trail preference"""
	return save_data["settings"].get("ball_trail_enabled", true)

func save_paddle_sensitivity(sensitivity: float) -> void:
	"""Save paddle sensitivity preference"""
	# Clamp to valid range
	sensitivity = clampf(sensitivity, 0.5, 2.0)
	save_data["settings"]["paddle_sensitivity"] = sensitivity
	save_to_disk()

func get_paddle_sensitivity() -> float:
	"""Get paddle sensitivity preference"""
	return save_data["settings"].get("paddle_sensitivity", 1.0)

# ============================================================================
# SET SYSTEM
# ============================================================================

func get_set_high_score(set_id: int) -> int:
	"""Get the high score for a set (returns 0 if no score exists)"""
	var key = str(set_id)
	if save_data["set_high_scores"].has(key):
		return save_data["set_high_scores"][key]
	return 0

func update_set_high_score(set_id: int, score: int) -> bool:
	"""Update set high score if new score is higher. Returns true if high score was beaten."""
	var key = str(set_id)
	var current_high_score = get_set_high_score(set_id)

	if score > current_high_score:
		save_data["set_high_scores"][key] = score
		save_to_disk()
		print("New set high score for set ", set_id, ": ", score)
		return true

	return false

func mark_set_completed(set_id: int) -> void:
	"""Mark a set as completed"""
	if not set_id in save_data["set_progression"]["sets_completed"]:
		save_data["set_progression"]["sets_completed"].append(set_id)
		save_to_disk()
		print("Set ", set_id, " marked as completed")

func is_set_unlocked(set_id: int) -> bool:
	"""Check if a set is unlocked (all sets unlocked for now)"""
	return set_id <= save_data["set_progression"]["highest_unlocked_set"] or set_id == 1

func is_set_completed(set_id: int) -> bool:
	"""Check if a set has been completed"""
	return set_id in save_data["set_progression"]["sets_completed"]
