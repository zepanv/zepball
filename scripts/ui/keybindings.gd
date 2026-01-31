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
var action_buttons: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	reset_button.pressed.connect(_on_reset_pressed)
	back_button.pressed.connect(_on_back_pressed)
	_build_bindings_list()
	_update_hint("Select a binding to reassign")

func _build_bindings_list() -> void:
	for child in bindings_list.get_children():
		child.queue_free()
	action_buttons.clear()

	for action in SaveManager.get_rebind_actions():
		var row = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.set("theme_override_constants/separation", 12)

		var label = Label.new()
		label.text = ACTION_LABELS.get(action, action)
		label.custom_minimum_size = Vector2(260, 0)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)

		var button = Button.new()
		button.custom_minimum_size = Vector2(220, 40)
		button.text = _get_action_text(action)
		button.pressed.connect(_on_rebind_pressed.bind(action, button))
		row.add_child(button)

		bindings_list.add_child(row)
		action_buttons[action] = button

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

func _on_rebind_pressed(action: String, button: Button) -> void:
	if waiting_action != "":
		return
	waiting_action = action
	waiting_button = button
	button.text = "Press a key..."
	_update_hint("Press a key or mouse button")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE and waiting_action == "":
			_on_back_pressed()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_ESCAPE:
			_cancel_rebind()
			get_viewport().set_input_as_handled()
			return
	if waiting_action == "":
		return
	if event is InputEventKey and event.pressed and not event.echo:
		_apply_binding(event)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed:
		_apply_binding(event)
		get_viewport().set_input_as_handled()
		return

func _apply_binding(event: InputEvent) -> void:
	if waiting_action == "":
		return

	var preserved: Array = []
	for existing in InputMap.action_get_events(waiting_action):
		if event is InputEventKey and not (existing is InputEventKey):
			preserved.append(existing)
		elif event is InputEventMouseButton and not (existing is InputEventMouseButton):
			preserved.append(existing)

	InputMap.action_erase_events(waiting_action)
	for existing in preserved:
		InputMap.action_add_event(waiting_action, existing)
	InputMap.action_add_event(waiting_action, _clone_input_event(event))

	SaveManager.save_keybindings(SaveManager.capture_keybindings())
	_refresh_action_button(waiting_action)

	waiting_action = ""
	waiting_button = null
	_update_hint("Select a binding to reassign")

func _refresh_action_button(action: String) -> void:
	if not action_buttons.has(action):
		return
	var button: Button = action_buttons[action]
	button.text = _get_action_text(action)

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
	_update_hint("Keybind change cancelled")
	if action != "":
		_refresh_action_button(action)

func _on_back_pressed() -> void:
	closed.emit()
	queue_free()

func _update_hint(text: String) -> void:
	hint_label.text = text

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
	return event
