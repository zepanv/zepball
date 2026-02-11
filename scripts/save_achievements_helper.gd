extends RefCounted
class_name SaveAchievementsHelper

## SaveAchievementsHelper - Achievement definitions and check/unlock/query extracted from save_manager.gd.

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
		"condition_value": 3600.0
	}
}

func check_achievements(save_data: Dictionary, get_stat: Callable) -> Array[Dictionary]:
	"""Check all achievements, return array of newly unlocked {id, name} dicts."""
	var newly_unlocked: Array[Dictionary] = []
	for achievement_id in ACHIEVEMENTS:
		if is_unlocked(save_data, achievement_id):
			continue
		var achievement = ACHIEVEMENTS[achievement_id]
		var stat_name = achievement["condition_stat"]
		var required_value = achievement["condition_value"]
		var current_value = get_stat.call(stat_name)
		if current_value >= required_value:
			newly_unlocked.append({"id": achievement_id, "name": achievement["name"]})
	return newly_unlocked

func unlock(save_data: Dictionary, save_to_disk: Callable, achievement_id: String) -> String:
	"""Unlock an achievement. Returns the achievement name, or empty string if already unlocked/unknown."""
	if is_unlocked(save_data, achievement_id):
		return ""
	if not ACHIEVEMENTS.has(achievement_id):
		push_warning("Unknown achievement: " + achievement_id)
		return ""
	save_data["achievements"].append(achievement_id)
	save_to_disk.call()
	return ACHIEVEMENTS[achievement_id]["name"]

func is_unlocked(save_data: Dictionary, achievement_id: String) -> bool:
	return achievement_id in save_data["achievements"]

func get_unlocked(save_data: Dictionary) -> Array:
	return save_data["achievements"].duplicate()

func get_progress(save_data: Dictionary, get_stat: Callable, achievement_id: String) -> Dictionary:
	if not ACHIEVEMENTS.has(achievement_id):
		return {}
	var achievement = ACHIEVEMENTS[achievement_id]
	var stat_name = achievement["condition_stat"]
	var required_value = achievement["condition_value"]
	var current_value = get_stat.call(stat_name)
	return {
		"current": current_value,
		"required": required_value,
		"percentage": (current_value / required_value) * 100.0,
		"unlocked": is_unlocked(save_data, achievement_id)
	}
