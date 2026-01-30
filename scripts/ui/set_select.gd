extends Control

## Set Select Screen - Displays available level sets
## Allows player to start a set or view individual levels

@onready var sets_container = $VBoxContainer/ScrollContainer/SetsContainer

func _ready():
	"""Initialize set select screen"""
	# Populate sets
	populate_sets()

func populate_sets():
	"""Create set cards dynamically based on available sets"""
	# Clear existing children
	for child in sets_container.get_children():
		child.queue_free()

	var all_sets = SetLoader.get_all_sets()

	for set_data in all_sets:
		create_set_card(set_data)

func create_set_card(set_data: Dictionary):
	"""Create a card panel for a single set"""
	var set_id = set_data.get("set_id", -1)
	var set_display_name = set_data.get("name", "Unknown Set")  # Renamed to avoid shadowing Node.set_name()
	var description = set_data.get("description", "")
	var level_ids = set_data.get("level_ids", [])

	# Check if set is unlocked and completed
	var is_unlocked = SaveManager.is_set_unlocked(set_id)
	var is_completed = SaveManager.is_set_completed(set_id)
	var high_score = SaveManager.get_set_high_score(set_id)

	# Create container panel
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(700, 160)

	# Add margins
	var margin = MarginContainer.new()
	margin.set("theme_override_constants/margin_left", 15)
	margin.set("theme_override_constants/margin_right", 15)
	margin.set("theme_override_constants/margin_top", 12)
	margin.set("theme_override_constants/margin_bottom", 12)
	panel.add_child(margin)

	# Create VBox for set info
	var vbox = VBoxContainer.new()
	vbox.set("theme_override_constants/separation", 8)
	margin.add_child(vbox)

	# Set name
	var title_label = Label.new()
	title_label.text = set_display_name.to_upper()
	title_label.set("theme_override_font_sizes/font_size", 32)
	if is_unlocked:
		title_label.set("theme_override_colors/font_color", Color(0, 0.9, 1, 1))
	else:
		title_label.set("theme_override_colors/font_color", Color(0.3, 0.3, 0.3, 1))
	vbox.add_child(title_label)

	# Description
	var desc_label = Label.new()
	desc_label.text = description
	desc_label.set("theme_override_font_sizes/font_size", 18)
	desc_label.set("theme_override_colors/font_color", Color(0.7, 0.7, 0.7, 1))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)

	# Level count and status
	var info_hbox = HBoxContainer.new()
	info_hbox.set("theme_override_constants/separation", 20)
	vbox.add_child(info_hbox)

	var level_count_label = Label.new()
	level_count_label.text = str(level_ids.size()) + " Levels"
	level_count_label.set("theme_override_font_sizes/font_size", 18)
	level_count_label.set("theme_override_colors/font_color", Color(0.6, 0.6, 0.6, 1))
	info_hbox.add_child(level_count_label)

	# Status label (completion / high score)
	var status_label = Label.new()
	status_label.set("theme_override_font_sizes/font_size", 18)
	if is_completed and high_score > 0:
		status_label.text = "✓ Best: " + str(high_score)
		status_label.set("theme_override_colors/font_color", Color(0.5, 1, 0.5, 1))
	elif high_score > 0:
		status_label.text = "Best: " + str(high_score)
		status_label.set("theme_override_colors/font_color", Color(0.7, 0.7, 0.7, 1))
	else:
		status_label.text = ""
	info_hbox.add_child(status_label)

	# Buttons
	var button_hbox = HBoxContainer.new()
	button_hbox.set("theme_override_constants/separation", 15)
	vbox.add_child(button_hbox)

	# Play Set button
	var play_button = Button.new()
	play_button.text = "PLAY SET"
	play_button.custom_minimum_size = Vector2(200, 45)
	play_button.set("theme_override_colors/font_color", Color(0, 0.9, 1, 1))
	play_button.set("theme_override_colors/font_hover_color", Color(0.9, 0.3, 0.4, 1))
	play_button.set("theme_override_font_sizes/font_size", 24)
	play_button.pressed.connect(_on_play_set_pressed.bind(set_id))
	button_hbox.add_child(play_button)

	# View Levels button
	var view_button = Button.new()
	view_button.text = "VIEW LEVELS"
	view_button.custom_minimum_size = Vector2(200, 45)
	view_button.set("theme_override_colors/font_color", Color(0.7, 0.7, 0.7, 1))
	view_button.set("theme_override_colors/font_hover_color", Color(0, 0.9, 1, 1))
	view_button.set("theme_override_font_sizes/font_size", 22)
	view_button.pressed.connect(_on_view_levels_pressed.bind(set_id))
	button_hbox.add_child(view_button)

	sets_container.add_child(panel)

func _on_play_set_pressed(set_id: int):
	"""Start playing the set"""
	MenuController.start_set(set_id)

func _on_view_levels_pressed(set_id: int):
	"""Go to level select for this set"""
	# Set the current set context in MenuController
	MenuController.current_set_id = set_id

	# Go to level select
	MenuController.show_level_select()

func _on_back_button_pressed():
	"""Return to main menu"""
	MenuController.show_main_menu()
