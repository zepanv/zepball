extends Node

## DifficultyManager - Autoload singleton for managing game difficulty
## Provides speed and score multipliers based on selected difficulty

enum Difficulty {
	EASY,
	NORMAL,
	HARD
}

# Current difficulty setting
var current_difficulty: Difficulty = Difficulty.NORMAL

# Lock difficulty changes once gameplay starts (unlocked in main menu)
var is_locked: bool = false

# Difficulty multipliers
const DIFFICULTY_SETTINGS = {
	Difficulty.EASY: {
		"speed_multiplier": 0.8,
		"score_multiplier": 0.8,
		"name": "Easy"
	},
	Difficulty.NORMAL: {
		"speed_multiplier": 1.0,
		"score_multiplier": 1.0,
		"name": "Normal"
	},
	Difficulty.HARD: {
		"speed_multiplier": 1.2,
		"score_multiplier": 1.5,
		"name": "Hard"
	}
}

# Signals
signal difficulty_changed(new_difficulty: Difficulty)

func set_difficulty(difficulty: Difficulty):
	"""Set the game difficulty (only allowed when not locked)"""
	if is_locked:
		push_warning("Cannot change difficulty during gameplay")
		return

	if current_difficulty != difficulty:
		current_difficulty = difficulty
		difficulty_changed.emit(difficulty)

func lock_difficulty():
	"""Lock difficulty changes (called when gameplay starts)"""
	is_locked = true

func unlock_difficulty():
	"""Unlock difficulty changes (called in main menu)"""
	is_locked = false

func get_speed_multiplier() -> float:
	"""Get the speed multiplier for current difficulty"""
	return DIFFICULTY_SETTINGS[current_difficulty]["speed_multiplier"]

func get_score_multiplier() -> float:
	"""Get the score multiplier for current difficulty"""
	return DIFFICULTY_SETTINGS[current_difficulty]["score_multiplier"]

func get_difficulty_name() -> String:
	"""Get the human-readable name of current difficulty"""
	return DIFFICULTY_SETTINGS[current_difficulty]["name"]

func get_difficulty() -> Difficulty:
	"""Get the current difficulty level"""
	return current_difficulty
