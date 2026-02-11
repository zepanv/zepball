extends RefCounted
class_name HudPowerUpTimersHelper

## HudPowerUpTimersHelper - Power-up indicator creation, timer updates, removal extracted from hud.gd.

const POWERUP_TIMER_REFRESH_INTERVAL = 0.1

var powerup_indicators: Array[Control] = []
var powerup_timer_refresh_time: float = 0.0

func create_indicator(type: int) -> Control:
	var indicator = PanelContainer.new()
	indicator.set_meta("powerup_type", type)
	indicator.custom_minimum_size = Vector2(120, 40)

	var hbox = HBoxContainer.new()
	indicator.add_child(hbox)

	var name_label = Label.new()
	match type:
		0:  # EXPAND
			name_label.text = "BIG PADDLE"
			name_label.modulate = Color(0.3, 0.8, 0.3)
		1:  # CONTRACT
			name_label.text = "SMALL PADDLE"
			name_label.modulate = Color(0.8, 0.3, 0.3)
		2:  # SPEED_UP
			name_label.text = "FAST BALL"
			name_label.modulate = Color(1.0, 0.8, 0.3)
		4:  # BIG_BALL
			name_label.text = "BIG BALL"
			name_label.modulate = Color(0.3, 0.8, 0.3)
		5:  # SMALL_BALL
			name_label.text = "SMALL BALL"
			name_label.modulate = Color(0.8, 0.3, 0.3)
		6:  # SLOW_DOWN
			name_label.text = "SLOW BALL"
			name_label.modulate = Color(0.3, 0.6, 1.0)
		7:  # EXTRA_LIFE
			name_label.text = "EXTRA LIFE"
			name_label.modulate = Color(0.3, 0.8, 0.3)
		8:  # GRAB
			name_label.text = "GRAB"
			name_label.modulate = Color(0.3, 0.8, 0.3)
		9:  # BRICK_THROUGH
			name_label.text = "BRICK THROUGH"
			name_label.modulate = Color(0.3, 0.8, 0.3)
		10:  # DOUBLE_SCORE
			name_label.text = "DOUBLE SCORE"
			name_label.modulate = Color(1.0, 0.8, 0.0)
		11:  # MYSTERY
			name_label.text = "MYSTERY"
			name_label.modulate = Color(1.0, 1.0, 0.3)
		12:  # BOMB_BALL
			name_label.text = "BOMB BALL"
			name_label.modulate = Color(1.0, 0.4, 0.1)
		13:  # AIR_BALL
			name_label.text = "AIR BALL"
			name_label.modulate = Color(0.3, 0.8, 0.3)
		14:  # MAGNET
			name_label.text = "MAGNET"
			name_label.modulate = Color(0.3, 0.8, 0.3)
		15:  # BLOCK
			name_label.text = "BLOCK"
			name_label.modulate = Color(0.3, 0.8, 0.3)

	name_label.add_theme_font_size_override("font_size", 14)
	hbox.add_child(name_label)

	var timer_label = Label.new()
	timer_label.name = "TimerLabel"
	timer_label.add_theme_font_size_override("font_size", 14)
	hbox.add_child(timer_label)
	indicator.set_meta("timer_label", timer_label)

	return indicator

func on_effect_applied(type: int, powerup_container: VBoxContainer) -> void:
	if not powerup_container:
		return
	on_effect_expired(type, powerup_container)
	var indicator = create_indicator(type)
	if indicator:
		powerup_container.add_child(indicator)
		powerup_indicators.append(indicator)
		_update_single_timer(indicator, type)

func on_effect_expired(type: int, powerup_container: VBoxContainer) -> void:
	if not powerup_container:
		return
	for i in range(powerup_indicators.size() - 1, -1, -1):
		var child = powerup_indicators[i]
		if not child or not is_instance_valid(child):
			powerup_indicators.remove_at(i)
			continue
		if child.has_meta("powerup_type") and int(child.get_meta("powerup_type")) == type:
			powerup_indicators.remove_at(i)
			child.queue_free()

func update_timers(delta: float) -> void:
	if powerup_indicators.is_empty():
		return
	powerup_timer_refresh_time -= delta
	if powerup_timer_refresh_time <= 0.0:
		_update_all_timers()
		powerup_timer_refresh_time = POWERUP_TIMER_REFRESH_INTERVAL

func _update_all_timers() -> void:
	for i in range(powerup_indicators.size() - 1, -1, -1):
		var child = powerup_indicators[i]
		if not child or not is_instance_valid(child):
			powerup_indicators.remove_at(i)
			continue
		if child.has_meta("powerup_type"):
			var type = int(child.get_meta("powerup_type"))
			_update_single_timer(child, type)

func _update_single_timer(indicator: Node, type: int) -> void:
	if not indicator:
		return
	var timer_label: Label = indicator.get_meta("timer_label", null)
	if not timer_label:
		return
	var time_remaining = PowerUpManager.get_time_remaining(type)
	timer_label.text = " %.1fs" % time_remaining
