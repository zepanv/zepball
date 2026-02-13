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
	BOMB,       # Explodes and destroys surrounding bricks, 30 points
	DIAMOND,        # 1-hit diamond brick (random color)
	DIAMOND_GLOSSY, # 2-hit diamond brick (random color)
	POLYGON,        # 1-hit pentagon brick (random color)
	POLYGON_GLOSSY,  # 2-hit pentagon brick (random color)
	FORCE_ARROW,     # Non-breakable directional force tile
	POWERUP_BRICK    # Pass-through tile that grants a specific power-up
}

# Configuration
@export var brick_type: BrickType = BrickType.NORMAL
@export var brick_color: Color = Color(0.059, 0.773, 0.627)  # Teal (fallback for ColorRect mode)
@export var direction: int = 45
@export var powerup_type_name: String = "MYSTERY"

const TARGET_BRICK_SIZE = 48.0
const UNBREAKABLE_HITS = 999
const BOMB_RADIUS = 75.0
const BOMB_RADIUS_SQ = BOMB_RADIUS * BOMB_RADIUS
const DEFAULT_POWER_UP_SPAWN_CHANCE = 0.20
const POWER_UP_SCENE = preload("res://scenes/gameplay/power_up.tscn")
const POWER_UP_TYPES = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
const FORCE_ARROW_TEXTURE_PATH = "res://assets/graphics/powerups/arrow_down_right.png"
const FORCE_ARROW_BASE_ANGLE_DEG = 45
const POWERUP_TEXTURE_MAP: Dictionary = {
	"EXPAND": "res://assets/graphics/powerups/expand.png",
	"CONTRACT": "res://assets/graphics/powerups/contract.png",
	"SPEED_UP": "res://assets/graphics/powerups/speed_up.png",
	"TRIPLE_BALL": "res://assets/graphics/powerups/triple_ball.png",
	"BIG_BALL": "res://assets/graphics/powerups/big_ball.png",
	"SMALL_BALL": "res://assets/graphics/powerups/small_ball.png",
	"SLOW_DOWN": "res://assets/graphics/powerups/slow_down.png",
	"EXTRA_LIFE": "res://assets/graphics/powerups/extra_life.png",
	"GRAB": "res://assets/graphics/powerups/grab.png",
	"BRICK_THROUGH": "res://assets/graphics/powerups/brick_through.png",
	"DOUBLE_SCORE": "res://assets/graphics/powerups/double_score.png",
	"MYSTERY": "res://assets/graphics/powerups/mystery.png",
	"BOMB_BALL": "res://assets/graphics/powerups/bomb_ball.png",
	"AIR_BALL": "res://assets/graphics/powerups/air_ball.png",
	"MAGNET": "res://assets/graphics/powerups/magnet.png",
	"BLOCK": "res://assets/graphics/powerups/block.png"
}
const POWERUP_NAME_TO_TYPE: Dictionary = {
	"EXPAND": 0,
	"CONTRACT": 1,
	"SPEED_UP": 2,
	"TRIPLE_BALL": 3,
	"BIG_BALL": 4,
	"SMALL_BALL": 5,
	"SLOW_DOWN": 6,
	"EXTRA_LIFE": 7,
	"GRAB": 8,
	"BRICK_THROUGH": 9,
	"DOUBLE_SCORE": 10,
	"MYSTERY": 11,
	"BOMB_BALL": 12,
	"AIR_BALL": 13,
	"MAGNET": 14,
	"BLOCK": 15
}

const DIAMOND_VARIANTS = [
	{"texture": "res://assets/graphics/bricks/element_blue_diamond.png", "color": Color(0.2, 0.4, 1.0)},
	{"texture": "res://assets/graphics/bricks/element_green_diamond.png", "color": Color(0.2, 0.8, 0.2)},
	{"texture": "res://assets/graphics/bricks/element_grey_diamond.png", "color": Color(0.5, 0.5, 0.5)},
	{"texture": "res://assets/graphics/bricks/element_purple_diamond.png", "color": Color(0.6, 0.2, 0.8)},
	{"texture": "res://assets/graphics/bricks/element_red_diamond.png", "color": Color(1.0, 0.2, 0.2)},
	{"texture": "res://assets/graphics/bricks/element_yellow_diamond.png", "color": Color(1.0, 0.843, 0.0)}
]
const DIAMOND_GLOSSY_VARIANTS = [
	{"texture": "res://assets/graphics/bricks/element_blue_diamond_glossy.png", "color": Color(0.2, 0.4, 1.0)},
	{"texture": "res://assets/graphics/bricks/element_green_diamond_glossy.png", "color": Color(0.2, 0.8, 0.2)},
	{"texture": "res://assets/graphics/bricks/element_grey_diamond_glossy.png", "color": Color(0.5, 0.5, 0.5)},
	{"texture": "res://assets/graphics/bricks/element_purple_diamond_glossy.png", "color": Color(0.6, 0.2, 0.8)},
	{"texture": "res://assets/graphics/bricks/element_red_diamond_glossy.png", "color": Color(1.0, 0.2, 0.2)},
	{"texture": "res://assets/graphics/bricks/element_yellow_diamond_glossy.png", "color": Color(1.0, 0.843, 0.0)}
]
const POLYGON_VARIANTS = [
	{"texture": "res://assets/graphics/bricks/element_blue_polygon.png", "color": Color(0.2, 0.4, 1.0)},
	{"texture": "res://assets/graphics/bricks/element_green_polygon.png", "color": Color(0.2, 0.8, 0.2)},
	{"texture": "res://assets/graphics/bricks/element_grey_polygon.png", "color": Color(0.5, 0.5, 0.5)},
	{"texture": "res://assets/graphics/bricks/element_purple_polygon.png", "color": Color(0.6, 0.2, 0.8)},
	{"texture": "res://assets/graphics/bricks/element_red_polygon.png", "color": Color(1.0, 0.2, 0.2)},
	{"texture": "res://assets/graphics/bricks/element_yellow_polygon.png", "color": Color(1.0, 0.843, 0.0)}
]
const POLYGON_GLOSSY_VARIANTS = [
	{"texture": "res://assets/graphics/bricks/element_blue_polygon_glossy.png", "color": Color(0.2, 0.4, 1.0)},
	{"texture": "res://assets/graphics/bricks/element_green_polygon_glossy.png", "color": Color(0.2, 0.8, 0.2)},
	{"texture": "res://assets/graphics/bricks/element_grey_polygon_glossy.png", "color": Color(0.5, 0.5, 0.5)},
	{"texture": "res://assets/graphics/bricks/element_purple_polygon_glossy.png", "color": Color(0.6, 0.2, 0.8)},
	{"texture": "res://assets/graphics/bricks/element_red_polygon_glossy.png", "color": Color(1.0, 0.2, 0.2)},
	{"texture": "res://assets/graphics/bricks/element_yellow_polygon_glossy.png", "color": Color(1.0, 0.843, 0.0)}
]

var DIAMOND_POINTS := PackedVector2Array([
	Vector2(0, -24),
	Vector2(24, 0),
	Vector2(0, 24),
	Vector2(-24, 0)
])
var PENTAGON_POINTS := PackedVector2Array([
	Vector2(0, -23),
	Vector2(22, -8),
	Vector2(18, 20),
	Vector2(-18, 20),
	Vector2(-22, -8)
])

# State
var hits_remaining: int = 1
var score_value: int = 10
var is_breaking: bool = false
var main_controller_ref: Node = null

# Signals
signal brick_broken(score_value: int)
signal power_up_spawned(power_up_node: Node)
signal powerup_collected(powerup_type_int: int)

# Power-up configuration
@export var power_up_spawn_chance: float = DEFAULT_POWER_UP_SPAWN_CHANCE  # 20% chance to spawn

func _ready():
	_cache_main_controller_ref()
	direction = _normalize_direction(direction)
	powerup_type_name = _normalize_powerup_type_name(powerup_type_name)

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
			hits_remaining = UNBREAKABLE_HITS
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
		BrickType.DIAMOND:
			hits_remaining = 1
			score_value = 15
			brick_color = Color(0.2, 0.4, 1.0)
		BrickType.DIAMOND_GLOSSY:
			hits_remaining = 2
			score_value = 20
			brick_color = Color(0.2, 0.4, 1.0)
		BrickType.POLYGON:
			hits_remaining = 1
			score_value = 15
			brick_color = Color(0.2, 0.4, 1.0)
		BrickType.POLYGON_GLOSSY:
			hits_remaining = 2
			score_value = 20
			brick_color = Color(0.2, 0.4, 1.0)
		BrickType.FORCE_ARROW:
			hits_remaining = UNBREAKABLE_HITS
			score_value = 0
			brick_color = Color(1.0, 0.85, 0.3)
			add_to_group("force_arrow")
		BrickType.POWERUP_BRICK:
			hits_remaining = 1
			score_value = 0
			brick_color = Color(0.3, 1.0, 0.45)

	# Set up sprite if using Sprite2D
	if has_node("Sprite"):
		setup_sprite()
	# Fallback to ColorRect for backwards compatibility
	elif has_node("Visual"):
		$Visual.color = brick_color

	# Apply color to particles
	if has_node("Particles"):
		$Particles.color = brick_color

	_update_collision_shape()

	# Disable collision for force arrows - they should only exert field forces
	if brick_type == BrickType.FORCE_ARROW:
		if has_node("CollisionShape2D"):
			$CollisionShape2D.disabled = true
		if has_node("CollisionPolygon2D"):
			$CollisionPolygon2D.disabled = true
		collision_layer = 0
		collision_mask = 0

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
		BrickType.DIAMOND:
			var variant = _pick_variant(DIAMOND_VARIANTS)
			texture_path = variant["texture"]
			brick_color = variant["color"]
		BrickType.DIAMOND_GLOSSY:
			var variant = _pick_variant(DIAMOND_GLOSSY_VARIANTS)
			texture_path = variant["texture"]
			brick_color = variant["color"]
		BrickType.POLYGON:
			var variant = _pick_variant(POLYGON_VARIANTS)
			texture_path = variant["texture"]
			brick_color = variant["color"]
		BrickType.POLYGON_GLOSSY:
			var variant = _pick_variant(POLYGON_GLOSSY_VARIANTS)
			texture_path = variant["texture"]
			brick_color = variant["color"]
		BrickType.FORCE_ARROW:
			texture_path = FORCE_ARROW_TEXTURE_PATH
		BrickType.POWERUP_BRICK:
			texture_path = str(POWERUP_TEXTURE_MAP.get(powerup_type_name, POWERUP_TEXTURE_MAP["MYSTERY"]))

	# Load texture
	var texture = load(texture_path)
	if not texture:
		push_error("Could not load brick texture: %s" % texture_path)
		return

	sprite.texture = texture
	if brick_type == BrickType.FORCE_ARROW:
		# Source art points down-right (45 deg), so offset rotation to match configured push direction.
		sprite.rotation_degrees = float(direction - FORCE_ARROW_BASE_ANGLE_DEG)
	else:
		sprite.rotation_degrees = 0.0

	# Scale based on brick type
	# Most textures are 32x32, scaled to 1.5x = 48px
	# Special bomb texture is 180x180, needs 48/180 = 0.267x
	if brick_type == BrickType.BOMB:
		sprite.scale = Vector2(0.267, 0.267)
	else:
		var tex_size = sprite.texture.get_size()
		if tex_size.x == 32.0 and tex_size.y == 32.0:
			sprite.scale = Vector2(1.5, 1.5)
		else:
			var uniform_scale = TARGET_BRICK_SIZE / tex_size.x
			sprite.scale = Vector2(uniform_scale, uniform_scale)

	if brick_type == BrickType.POWERUP_BRICK:
		sprite.modulate = Color(1.0, 1.0, 1.0, 0.95)
	elif brick_type == BrickType.FORCE_ARROW:
		sprite.modulate = Color(1.0, 1.0, 1.0, 0.9)
		_start_force_arrow_pulse(sprite)

func _pick_variant(variants: Array) -> Dictionary:
	if variants.is_empty():
		return {"texture": "", "color": brick_color}
	return variants[randi() % variants.size()]

func _update_collision_shape() -> void:
	if not has_node("CollisionPolygon2D"):
		return
	var polygon_node = $CollisionPolygon2D
	var shape_node = $CollisionShape2D if has_node("CollisionShape2D") else null
	var shape_kind = _get_brick_shape()
	if shape_kind == "diamond":
		polygon_node.set_deferred("polygon", DIAMOND_POINTS)
		polygon_node.set_deferred("disabled", false)
		if shape_node:
			shape_node.set_deferred("disabled", true)
	elif shape_kind == "polygon":
		polygon_node.set_deferred("polygon", PENTAGON_POINTS)
		polygon_node.set_deferred("disabled", false)
		if shape_node:
			shape_node.set_deferred("disabled", true)
	else:
		polygon_node.set_deferred("disabled", true)
		if shape_node:
			shape_node.set_deferred("disabled", false)

func _get_brick_shape() -> String:
	if brick_type == BrickType.DIAMOND or brick_type == BrickType.DIAMOND_GLOSSY:
		return "diamond"
	if brick_type == BrickType.POLYGON or brick_type == BrickType.POLYGON_GLOSSY:
		return "polygon"
	return "square"

func collect_powerup() -> void:
	if is_breaking:
		return
	powerup_collected.emit(_resolve_powerup_type(powerup_type_name))
	break_brick(Vector2.ZERO)

func hit(impact_direction: Vector2 = Vector2.ZERO):
	"""Called when ball collides with brick
	impact_direction: Direction the ball was traveling when it hit (for particle emission)
	"""
	if is_breaking:
		return
	if brick_type == BrickType.UNBREAKABLE or brick_type == BrickType.FORCE_ARROW:
		return
	hits_remaining -= 1

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
	if has_node("CollisionPolygon2D"):
		$CollisionPolygon2D.set_deferred("disabled", true)
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
	# Skip if unbreakable, force arrow, or power-up brick (power-up bricks grant effect immediately via collect_powerup)
	if brick_type == BrickType.UNBREAKABLE or brick_type == BrickType.FORCE_ARROW or brick_type == BrickType.POWERUP_BRICK:
		return

	# Random chance to spawn
	if randf() > power_up_spawn_chance:
		return  # No power-up this time

	if not POWER_UP_SCENE:
		push_error("Could not load power-up scene")
		return

	# Create power-up instance
	var powerup = POWER_UP_SCENE.instantiate()

	# Randomly select power-up type
	powerup.power_up_type = POWER_UP_TYPES[randi() % POWER_UP_TYPES.size()]

	# Set position to brick position
	powerup.position = global_position

	# Emit signal so main can add it to the scene
	power_up_spawned.emit(powerup)

func explode_surrounding_bricks():
	"""Destroy bricks in a radius around this bomb brick"""
	for brick in _get_cached_level_bricks():
		if not is_instance_valid(brick):
			continue
		if brick == self:  # Don't count self
			continue
		if brick.is_in_group("block_brick"):
			continue
		if "brick_type" in brick and (
			brick.brick_type == BrickType.UNBREAKABLE
			or brick.brick_type == BrickType.FORCE_ARROW
		):
			continue

		# Check distance from this brick using squared values (avoid sqrt in hot path)
		var dist_sq = brick.global_position.distance_squared_to(global_position)
		if dist_sq <= BOMB_RADIUS_SQ:
			# For power-up bricks, grant the effect immediately (not a falling power-up)
			if "brick_type" in brick and brick.brick_type == BrickType.POWERUP_BRICK:
				if brick.has_method("collect_powerup"):
					brick.collect_powerup()
				else:
					brick.break_brick(Vector2(-1, 0))
			# For regular bricks, break normally
			elif brick.has_method("break_brick"):
				brick.break_brick(Vector2(-1, 0))  # Use left direction for consistency
			elif brick.has_method("hit"):
				brick.hit(Vector2(-1, 0))  # Fallback for safety

func _get_cached_level_bricks() -> Array[Node]:
	if main_controller_ref == null or not is_instance_valid(main_controller_ref):
		_cache_main_controller_ref()
	if main_controller_ref and main_controller_ref.has_method("get_cached_level_bricks"):
		return main_controller_ref.get_cached_level_bricks()
	var container = get_parent()
	if container:
		return container.get_children()
	return []

func _cache_main_controller_ref() -> void:
	var candidate = get_tree().get_first_node_in_group("main_controller")
	if candidate and is_instance_valid(candidate):
		main_controller_ref = candidate

func _normalize_direction(raw_direction: int) -> int:
	match raw_direction:
		0, 45, 90, 135, 180, 225, 270, 315:
			return raw_direction
		_:
			return 45

func _normalize_powerup_type_name(raw_name: String) -> String:
	var normalized: String = raw_name.strip_edges().to_upper()
	if POWERUP_NAME_TO_TYPE.has(normalized):
		return normalized
	return "MYSTERY"

func _resolve_powerup_type(type_name: String) -> int:
	var normalized: String = _normalize_powerup_type_name(type_name)
	return int(POWERUP_NAME_TO_TYPE.get(normalized, POWERUP_NAME_TO_TYPE["MYSTERY"]))

func _start_force_arrow_pulse(sprite: Sprite2D) -> void:
	var base_scale = sprite.scale
	var tween: Tween = create_tween()
	tween.set_loops()
	tween.set_parallel(true)
	# Pulse alpha
	tween.tween_property(sprite, "modulate:a", 0.55, 0.65)
	# Pulse scale (grow slightly)
	tween.tween_property(sprite, "scale", base_scale * 1.15, 0.65)
	tween.set_parallel(false)
	tween.tween_property(sprite, "modulate:a", 0.95, 0.65)
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", base_scale, 0.65)
