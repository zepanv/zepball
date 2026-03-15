extends Control

## Stats Screen - Display player statistics and achievements
const UI_THEME = preload("res://scripts/ui/ui_theme.gd")

const SCROLL_STEP := 80

@onready var background = $Background
@onready var panel = $ScreenMargin/CenterContainer/Panel
@onready var title_label = $ScreenMargin/CenterContainer/Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var stats_title = $ScreenMargin/CenterContainer/Panel/MarginContainer/VBoxContainer/ContentRow/StatsSection/StatsTitle
@onready var achievements_title = $ScreenMargin/CenterContainer/Panel/MarginContainer/VBoxContainer/ContentRow/AchievementsSection/AchievementsTitle
@onready var back_button = $ScreenMargin/CenterContainer/Panel/MarginContainer/VBoxContainer/FooterRow/BackButton

# Statistics labels
@onready var bricks_label = $ScreenMargin/CenterContainer/Panel/MarginContainer/VBoxContainer/ContentRow/StatsSection/BricksLabel
@onready var powerups_label = $ScreenMargin/CenterContainer/Panel/MarginContainer/VBoxContainer/ContentRow/StatsSection/PowerUpsLabel
@onready var levels_label = $ScreenMargin/CenterContainer/Panel/MarginContainer/VBoxContainer/ContentRow/StatsSection/LevelsLabel
@onready var combo_label = $ScreenMargin/CenterContainer/Panel/MarginContainer/VBoxContainer/ContentRow/StatsSection/ComboLabel
@onready var score_label = $ScreenMargin/CenterContainer/Panel/MarginContainer/VBoxContainer/ContentRow/StatsSection/ScoreLabel
@onready var games_label = $ScreenMargin/CenterContainer/Panel/MarginContainer/VBoxContainer/ContentRow/StatsSection/GamesLabel
@onready var perfect_label = $ScreenMargin/CenterContainer/Panel/MarginContainer/VBoxContainer/ContentRow/StatsSection/PerfectLabel
@onready var playtime_label = $ScreenMargin/CenterContainer/Panel/MarginContainer/VBoxContainer/ContentRow/StatsSection/PlaytimeLabel

# Achievements container
@onready var achievements_scroll_container = $ScreenMargin/CenterContainer/Panel/MarginContainer/VBoxContainer/ContentRow/AchievementsSection/ScrollContainer
@onready var achievements_container = $ScreenMargin/CenterContainer/Panel/MarginContainer/VBoxContainer/ContentRow/AchievementsSection/ScrollContainer/AchievementsContainer

func _ready():
	_apply_theme()
	back_button.pressed.connect(_on_back_pressed)
	_populate_statistics()
	_populate_achievements()

	# Grab focus for controller navigation
	await get_tree().process_frame
	back_button.grab_focus()

func _apply_theme() -> void:
	UI_THEME.apply_to(self)
	UI_THEME.style_background(background)
	UI_THEME.style_panel(panel, UI_THEME.PANEL_BORDER_ACCENT)
	UI_THEME.style_title_large(title_label)
	UI_THEME.style_section_title(stats_title)
	UI_THEME.style_section_title(achievements_title)
	UI_THEME.style_muted_button(back_button)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		accept_event()
	elif event.is_action_pressed("ui_down", true):
		achievements_scroll_container.scroll_vertical += SCROLL_STEP
		accept_event()
	elif event.is_action_pressed("ui_up", true):
		achievements_scroll_container.scroll_vertical -= SCROLL_STEP
		accept_event()

func _populate_statistics():
	"""Load and display all statistics from SaveManager"""
	var stats = SaveManager.get_all_statistics()

	bricks_label.text = "Bricks Broken: " + ScoreBreakdownHelpers.comma_sep(int(stats.get("total_bricks_broken", 0)))
	powerups_label.text = "Power-ups: " + ScoreBreakdownHelpers.comma_sep(int(stats.get("total_power_ups_collected", 0)))
	levels_label.text = "Levels Completed: " + ScoreBreakdownHelpers.comma_sep(int(stats.get("total_levels_completed", 0)))
	combo_label.text = "Highest Combo: " + ScoreBreakdownHelpers.comma_sep(int(stats.get("highest_combo", 0))) + "x"
	score_label.text = "Highest Score: " + ScoreBreakdownHelpers.comma_sep(int(stats.get("highest_score", 0)))
	games_label.text = "Games Played: " + ScoreBreakdownHelpers.comma_sep(int(stats.get("total_games_played", 0)))
	perfect_label.text = "Perfect Clears: " + ScoreBreakdownHelpers.comma_sep(int(stats.get("perfect_clears", 0)))

	# Format playtime as hours:minutes
	var total_seconds = stats.get("total_playtime", 0.0)
	var hours = int(total_seconds / 3600)
	var minutes = int((total_seconds - (hours * 3600)) / 60)
	playtime_label.text = "Playtime: " + str(hours) + "h " + str(minutes) + "m"

	# Style all stat labels
	for stat_label in [bricks_label, powerups_label, levels_label, combo_label,
		score_label, games_label, perfect_label, playtime_label]:
		UI_THEME.style_stat_label(stat_label)

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
	var item = PanelContainer.new()
	item.custom_minimum_size = Vector2(0, 0)

	# Style as accent row — gold left stripe for unlocked, muted for locked
	var bg := Color(UI_THEME.PANEL_BACKGROUND_SOFT.r, UI_THEME.PANEL_BACKGROUND_SOFT.g, UI_THEME.PANEL_BACKGROUND_SOFT.b, 0.6)
	var accent := UI_THEME.RANK_GOLD if is_unlocked else Color(UI_THEME.PANEL_BORDER.r, UI_THEME.PANEL_BORDER.g, UI_THEME.PANEL_BORDER.b, 0.3)
	UI_THEME.style_accent_row(item, accent, bg)

	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 2)

	var inner_margin = MarginContainer.new()
	inner_margin.add_theme_constant_override("margin_left", 10)
	inner_margin.add_theme_constant_override("margin_right", 8)
	inner_margin.add_theme_constant_override("margin_top", 6)
	inner_margin.add_theme_constant_override("margin_bottom", 6)
	item.add_child(inner_margin)
	inner_margin.add_child(content)

	# Header with icon and name
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 6)

	# Unlock indicator
	var unlock_icon = Label.new()
	unlock_icon.text = "🏆" if is_unlocked else "🔒"
	unlock_icon.add_theme_font_size_override("font_size", 16)
	header.add_child(unlock_icon)

	# Achievement name
	var name_label = Label.new()
	name_label.text = achievement.get("name", "Unknown")
	name_label.add_theme_font_size_override("font_size", 15)
	if is_unlocked:
		name_label.add_theme_color_override("font_color", UI_THEME.RANK_GOLD)
	else:
		name_label.add_theme_color_override("font_color", UI_THEME.TEXT_PRIMARY)
	header.add_child(name_label)

	content.add_child(header)

	# Description
	var desc_label = Label.new()
	desc_label.text = achievement.get("description", "")
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", UI_THEME.TEXT_MUTED)
	content.add_child(desc_label)

	# Progress bar for locked achievements
	if not is_unlocked:
		var progress_container = HBoxContainer.new()
		progress_container.add_theme_constant_override("separation", 8)

		var progress_bar = ProgressBar.new()
		progress_bar.custom_minimum_size = Vector2(180, 16)
		progress_bar.max_value = progress.get("required", 100)
		progress_bar.value = progress.get("current", 0)
		progress_bar.show_percentage = false
		progress_container.add_child(progress_bar)

		var progress_label = Label.new()
		progress_label.text = str(int(progress.get("current", 0))) + " / " + str(int(progress.get("required", 0)))
		progress_label.add_theme_font_size_override("font_size", 11)
		progress_label.add_theme_color_override("font_color", UI_THEME.TEXT_MUTED)
		progress_container.add_child(progress_label)

		content.add_child(progress_container)

	achievements_container.add_child(item)

func _on_back_pressed():
	"""Return to main menu"""
	MenuController.show_main_menu()
