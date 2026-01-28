extends Area2D

## PowerUp - Collectible items that spawn from broken bricks
## Moves horizontally and applies effects when collected by paddle

# Power-up types
enum PowerUpType {
	EXPAND,      # Big paddle (height 120 → 180, 15s)
	CONTRACT,    # Small paddle (height 120 → 80, 10s)
	SPEED_UP,    # Faster ball (speed 500 → 650, 12s)
	TRIPLE_BALL  # Spawn 2 additional balls
}

# Configuration
@export var power_up_type: PowerUpType = PowerUpType.EXPAND
@export var move_speed: float = 150.0  # Pixels per second (horizontal)

# Sprite atlas configuration (5×5 grid from powerups.jpg, 1024×1024)
const POWERUP_WIDTH = 204  # 1024 / 5 ≈ 204
const POWERUP_HEIGHT = 204

# Signals
signal collected(type: PowerUpType)

func _ready():
	# Set up sprite based on type
	setup_sprite()

	# Connect to paddle collision
	body_entered.connect(_on_body_entered)

	print("PowerUp spawned: ", PowerUpType.keys()[power_up_type])

func _physics_process(delta):
	# Move horizontally toward right edge
	position.x += move_speed * delta

	# Destroy if passed right edge (missed by paddle)
	if position.x > 1300:
		queue_free()

func setup_sprite():
	"""Configure sprite based on power-up type"""
	if not has_node("Sprite"):
		return

	var sprite = $Sprite

	# Load power-up sprite sheet
	var texture = load("res://assets/graphics/powerups/powerups.jpg")
	if not texture:
		print("ERROR: Could not load powerup spritesheet")
		return

	# Map power-up types to sprite positions (will adjust based on actual sheet)
	var atlas_row = 0
	var atlas_col = 0

	match power_up_type:
		PowerUpType.EXPAND:
			atlas_row = 0
			atlas_col = 0  # Arrow up / expand icon
		PowerUpType.CONTRACT:
			atlas_row = 0
			atlas_col = 1  # Arrow down / shrink icon
		PowerUpType.SPEED_UP:
			atlas_row = 0
			atlas_col = 2  # Lightning / speed icon
		PowerUpType.TRIPLE_BALL:
			atlas_row = 0
			atlas_col = 3  # Multi-ball icon

	# Create atlas texture
	var atlas = AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(
		atlas_col * POWERUP_WIDTH,
		atlas_row * POWERUP_HEIGHT,
		POWERUP_WIDTH,
		POWERUP_HEIGHT
	)

	sprite.texture = atlas

	# Scale to reasonable size (40×40 pixels)
	var scale_factor = 40.0 / POWERUP_WIDTH
	sprite.scale = Vector2(scale_factor, scale_factor)

func _on_body_entered(body):
	"""Detect collision with paddle"""
	if body.is_in_group("paddle"):
		# Emit signal for collection
		collected.emit(power_up_type)
		print("PowerUp collected: ", PowerUpType.keys()[power_up_type])

		# Remove power-up
		queue_free()
