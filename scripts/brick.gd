extends StaticBody2D

## Brick - Breakable tile that awards points when destroyed
## Can have different types (normal, strong, unbreakable)

# Brick types
enum BrickType {
	NORMAL,     # Breaks in 1 hit, 10 points
	STRONG,     # Breaks in 2 hits, 20 points
	UNBREAKABLE # Never breaks
}

# Configuration
@export var brick_type: BrickType = BrickType.NORMAL
@export var brick_color: Color = Color(0.059, 0.773, 0.627)  # Teal

# State
var hits_remaining: int = 1
var score_value: int = 10

# Signals
signal brick_broken(score_value: int)

func _ready():
	# Set up brick based on type
	match brick_type:
		BrickType.NORMAL:
			hits_remaining = 1
			score_value = 10
		BrickType.STRONG:
			hits_remaining = 2
			score_value = 20
			brick_color = Color(0.914, 0.275, 0.376)  # Pink/red
		BrickType.UNBREAKABLE:
			hits_remaining = 999
			score_value = 0
			brick_color = Color(0.5, 0.5, 0.5)  # Gray

	# Apply color to visual
	if has_node("Visual"):
		$Visual.color = brick_color

	# Apply color to particles
	if has_node("Particles"):
		$Particles.color = brick_color

	print("Brick ready: type=", BrickType.keys()[brick_type], " hits=", hits_remaining)

func hit():
	"""Called when ball collides with brick"""
	hits_remaining -= 1
	print("Brick hit! Hits remaining: ", hits_remaining)

	if hits_remaining <= 0:
		break_brick()
	else:
		# Visual feedback for damaged brick (change color slightly)
		if has_node("Visual"):
			$Visual.color = brick_color.darkened(0.3)

func break_brick():
	"""Break the brick and emit particles"""
	print("Brick broken! Score: +", score_value)

	# Emit signal to game manager
	brick_broken.emit(score_value)

	# Play particle effect
	if has_node("Particles"):
		var particles = $Particles
		particles.emitting = true

		# Wait for particles to finish, then remove brick
		await get_tree().create_timer(0.5).timeout

	# Remove brick from scene
	queue_free()
