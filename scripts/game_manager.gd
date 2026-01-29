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

# Signals for UI and other systems
signal score_changed(new_score: int)
signal lives_changed(new_lives: int)
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

## Add points to score
func add_score(points: int):
	score += points
	score_changed.emit(score)
	print("Score: ", score, " (+", points, ")")

## Lose a life
func lose_life():
	lives -= 1
	lives_changed.emit(lives)
	print("Lives remaining: ", lives)

	if lives <= 0:
		set_state(GameState.GAME_OVER)
		game_over.emit()
	else:
		set_state(GameState.READY)

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
	set_state(GameState.READY)
	score_changed.emit(score)
	lives_changed.emit(lives)
	print("Game reset")

## Start playing (ball launched)
func start_playing():
	set_state(GameState.PLAYING)
