extends Control

const UI_THEME = preload("res://scripts/ui/ui_theme.gd")

@onready var background: ColorRect = $Background
@onready var panel: PanelContainer = $ScreenMargin/CenterContainer/Panel
@onready var title_label: Label = $ScreenMargin/CenterContainer/Panel/MarginContainer/VBoxContainer/HeaderVBox/TitleLabel
@onready var subtitle_label: Label = $ScreenMargin/CenterContainer/Panel/MarginContainer/VBoxContainer/HeaderVBox/SubtitleLabel
@onready var survival_card: PanelContainer = $ScreenMargin/CenterContainer/Panel/MarginContainer/VBoxContainer/CardsRow/SurvivalCard
@onready var survival_title_label: Label = $ScreenMargin/CenterContainer/Panel/MarginContainer/VBoxContainer/CardsRow/SurvivalCard/SurvivalMargin/SurvivalVBox/SurvivalTitleLabel
@onready var survival_description_label: Label = $ScreenMargin/CenterContainer/Panel/MarginContainer/VBoxContainer/CardsRow/SurvivalCard/SurvivalMargin/SurvivalVBox/SurvivalDescriptionLabel
@onready var survival_best_label: Label = $ScreenMargin/CenterContainer/Panel/MarginContainer/VBoxContainer/CardsRow/SurvivalCard/SurvivalMargin/SurvivalVBox/SurvivalBestLabel
@onready var survival_start_button: Button = $ScreenMargin/CenterContainer/Panel/MarginContainer/VBoxContainer/CardsRow/SurvivalCard/SurvivalMargin/SurvivalVBox/SurvivalStartButton
@onready var blitz_card: PanelContainer = $ScreenMargin/CenterContainer/Panel/MarginContainer/VBoxContainer/CardsRow/BlitzCard
@onready var blitz_title_label: Label = $ScreenMargin/CenterContainer/Panel/MarginContainer/VBoxContainer/CardsRow/BlitzCard/BlitzMargin/BlitzVBox/BlitzTitleLabel
@onready var blitz_description_label: Label = $ScreenMargin/CenterContainer/Panel/MarginContainer/VBoxContainer/CardsRow/BlitzCard/BlitzMargin/BlitzVBox/BlitzDescriptionLabel
@onready var blitz_best_label: Label = $ScreenMargin/CenterContainer/Panel/MarginContainer/VBoxContainer/CardsRow/BlitzCard/BlitzMargin/BlitzVBox/BlitzBestLabel
@onready var blitz_start_button: Button = $ScreenMargin/CenterContainer/Panel/MarginContainer/VBoxContainer/CardsRow/BlitzCard/BlitzMargin/BlitzVBox/BlitzStartButton
@onready var footer_hint_label: Label = $ScreenMargin/CenterContainer/Panel/MarginContainer/VBoxContainer/FooterRow/FooterHintLabel
@onready var back_button: Button = $ScreenMargin/CenterContainer/Panel/MarginContainer/VBoxContainer/FooterRow/BackButton

func _ready() -> void:
	_apply_theme()
	_populate_descriptions()
	_populate_run_summaries()
	_update_focus_neighbors()
	await get_tree().process_frame
	survival_start_button.grab_focus()

func _apply_theme() -> void:
	UI_THEME.apply_to(self)
	UI_THEME.style_background(background)
	UI_THEME.style_panel(panel, UI_THEME.PANEL_BORDER_ACCENT)
	UI_THEME.style_title(title_label)
	title_label.add_theme_font_size_override("font_size", 42)
	UI_THEME.style_subtitle(subtitle_label)
	UI_THEME.style_soft_panel(survival_card)
	UI_THEME.style_soft_panel(blitz_card)
	UI_THEME.style_section_title(survival_title_label)
	UI_THEME.style_section_title(blitz_title_label)
	UI_THEME.style_meta(survival_description_label)
	UI_THEME.style_meta(blitz_description_label)
	UI_THEME.style_subtitle(survival_best_label)
	UI_THEME.style_subtitle(blitz_best_label)
	UI_THEME.style_secondary_button(survival_start_button)
	UI_THEME.style_secondary_button(blitz_start_button)
	UI_THEME.style_muted_button(back_button)
	UI_THEME.style_meta(footer_hint_label)
	blitz_start_button.disabled = false

func _populate_descriptions() -> void:
	blitz_description_label.text = "Rows push toward the paddle on a timer. Survive pressure by clearing lanes before they close.\nPush interval by difficulty — Easy: 18s  |  Normal: 16s  |  Hard: 14s"

func _populate_run_summaries() -> void:
	var survival_runs: Array = SaveManager.get_survival_top_runs()
	if survival_runs.is_empty():
		survival_best_label.text = "BEST RUN: NO RUNS YET"
	else:
		var best_run: Dictionary = survival_runs[0]
		var best_wave: int = int(max(1, int(best_run.get("wave", 1))))
		var best_score: int = int(max(0, int(best_run.get("score", 0))))
		survival_best_label.text = "BEST RUN: WAVE %d | %d PTS" % [best_wave, best_score]

	var blitz_runs: Array = SaveManager.get_blitz_top_runs()
	if blitz_runs.is_empty():
		blitz_best_label.text = "BEST RUN: NO RUNS YET"
	else:
		var best_blitz_run: Dictionary = blitz_runs[0]
		var best_blitz_score: int = int(max(0, int(best_blitz_run.get("score", 0))))
		blitz_best_label.text = "BEST RUN: %d PTS" % best_blitz_score

func _update_focus_neighbors() -> void:
	survival_start_button.focus_neighbor_right = survival_start_button.get_path_to(blitz_start_button)
	survival_start_button.focus_neighbor_bottom = survival_start_button.get_path_to(back_button)
	blitz_start_button.focus_neighbor_left = blitz_start_button.get_path_to(survival_start_button)
	blitz_start_button.focus_neighbor_bottom = blitz_start_button.get_path_to(back_button)
	back_button.focus_neighbor_top = back_button.get_path_to(survival_start_button)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		accept_event()

func _on_survival_start_pressed() -> void:
	MenuController.start_survival()

func _on_blitz_start_pressed() -> void:
	if MenuController.has_method("start_blitz"):
		MenuController.start_blitz()

func _on_back_pressed() -> void:
	MenuController.show_main_menu()
