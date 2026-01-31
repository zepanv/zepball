extends Node

## Game Manager - Central game state and flow control
## Manages score, lives, game state, and coordinates between systems

# Game states
enum GameState {
	MAIN_MENU,
	READY,      # Ball attached to paddle, waiting for launch
	PLAYING,    # Ball in motion
	PAUSED,
	LEVEL_COMPLETE,
	GAME_OVER
}

# Current game state
var game_state: GameState = GameState.READY
var last_state_before_pause: GameState = GameState.READY

# Player stats
var score: int = 0
var lives: int = 3
var current_level: int = 1
var combo: int = 0  # Consecutive brick hits
var no_miss_hits: int = 0  # Consecutive hits without losing ball
var is_perfect_clear: bool = true  # True if no lives lost this level
var had_continue: bool = false  # True if player used continue in set mode

# Playtime tracking
const PLAYTIME_FLUSH_INTERVAL = 5.0  # seconds
var playtime_accumulator: float = 0.0
var playtime_since_flush: float = 0.0
var level_time_seconds: float = 0.0

# Score breakdown tracking (per level)
var score_breakdown: Dictionary = {
	"base_points": 0,
	"difficulty_bonus": 0,
	"combo_bonus": 0,
	"streak_bonus": 0,
	"double_bonus": 0
}

# Combo thresholds for bonuses
const COMBO_BONUS_THRESHOLD = 3  # Combo must be at least this to get bonuses
const COMBO_BONUS_PER_HIT = 0.1  # 10% bonus per combo hit above threshold

# Streak multiplier constants
const STREAK_HITS_PER_BONUS = 5  # Every 5 hits without missing = +10% score
const STREAK_BONUS_PER_TIER = 0.1  # 10% bonus per tier

# Signals for UI and other systems
signal score_changed(new_score: int)
signal lives_changed(new_lives: int)
signal combo_changed(new_combo: int)
signal combo_milestone(combo_value: int)  # Emitted at 5, 10, 15, 20, etc.
signal no_miss_streak_changed(hits: int)  # Emitted when no-miss streak changes
signal level_complete()
signal game_over()
signal state_changed(new_state: GameState)

func _ready():
	# Set this node to always process, even when paused (so pause toggle works)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_reset_level_breakdown()
	_apply_mouse_mode_for_state(game_state)

	print("GameManager initialized")
	print("Starting lives: ", lives)
	print("Starting score: ", score)

func _process(_delta):
	# Debug: Press Escape to toggle pause (when implemented)
	if Input.is_action_just_pressed("ui_cancel") and (game_state == GameState.PLAYING or game_state == GameState.READY):
		set_state(GameState.PAUSED)
	elif Input.is_action_just_pressed("ui_cancel") and game_state == GameState.PAUSED:
		set_state(last_state_before_pause)

	# Track playtime during active gameplay states (exclude pause/menu)
	if game_state == GameState.READY or game_state == GameState.PLAYING:
		playtime_accumulator += _delta
		playtime_since_flush += _delta
		level_time_seconds += _delta

		if playtime_since_flush >= PLAYTIME_FLUSH_INTERVAL:
			_flush_playtime()

## Set game state and emit signal
func set_state(new_state: GameState):
	if game_state != new_state:
		if new_state == GameState.PAUSED:
			last_state_before_pause = game_state
		game_state = new_state
		state_changed.emit(new_state)
		print("Game state changed to: ", GameState.keys()[new_state])

		# Use Godot's built-in pause system
		get_tree().paused = (new_state == GameState.PAUSED)
		_apply_mouse_mode_for_state(new_state)

func _apply_mouse_mode_for_state(state: GameState) -> void:
	"""Capture mouse during READY/PLAYING; release for menus/overlays"""
	if state == GameState.READY or state == GameState.PLAYING:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

## Add points to score (with difficulty, combo, and streak multipliers applied)
func add_score(points: int):
	var base_points = points

	# Apply difficulty multiplier
	var adjusted_points = int(points * DifficultyManager.get_score_multiplier())
	var difficulty_bonus = adjusted_points - base_points

	# Apply combo bonus (10% extra per hit above threshold)
	var combo_bonus = 0
	if combo >= COMBO_BONUS_THRESHOLD:
		var combo_multiplier = 1.0 + (combo - COMBO_BONUS_THRESHOLD + 1) * COMBO_BONUS_PER_HIT
		var combo_points = int(adjusted_points * combo_multiplier)
		combo_bonus = combo_points - adjusted_points
		adjusted_points = combo_points

	# Apply no-miss streak bonus (10% per 5 consecutive hits)
	var streak_bonus = 0
	if no_miss_hits >= STREAK_HITS_PER_BONUS:
		var streak_tiers = floorf(no_miss_hits / float(STREAK_HITS_PER_BONUS))
		var streak_multiplier = 1.0 + (streak_tiers * STREAK_BONUS_PER_TIER)
		var streak_points = int(adjusted_points * streak_multiplier)
		streak_bonus = streak_points - adjusted_points
		adjusted_points = streak_points

	# Apply double score power-up (2x multiplier)
	var double_bonus = 0
	if PowerUpManager.is_double_score_active():
		var double_points = int(adjusted_points * 2.0)
		double_bonus = double_points - adjusted_points
		adjusted_points = double_points

	score_breakdown["base_points"] += base_points
	score_breakdown["difficulty_bonus"] += difficulty_bonus
	score_breakdown["combo_bonus"] += combo_bonus
	score_breakdown["streak_bonus"] += streak_bonus
	score_breakdown["double_bonus"] += double_bonus

	score += adjusted_points
	score_changed.emit(score)

	# Track highest score statistic
	SaveManager.update_stat_if_higher("highest_score", score)

	# Increment combo and streak
	increment_combo()
	increment_no_miss_streak()

	# Build debug message
	var multipliers = []
	if combo >= COMBO_BONUS_THRESHOLD:
		multipliers.append("COMBO x" + str(combo))
	if no_miss_hits >= STREAK_HITS_PER_BONUS:
		var streak_tiers = int(floorf(no_miss_hits / float(STREAK_HITS_PER_BONUS)))
		multipliers.append("STREAK +" + str(streak_tiers * 10) + "%")

	if multipliers.size() > 0:
		print("Score: ", score, " (+", adjusted_points, ") [", ", ".join(multipliers), "]")
	else:
		print("Score: ", score, " (+", adjusted_points, ")")

## Increment combo counter
func increment_combo():
	combo += 1
	combo_changed.emit(combo)

	# Track highest combo statistic
	SaveManager.update_stat_if_higher("highest_combo", combo)

	# Emit milestone signal at every 5th combo (5, 10, 15, 20, etc.)
	if combo % 5 == 0 and combo >= 5:
		combo_milestone.emit(combo)
		print("COMBO MILESTONE: ", combo, "x!")
	# Play SFX less frequently to avoid spam
	if combo % 20 == 0 and combo >= 20:
		AudioManager.play_sfx("combo_milestone")

## Reset combo counter
func reset_combo():
	if combo > 0:
		print("Combo broken! (was ", combo, ")")
		combo = 0
		combo_changed.emit(combo)

## Increment no-miss streak counter
func increment_no_miss_streak():
	no_miss_hits += 1
	no_miss_streak_changed.emit(no_miss_hits)

	# Show milestone message every 5 hits
	if no_miss_hits % 5 == 0 and no_miss_hits >= 5:
		print("NO-MISS STREAK: ", no_miss_hits, " hits!")

## Reset no-miss streak counter
func reset_no_miss_streak():
	if no_miss_hits > 0:
		print("No-miss streak broken! (was ", no_miss_hits, ")")
		no_miss_hits = 0
		no_miss_streak_changed.emit(no_miss_hits)

## Lose a life
func lose_life():
	lives -= 1
	lives_changed.emit(lives)
	print("Lives remaining: ", lives)
	AudioManager.play_sfx("life_lost")

	# Mark that perfect clear is no longer possible
	is_perfect_clear = false

	# Reset combo and streak on life loss
	reset_combo()
	reset_no_miss_streak()

	if lives <= 0:
		AudioManager.play_sfx("game_over")
		set_state(GameState.GAME_OVER)
		game_over.emit()
	else:
		set_state(GameState.READY)

func add_life():
	"""Add one life (from Extra Life power-up)"""
	lives += 1
	lives_changed.emit(lives)
	print("Extra life! Lives: ", lives)

## Complete current level
func complete_level():
	print("Level ", current_level, " complete!")
	AudioManager.play_sfx("level_complete")
	set_state(GameState.LEVEL_COMPLETE)
	level_complete.emit()

## Reset game state
func reset_game():
	score = 0
	lives = 3
	current_level = 1
	combo = 0
	no_miss_hits = 0
	is_perfect_clear = true
	had_continue = false
	set_state(GameState.READY)
	score_changed.emit(score)
	lives_changed.emit(lives)
	combo_changed.emit(combo)
	no_miss_streak_changed.emit(no_miss_hits)
	print("Game reset")
	_reset_level_breakdown()

## Start playing (ball launched)
func start_playing():
	set_state(GameState.PLAYING)
	# Reset perfect clear flag for new level attempt
	is_perfect_clear = true

func check_perfect_clear() -> bool:
	"""Check if player achieved a perfect clear (all lives intact)"""
	return is_perfect_clear

func get_score_breakdown() -> Dictionary:
	"""Return a copy of the current level's score breakdown"""
	return score_breakdown.duplicate()

func get_level_time_seconds() -> float:
	"""Return the elapsed time for the current level"""
	return level_time_seconds

func _reset_level_breakdown():
	level_time_seconds = 0.0
	score_breakdown["base_points"] = 0
	score_breakdown["difficulty_bonus"] = 0
	score_breakdown["combo_bonus"] = 0
	score_breakdown["streak_bonus"] = 0
	score_breakdown["double_bonus"] = 0

func _flush_playtime():
	"""Persist accumulated playtime to SaveManager"""
	if playtime_accumulator <= 0.0:
		return
	SaveManager.increment_stat("total_playtime", playtime_accumulator)
	playtime_accumulator = 0.0
	playtime_since_flush = 0.0

func _exit_tree():
	"""Flush any remaining playtime on scene exit"""
	_flush_playtime()
