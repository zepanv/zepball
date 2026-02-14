extends Control

signal closed

const ACTION_LABELS = {
	"move_up": "Move Up",
	"move_down": "Move Down",
	"launch_ball": "Launch Ball",
	"restart_game": "Restart Level",
	"ui_cancel": "Pause / Back",
	"audio_volume_down": "Music Volume Down",
	"audio_volume_up": "Music Volume Up",
	"audio_prev_track": "Previous Track",
	"audio_next_track": "Next Track",
	"audio_toggle_pause": "Music Pause/Play"
}

@onready var bindings_list: VBoxContainer = $Panel/VBoxContainer/Scroll/BindingsList
@onready var hint_label: Label = $Panel/VBoxContainer/HintLabel
@onready var reset_button: Button = $Panel/VBoxContainer/ButtonRow/ResetButton
@onready var back_button: Button = $Panel/VBoxContainer/ButtonRow/BackButton

var waiting_action: String = ""
var waiting_button: Button = null
var waiting_input_type: String = ""  # "keyboard" or "controller"
var action_buttons: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE  # Don't let the menu itself be focusable, only its buttons

	# Set high z_index to ensure we're on top
	z_index = 1000

	reset_button.pressed.connect(_on_reset_pressed)
	back_button.pressed.connect(_on_back_pressed)
	_build_column_headers()
	_build_bindings_list()
	_update_hint("Select a binding to reassign")

	# Disable focus on settings menu controls behind this overlay
	_disable_background_focus()

	# Set up focus chain within the menu
	await get_tree().process_frame
	_setup_focus_chain()

	# Connect focus tracking for debugging
	_setup_focus_debug()

	# Ensure reset button gets focus for controller navigation
	reset_button.grab_focus()
	print("[Keybindings] Initial focus set to: ", reset_button.name)

func _build_column_headers() -> void:
	# Add header row with column labels
	var header_row = HBoxContainer.new()
	header_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.set("theme_override_constants/separation", 12)

	var action_label = Label.new()
	action_label.text = "Action"
	action_label.custom_minimum_size = Vector2(180, 0)
	action_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_label.add_theme_font_size_override("font_size", 18)
	header_row.add_child(action_label)

	var kb_label = Label.new()
	kb_label.text = "Keyboard/Mouse"
	kb_label.custom_minimum_size = Vector2(160, 0)
	kb_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kb_label.add_theme_font_size_override("font_size", 18)
	header_row.add_child(kb_label)

	var ctrl_label = Label.new()
	ctrl_label.text = "Controller"
	ctrl_label.custom_minimum_size = Vector2(160, 0)
	ctrl_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ctrl_label.add_theme_font_size_override("font_size", 18)
	header_row.add_child(ctrl_label)

	bindings_list.add_child(header_row)

func _build_bindings_list() -> void:
	# Clear all children except the header row (first child)
	var children = bindings_list.get_children()
	for i in range(1, children.size()):
		children[i].queue_free()
	action_buttons.clear()

	for action in SaveManager.get_rebind_actions():
		var row = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.set("theme_override_constants/separation", 12)

		var label = Label.new()
		label.text = ACTION_LABELS.get(action, action)
		label.custom_minimum_size = Vector2(180, 0)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)

		# Keyboard binding button
		var kb_button = Button.new()
		kb_button.custom_minimum_size = Vector2(160, 40)
		kb_button.text = _get_keyboard_text(action)
		kb_button.pressed.connect(_on_rebind_pressed.bind(action, kb_button, "keyboard"))
		row.add_child(kb_button)

		# Controller binding button
		var ctrl_button = Button.new()
		ctrl_button.custom_minimum_size = Vector2(160, 40)
		ctrl_button.text = _get_controller_text(action)
		ctrl_button.pressed.connect(_on_rebind_pressed.bind(action, ctrl_button, "controller"))
		row.add_child(ctrl_button)

		bindings_list.add_child(row)
		action_buttons[action] = {"keyboard": kb_button, "controller": ctrl_button}

func _get_action_text(action: String) -> String:
	if not InputMap.has_action(action):
		return "Unbound"
	var events = InputMap.action_get_events(action)
	if events.is_empty():
		return "Unbound"
	var parts: Array = []
	for event in events:
		parts.append(event.as_text())
	return " / ".join(parts)

func _get_keyboard_text(action: String) -> String:
	if not InputMap.has_action(action):
		return "Unbound"
	var events = InputMap.action_get_events(action)
	var parts: Array = []
	for event in events:
		if event is InputEventKey or event is InputEventMouseButton:
			var text = event.as_text()
			# Clean up the text for better readability
			text = text.replace(" (Physical)", "")
			parts.append(text)
	if parts.is_empty():
		return "Unbound"
	return " / ".join(parts)

func _get_controller_text(action: String) -> String:
	if not InputMap.has_action(action):
		return "Unbound"
	var events = InputMap.action_get_events(action)
	var parts: Array[String] = []
	for event in events:
		# Check class name to ensure we're catching joypad events
		var event_class = event.get_class()
		if event_class == "InputEventJoypadButton":
			var joypad_event = event as InputEventJoypadButton
			parts.append(_format_joypad_button(joypad_event.button_index))
		elif event_class == "InputEventJoypadMotion":
			var motion_event = event as InputEventJoypadMotion
			parts.append(_format_joypad_motion(motion_event.axis, motion_event.axis_value))
	if parts.is_empty():
		return "Unbound"
	return " / ".join(parts)

func _format_joypad_button(button_index: int) -> String:
	match button_index:
		0: return "A/Cross"
		1: return "B/Circle"
		2: return "X/Square"
		3: return "Y/Triangle"
		4: return "LB/L1"
		5: return "RB/R1"
		6: return "Back/Select"
		7: return "Start"
		8: return "L3"
		9: return "R3"
		10: return "L3"
		11: return "D-Up"
		12: return "D-Down"
		13: return "D-Left"
		14: return "D-Right"
		_: return "Button " + str(button_index)

func _format_joypad_motion(axis: int, value: float) -> String:
	var direction = "+" if value > 0 else "-"
	match axis:
		0: return "Left Stick " + ("Right" if value > 0 else "Left")
		1: return "Left Stick " + ("Down" if value > 0 else "Up")
		2: return "Right Stick " + ("Right" if value > 0 else "Left")
		3: return "Right Stick " + ("Down" if value > 0 else "Up")
		_: return "Axis " + str(axis) + direction

func _on_rebind_pressed(action: String, button: Button, input_type: String) -> void:
	if waiting_action != "":
		return
	waiting_action = action
	waiting_button = button
	waiting_input_type = input_type
	if input_type == "keyboard":
		button.text = "Press a key..."
		_update_hint("Press a key or mouse button")
	else:
		button.text = "Press a button..."
		_update_hint("Press a controller button or move analog stick")

func _process(_delta: float) -> void:
	"""Track focus changes for debugging"""
	var focused = get_viewport().gui_get_focus_owner()
	if focused != _last_focused:
		_last_focused = focused
		if focused:
			print("[Keybindings] Focus changed to: ", focused.name if focused.has_method("get_name") else str(focused))
			print("  - Is in keybindings menu: ", _is_control_in_menu(focused))
			print("  - Focus mode: ", focused.focus_mode if focused is Control else "N/A")
		else:
			print("[Keybindings] Focus lost (null)")

var _last_focused: Control = null

func _is_control_in_menu(control: Control) -> bool:
	"""Check if a control is part of the keybindings menu"""
	var current = control
	while current:
		if current == self:
			return true
		current = current.get_parent() as Control
	return false

func _unhandled_input(event: InputEvent) -> void:
	# Debug controller navigation
	if event is InputEventJoypadButton and event.pressed:
		var button_name = "Unknown"
		match event.button_index:
			0: button_name = "A"
			1: button_name = "B"
			11: button_name = "D-Up"
			12: button_name = "D-Down"
			13: button_name = "D-Left"
			14: button_name = "D-Right"
		print("[Keybindings Input] Joypad button pressed: ", button_name, " (", event.button_index, ")")
		var focused = get_viewport().gui_get_focus_owner()
		if focused:
			print("  - Current focus: ", focused.name if focused.has_method("get_name") else str(focused))
	elif event is InputEventJoypadMotion and abs(event.axis_value) > 0.5:
		var axis_name = "Unknown"
		var direction = "+" if event.axis_value > 0 else "-"
		match event.axis:
			0: axis_name = "Left Stick X"
			1: axis_name = "Left Stick Y"
		print("[Keybindings Input] Joypad motion: ", axis_name, " ", direction, " (", event.axis, ")")

	# Original input handling below
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE and waiting_action == "":
			_on_back_pressed()
			accept_event()
			return
		if event.keycode == KEY_ESCAPE:
			_cancel_rebind()
			accept_event()
			return

	# When waiting for rebind
	if waiting_action != "":
		# Handle keyboard/mouse rebinding
		if waiting_input_type == "keyboard":
			if event is InputEventKey and event.pressed and not event.echo:
				_apply_binding(event)
				accept_event()
				return
			if event is InputEventMouseButton and event.pressed:
				_apply_binding(event)
				accept_event()
				return

		# Handle controller rebinding
		elif waiting_input_type == "controller":
			if event is InputEventJoypadButton and event.pressed:
				_apply_binding(event)
				accept_event()
				return
			if event is InputEventJoypadMotion:
				# Only register significant analog stick movement
				if abs(event.axis_value) > 0.5:
					_apply_binding(event)
					accept_event()
					return
	else:
		# When not waiting for rebind, handle ui_cancel to close menu
		if event.is_action_pressed("ui_cancel"):
			_on_back_pressed()
			accept_event()
			return

func _apply_binding(event: InputEvent) -> void:
	if waiting_action == "":
		return

	var preserved: Array = []
	var is_keyboard_event = event is InputEventKey or event is InputEventMouseButton
	var is_controller_event = event is InputEventJoypadButton or event is InputEventJoypadMotion

	# Preserve events of the opposite type
	for existing in InputMap.action_get_events(waiting_action):
		var existing_is_keyboard = existing is InputEventKey or existing is InputEventMouseButton
		var existing_is_controller = existing is InputEventJoypadButton or existing is InputEventJoypadMotion

		if is_keyboard_event and existing_is_controller:
			preserved.append(existing)
		elif is_controller_event and existing_is_keyboard:
			preserved.append(existing)

	InputMap.action_erase_events(waiting_action)
	for existing in preserved:
		InputMap.action_add_event(waiting_action, existing)
	InputMap.action_add_event(waiting_action, _clone_input_event(event))

	SaveManager.save_keybindings(SaveManager.capture_keybindings())
	_refresh_action_button(waiting_action)

	waiting_action = ""
	waiting_button = null
	waiting_input_type = ""
	_update_hint("Select a binding to reassign")

func _refresh_action_button(action: String) -> void:
	if not action_buttons.has(action):
		return
	var buttons: Dictionary = action_buttons[action]
	if buttons.has("keyboard"):
		buttons["keyboard"].text = _get_keyboard_text(action)
	if buttons.has("controller"):
		buttons["controller"].text = _get_controller_text(action)

func _on_reset_pressed() -> void:
	SaveManager.reset_keybindings_to_default()
	for action in action_buttons.keys():
		_refresh_action_button(action)
	waiting_action = ""
	waiting_button = null
	_update_hint("Keybindings reset to defaults")

func _cancel_rebind() -> void:
	var action = waiting_action
	waiting_action = ""
	waiting_button = null
	waiting_input_type = ""
	_update_hint("Keybind change cancelled")
	if action != "":
		_refresh_action_button(action)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		# Ensure focus is restored when menu is destroyed
		_restore_background_focus()

func _on_back_pressed() -> void:
	# Re-enable focus on settings menu before closing
	_restore_background_focus()
	closed.emit()
	queue_free()

func _update_hint(text: String) -> void:
	hint_label.text = text

var disabled_controls: Array[Control] = []

func _disable_background_focus() -> void:
	"""Disable focus on all controls in the parent (settings menu) to prevent focus bleeding"""
	var parent = get_parent()
	if not parent:
		return
	disabled_controls.clear()
	_disable_focus_recursive(parent)

func _disable_focus_recursive(node: Node) -> void:
	"""Recursively disable focus on all controls except this menu"""
	for child in node.get_children():
		if child == self:
			continue
		if child is Control:
			var control = child as Control
			if control.focus_mode != Control.FOCUS_NONE:
				disabled_controls.append(control)
				control.focus_mode = Control.FOCUS_NONE
		_disable_focus_recursive(child)

func _restore_background_focus() -> void:
	"""Restore focus mode on previously disabled controls"""
	for control in disabled_controls:
		if control:
			control.focus_mode = Control.FOCUS_ALL
	disabled_controls.clear()

func _setup_focus_debug() -> void:
	"""Set up debug logging for focus events"""
	reset_button.focus_entered.connect(func(): print("[Keybindings] Focus entered: Reset Button"))
	reset_button.focus_exited.connect(func(): print("[Keybindings] Focus exited: Reset Button"))
	back_button.focus_entered.connect(func(): print("[Keybindings] Focus entered: Back Button"))
	back_button.focus_exited.connect(func(): print("[Keybindings] Focus exited: Back Button"))

	for action in action_buttons.keys():
		var buttons: Dictionary = action_buttons[action]
		if buttons.has("keyboard") and buttons["keyboard"]:
			var kb = buttons["keyboard"]
			var action_name = action
			kb.focus_entered.connect(func(): print("[Keybindings] Focus entered: ", action_name, " (Keyboard)"))
			kb.focus_exited.connect(func(): print("[Keybindings] Focus exited: ", action_name, " (Keyboard)"))
		if buttons.has("controller") and buttons["controller"]:
			var ctrl = buttons["controller"]
			var action_name = action
			ctrl.focus_entered.connect(func(): print("[Keybindings] Focus entered: ", action_name, " (Controller)"))
			ctrl.focus_exited.connect(func(): print("[Keybindings] Focus exited: ", action_name, " (Controller)"))

func _setup_focus_chain() -> void:
	"""Set up explicit focus neighbor chain to keep focus within the menu"""
	# Collect all focusable controls in order: reset_button, back_button, then all rebind buttons
	var focusable: Array[Control] = []
	focusable.append(reset_button)
	focusable.append(back_button)

	# Add all rebind buttons from the bindings list
	for action in action_buttons.keys():
		var buttons: Dictionary = action_buttons[action]
		if buttons.has("keyboard") and buttons["keyboard"]:
			focusable.append(buttons["keyboard"])
		if buttons.has("controller") and buttons["controller"]:
			focusable.append(buttons["controller"])

	# Set up vertical focus chain (up/down navigation)
	for i in range(focusable.size()):
		var current = focusable[i]
		var prev_index = (i - 1 + focusable.size()) % focusable.size()
		var next_index = (i + 1) % focusable.size()

		current.focus_neighbor_top = current.get_path_to(focusable[prev_index])
		current.focus_neighbor_bottom = current.get_path_to(focusable[next_index])
		current.focus_previous = current.get_path_to(focusable[prev_index])
		current.focus_next = current.get_path_to(focusable[next_index])

	# Set up horizontal focus between Reset and Back buttons
	reset_button.focus_neighbor_right = reset_button.get_path_to(back_button)
	back_button.focus_neighbor_left = back_button.get_path_to(reset_button)
	# Don't allow going left from Reset or right from Back
	reset_button.focus_neighbor_left = reset_button.get_path_to(reset_button)  # Loop to self
	back_button.focus_neighbor_right = back_button.get_path_to(back_button)  # Loop to self

	# Set up horizontal focus within rows (for keyboard/controller button pairs)
	for action in action_buttons.keys():
		var buttons: Dictionary = action_buttons[action]
		if buttons.has("keyboard") and buttons.has("controller"):
			var kb = buttons["keyboard"]
			var ctrl = buttons["controller"]
			if kb and ctrl:
				kb.focus_neighbor_right = kb.get_path_to(ctrl)
				ctrl.focus_neighbor_left = ctrl.get_path_to(kb)
				# Loop to self when going beyond the bounds
				kb.focus_neighbor_left = kb.get_path_to(kb)
				ctrl.focus_neighbor_right = ctrl.get_path_to(ctrl)

func _clone_input_event(event: InputEvent) -> InputEvent:
	if event is InputEventKey:
		var key_event := InputEventKey.new()
		key_event.keycode = event.keycode
		key_event.physical_keycode = event.physical_keycode
		key_event.shift_pressed = event.shift_pressed
		key_event.alt_pressed = event.alt_pressed
		key_event.ctrl_pressed = event.ctrl_pressed
		key_event.meta_pressed = event.meta_pressed
		key_event.pressed = false
		key_event.echo = false
		return key_event
	if event is InputEventMouseButton:
		var mouse_event := InputEventMouseButton.new()
		mouse_event.button_index = event.button_index
		mouse_event.pressed = false
		return mouse_event
	if event is InputEventJoypadButton:
		var joypad_event := InputEventJoypadButton.new()
		joypad_event.button_index = event.button_index
		joypad_event.pressed = true
		return joypad_event
	if event is InputEventJoypadMotion:
		var motion_event := InputEventJoypadMotion.new()
		motion_event.axis = event.axis
		motion_event.axis_value = event.axis_value
		return motion_event
	return event
