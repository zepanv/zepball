extends Node2D

## Main scene controller - Connects signals between systems

@onready var game_manager = $GameManager
@onready var ball = $PlayArea/Ball
@onready var hud = $UI/HUD
@onready var brick_container = $PlayArea/BrickContainer
@onready var play_area = $PlayArea
@onready var paddle = $PlayArea/Paddle
@onready var background = $Background
@onready var camera = $Camera2D

# Brick scene to instantiate
const BRICK_SCENE = preload("res://scenes/gameplay/brick.tscn")
const BASE_RESOLUTION = Vector2i(1280, 720)

# Available backgrounds
const BACKGROUNDS = [
	"res://assets/graphics/backgrounds/bg_minimal_3_1769629212643.jpg",
	"res://assets/graphics/backgrounds/bg_minimal_4_1769629224923.jpg",
	"res://assets/graphics/backgrounds/bg_minimal_5_1769629238427.jpg",
	"res://assets/graphics/backgrounds/bg_refined_1_1769629758259.jpg",
	"res://assets/graphics/backgrounds/bg_refined_2_1769629770443.jpg",
	"res://assets/graphics/backgrounds/bg_nebula_dark_1769629799342.jpg",
	"res://assets/graphics/backgrounds/bg_stars_subtle_1769629782553.jpg"
]

# Track only breakable bricks so level completion is deterministic
var remaining_breakable_bricks: int = 0

func _ready():
	print("Main scene ready - connecting signals")

	# Set up background
	setup_background()
	var viewport = get_viewport()
	if viewport:
		viewport.size_changed.connect(_configure_background_rect)
	_configure_background_rect()

	# Connect ball signals to game manager
	if ball:
		ball.ball_lost.connect(_on_ball_lost)
		print("Connected ball_lost signal")

	# Connect game manager signals to HUD
	if game_manager and hud:
		game_manager.score_changed.connect(hud._on_score_changed)
		game_manager.lives_changed.connect(hud._on_lives_changed)
		game_manager.level_complete.connect(_on_level_complete)
		print("Connected GameManager signals to HUD")

	# Create initial test level
	create_test_level()

	# Connect existing bricks
	connect_brick_signals()

func setup_background():
	"""Load and configure a random background image"""
	if not background:
		return

	# Select a random background
	var selected_bg = BACKGROUNDS[randi() % BACKGROUNDS.size()]
	var texture = load(selected_bg)

	if not texture:
		print("Warning: Could not load background: ", selected_bg)
		return

	# Move background to a CanvasLayer so it renders in screen space
	var bg_layer = CanvasLayer.new()
	bg_layer.name = "BackgroundLayer"
	bg_layer.layer = -100

	# Convert ColorRect to TextureRect if needed
	if background is ColorRect:
		# Remove ColorRect and create TextureRect
		var texture_rect = TextureRect.new()
		texture_rect.name = "Background"
		texture_rect.texture = texture
		texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
		texture_rect.modulate.a = 0.85  # Slight dimming so it doesn't distract

		# Move to CanvasLayer
		var old_parent = background.get_parent()
		old_parent.remove_child(background)
		background.queue_free()

		add_child(bg_layer)
		bg_layer.add_child(texture_rect)
		background = texture_rect

		print("Background loaded: ", selected_bg)
	elif background is TextureRect:
		background.texture = texture
		background.stretch_mode = TextureRect.STRETCH_SCALE
		background.modulate.a = 0.85

		# Move to CanvasLayer
		var old_parent = background.get_parent()
		old_parent.remove_child(background)
		add_child(bg_layer)
		bg_layer.add_child(background)

		print("Background loaded: ", selected_bg)

	_configure_background_rect()

func _configure_background_rect():
	"""Make the background fit the viewport."""
	if not background or not (background is Control):
		return
	# In screen space (CanvasLayer), use viewport size and anchor to fill screen
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.position = Vector2.ZERO
	background.size = get_viewport().get_visible_rect().size


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
	remaining_breakable_bricks = 0
	for brick in brick_container.get_children():
		if brick.has_signal("brick_broken"):
			brick.brick_broken.connect(_on_brick_broken)
		if brick.has_signal("power_up_spawned"):
			brick.power_up_spawned.connect(_on_power_up_spawned)
		if brick.brick_type != brick.BrickType.UNBREAKABLE:
			remaining_breakable_bricks += 1
	print("Breakable bricks: ", remaining_breakable_bricks)

func _on_brick_broken(score_value: int):
	"""Handle brick destruction"""
	print("Main: Brick broken, adding score: ", score_value)
	game_manager.add_score(score_value)

	# Trigger screen shake (intensity scales with score)
	if camera and camera.has_method("shake"):
		var intensity = 2.0 + (score_value / 50.0) * 3.0  # 2-5 pixels based on score
		camera.shake(intensity, 0.15)

	# Decrement breakable brick count and check completion immediately
	remaining_breakable_bricks = max(remaining_breakable_bricks - 1, 0)
	check_level_complete()

func check_level_complete():
	"""Check if all bricks have been destroyed"""
	print("Bricks remaining: ", remaining_breakable_bricks)

	if remaining_breakable_bricks == 0:
		print("Level complete!")
		game_manager.complete_level()

func _on_ball_lost():
	print("Main: Ball was lost!")
	game_manager.lose_life()

func _on_level_complete():
	"""Stop the ball when the level is complete"""
	if ball and ball.has_method("reset_ball"):
		ball.reset_ball()

func _input(event):
	"""Debug/testing inputs"""
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_C:
			_hit_all_bricks()
		elif event.keycode == KEY_1:
			# Debug: Spawn a triple ball power-up for testing
			print("\n### DEBUG: Spawning TRIPLE_BALL power-up ###")
			var powerup_scene = load("res://scenes/gameplay/power_up.tscn")
			if powerup_scene:
				var powerup = powerup_scene.instantiate()
				powerup.power_up_type = 3  # TRIPLE_BALL
				powerup.position = Vector2(1100, 360)  # Near paddle
				_on_power_up_spawned(powerup)
				print("TRIPLE_BALL power-up spawned at position: ", powerup.position)
			else:
				print("ERROR: Could not load power-up scene")

func _hit_all_bricks():
	"""Hit all bricks (breaks normals, strongs via double hit)"""
	if not brick_container:
		return
	var bricks = brick_container.get_children()
	for brick in bricks:
		if brick.has_method("hit"):
			brick.hit()
			brick.hit()

func _on_power_up_spawned(power_up_node):
	"""Handle power-up spawning from broken brick"""
	# Add power-up to PlayArea
	play_area.add_child(power_up_node)

	# Connect collection signal
	if power_up_node.has_signal("collected"):
		power_up_node.collected.connect(_on_power_up_collected)

	print("Power-up spawned and added to scene")

func _on_power_up_collected(type):
	"""Handle power-up collection"""
	print("Main: Power-up collected, type: ", type)

	# Apply power-up effect based on type
	match type:
		0:  # EXPAND
			if paddle and paddle.has_method("apply_expand_effect"):
				paddle.apply_expand_effect()
				PowerUpManager.apply_effect(PowerUpManager.PowerUpType.EXPAND, paddle)
		1:  # CONTRACT
			if paddle and paddle.has_method("apply_contract_effect"):
				paddle.apply_contract_effect()
				PowerUpManager.apply_effect(PowerUpManager.PowerUpType.CONTRACT, paddle)
		2:  # SPEED_UP
			if ball and ball.has_method("apply_speed_up_effect"):
				ball.apply_speed_up_effect()
				PowerUpManager.apply_effect(PowerUpManager.PowerUpType.SPEED_UP, ball)
		3:  # TRIPLE_BALL
			spawn_additional_balls()
			# TRIPLE_BALL doesn't have a timer, so we don't add it to PowerUpManager

func spawn_additional_balls():
	"""Spawn 2 additional balls for multi-ball power-up"""
	print("=== SPAWNING TRIPLE BALL ===")

	if not ball:
		print("ERROR: No ball reference found")
		return

	print("Current ball position: ", ball.position)
	print("Current ball velocity: ", ball.velocity)
	print("Current ball speed: ", ball.current_speed)

	# Get ball scene
	var ball_scene = load("res://scenes/gameplay/ball.tscn")
	if not ball_scene:
		print("ERROR: Could not load ball scene")
		return

	# Spawn 2 additional balls
	for i in range(2):
		print("\n--- Spawning ball ", i + 1, " ---")
		var new_ball = ball_scene.instantiate()

		# Position at current ball location
		new_ball.position = ball.position
		print("New ball position: ", new_ball.position)

		# Launch with safe angles based on current ball position
		# If ball is near top (Y < 200), send both balls downward
		# If ball is near bottom (Y > 520), send both balls upward
		# Otherwise, send one up and one down
		var angle_offset = 0.0

		if ball.position.y < 200:
			# Near top - both balls go slightly downward
			angle_offset = -5.0 if i == 0 else -15.0
		elif ball.position.y > 520:
			# Near bottom - both balls go slightly upward
			angle_offset = 5.0 if i == 0 else 15.0
		else:
			# Middle area - spread up and down
			angle_offset = -10.0 if i == 0 else 10.0

		var target_angle = 180.0 + angle_offset
		var angle_rad = deg_to_rad(target_angle)

		print("Ball Y position: ", ball.position.y, " -> Using angle offset: ", angle_offset, "°")

		new_ball.velocity = Vector2(cos(angle_rad), sin(angle_rad)) * ball.current_speed
		new_ball.is_attached_to_paddle = false

		print("Target angle: ", target_angle, "° (180° = straight left)")
		print("Calculated velocity: ", new_ball.velocity)
		print("Velocity magnitude: ", new_ball.velocity.length())
		print("Velocity angle check: ", rad_to_deg(atan2(new_ball.velocity.y, new_ball.velocity.x)), "°")

		# Enable trail
		if new_ball.has_node("Trail"):
			new_ball.get_node("Trail").emitting = true

		# Add to scene
		play_area.add_child(new_ball)

		# Connect signals
		new_ball.ball_lost.connect(_on_ball_lost)

		print("Ball ", i + 1, " added to scene successfully")

	print("=== TRIPLE BALL SPAWN COMPLETE ===")
