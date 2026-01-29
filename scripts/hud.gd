extends Control

## HUD - Heads-Up Display for score, lives, and game info
## Updates in response to GameManager signals

@onready var score_label = $TopBar/ScoreLabel
@onready var lives_label = $TopBar/LivesLabel
@onready var logo_label = $TopBar/LogoLabel
@onready var powerup_container = $PowerUpIndicators

var pause_label: Label = null
var difficulty_label: Label = null
var game_over_label: Label = null
var level_complete_label: Label = null
var combo_label: Label = null

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

	# Create difficulty indicator (positioned below score/lives to avoid overlap)
	difficulty_label = Label.new()
	difficulty_label.text = "DIFFICULTY: " + DifficultyManager.get_difficulty_name()
	difficulty_label.add_theme_font_size_override("font_size", 14)
	difficulty_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	difficulty_label.position = Vector2(10, 50)  # Below top bar
	difficulty_label.size = Vector2(200, 25)
	difficulty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(difficulty_label)

	# Connect to difficulty changes
	if DifficultyManager:
		DifficultyManager.difficulty_changed.connect(_on_difficulty_changed)

	# Create game over overlay
	game_over_label = Label.new()
	game_over_label.text = "GAME OVER\n\nPress R to Restart"
	game_over_label.add_theme_font_size_override("font_size", 64)
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	game_over_label.set_anchors_preset(Control.PRESET_CENTER)
	game_over_label.position = Vector2(-300, -100)
	game_over_label.size = Vector2(600, 200)
	game_over_label.modulate = Color(1.0, 0.3, 0.3)  # Red tint
	game_over_label.visible = false
	add_child(game_over_label)

	# Create level complete overlay
	level_complete_label = Label.new()
	level_complete_label.text = "LEVEL COMPLETE!\n\nPress R to Continue"
	level_complete_label.add_theme_font_size_override("font_size", 64)
	level_complete_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_complete_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_complete_label.set_anchors_preset(Control.PRESET_CENTER)
	level_complete_label.position = Vector2(-400, -100)
	level_complete_label.size = Vector2(800, 200)
	level_complete_label.modulate = Color(0.3, 1.0, 0.3)  # Green tint
	level_complete_label.visible = false
	add_child(level_complete_label)

	# Create combo counter
	combo_label = Label.new()
	combo_label.text = ""  # Hidden until combo starts
	combo_label.add_theme_font_size_override("font_size", 32)
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	combo_label.set_anchors_preset(Control.PRESET_CENTER)
	combo_label.position = Vector2(-150, 150)  # Below center
	combo_label.size = Vector2(300, 50)
	combo_label.modulate = Color(1.0, 0.8, 0.2)  # Gold color
	combo_label.visible = false
	add_child(combo_label)

	# Connect to game state changes
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		game_manager.state_changed.connect(_on_game_state_changed)
		game_manager.combo_changed.connect(_on_combo_changed)

func _on_game_state_changed(new_state):
	"""Show/hide overlays based on game state"""
	if pause_label:
		pause_label.visible = (new_state == 3)  # 3 = PAUSED
	if game_over_label:
		game_over_label.visible = (new_state == 5)  # 5 = GAME_OVER
	if level_complete_label:
		level_complete_label.visible = (new_state == 4)  # 4 = LEVEL_COMPLETE

func _on_difficulty_changed(new_difficulty):
	"""Update difficulty display when changed"""
	if difficulty_label:
		difficulty_label.text = "DIFFICULTY: " + DifficultyManager.get_difficulty_name()

func _on_combo_changed(new_combo: int):
	"""Update combo display"""
	if not combo_label:
		return

	if new_combo >= 3:
		combo_label.visible = true
		combo_label.text = "COMBO x" + str(new_combo) + "!"
		# Scale effect for visual feedback
		combo_label.scale = Vector2(1.2, 1.2)
		var tween = create_tween()
		tween.tween_property(combo_label, "scale", Vector2(1.0, 1.0), 0.2)
	else:
		combo_label.visible = false

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
