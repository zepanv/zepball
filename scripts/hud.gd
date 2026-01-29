extends Control

## HUD - Heads-Up Display for score, lives, and game info
## Updates in response to GameManager signals

@onready var score_label = $TopBar/ScoreLabel
@onready var lives_label = $TopBar/LivesLabel
@onready var logo_label = $TopBar/LogoLabel
@onready var powerup_container = $PowerUpIndicators

var pause_label: Label = null

func _ready():
	# Allow UI to process even when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

	print("HUD ready")
	# Initial values will be connected via main.gd signals

	# Connect to PowerUpManager signals
	if PowerUpManager:
		PowerUpManager.effect_applied.connect(_on_effect_applied)
		PowerUpManager.effect_expired.connect(_on_effect_expired)

	# Create pause indicator
	pause_label = Label.new()
	pause_label.text = "PAUSED"
	pause_label.add_theme_font_size_override("font_size", 48)
	pause_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pause_label.set_anchors_preset(Control.PRESET_CENTER)
	pause_label.position = Vector2(-100, -24)
	pause_label.size = Vector2(200, 48)
	pause_label.visible = false
	add_child(pause_label)

	# Connect to game state changes
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		game_manager.state_changed.connect(_on_game_state_changed)

func _on_game_state_changed(new_state):
	"""Show/hide pause indicator based on game state"""
	if pause_label:
		pause_label.visible = (new_state == 3)  # 3 = PAUSED

func _on_score_changed(new_score: int):
	"""Update score display"""
	score_label.text = "SCORE: " + str(new_score)

func _on_lives_changed(new_lives: int):
	"""Update lives display"""
	lives_label.text = "LIVES: " + str(new_lives)

func _on_effect_applied(type):
	"""Show power-up indicator when effect is applied"""
	if not powerup_container:
		return

	# Remove existing indicator for this type if any
	_on_effect_expired(type)

	# Create new indicator
	var indicator = create_powerup_indicator(type)
	if indicator:
		powerup_container.add_child(indicator)

func _on_effect_expired(type):
	"""Remove power-up indicator when effect expires"""
	if not powerup_container:
		return

	# Find and remove indicator for this type
	for child in powerup_container.get_children():
		if child.has_meta("powerup_type") and child.get_meta("powerup_type") == type:
			child.queue_free()

func create_powerup_indicator(type) -> Control:
	"""Create a visual indicator for an active power-up"""
	var indicator = PanelContainer.new()
	indicator.set_meta("powerup_type", type)

	# Style the panel
	indicator.custom_minimum_size = Vector2(120, 40)

	# Create content
	var hbox = HBoxContainer.new()
	indicator.add_child(hbox)

	# Power-up name label
	var name_label = Label.new()
	match type:
		0:  # EXPAND
			name_label.text = "BIG PADDLE"
			name_label.modulate = Color(0.3, 0.8, 0.3)  # Green
		1:  # CONTRACT
			name_label.text = "SMALL PADDLE"
			name_label.modulate = Color(0.8, 0.3, 0.3)  # Red
		2:  # SPEED_UP
			name_label.text = "FAST BALL"
			name_label.modulate = Color(1.0, 0.8, 0.3)  # Yellow

	name_label.add_theme_font_size_override("font_size", 14)
	hbox.add_child(name_label)

	# Timer label (updated each frame)
	var timer_label = Label.new()
	timer_label.name = "TimerLabel"
	timer_label.add_theme_font_size_override("font_size", 14)
	hbox.add_child(timer_label)

	return indicator

func _process(_delta):
	"""Update power-up timer displays"""
	if not powerup_container:
		return

	for child in powerup_container.get_children():
		if child.has_meta("powerup_type"):
			var type = child.get_meta("powerup_type")
			var time_remaining = PowerUpManager.get_time_remaining(type)

			# Update timer label
			var timer_label = child.find_child("TimerLabel", true, false)
			if timer_label:
				timer_label.text = " %.1fs" % time_remaining
