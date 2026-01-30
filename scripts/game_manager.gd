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

# Player stats
var score: int = 0
var lives: int = 3
var current_level: int = 1
var combo: int = 0  # Consecutive brick hits
var no_miss_hits: int = 0  # Consecutive hits without losing ball
var is_perfect_clear: bool = true  # True if no lives lost this level

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

	print("GameManager initialized")
	print("Starting lives: ", lives)
	print("Starting score: ", score)

func _process(_delta):
	# Debug: Press Escape to toggle pause (when implemented)
	if Input.is_action_just_pressed("ui_cancel") and game_state == GameState.PLAYING:
		set_state(GameState.PAUSED)
	elif Input.is_action_just_pressed("ui_cancel") and game_state == GameState.PAUSED:
		set_state(GameState.PLAYING)

## Set game state and emit signal
func set_state(new_state: GameState):
	if game_state != new_state:
		game_state = new_state
		state_changed.emit(new_state)
		print("Game state changed to: ", GameState.keys()[new_state])

		# Use Godot's built-in pause system
		get_tree().paused = (new_state == GameState.PAUSED)

## Add points to score (with difficulty, combo, and streak multipliers applied)
func add_score(points: int):
	# Apply difficulty multiplier
	var adjusted_points = int(points * DifficultyManager.get_score_multiplier())

	# Apply combo bonus (10% extra per hit above threshold)
	if combo >= COMBO_BONUS_THRESHOLD:
		var combo_multiplier = 1.0 + (combo - COMBO_BONUS_THRESHOLD + 1) * COMBO_BONUS_PER_HIT
		adjusted_points = int(adjusted_points * combo_multiplier)

	# Apply no-miss streak bonus (10% per 5 consecutive hits)
	if no_miss_hits >= STREAK_HITS_PER_BONUS:
		var streak_tiers = floorf(no_miss_hits / float(STREAK_HITS_PER_BONUS))
		var streak_multiplier = 1.0 + (streak_tiers * STREAK_BONUS_PER_TIER)
		adjusted_points = int(adjusted_points * streak_multiplier)

	# Apply double score power-up (2x multiplier)
	if PowerUpManager.is_double_score_active():
		adjusted_points = int(adjusted_points * 2.0)

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

	# Mark that perfect clear is no longer possible
	is_perfect_clear = false

	# Reset combo and streak on life loss
	reset_combo()
	reset_no_miss_streak()

	if lives <= 0:
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
	set_state(GameState.READY)
	score_changed.emit(score)
	lives_changed.emit(lives)
	combo_changed.emit(combo)
	no_miss_streak_changed.emit(no_miss_hits)
	print("Game reset")

## Start playing (ball launched)
func start_playing():
	set_state(GameState.PLAYING)
	# Reset perfect clear flag for new level attempt
	is_perfect_clear = true

func check_perfect_clear() -> bool:
	"""Check if player achieved a perfect clear (all lives intact)"""
	return is_perfect_clear and lives == 3
