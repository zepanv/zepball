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
	ORANGE,     # Energy brick, 20 points (row 2, col 2)
	BOMB        # Explodes and destroys surrounding bricks, 30 points
}

# Configuration
@export var brick_type: BrickType = BrickType.NORMAL
@export var brick_color: Color = Color(0.059, 0.773, 0.627)  # Teal (fallback for ColorRect mode)

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
		BrickType.BOMB:
			hits_remaining = 1
			score_value = 30
			brick_color = Color(1.0, 0.3, 0.0)  # Orange-red

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
	"""Load PNG texture based on brick type
	Uses square textures (32x32) for all brick types
	- Normal bricks: regular square textures
	- Strong bricks: square_glossy textures
	"""
	var sprite = $Sprite
	var texture_path = ""

	# Map brick types to texture files
	match brick_type:
		BrickType.NORMAL:
			texture_path = "res://assets/graphics/bricks/element_green_square.png"
		BrickType.STRONG:
			texture_path = "res://assets/graphics/bricks/element_red_square_glossy.png"
		BrickType.UNBREAKABLE:
			texture_path = "res://assets/graphics/bricks/element_grey_square.png"
		BrickType.GOLD:
			texture_path = "res://assets/graphics/bricks/element_yellow_square_glossy.png"
		BrickType.RED:
			texture_path = "res://assets/graphics/bricks/element_red_square.png"
		BrickType.BLUE:
			texture_path = "res://assets/graphics/bricks/element_blue_square.png"
		BrickType.GREEN:
			texture_path = "res://assets/graphics/bricks/element_green_square.png"
		BrickType.PURPLE:
			texture_path = "res://assets/graphics/bricks/element_purple_square.png"
		BrickType.ORANGE:
			texture_path = "res://assets/graphics/bricks/element_yellow_square.png"
		BrickType.BOMB:
			texture_path = "res://assets/graphics/bricks/special_bomb.png"

	# Load texture
	var texture = load(texture_path)
	if not texture:
		print("ERROR: Could not load brick texture: ", texture_path)
		return

	sprite.texture = texture

	# Scale based on brick type
	# Most textures are 32x32, scaled to 1.5x = 48px
	# Special bomb texture is 180x180, needs 48/180 = 0.267x
	if brick_type == BrickType.BOMB:
		sprite.scale = Vector2(0.267, 0.267)
	else:
		sprite.scale = Vector2(1.5, 1.5)

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

	# If this is a bomb brick, explode and destroy surrounding bricks
	if brick_type == BrickType.BOMB:
		explode_surrounding_bricks()

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

	# Play particle effect (if enabled in settings)
	if has_node("Particles") and SaveManager.get_particle_effects():
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
		# Check if still in tree before awaiting (scene might be changing)
		if is_inside_tree():
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
	var types = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]  # All power-up types
	powerup.power_up_type = types[randi() % types.size()]

	# Set position to brick position
	powerup.position = global_position

	# Emit signal so main can add it to the scene
	power_up_spawned.emit(powerup)

func explode_surrounding_bricks():
	"""Destroy bricks in a radius around this bomb brick"""
	const BOMB_RADIUS = 75.0  # Same as bomb_ball power-up

	# Find all bricks in the scene
	var all_bricks = get_tree().get_nodes_in_group("brick")
	var destroyed_count = 0

	for brick in all_bricks:
		if not is_instance_valid(brick):
			continue
		if brick == self:  # Don't count self
			continue

		# Check distance from this brick
		var distance = brick.global_position.distance_to(global_position)
		if distance <= BOMB_RADIUS:
			# Hit this brick
			if brick.has_method("hit"):
				brick.hit(Vector2(-1, 0))  # Use left direction for consistency
				destroyed_count += 1

	if destroyed_count > 0:
		print("Bomb brick exploded and destroyed ", destroyed_count, " surrounding bricks!")
