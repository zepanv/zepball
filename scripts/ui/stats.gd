extends Control

## Stats Screen - Display player statistics and achievements

@onready var back_button = $BackButton

# Statistics labels
@onready var bricks_label = $Panel/VBoxContainer/ContentRow/StatsSection/BricksLabel
@onready var powerups_label = $Panel/VBoxContainer/ContentRow/StatsSection/PowerUpsLabel
@onready var levels_label = $Panel/VBoxContainer/ContentRow/StatsSection/LevelsLabel
@onready var combo_label = $Panel/VBoxContainer/ContentRow/StatsSection/ComboLabel
@onready var score_label = $Panel/VBoxContainer/ContentRow/StatsSection/ScoreLabel
@onready var games_label = $Panel/VBoxContainer/ContentRow/StatsSection/GamesLabel
@onready var perfect_label = $Panel/VBoxContainer/ContentRow/StatsSection/PerfectLabel
@onready var playtime_label = $Panel/VBoxContainer/ContentRow/StatsSection/PlaytimeLabel

# Achievements container
@onready var achievements_container = $Panel/VBoxContainer/ContentRow/AchievementsSection/ScrollContainer/AchievementsContainer

func _ready():
	back_button.pressed.connect(_on_back_pressed)
	_populate_statistics()
	_populate_achievements()

	# Grab focus for controller navigation
	await get_tree().process_frame
	back_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		accept_event()

func _populate_statistics():
	"""Load and display all statistics from SaveManager"""
	var stats = SaveManager.get_all_statistics()

	bricks_label.text = "Bricks Broken: " + str(int(stats.get("total_bricks_broken", 0)))
	powerups_label.text = "Power-ups Collected: " + str(int(stats.get("total_power_ups_collected", 0)))
	levels_label.text = "Levels Completed: " + str(int(stats.get("total_levels_completed", 0)))
	combo_label.text = "Highest Combo: " + str(int(stats.get("highest_combo", 0))) + "x"
	score_label.text = "Highest Score: " + str(int(stats.get("highest_score", 0)))
	games_label.text = "Games Played: " + str(int(stats.get("total_games_played", 0)))
	perfect_label.text = "Perfect Clears: " + str(int(stats.get("perfect_clears", 0)))

	# Format playtime as hours:minutes
	var total_seconds = stats.get("total_playtime", 0.0)
	var hours = int(total_seconds / 3600)
	var minutes = int((total_seconds - (hours * 3600)) / 60)
	playtime_label.text = "Total Playtime: " + str(hours) + "h " + str(minutes) + "m"

func _populate_achievements():
	"""Display all achievements with unlock status and progress"""
	# Clear existing achievement items
	for child in achievements_container.get_children():
		child.queue_free()

	# Get all achievements from SaveManager
	var achievements = SaveManager.ACHIEVEMENTS
	var unlocked = SaveManager.get_unlocked_achievements()

	# Create achievement display for each achievement
	for achievement_id in achievements:
		var achievement = achievements[achievement_id]
		var is_unlocked = achievement_id in unlocked
		var progress = SaveManager.get_achievement_progress(achievement_id)

		_create_achievement_item(achievement_id, achievement, is_unlocked, progress)

func _create_achievement_item(_achievement_id: String, achievement: Dictionary, is_unlocked: bool, progress: Dictionary):
	"""Create a UI element for an achievement"""
	var item = VBoxContainer.new()
	item.add_theme_constant_override("separation", 4)

	# Header with icon and name
	var header = HBoxContainer.new()

	# Unlock indicator
	var unlock_icon = Label.new()
	unlock_icon.text = "🏆" if is_unlocked else "🔒"
	unlock_icon.add_theme_font_size_override("font_size", 20)
	header.add_child(unlock_icon)

	# Achievement name
	var name_label = Label.new()
	name_label.text = achievement.get("name", "Unknown")
	name_label.add_theme_font_size_override("font_size", 16)
	if is_unlocked:
		name_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))  # Gold color
	header.add_child(name_label)

	item.add_child(header)

	# Description
	var desc_label = Label.new()
	desc_label.text = achievement.get("description", "")
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	item.add_child(desc_label)

	# Progress bar for locked achievements
	if not is_unlocked:
		var progress_container = HBoxContainer.new()

		var progress_bar = ProgressBar.new()
		progress_bar.custom_minimum_size = Vector2(200, 20)
		progress_bar.max_value = progress.get("required", 100)
		progress_bar.value = progress.get("current", 0)
		progress_bar.show_percentage = false
		progress_container.add_child(progress_bar)

		var progress_label = Label.new()
		progress_label.text = str(int(progress.get("current", 0))) + " / " + str(int(progress.get("required", 0)))
		progress_label.add_theme_font_size_override("font_size", 11)
		progress_container.add_child(progress_label)

		item.add_child(progress_container)

	# Separator line
	var separator = HSeparator.new()
	separator.add_theme_constant_override("separation", 8)
	item.add_child(separator)

	achievements_container.add_child(item)

func _on_back_pressed():
	"""Return to main menu"""
	MenuController.show_main_menu()
