extends Node2D

## Main scene controller - Connects signals between systems

@onready var game_manager = $GameManager
@onready var ball = $PlayArea/Ball
@onready var hud = $UI/HUD
@onready var brick_container = $PlayArea/BrickContainer

# Brick scene to instantiate
const BRICK_SCENE = preload("res://scenes/gameplay/brick.tscn")

func _ready():
	print("Main scene ready - connecting signals")

	# Connect ball signals to game manager
	if ball:
		ball.ball_lost.connect(_on_ball_lost)
		print("Connected ball_lost signal")

	# Connect game manager signals to HUD
	if game_manager and hud:
		game_manager.score_changed.connect(hud._on_score_changed)
		game_manager.lives_changed.connect(hud._on_lives_changed)
		print("Connected GameManager signals to HUD")

	# Create initial test level
	create_test_level()

	# Connect existing bricks
	connect_brick_signals()

func create_test_level():
	"""Create a simple 5x5 grid of bricks for testing"""
	var brick_width = 60
	var brick_height = 30
	var start_x = 150
	var start_y = 150
	var rows = 5
	var cols = 8

	for row in range(rows):
		for col in range(cols):
			var brick = BRICK_SCENE.instantiate()
			brick.position = Vector2(
				start_x + col * brick_width,
				start_y + row * brick_height
			)

			# Vary brick types by row
			if row == 0:
				brick.brick_type = brick.BrickType.STRONG
			else:
				brick.brick_type = brick.BrickType.NORMAL

			brick_container.add_child(brick)

	print("Created test level with ", rows * cols, " bricks")

func connect_brick_signals():
	"""Connect all brick signals to game manager"""
	for brick in brick_container.get_children():
		if brick.has_signal("brick_broken"):
			brick.brick_broken.connect(_on_brick_broken)

func _on_brick_broken(score_value: int):
	"""Handle brick destruction"""
	print("Main: Brick broken, adding score: ", score_value)
	game_manager.add_score(score_value)

	# Check if all bricks are gone
	await get_tree().create_timer(0.1).timeout  # Wait for brick to be removed
	check_level_complete()

func check_level_complete():
	"""Check if all bricks have been destroyed"""
	var remaining_bricks = brick_container.get_child_count()
	print("Bricks remaining: ", remaining_bricks)

	if remaining_bricks == 0:
		print("Level complete!")
		game_manager.complete_level()

func _on_ball_lost():
	print("Main: Ball was lost!")
	game_manager.lose_life()
