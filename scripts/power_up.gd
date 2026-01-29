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

@export_group("Sprite Atlas Settings")
@export var atlas_texture: Texture2D = preload("res://assets/graphics/powerups/powerups-transparent.png")
@export var cell_size: Vector2 = Vector2(200, 200) # Increased size to capture full icon
@export var spacing: Vector2 = Vector2(16, 56)     # Reduced vertical spacing to fix row 3 offset
@export var margin: Vector2 = Vector2(10, 10)      # Increased margin to center row 0

# Signals
signal collected(type: PowerUpType)

func _ready():
	# Set up sprite based on type
	setup_sprite()

	# Connect to paddle collision
	body_entered.connect(_on_body_entered)

	print("PowerUp spawned: ", PowerUpType.keys()[power_up_type])

func _physics_process(delta):
	# Stop movement if level is complete or game over
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager and (game_manager.game_state == game_manager.GameState.LEVEL_COMPLETE or game_manager.game_state == game_manager.GameState.GAME_OVER):
		return

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

	if not atlas_texture:
		print("ERROR: No powerup texture loaded")
		return

	# Map power-up types to sprite positions
	var atlas_row = 0
	var atlas_col = 0

	match power_up_type:
		PowerUpType.EXPAND:
			atlas_row = 3
			atlas_col = 3  # Arrow up / expand icon
		PowerUpType.CONTRACT:
			atlas_row = 3
			atlas_col = 4  # Arrow down / shrink icon
		PowerUpType.SPEED_UP:
			atlas_row = 0
			atlas_col = 0  # Lightning / speed icon
		PowerUpType.TRIPLE_BALL:
			atlas_row = 3
			atlas_col = 2  # Multi-ball icon

	# Create atlas texture
	var atlas = AtlasTexture.new()
	atlas.atlas = atlas_texture
	
	# Calculate region with margin and spacing
	var region_x = margin.x + atlas_col * (cell_size.x + spacing.x)
	var region_y = margin.y + atlas_row * (cell_size.y + spacing.y)
	
	atlas.region = Rect2(
		region_x,
		region_y,
		cell_size.x,
		cell_size.y
	)

	sprite.texture = atlas

	# Scale to reasonable size (40×40 pixels)
	# Use the actual cell size for scaling ratio
	var scale_factor = 40.0 / cell_size.x
	sprite.scale = Vector2(scale_factor, scale_factor)

func _on_body_entered(body):
	"""Detect collision with paddle"""
	if body.is_in_group("paddle"):
		# Emit signal for collection
		collected.emit(power_up_type)
		print("PowerUp collected: ", PowerUpType.keys()[power_up_type])

		# Remove power-up
		queue_free()
