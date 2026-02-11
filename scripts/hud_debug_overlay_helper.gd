extends RefCounted
class_name HudDebugOverlayHelper

## HudDebugOverlayHelper - Debug overlay with FPS/ball/velocity/speed/combo display extracted from hud.gd.

const DEBUG_BALL_REFRESH_INTERVAL = 0.1

var debug_overlay: PanelContainer = null
var debug_fps_label: Label = null
var debug_ball_count_label: Label = null
var debug_velocity_label: Label = null
var debug_speed_label: Label = null
var debug_combo_label: Label = null
var debug_ball_refresh_time: float = 0.0
var debug_balls_cache: Array[Node] = []
var debug_valid_balls: Array[Node] = []
var debug_last_fps: int = -1
var debug_last_ball_count: int = -1
var debug_last_velocity_x: int = 0
var debug_last_velocity_y: int = 0
var debug_last_speed: int = 0
var debug_last_combo: int = -1
var debug_last_has_main_ball: bool = false
var debug_key_handled: bool = false

func create_overlay() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	panel.position = Vector2(10, -170)
	panel.custom_minimum_size = Vector2(250, 150)
	panel.modulate.a = 0.8

	var vbox = VBoxContainer.new()
	vbox.set("theme_override_constants/separation", 5)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "DEBUG INFO (` to toggle)"
	title.set("theme_override_font_sizes/font_size", 12)
	title.set("theme_override_colors/font_color", Color(1, 1, 0, 1))
	vbox.add_child(title)

	var fps_label = Label.new()
	fps_label.name = "FPS"
	fps_label.text = "FPS: 0"
	fps_label.set("theme_override_font_sizes/font_size", 14)
	vbox.add_child(fps_label)
	debug_fps_label = fps_label

	var ball_count_label = Label.new()
	ball_count_label.name = "BallCount"
	ball_count_label.text = "Balls: 0"
	ball_count_label.set("theme_override_font_sizes/font_size", 14)
	vbox.add_child(ball_count_label)
	debug_ball_count_label = ball_count_label

	var velocity_label = Label.new()
	velocity_label.name = "Velocity"
	velocity_label.text = "Velocity: (0, 0)"
	velocity_label.set("theme_override_font_sizes/font_size", 14)
	vbox.add_child(velocity_label)
	debug_velocity_label = velocity_label

	var speed_label = Label.new()
	speed_label.name = "Speed"
	speed_label.text = "Speed: 0"
	speed_label.set("theme_override_font_sizes/font_size", 14)
	vbox.add_child(speed_label)
	debug_speed_label = speed_label

	var combo_label_debug = Label.new()
	combo_label_debug.name = "Combo"
	combo_label_debug.text = "Combo: 0"
	combo_label_debug.set("theme_override_font_sizes/font_size", 14)
	vbox.add_child(combo_label_debug)
	debug_combo_label = combo_label_debug

	debug_overlay = panel
	return panel

func handle_toggle_key(show_fps: bool) -> bool:
	"""Handle backtick key toggle. Returns the new debug_visible state."""
	if not show_fps:
		debug_key_handled = false
		if debug_overlay and debug_overlay.visible:
			debug_overlay.visible = false
		return false

	var toggled: bool = debug_overlay.visible if debug_overlay else false
	if Input.is_physical_key_pressed(KEY_QUOTELEFT) and not Input.is_key_pressed(KEY_SHIFT):
		if not debug_key_handled:
			toggled = !toggled
			if debug_overlay:
				debug_overlay.visible = toggled
			debug_key_handled = true
	else:
		debug_key_handled = false
	return toggled

func update(delta: float, game_manager: Node) -> void:
	if not debug_overlay:
		return

	debug_ball_refresh_time -= delta
	if debug_ball_refresh_time <= 0.0:
		debug_balls_cache.clear()
		for ball in PowerUpManager.get_active_balls():
			debug_balls_cache.append(ball)
		debug_ball_refresh_time = DEBUG_BALL_REFRESH_INTERVAL

	var fps: int = int(round(Engine.get_frames_per_second()))
	if debug_fps_label:
		if fps != debug_last_fps:
			debug_fps_label.text = "FPS: " + str(fps)
			debug_last_fps = fps

	debug_valid_balls.clear()
	var main_ball = null
	for ball in debug_balls_cache:
		if not is_instance_valid(ball):
			continue
		debug_valid_balls.append(ball)
		if main_ball == null and ball.is_main_ball:
			main_ball = ball
	if debug_valid_balls.size() != debug_balls_cache.size():
		debug_balls_cache.clear()
		for ball in debug_valid_balls:
			debug_balls_cache.append(ball)

	var ball_count = debug_valid_balls.size()
	if debug_ball_count_label:
		if ball_count != debug_last_ball_count:
			debug_ball_count_label.text = "Balls: " + str(ball_count)
			debug_last_ball_count = ball_count

	if main_ball and is_instance_valid(main_ball):
		var velocity_x = int(round(main_ball.velocity.x))
		var velocity_y = int(round(main_ball.velocity.y))
		var speed = int(round(main_ball.current_speed))
		if debug_velocity_label:
			if not debug_last_has_main_ball or velocity_x != debug_last_velocity_x or velocity_y != debug_last_velocity_y:
				debug_velocity_label.text = "Velocity: (%d, %d)" % [velocity_x, velocity_y]
				debug_last_velocity_x = velocity_x
				debug_last_velocity_y = velocity_y
		if debug_speed_label:
			if not debug_last_has_main_ball or speed != debug_last_speed:
				debug_speed_label.text = "Speed: %d" % speed
				debug_last_speed = speed
		debug_last_has_main_ball = true
	elif debug_last_has_main_ball:
		if debug_velocity_label:
			debug_velocity_label.text = "Velocity: (0, 0)"
		if debug_speed_label:
			debug_speed_label.text = "Speed: 0"
		debug_last_velocity_x = 0
		debug_last_velocity_y = 0
		debug_last_speed = 0
		debug_last_has_main_ball = false

	if game_manager:
		if debug_combo_label:
			var combo = int(game_manager.combo)
			if combo != debug_last_combo:
				debug_combo_label.text = "Combo: " + str(combo)
				debug_last_combo = combo
