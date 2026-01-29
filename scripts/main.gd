extends Node2D

## Main scene controller - Orchestrates gameplay systems
##
## Responsibilities:
## - Connect signals between gameplay systems (ball, bricks, power-ups, game manager)
## - Manage level layout and brick spawning
## - Handle ball loss logic (life deduction when last ball is lost)
## - Coordinate power-up spawning and collection
## - Track breakable brick count for level completion
## - Background selection and setup

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

# Level layout constants
const BRICK_SIZE = 48         # Square brick size in pixels
const BRICK_SPACING = 3       # Gap between bricks
const LEVEL_START_X = 150     # Default X position for level start
const LEVEL_START_Y = 150     # Default Y position for level start

# Boundary constants
const RIGHT_BOUNDARY = 1300   # Past paddle (ball lost)
const POWER_UP_MISS_X = 1300  # X position where power-ups despawn

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
		game_manager.game_over.connect(_on_game_over)
		print("Connected GameManager signals to HUD")

	# Load level from MenuController (or level 1 as fallback)
	var level_id = MenuController.get_current_level_id()
	load_level(level_id)

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
	# Use set_deferred to avoid anchor warning
	background.set_deferred("size", get_viewport().get_visible_rect().size)


func load_level(level_id: int):
	"""Load a level from JSON using LevelLoader"""
	print("Loading level ", level_id)

	var level_result = LevelLoader.instantiate_level(level_id, brick_container)

	if level_result["success"]:
		print("Level loaded: ", level_result["name"])
		print("  Description: ", level_result["description"])
		print("  Total bricks: ", level_result["total_bricks"])
		print("  Breakable bricks: ", level_result["breakable_count"])

		# Update game manager with level info
		if game_manager:
			game_manager.current_level = level_id

		# Show level intro
		if hud and hud.has_method("show_level_intro"):
			hud.show_level_intro(level_id, level_result["name"], level_result["description"])
	else:
		push_error("Failed to load level ", level_id, " - falling back to test level")
		create_test_level()

func create_test_level():
	"""Create a grid of square bricks for testing (fallback)"""
	var rows = 5
	var cols = 8

	for row in range(rows):
		for col in range(cols):
			var brick = BRICK_SCENE.instantiate()
			brick.position = Vector2(
				LEVEL_START_X + col * (BRICK_SIZE + BRICK_SPACING),
				LEVEL_START_Y + row * (BRICK_SIZE + BRICK_SPACING)
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

	# Track statistic
	SaveManager.increment_stat("total_bricks_broken")

	# Trigger screen shake (intensity scales with score AND combo)
	if camera and camera.has_method("shake"):
		var base_intensity = 2.0 + (score_value / 50.0) * 3.0  # 2-5 pixels based on score

		# Scale with combo multiplier (higher combo = more shake)
		var combo_multiplier = 1.0
		if game_manager and game_manager.combo >= 3:
			combo_multiplier = 1.0 + (game_manager.combo - 2) * 0.15  # +15% per combo over 2

		var intensity = min(base_intensity * combo_multiplier, 12.0)  # Cap at 12 pixels
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

func _on_ball_lost(lost_ball):
	"""Handle ball loss - only lose life if this is the last ball in play"""
	# Get all balls currently in play (before removing this one)
	var balls_in_play = get_tree().get_nodes_in_group("ball")

	# Check if this is the last ball
	if balls_in_play.size() <= 1:
		# Last ball lost - lose a life and reset main ball
		print("Main: Last ball was lost! Losing life.")
		game_manager.lose_life()

		# Find the actual main ball in the scene
		var main_ball_ref = null
		for b in balls_in_play:
			if b.is_main_ball:
				main_ball_ref = b
				break

		# If we found a main ball, use it
		if main_ball_ref and is_instance_valid(main_ball_ref):
			if main_ball_ref.has_method("reset_ball"):
				main_ball_ref.reset_ball()
				ball = main_ball_ref  # Update reference
			else:
				print("ERROR: Main ball has no reset_ball method")
		# Otherwise try the scene's ball reference
		elif is_instance_valid(ball) and ball.has_method("reset_ball"):
			ball.reset_ball()
		else:
			print("WARNING: Cannot reset main ball - no valid main ball found")
			print("  Scene ball reference valid: ", is_instance_valid(ball))
			print("  Lost ball is main: ", lost_ball.is_main_ball if lost_ball else "null")
			# Try to recover by finding ANY ball in the scene
			if balls_in_play.size() > 0 and is_instance_valid(balls_in_play[0]):
				print("  RECOVERY: Using first available ball as main ball")
				balls_in_play[0].is_main_ball = true
				ball = balls_in_play[0]
				if ball.has_method("reset_ball"):
					ball.reset_ball()

		# Clean up the lost ball if it's not the one we're using
		if lost_ball != ball and is_instance_valid(lost_ball):
			lost_ball.queue_free()
	else:
		# Still have other balls in play - no life penalty
		print("Main: Ball lost, but ", balls_in_play.size() - 1, " ball(s) still in play")
		if is_instance_valid(lost_ball):
			lost_ball.queue_free()

func _on_level_complete():
	"""Handle level completion - stop ball and transition to complete screen"""
	print("Main: Level complete handler triggered")

	# Stop the ball
	if ball and ball.has_method("reset_ball"):
		ball.reset_ball()

	# Show level complete screen with final score
	MenuController.show_level_complete(game_manager.score)

func _on_game_over():
	"""Handle game over - transition to game over screen"""
	print("Main: Game over handler triggered")

	# Show game over screen with final score
	MenuController.show_game_over(game_manager.score)

func _input(event):
	"""Handle input for restart and debug/testing"""
	# Restart with input action
	if Input.is_action_just_pressed("restart_game"):
		print("Restarting level...")
		MenuController.restart_current_level()

	if event is InputEventKey and event.pressed and not event.echo:
		# DEBUG ONLY: Difficulty selection (remove once main menu exists)
		# TODO: Move difficulty selection to main menu
		if OS.is_debug_build():
			if event.keycode == KEY_E:
				DifficultyManager.unlock_difficulty()
				DifficultyManager.set_difficulty(DifficultyManager.Difficulty.EASY)
			elif event.keycode == KEY_N:
				DifficultyManager.unlock_difficulty()
				DifficultyManager.set_difficulty(DifficultyManager.Difficulty.NORMAL)
			elif event.keycode == KEY_H:
				DifficultyManager.unlock_difficulty()
				DifficultyManager.set_difficulty(DifficultyManager.Difficulty.HARD)

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

	# Track statistic
	SaveManager.increment_stat("total_power_ups_collected")

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
			# Defer spawning to avoid physics query conflict during collision callback
			call_deferred("spawn_additional_balls_with_retry", 3)  # Try up to 3 times
			# TRIPLE_BALL doesn't have a timer, so we don't add it to PowerUpManager

func spawn_additional_balls_with_retry(retries_remaining: int = 3):
	"""Try to spawn additional balls, retrying if ball is in a bad position"""
	var result = try_spawn_additional_balls()

	if not result and retries_remaining > 1:
		print("Retrying triple ball spawn in 0.5 seconds... (", retries_remaining - 1, " attempts left)")
		await get_tree().create_timer(0.5).timeout
		spawn_additional_balls_with_retry(retries_remaining - 1)
	elif not result:
		print("ERROR: Failed to spawn triple ball after all retries - power-up wasted")

func try_spawn_additional_balls() -> bool:
	"""Attempt to spawn additional balls - returns true if successful, false if position is bad"""
	# Find any active ball in play
	var active_balls = get_tree().get_nodes_in_group("ball")
	var source_ball = null

	# Prefer a ball that's in motion (not attached to paddle)
	for b in active_balls:
		if not b.is_attached_to_paddle:
			source_ball = b
			break

	# If no moving ball, use any ball (including attached one)
	if not source_ball and active_balls.size() > 0:
		source_ball = active_balls[0]

	# If still no ball, use the main ball reference as fallback
	if not source_ball:
		source_ball = ball

	if not source_ball:
		print("ERROR: No ball reference found (no balls in scene)")
		return false

	# Safety check: Don't spawn if ball is too close to edges
	if source_ball.position.x > 1100:
		print("WARNING: Cannot spawn triple ball - source ball too close to paddle (X=", source_ball.position.x, ")")
		return false
	if source_ball.position.x < 50:
		print("WARNING: Cannot spawn triple ball - source ball too close to left wall (X=", source_ball.position.x, ")")
		return false
	if source_ball.position.y < 50 or source_ball.position.y > 670:
		print("WARNING: Cannot spawn triple ball - source ball too close to top/bottom (Y=", source_ball.position.y, ")")
		return false

	# Position is good - spawn the balls
	spawn_additional_balls(source_ball)
	return true

func spawn_additional_balls(source_ball):
	"""Spawn 2 additional balls for multi-ball power-up - source_ball position already validated"""
	print("\n" + "=".repeat(60))
	print("=== SPAWNING TRIPLE BALL POWER-UP ===")
	print("=".repeat(60))

	print("\n[SOURCE BALL STATE]")
	print("  Position: ", source_ball.position, " (X: ", source_ball.position.x, ", Y: ", source_ball.position.y, ")")
	print("  Velocity: ", source_ball.velocity, " (X: ", source_ball.velocity.x, ", Y: ", source_ball.velocity.y, ")")
	print("  Speed: ", source_ball.current_speed)
	print("  Is attached: ", source_ball.is_attached_to_paddle)
	print("  Velocity angle: ", rad_to_deg(atan2(source_ball.velocity.y, source_ball.velocity.x)), "° (0°=right, 90°=down, 180°=left, 270°=up)")

	# Get ball scene
	var ball_scene = load("res://scenes/gameplay/ball.tscn")
	if not ball_scene:
		print("ERROR: Could not load ball scene")
		return

	# Enable collision immunity on source ball
	if source_ball.has_method("enable_collision_immunity"):
		source_ball.enable_collision_immunity(0.5)

	# Spawn 2 additional balls
	for i in range(2):
		print("\n" + "-".repeat(50))
		print("[SPAWNING BALL #", i + 1, "]")
		print("-".repeat(50))

		var new_ball = ball_scene.instantiate()

		# Mark as extra ball (won't count as life loss)
		new_ball.is_main_ball = false

		# Position with small offset to prevent physics overlap issues
		# Offset perpendicular to source ball's velocity direction
		var offset_distance = 20.0  # pixels apart
		var perpendicular_offset = Vector2(0, offset_distance * (1 if i == 0 else -1))
		new_ball.position = source_ball.position + perpendicular_offset
		print("  Spawn Position: ", new_ball.position, " (X: ", new_ball.position.x, ", Y: ", new_ball.position.y, ")")
		print("  Position Offset: ", perpendicular_offset, " (from source ball)")

		# Launch with safe angles based on current ball position
		# Angles: 0° = right, 90° = down, 180° = left, 270° = up
		# CRITICAL: Use only SAFE angles (120°-240°) to prevent any escapes
		var angle_offset = 0.0
		var zone = ""
		var base_angle = 180.0  # Default: leftward

		# CRITICAL: Check boundaries and adjust angles to prevent escapes
		# All angles constrained to 120°-240° range (safe zone)
		# Check left wall (X < 100) - shoot RIGHT-DOWN
		if source_ball.position.x < 100:
			# Near left: shoot toward right-down quadrant (90° to 120°)
			base_angle = 105.0  # Right-down diagonal
			angle_offset = -10.0 if i == 0 else 10.0
			zone = "NEAR LEFT (shooting RIGHT+DOWN)"
		# Check top wall (Y < 150) - shoot DOWN-LEFT
		elif source_ball.position.y < 150:
			# Near top: shoot down-left (200°-220°)
			base_angle = 210.0  # Down-left
			angle_offset = -5.0 if i == 0 else 5.0
			zone = "NEAR TOP (shooting DOWN+LEFT)"
		# Check bottom wall (Y > 570) - shoot LEFT-UP (but still safe)
		elif source_ball.position.y > 570:
			# Near bottom: shoot left-up but stay in safe range (150°-160°)
			base_angle = 155.0  # Left-up but safe
			angle_offset = -5.0 if i == 0 else 5.0
			zone = "NEAR BOTTOM (shooting LEFT+UP safe)"
		# Normal position - horizontal spread
		else:
			# Center area - horizontal spread (175°-185°)
			base_angle = 180.0
			angle_offset = -5.0 if i == 0 else 5.0
			zone = "CENTER"

		var target_angle = base_angle + angle_offset

		# SAFETY CLAMP: Ensure angle is always in safe range
		target_angle = clamp(target_angle, 120.0, 240.0)
		print("  Angle clamped to safe range: ", target_angle, "° (120°-240° safe zone)")
		var angle_rad = deg_to_rad(target_angle)

		print("  Zone: ", zone, " (X=", source_ball.position.x, ", Y=", source_ball.position.y, ")")
		print("  Base Angle: ", base_angle, "° (0°=right, 180°=left)")
		print("  Angle Offset: ", angle_offset, "°")
		print("  Target Angle: ", target_angle, "°")

		new_ball.velocity = Vector2(cos(angle_rad), sin(angle_rad)) * source_ball.current_speed
		new_ball.is_attached_to_paddle = false

		print("  Calculated Velocity: ", new_ball.velocity)
		print("    - X component: ", new_ball.velocity.x, " (negative=left, positive=right)")
		print("    - Y component: ", new_ball.velocity.y, " (negative=up, positive=down)")
		print("  Velocity Magnitude: ", new_ball.velocity.length(), " (should be ", source_ball.current_speed, ")")
		print("  Velocity Angle (verify): ", rad_to_deg(atan2(new_ball.velocity.y, new_ball.velocity.x)), "°")

		# Enable trail
		if new_ball.has_node("Trail"):
			new_ball.get_node("Trail").emitting = true

		# Add to scene
		play_area.add_child(new_ball)

		# Enable collision immunity to prevent spawn collision issues
		if new_ball.has_method("enable_collision_immunity"):
			new_ball.enable_collision_immunity(0.5)

		# Connect signals
		new_ball.ball_lost.connect(_on_ball_lost)

		print("  ✓ Ball #", i + 1, " added to scene successfully")

	print("\n" + "=".repeat(60))
	print("=== TRIPLE BALL SPAWN COMPLETE ===")
	print("Total balls in play: ", get_tree().get_nodes_in_group("ball").size())
	print("=".repeat(60) + "\n")
