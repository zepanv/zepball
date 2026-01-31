extends Control

## Level Select Screen - Displays available levels with unlock status
## Shows high scores and allows launching unlocked levels

@onready var levels_grid = $VBoxContainer/LevelsGrid
@onready var vbox_container = $VBoxContainer

var set_header_label: Label = null
var play_set_button: Button = null

func _ready():
	"""Initialize level select screen"""
	# Check if we're viewing a specific set
	if MenuController.current_set_id != -1:
		add_set_context_ui()

	# Populate levels
	populate_levels()

func add_set_context_ui():
	"""Add set header and Play Set button when viewing a set"""
	var set_id = MenuController.current_set_id
	var set_title = SetLoader.get_set_name(set_id)
	var set_description = SetLoader.get_set_description(set_id)

	# Create header label
	set_header_label = Label.new()
	set_header_label.text = "SET: " + set_title.to_upper()
	set_header_label.set("theme_override_font_sizes/font_size", 32)
	set_header_label.set("theme_override_colors/font_color", Color(0, 0.9, 1, 1))
	set_header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Insert at beginning of VBox
	vbox_container.add_child(set_header_label)
	vbox_container.move_child(set_header_label, 0)

	# Create description label
	var desc_label = Label.new()
	desc_label.text = set_description
	desc_label.set("theme_override_font_sizes/font_size", 18)
	desc_label.set("theme_override_colors/font_color", Color(0.7, 0.7, 0.7, 1))
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_container.add_child(desc_label)
	vbox_container.move_child(desc_label, 1)

	# Create Play Set button
	play_set_button = Button.new()
	play_set_button.text = "PLAY THIS SET"
	play_set_button.custom_minimum_size = Vector2(300, 55)
	play_set_button.set("theme_override_colors/font_color", Color(0, 0.9, 1, 1))
	play_set_button.set("theme_override_colors/font_hover_color", Color(0.9, 0.3, 0.4, 1))
	play_set_button.set("theme_override_font_sizes/font_size", 28)
	play_set_button.pressed.connect(_on_play_set_button_pressed)

	# Create HBox to center the button
	var button_hbox = HBoxContainer.new()
	button_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	button_hbox.add_child(play_set_button)

	# Insert before levels grid
	var grid_index = levels_grid.get_index()
	vbox_container.add_child(button_hbox)
	vbox_container.move_child(button_hbox, grid_index)

	# Add spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox_container.add_child(spacer)
	vbox_container.move_child(spacer, 2)

func _on_play_set_button_pressed():
	"""Start playing the current set"""
	MenuController.start_set(MenuController.current_set_id)

func populate_levels():
	"""Create level buttons dynamically based on available levels"""
	# Clear existing children
	for child in levels_grid.get_children():
		child.queue_free()

	var total_levels = LevelLoader.get_total_level_count()

	for level_id in range(1, total_levels + 1):
		create_level_button(level_id)

func create_level_button(level_id: int):
	"""Create a button panel for a single level"""
	# Check if level is unlocked
	var is_unlocked = SaveManager.is_level_unlocked(level_id)
	var is_completed = SaveManager.is_level_completed(level_id)
	var high_score = SaveManager.get_high_score(level_id)
	var level_info = LevelLoader.get_level_info(level_id)

	# Create container panel
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(350, 120)

	# Create VBox for level info
	var vbox = VBoxContainer.new()
	vbox.set("theme_override_constants/separation", 5)
	panel.add_child(vbox)

	# Level number and name
	var title_label = Label.new()
	title_label.text = "LEVEL " + str(level_id) + ": " + level_info.get("name", "Unknown")
	title_label.set("theme_override_font_sizes/font_size", 24)

	if is_unlocked:
		title_label.set("theme_override_colors/font_color", Color(0, 0.9, 1, 1))
	else:
		title_label.set("theme_override_colors/font_color", Color(0.3, 0.3, 0.3, 1))

	vbox.add_child(title_label)

	# Description
	var desc_label = Label.new()
	desc_label.text = level_info.get("description", "")
	desc_label.set("theme_override_font_sizes/font_size", 16)
	desc_label.set("theme_override_colors/font_color", Color(0.7, 0.7, 0.7, 1))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)

	# High score / Lock status
	var status_label = Label.new()
	status_label.set("theme_override_font_sizes/font_size", 18)

	if not is_unlocked:
		status_label.text = "🔒 LOCKED"
		status_label.set("theme_override_colors/font_color", Color(0.5, 0.5, 0.5, 1))
	elif is_completed and high_score > 0:
		status_label.text = "✓ Best: " + str(high_score)
		status_label.set("theme_override_colors/font_color", Color(0.5, 1, 0.5, 1))
	else:
		status_label.text = "NEW"
		status_label.set("theme_override_colors/font_color", Color(1, 1, 0.5, 1))

	vbox.add_child(status_label)

	# Make panel clickable if unlocked
	if is_unlocked:
		# Convert to button-like behavior
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

		# Store level_id in metadata
		panel.set_meta("level_id", level_id)

		# Connect click signal
		panel.gui_input.connect(_on_level_panel_input.bind(panel))

		# Add hover effect
		panel.mouse_entered.connect(_on_level_hover_start.bind(panel))
		panel.mouse_exited.connect(_on_level_hover_end.bind(panel))
	else:
		panel.modulate = Color(0.5, 0.5, 0.5, 1)

	levels_grid.add_child(panel)

func _on_level_panel_input(event: InputEvent, panel: PanelContainer):
	"""Handle click on level panel"""
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var level_id = panel.get_meta("level_id")
			MenuController.start_level(level_id)

func _on_level_hover_start(panel: PanelContainer):
	"""Highlight panel on hover"""
	panel.modulate = Color(1.2, 1.2, 1.2, 1)

func _on_level_hover_end(panel: PanelContainer):
	"""Remove highlight on hover end"""
	panel.modulate = Color.WHITE

func _on_back_button_pressed():
	"""Return to appropriate screen (set select if from set, otherwise main menu)"""
	if MenuController.current_set_id != -1:
		# Coming from set select, go back to set select
		MenuController.show_set_select()
	else:
		# Coming from main menu, go back to main menu
		MenuController.show_main_menu()
