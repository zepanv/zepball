extends Area2D

## PowerUp - Collectible items that spawn from broken bricks
## Moves horizontally and applies effects when collected by paddle

# Power-up types
enum PowerUpType {
	EXPAND,       # Big paddle (height 120 → 180, 15s)
	CONTRACT,     # Small paddle (height 120 → 80, 10s)
	SPEED_UP,     # Faster ball (speed 500 → 650, 12s)
	TRIPLE_BALL,  # Spawn 2 additional balls
	BIG_BALL,     # Double ball size
	SMALL_BALL,   # Half ball size
	SLOW_DOWN,    # Slower ball (speed 500 → 350, 12s)
	EXTRA_LIFE,   # Add one life
	GRAB,         # Ball sticks to paddle (15s)
	BRICK_THROUGH, # Ball pierces through bricks (12s)
	DOUBLE_SCORE, # 2x score multiplier (15s)
	MYSTERY,      # Random effect
	BOMB_BALL,    # Ball destroys surrounding bricks on impact (12s)
	AIR_BALL,     # Ball jumps over bricks and lands center (12s)
	MAGNET,       # Paddle attracts ball with gravity
	BLOCK         # Temporary protective bricks near paddle
}

# Configuration
@export var power_up_type: PowerUpType = PowerUpType.EXPAND
@export var move_speed: float = 150.0  # Pixels per second (horizontal)
const MISS_BOUNDARY_X = 1300.0
const GAME_MANAGER_RETRY_INTERVAL = 0.25

@export_group("Power-up Textures")
@export var expand_texture: Texture2D = preload("res://assets/graphics/powerups/expand.png")
@export var contract_texture: Texture2D = preload("res://assets/graphics/powerups/contract.png")
@export var speed_up_texture: Texture2D = preload("res://assets/graphics/powerups/speed_up.png")
@export var triple_ball_texture: Texture2D = preload("res://assets/graphics/powerups/triple_ball.png")
@export var big_ball_texture: Texture2D = preload("res://assets/graphics/powerups/big_ball.png")
@export var small_ball_texture: Texture2D = preload("res://assets/graphics/powerups/small_ball.png")
@export var slow_down_texture: Texture2D = preload("res://assets/graphics/powerups/slow_down.png")
@export var extra_life_texture: Texture2D = preload("res://assets/graphics/powerups/extra_life.png")
@export var grab_texture: Texture2D = preload("res://assets/graphics/powerups/grab.png")
@export var brick_through_texture: Texture2D = preload("res://assets/graphics/powerups/brick_through.png")
@export var double_score_texture: Texture2D = preload("res://assets/graphics/powerups/double_score.png")
@export var mystery_texture: Texture2D = preload("res://assets/graphics/powerups/mystery.png")
@export var bomb_ball_texture: Texture2D = preload("res://assets/graphics/powerups/bomb_ball.png")
@export var air_ball_texture: Texture2D = preload("res://assets/graphics/powerups/air_ball.png")
@export var magnet_texture: Texture2D = preload("res://assets/graphics/powerups/magnet.png")
@export var block_texture: Texture2D = preload("res://assets/graphics/powerups/block.png")

# Signals
signal collected(type: PowerUpType)

var game_manager: Node = null
var game_manager_retry_timer: float = 0.0
static var shared_glow_material: CanvasItemMaterial = null

func _ready():
	# Set up sprite based on type
	setup_sprite()

	# Connect to paddle collision
	body_entered.connect(_on_body_entered)
	_cache_game_manager()

func _physics_process(delta):
	# Stop movement if level is complete or game over
	if game_manager == null or not is_instance_valid(game_manager):
		game_manager_retry_timer -= delta
		if game_manager_retry_timer <= 0.0:
			game_manager_retry_timer = GAME_MANAGER_RETRY_INTERVAL
			_cache_game_manager()

	if game_manager and _is_terminal_game_state(game_manager.game_state):
		set_physics_process(false)
		return

	# Move horizontally toward right edge
	position.x += move_speed * delta

	# Destroy if passed right edge (missed by paddle)
	if position.x > MISS_BOUNDARY_X:
		queue_free()

func _cache_game_manager() -> void:
	if game_manager and is_instance_valid(game_manager):
		return
	var candidate = get_tree().get_first_node_in_group("game_manager")
	if candidate == null or not is_instance_valid(candidate):
		return
	game_manager = candidate
	if game_manager.has_signal("state_changed") and not game_manager.state_changed.is_connected(_on_game_state_changed):
		game_manager.state_changed.connect(_on_game_state_changed)
	if _is_terminal_game_state(game_manager.game_state):
		set_physics_process(false)

func _on_game_state_changed(new_state: int) -> void:
	if _is_terminal_game_state(new_state):
		set_physics_process(false)

func _is_terminal_game_state(state: int) -> bool:
	if game_manager == null:
		return false
	return state == game_manager.GameState.LEVEL_COMPLETE or state == game_manager.GameState.GAME_OVER

func setup_sprite():
	"""Configure sprite based on power-up type"""
	if not has_node("Sprite"):
		return

	var sprite = $Sprite
	var texture: Texture2D = null

	match power_up_type:
		PowerUpType.EXPAND:
			texture = expand_texture
		PowerUpType.CONTRACT:
			texture = contract_texture
		PowerUpType.SPEED_UP:
			texture = speed_up_texture
		PowerUpType.TRIPLE_BALL:
			texture = triple_ball_texture
		PowerUpType.BIG_BALL:
			texture = big_ball_texture
		PowerUpType.SMALL_BALL:
			texture = small_ball_texture
		PowerUpType.SLOW_DOWN:
			texture = slow_down_texture
		PowerUpType.EXTRA_LIFE:
			texture = extra_life_texture
		PowerUpType.GRAB:
			texture = grab_texture
		PowerUpType.BRICK_THROUGH:
			texture = brick_through_texture
		PowerUpType.DOUBLE_SCORE:
			texture = double_score_texture
		PowerUpType.MYSTERY:
			texture = mystery_texture
		PowerUpType.BOMB_BALL:
			texture = bomb_ball_texture
		PowerUpType.AIR_BALL:
			texture = air_ball_texture
		PowerUpType.MAGNET:
			texture = magnet_texture
		PowerUpType.BLOCK:
			texture = block_texture

	if not texture:
		push_error("No power-up texture loaded for type: %s" % PowerUpType.keys()[power_up_type])
		return

	sprite.texture = texture

	# Scale to reasonable size (40×40 pixels)
	var texture_size = texture.get_size()
	if texture_size.x > 0 and texture_size.y > 0:
		var scale_factor = 40.0 / max(texture_size.x, texture_size.y)
		sprite.scale = Vector2(scale_factor, scale_factor)

	if has_node("Glow"):
		var glow = $Glow
		glow.texture = texture
		glow.scale = sprite.scale * 1.4

		var glow_color = Color(0.2, 1.0, 0.2, 0.6)  # Default green
		match power_up_type:
			PowerUpType.EXPAND, PowerUpType.TRIPLE_BALL, PowerUpType.BIG_BALL:
				glow_color = Color(0.2, 1.0, 0.2, 0.6)  # Green
			PowerUpType.CONTRACT, PowerUpType.SPEED_UP, PowerUpType.SMALL_BALL:
				glow_color = Color(1.0, 0.25, 0.25, 0.6)  # Red
			PowerUpType.SLOW_DOWN, PowerUpType.EXTRA_LIFE, PowerUpType.GRAB, PowerUpType.BRICK_THROUGH, PowerUpType.DOUBLE_SCORE, PowerUpType.BOMB_BALL, PowerUpType.AIR_BALL, PowerUpType.MAGNET, PowerUpType.BLOCK:
				glow_color = Color(0.2, 1.0, 0.2, 0.6)  # Green
			PowerUpType.MYSTERY:
				glow_color = Color(1.0, 1.0, 0.2, 0.6)  # Yellow

		glow.modulate = glow_color

		glow.material = _get_shared_glow_material()

func _get_shared_glow_material() -> CanvasItemMaterial:
	if shared_glow_material == null:
		shared_glow_material = CanvasItemMaterial.new()
		shared_glow_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return shared_glow_material

func _on_body_entered(body):
	"""Detect collision with paddle"""
	if body.is_in_group("paddle"):
		if _is_bad_power_up(power_up_type):
			AudioManager.play_sfx("power_down")
		else:
			AudioManager.play_sfx("power_up")
		# Emit signal for collection
		collected.emit(power_up_type)

		# Remove power-up
		queue_free()

func _is_bad_power_up(power_type: PowerUpType) -> bool:
	match power_type:
		PowerUpType.CONTRACT, PowerUpType.SPEED_UP, PowerUpType.SMALL_BALL:
			return true
		_:
			return false
