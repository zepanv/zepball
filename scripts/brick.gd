extends StaticBody2D

## Brick - Breakable tile that awards points when destroyed
## Can have different types (normal, strong, unbreakable)

# Brick types
enum BrickType {
	NORMAL,     # Breaks in 1 hit, 10 points (Cyan - row 0, col 0)
	STRONG,     # Breaks in 2 hits, 20 points (Pink - row 0, col 1)
	UNBREAKABLE, # Never breaks (Gray - row 0, col 2)
	GOLD,       # Special brick, 50 points (row 1, col 0)
	RED,        # Fire brick, 15 points (row 1, col 1)
	BLUE,       # Ice brick, 15 points (row 1, col 2)
	GREEN,      # Nature brick, 15 points (row 2, col 0)
	PURPLE,     # Magic brick, 25 points (row 2, col 1)
	ORANGE      # Energy brick, 20 points (row 2, col 2)
}

# Configuration
@export var brick_type: BrickType = BrickType.NORMAL
@export var brick_color: Color = Color(0.059, 0.773, 0.627)  # Teal (fallback for ColorRect mode)

# Sprite atlas configuration
# SVG has 4x4 grid of 64x64 pixel bricks
const BRICK_WIDTH = 64
const BRICK_HEIGHT = 64

# State
var hits_remaining: int = 1
var score_value: int = 10
var is_breaking: bool = false

# Signals
signal brick_broken(score_value: int)
signal power_up_spawned(power_up_node: Node)

# Power-up configuration
@export var power_up_spawn_chance: float = 0.20  # 20% chance to spawn

func _ready():
	# Set up brick based on type
	match brick_type:
		BrickType.NORMAL:
			hits_remaining = 1
			score_value = 10
			brick_color = Color(0.059, 0.773, 0.627)  # Cyan
		BrickType.STRONG:
			hits_remaining = 2
			score_value = 20
			brick_color = Color(0.914, 0.275, 0.376)  # Pink/red
		BrickType.UNBREAKABLE:
			hits_remaining = 999
			score_value = 0
			brick_color = Color(0.5, 0.5, 0.5)  # Gray
		BrickType.GOLD:
			hits_remaining = 1
			score_value = 50
			brick_color = Color(1.0, 0.843, 0.0)  # Gold
		BrickType.RED:
			hits_remaining = 1
			score_value = 15
			brick_color = Color(1.0, 0.2, 0.2)  # Red
		BrickType.BLUE:
			hits_remaining = 1
			score_value = 15
			brick_color = Color(0.2, 0.4, 1.0)  # Blue
		BrickType.GREEN:
			hits_remaining = 1
			score_value = 15
			brick_color = Color(0.2, 0.8, 0.2)  # Green
		BrickType.PURPLE:
			hits_remaining = 2
			score_value = 25
			brick_color = Color(0.6, 0.2, 0.8)  # Purple
		BrickType.ORANGE:
			hits_remaining = 1
			score_value = 20
			brick_color = Color(1.0, 0.5, 0.0)  # Orange

	# Set up sprite if using Sprite2D
	if has_node("Sprite"):
		setup_sprite()
	# Fallback to ColorRect for backwards compatibility
	elif has_node("Visual"):
		$Visual.color = brick_color

	# Apply color to particles
	if has_node("Particles"):
		$Particles.color = brick_color

	print("Brick ready: type=", BrickType.keys()[brick_type], " hits=", hits_remaining)

func setup_sprite():
	"""Configure sprite atlas region based on brick type
	SVG layout (4x4 grid, 64x64 each):
	Row 0: Red, Orange, Yellow, DarkOrange
	Row 1: Green, DarkGreen, Cyan, DarkCyan
	Row 2: Blue, DarkBlue, Purple, DarkPurple
	Row 3: White, LightGray, Gray, DarkGray
	"""
	var sprite = $Sprite

	# Load the brick spritesheet (SVG)
	var texture = load("res://assets/graphics/bricks/bricks.svg")
	if not texture:
		print("ERROR: Could not load brick spritesheet at res://assets/graphics/bricks/bricks.svg")
		return

	# Map brick types to grid positions (row, col)
	var atlas_row = 0
	var atlas_col = 0

	match brick_type:
		BrickType.NORMAL:
			atlas_row = 1  # Row 1
			atlas_col = 2  # Cyan
		BrickType.STRONG:
			atlas_row = 0  # Row 0
			atlas_col = 0  # Red
		BrickType.UNBREAKABLE:
			atlas_row = 3  # Row 3
			atlas_col = 2  # Gray
		BrickType.GOLD:
			atlas_row = 0  # Row 0
			atlas_col = 2  # Yellow (gold-ish)
		BrickType.RED:
			atlas_row = 0  # Row 0
			atlas_col = 0  # Red
		BrickType.BLUE:
			atlas_row = 2  # Row 2
			atlas_col = 0  # Blue
		BrickType.GREEN:
			atlas_row = 1  # Row 1
			atlas_col = 0  # Green
		BrickType.PURPLE:
			atlas_row = 2  # Row 2
			atlas_col = 2  # Purple
		BrickType.ORANGE:
			atlas_row = 0  # Row 0
			atlas_col = 1  # Orange

	# Calculate atlas position (64x64 grid)
	var atlas_x = atlas_col * BRICK_WIDTH
	var atlas_y = atlas_row * BRICK_HEIGHT

	# Create AtlasTexture for this brick
	var atlas = AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(atlas_x, atlas_y, BRICK_WIDTH, BRICK_HEIGHT)

	sprite.texture = atlas

	# Scale sprite to match collision shape (58x28 target size)
	var scale_x = 58.0 / BRICK_WIDTH
	var scale_y = 28.0 / BRICK_HEIGHT
	sprite.scale = Vector2(scale_x, scale_y)

func hit(impact_direction: Vector2 = Vector2.ZERO):
	"""Called when ball collides with brick
	impact_direction: Direction the ball was traveling when it hit (for particle emission)
	"""
	if is_breaking:
		return
	hits_remaining -= 1
	print("Brick hit! Hits remaining: ", hits_remaining)

	if hits_remaining <= 0:
		break_brick(impact_direction)
	else:
		# Visual feedback for damaged brick (darken slightly)
		if has_node("Sprite"):
			$Sprite.modulate = brick_color.darkened(0.3)
		elif has_node("Visual"):
			$Visual.color = brick_color.darkened(0.3)

func break_brick(impact_direction: Vector2 = Vector2.ZERO):
	"""Break the brick and emit particles
	impact_direction: Direction to emit particles (opposite of ball travel direction)
	"""
	if is_breaking:
		return
	is_breaking = true
	print("Brick broken! Score: +", score_value)

	# Emit signal to game manager
	brick_broken.emit(score_value)

	# Chance to spawn power-up
	try_spawn_power_up()

	# Disable collisions immediately so the ball can't hit again
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)

	# Hide visual immediately (but keep node for particles)
	if has_node("Sprite"):
		$Sprite.visible = false
	if has_node("Visual"):
		$Visual.visible = false

	# Play particle effect
	if has_node("Particles"):
		var particles = $Particles

		# Set particle direction based on impact (reflect the ball's direction)
		if impact_direction != Vector2.ZERO:
			particles.direction = -impact_direction.normalized()
		else:
			particles.direction = Vector2(0, -1)  # Default: upward

		# Match particle color to brick type
		particles.color = brick_color

		particles.emitting = true

		# Wait for particles to finish, then remove brick
		await get_tree().create_timer(0.6).timeout

	# Remove brick from scene
	queue_free()

func try_spawn_power_up():
	"""Randomly spawn a power-up at this brick's position"""
	# Skip if unbreakable (shouldn't happen, but safety check)
	if brick_type == BrickType.UNBREAKABLE:
		return

	# Random chance to spawn
	if randf() > power_up_spawn_chance:
		return  # No power-up this time

	# Load power-up scene
	var powerup_scene = load("res://scenes/gameplay/power_up.tscn")
	if not powerup_scene:
		print("ERROR: Could not load power-up scene")
		return

	# Create power-up instance
	var powerup = powerup_scene.instantiate()

	# Randomly select power-up type
	var types = [0, 1, 2, 3]  # EXPAND, CONTRACT, SPEED_UP, TRIPLE_BALL
	powerup.power_up_type = types[randi() % types.size()]

	# Set position to brick position
	powerup.position = global_position

	# Emit signal so main can add it to the scene
	power_up_spawned.emit(powerup)
