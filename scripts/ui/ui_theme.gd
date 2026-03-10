class_name ZepballUITheme
extends RefCounted

const SCREEN_BACKGROUND := Color(0.03, 0.05, 0.08, 1.0)
const SCREEN_BACKGROUND_ALT := Color(0.05, 0.08, 0.12, 1.0)
const PANEL_BACKGROUND := Color(0.07, 0.10, 0.15, 0.92)
const PANEL_BACKGROUND_SOFT := Color(0.06, 0.09, 0.13, 0.82)
const PANEL_BORDER := Color(0.19, 0.29, 0.39, 0.95)
const PANEL_BORDER_ACCENT := Color(0.08, 0.76, 0.94, 0.95)
const PRIMARY := Color(0.10, 0.86, 1.00, 1.0)
const PRIMARY_SOFT := Color(0.56, 0.89, 0.98, 1.0)
const GOLD := Color(1.00, 0.82, 0.28, 1.0)
const SUCCESS := Color(0.46, 0.96, 0.64, 1.0)
const DANGER := Color(0.96, 0.40, 0.40, 1.0)
const TEXT_PRIMARY := Color(0.94, 0.97, 1.0, 1.0)
const TEXT_SECONDARY := Color(0.72, 0.79, 0.86, 1.0)
const TEXT_MUTED := Color(0.53, 0.60, 0.68, 1.0)

# Richer rank colors for leaderboard badges
const RANK_GOLD := Color(1.00, 0.84, 0.20, 1.0)
const RANK_SILVER := Color(0.80, 0.84, 0.92, 1.0)
const RANK_BRONZE := Color(0.86, 0.58, 0.32, 1.0)
const RANK_DEFAULT := Color(0.40, 0.48, 0.58, 1.0)

static var _shared_theme: Theme = null

static func apply_to(root: Control) -> void:
	if root:
		root.theme = get_theme()

static func get_theme() -> Theme:
	if _shared_theme != null:
		return _shared_theme

	var theme := Theme.new()
	theme.set_color("font_color", "Label", TEXT_PRIMARY)
	theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.18))
	theme.set_constant("shadow_offset_x", "Label", 1)
	theme.set_constant("shadow_offset_y", "Label", 1)
	theme.set_font_size("font_size", "Label", 18)

	theme.set_constant("separation", "VBoxContainer", 12)
	theme.set_constant("separation", "HBoxContainer", 12)

	theme.set_stylebox("panel", "Panel", _make_panel_style(PANEL_BACKGROUND, PANEL_BORDER, 8))
	theme.set_stylebox("panel", "PanelContainer", _make_panel_style(PANEL_BACKGROUND, PANEL_BORDER, 8))
	theme.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())

	var button_normal := _make_button_style(PANEL_BACKGROUND_SOFT, PANEL_BORDER, 6)
	var button_hover := _make_button_style(Color(PANEL_BACKGROUND_SOFT.r, PANEL_BACKGROUND_SOFT.g, PANEL_BACKGROUND_SOFT.b, 0.96), PRIMARY, 6)
	var button_pressed := _make_button_style(Color(0.09, 0.13, 0.19, 0.98), PRIMARY_SOFT, 6)
	var button_disabled := _make_button_style(Color(0.05, 0.06, 0.09, 0.72), Color(0.16, 0.18, 0.24, 0.8), 6)
	var button_focus := _make_focus_style(PRIMARY)

	for type_name in ["Button", "OptionButton"]:
		theme.set_stylebox("normal", type_name, button_normal)
		theme.set_stylebox("hover", type_name, button_hover)
		theme.set_stylebox("pressed", type_name, button_pressed)
		theme.set_stylebox("disabled", type_name, button_disabled)
		theme.set_stylebox("focus", type_name, button_focus)
		theme.set_color("font_color", type_name, TEXT_PRIMARY)
		theme.set_color("font_hover_color", type_name, TEXT_PRIMARY)
		theme.set_color("font_pressed_color", type_name, TEXT_PRIMARY)
		theme.set_color("font_disabled_color", type_name, TEXT_MUTED)
		theme.set_constant("h_separation", type_name, 6)
		theme.set_font_size("font_size", type_name, 17)

	theme.set_stylebox("normal", "CheckBox", StyleBoxEmpty.new())
	theme.set_stylebox("pressed", "CheckBox", StyleBoxEmpty.new())
	theme.set_stylebox("focus", "CheckBox", _make_focus_style(PRIMARY))
	theme.set_color("font_color", "CheckBox", TEXT_PRIMARY)
	theme.set_color("font_hover_color", "CheckBox", TEXT_PRIMARY)
	theme.set_color("font_pressed_color", "CheckBox", TEXT_PRIMARY)
	theme.set_font_size("font_size", "CheckBox", 17)

	theme.set_stylebox("slider", "HSlider", _make_line_style(PANEL_BORDER, 4))
	theme.set_stylebox("grabber_area", "HSlider", StyleBoxEmpty.new())
	theme.set_stylebox("grabber_area_highlight", "HSlider", StyleBoxEmpty.new())
	theme.set_stylebox("grabber", "HSlider", _make_grabber_style(PRIMARY))
	theme.set_stylebox("grabber_highlight", "HSlider", _make_grabber_style(PRIMARY_SOFT))

	theme.set_stylebox("tab_unselected", "TabBar", _make_tab_style(PANEL_BACKGROUND_SOFT, PANEL_BORDER))
	theme.set_stylebox("tab_selected", "TabBar", _make_tab_style(Color(0.08, 0.13, 0.20, 0.98), PRIMARY))
	theme.set_stylebox("tab_hovered", "TabBar", _make_tab_style(Color(0.08, 0.13, 0.20, 0.96), PRIMARY_SOFT))
	theme.set_stylebox("tab_disabled", "TabBar", _make_tab_style(Color(0.05, 0.06, 0.09, 0.72), PANEL_BORDER))
	theme.set_color("font_selected_color", "TabBar", TEXT_PRIMARY)
	theme.set_color("font_hovered_color", "TabBar", TEXT_PRIMARY)
	theme.set_color("font_unselected_color", "TabBar", TEXT_SECONDARY)
	theme.set_color("font_disabled_color", "TabBar", TEXT_MUTED)
	theme.set_constant("h_separation", "TabBar", 6)
	theme.set_constant("top_margin", "TabBar", 4)
	theme.set_constant("side_margin", "TabBar", 10)

	_shared_theme = theme
	return _shared_theme

static func style_background(background: ColorRect, use_alt: bool = false) -> void:
	if not background:
		return
	background.color = SCREEN_BACKGROUND_ALT if use_alt else SCREEN_BACKGROUND

static func style_panel(panel: Control, accent: Color = PANEL_BORDER) -> void:
	if not panel:
		return
	panel.add_theme_stylebox_override("panel", _make_panel_style(PANEL_BACKGROUND, accent, 8))

static func style_soft_panel(panel: Control) -> void:
	if not panel:
		return
	panel.add_theme_stylebox_override("panel", _make_panel_style(PANEL_BACKGROUND_SOFT, PANEL_BORDER, 6))

static func style_flush_panel(panel: Control) -> void:
	if not panel:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Color(0, 0, 0, 0)
	style.content_margin_left = 10
	style.content_margin_top = 6
	style.content_margin_right = 10
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)

static func style_accent_row(panel: Control, accent: Color, bg: Color, radius: int = 6) -> void:
	if not panel:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = accent
	style.border_width_left = 3
	style.border_width_top = 0
	style.border_width_right = 0
	style.border_width_bottom = 0
	style.corner_radius_top_left = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 0
	style.content_margin_top = 0
	style.content_margin_right = 0
	style.content_margin_bottom = 0
	panel.add_theme_stylebox_override("panel", style)

static func style_title_large(label: Label) -> void:
	_style_label(label, 44, PRIMARY)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.add_theme_color_override("font_shadow_color", Color(0, 0.3, 0.5, 0.35))

static func style_rank_badge(label: Label, rank: int) -> void:
	var color := _get_rank_color_static(rank)
	_style_label(label, 15, color)
	label.uppercase = true

static func _get_rank_color_static(rank: int) -> Color:
	match rank:
		1:
			return RANK_GOLD
		2:
			return RANK_SILVER
		3:
			return RANK_BRONZE
		_:
			return RANK_DEFAULT

static func style_title(label: Label) -> void:
	_style_label(label, 38, PRIMARY)

static func style_section_title(label: Label) -> void:
	_style_label(label, 20, PRIMARY_SOFT)

static func style_subtitle(label: Label) -> void:
	_style_label(label, 18, TEXT_SECONDARY)

static func style_meta(label: Label) -> void:
	_style_label(label, 14, TEXT_MUTED)

static func style_stat_label(label: Label) -> void:
	"""Style for stat value labels in the stats screen — muted key, bright value."""
	_style_label(label, 16, TEXT_SECONDARY)

static func style_value(label: Label, size: int = 28) -> void:
	_style_label(label, size, TEXT_PRIMARY)

static func style_accent_value(label: Label, size: int = 28) -> void:
	_style_label(label, size, GOLD)

static func style_success(label: Label, size: int = 22) -> void:
	_style_label(label, size, SUCCESS)

static func style_warning(label: Label, size: int = 22) -> void:
	_style_label(label, size, GOLD)

static func style_danger(label: Label, size: int = 22) -> void:
	_style_label(label, size, DANGER)

static func style_primary_button(button: BaseButton) -> void:
	_style_button(button, PRIMARY, TEXT_PRIMARY)

static func style_secondary_button(button: BaseButton) -> void:
	_style_button(button, GOLD, TEXT_PRIMARY)

static func style_success_button(button: BaseButton) -> void:
	_style_button(button, SUCCESS, TEXT_PRIMARY)

static func style_muted_button(button: BaseButton) -> void:
	_style_button(button, TEXT_SECONDARY, TEXT_PRIMARY)

static func style_danger_button(button: BaseButton) -> void:
	_style_button(button, DANGER, TEXT_PRIMARY)

static func style_option_button(option_button: OptionButton, accent: Color = PRIMARY) -> void:
	_style_button(option_button, accent, TEXT_PRIMARY)

static func _style_label(label: Label, size: int, color: Color) -> void:
	if not label:
		return
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)

static func _style_button(button: BaseButton, accent: Color, hover_color: Color) -> void:
	if not button:
		return
	button.add_theme_color_override("font_color", accent)
	button.add_theme_color_override("font_hover_color", hover_color)
	button.add_theme_color_override("font_pressed_color", hover_color)

static func _make_panel_style(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.draw_center = true
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	style.content_margin_left = 10
	style.content_margin_top = 8
	style.content_margin_right = 10
	style.content_margin_bottom = 8
	return style

static func _make_button_style(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := _make_panel_style(bg, border, radius)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

static func _make_tab_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := _make_button_style(bg, border, 4)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

static func _make_focus_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = color
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	style.expand_margin_left = 2
	style.expand_margin_top = 2
	style.expand_margin_right = 2
	style.expand_margin_bottom = 2
	return style

static func _make_line_style(color: Color, thickness: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 1
	style.corner_radius_top_right = 1
	style.corner_radius_bottom_right = 1
	style.corner_radius_bottom_left = 1
	style.content_margin_left = 0
	style.content_margin_top = thickness
	style.content_margin_right = 0
	style.content_margin_bottom = thickness
	return style

static func _make_grabber_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	style.content_margin_left = 8
	style.content_margin_top = 8
	style.content_margin_right = 8
	style.content_margin_bottom = 8
	return style
