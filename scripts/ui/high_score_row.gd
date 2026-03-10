extends PanelContainer

const UI_THEME = preload("res://scripts/ui/ui_theme.gd")

@onready var rank_badge: Label = $MarginContainer/ContentRow/RankBadge
@onready var player_name_label: Label = $MarginContainer/ContentRow/PlayerColumn/PlayerNameLabel
@onready var player_meta_label: Label = $MarginContainer/ContentRow/PlayerColumn/PlayerMetaLabel
@onready var context_label: Label = $MarginContainer/ContentRow/ContextLabel
@onready var score_label: Label = $MarginContainer/ContentRow/ScoreLabel
@onready var date_label: Label = $MarginContainer/ContentRow/DateLabel

var _pending_entry: Dictionary = {}
var _pending_rank: int = 0
var _pending_show_context: bool = true
var _pending_score_mode: String = "score"
var _pending_is_current_player: bool = false
var _pending_alternate: bool = false
var _has_pending_data: bool = false

func _ready() -> void:
	UI_THEME.apply_to(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _has_pending_data:
		_apply_data()

func configure(entry: Dictionary, rank: int, show_context: bool, score_mode: String, is_current_player: bool, alternate: bool) -> void:
	_pending_entry = entry.duplicate(true)
	_pending_rank = rank
	_pending_show_context = show_context
	_pending_score_mode = score_mode
	_pending_is_current_player = is_current_player
	_pending_alternate = alternate
	_has_pending_data = true

	if is_node_ready():
		_apply_data()

func _apply_data() -> void:
	_has_pending_data = false

	var rank_color := _get_rank_color(_pending_rank)
	_apply_panel_style(_pending_alternate, _pending_is_current_player, rank_color)

	# Rank badge — colored text, centered
	rank_badge.text = _format_rank(_pending_rank)
	rank_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UI_THEME.style_rank_badge(rank_badge, _pending_rank)
	if _pending_rank <= 3:
		rank_badge.add_theme_font_size_override("font_size", 17)
	else:
		rank_badge.add_theme_font_size_override("font_size", 15)

	player_name_label.text = str(_pending_entry.get("name", "Unknown"))
	UI_THEME.style_value(player_name_label, 17)
	if _pending_is_current_player:
		player_name_label.add_theme_color_override("font_color", UI_THEME.SUCCESS)
	player_meta_label.visible = false

	context_label.visible = _pending_show_context
	context_label.text = str(_pending_entry.get("context", ""))
	context_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI_THEME.style_subtitle(context_label)
	context_label.add_theme_font_size_override("font_size", 16)

	# Score — bigger and bolder
	score_label.text = _format_score(_pending_entry, _pending_score_mode)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UI_THEME.style_warning(score_label, 22)
	if _pending_is_current_player:
		score_label.add_theme_color_override("font_color", UI_THEME.SUCCESS)

	date_label.text = _format_date(str(_pending_entry.get("date", "Unknown")))
	date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UI_THEME.style_meta(date_label)

func _apply_panel_style(alternate: bool, is_current_player: bool, rank_color: Color) -> void:
	# Background — stronger zebra stripe
	var bg_base := UI_THEME.PANEL_BACKGROUND_SOFT
	var bg: Color
	if alternate:
		bg = Color(
			min(bg_base.r + 0.03, 1.0),
			min(bg_base.g + 0.035, 1.0),
			min(bg_base.b + 0.04, 1.0),
			0.92
		)
	else:
		bg = Color(bg_base.r, bg_base.g, bg_base.b, 0.72)

	# Current player gets a green wash
	if is_current_player:
		bg = Color(
			lerp(bg.r, UI_THEME.SUCCESS.r, 0.08),
			lerp(bg.g, UI_THEME.SUCCESS.g, 0.08),
			lerp(bg.b, UI_THEME.SUCCESS.b, 0.06),
			0.92
		)

	# Left accent stripe color
	var accent: Color
	if is_current_player:
		accent = UI_THEME.SUCCESS
	elif _pending_rank <= 3:
		accent = rank_color
	else:
		accent = Color(UI_THEME.PANEL_BORDER.r, UI_THEME.PANEL_BORDER.g, UI_THEME.PANEL_BORDER.b, 0.5)

	UI_THEME.style_accent_row(self, accent, bg)

func _get_rank_color(rank: int) -> Color:
	match rank:
		1:
			return UI_THEME.RANK_GOLD
		2:
			return UI_THEME.RANK_SILVER
		3:
			return UI_THEME.RANK_BRONZE
		_:
			return UI_THEME.RANK_DEFAULT

func _format_rank(rank: int) -> String:
	match rank:
		1:
			return "1ST"
		2:
			return "2ND"
		3:
			return "3RD"
		_:
			return "#%d" % rank

func _format_score(entry: Dictionary, score_mode: String) -> String:
	var value := int(entry.get("score", 0))
	if score_mode == "time":
		return _format_time(value)
	return str(value)

func _format_date(raw_date: String) -> String:
	if raw_date == "" or raw_date == "Unknown":
		return "---"
	return raw_date.split("T")[0]

func _format_time(total_seconds: int) -> String:
	var minutes := int(floor(float(total_seconds) / 60.0))
	var seconds := int(total_seconds % 60)
	return "%02d:%02d" % [minutes, seconds]
