extends RefCounted
class_name SaveSettingsHelper

## SaveSettingsHelper - Audio, gameplay, and keybinding settings extracted from save_manager.gd.

const DEFAULT_SETTINGS = {
	"difficulty": "Normal",
	"music_volume_db": 0.0,
	"sfx_volume_db": 0.0,
	"music_playback_mode": "loop_all",
	"music_track_id": "",
	"screen_shake_intensity": "Medium",
	"particle_effects_enabled": true,
	"ball_trail_enabled": true,
	"paddle_sensitivity": 1.0,
	"combo_flash_enabled": false,
	"skip_level_intro": false,
	"show_fps": false,
	"keybindings": {}
}

const REBIND_ACTIONS = [
	"move_up",
	"move_down",
	"launch_ball",
	"restart_game",
	"audio_volume_down",
	"audio_volume_up",
	"audio_prev_track",
	"audio_next_track",
	"audio_toggle_pause"
]

var default_keybindings: Dictionary = {}

# ============================================================================
# DIFFICULTY
# ============================================================================

func save_difficulty(save_data: Dictionary, save_to_disk: Callable, difficulty_name: String) -> void:
	save_data["settings"]["difficulty"] = difficulty_name
	save_to_disk.call()

func get_saved_difficulty(save_data: Dictionary) -> String:
	return save_data["settings"]["difficulty"]

# ============================================================================
# AUDIO
# ============================================================================

func save_audio_settings(save_data: Dictionary, save_to_disk: Callable, music_volume_db: float, sfx_volume_db: float) -> void:
	save_data["settings"]["music_volume_db"] = music_volume_db
	save_data["settings"]["sfx_volume_db"] = sfx_volume_db
	save_to_disk.call()

func get_music_volume(save_data: Dictionary) -> float:
	return save_data["settings"]["music_volume_db"]

func get_sfx_volume(save_data: Dictionary) -> float:
	return save_data["settings"]["sfx_volume_db"]

func save_music_playback_mode(save_data: Dictionary, save_to_disk: Callable, mode: String) -> void:
	if mode not in ["off", "loop_one", "loop_all", "shuffle"]:
		push_warning("Invalid music playback mode: " + mode)
		return
	save_data["settings"]["music_playback_mode"] = mode
	save_to_disk.call()

func get_music_playback_mode(save_data: Dictionary) -> String:
	return save_data["settings"].get("music_playback_mode", "loop_all")

func save_music_track_id(save_data: Dictionary, save_to_disk: Callable, track_id: String) -> void:
	save_data["settings"]["music_track_id"] = track_id
	save_to_disk.call()

func get_music_track_id(save_data: Dictionary) -> String:
	return save_data["settings"].get("music_track_id", "")

# ============================================================================
# GAMEPLAY SETTINGS
# ============================================================================

func save_screen_shake_intensity(save_data: Dictionary, save_to_disk: Callable, intensity: String) -> void:
	if intensity not in ["Off", "Low", "Medium", "High"]:
		push_warning("Invalid screen shake intensity: " + intensity)
		return
	save_data["settings"]["screen_shake_intensity"] = intensity
	save_to_disk.call()

func get_screen_shake_intensity(save_data: Dictionary) -> String:
	return save_data["settings"].get("screen_shake_intensity", "Medium")

func save_particle_effects(save_data: Dictionary, save_to_disk: Callable, enabled: bool) -> void:
	save_data["settings"]["particle_effects_enabled"] = enabled
	save_to_disk.call()

func get_particle_effects(save_data: Dictionary) -> bool:
	return save_data["settings"].get("particle_effects_enabled", true)

func save_ball_trail(save_data: Dictionary, save_to_disk: Callable, enabled: bool) -> void:
	save_data["settings"]["ball_trail_enabled"] = enabled
	save_to_disk.call()

func get_ball_trail(save_data: Dictionary) -> bool:
	return save_data["settings"].get("ball_trail_enabled", true)

func save_combo_flash_enabled(save_data: Dictionary, save_to_disk: Callable, enabled: bool) -> void:
	save_data["settings"]["combo_flash_enabled"] = enabled
	save_to_disk.call()

func get_combo_flash_enabled(save_data: Dictionary) -> bool:
	return save_data["settings"].get("combo_flash_enabled", false)

func save_skip_level_intro(save_data: Dictionary, save_to_disk: Callable, enabled: bool) -> void:
	save_data["settings"]["skip_level_intro"] = enabled
	save_to_disk.call()

func get_skip_level_intro(save_data: Dictionary) -> bool:
	return save_data["settings"].get("skip_level_intro", false)

func save_show_fps(save_data: Dictionary, save_to_disk: Callable, enabled: bool) -> void:
	save_data["settings"]["show_fps"] = enabled
	save_to_disk.call()

func get_show_fps(save_data: Dictionary) -> bool:
	return save_data["settings"].get("show_fps", false)

func save_paddle_sensitivity(save_data: Dictionary, save_to_disk: Callable, sensitivity: float) -> void:
	sensitivity = clampf(sensitivity, 0.5, 2.0)
	save_data["settings"]["paddle_sensitivity"] = sensitivity
	save_to_disk.call()

func get_paddle_sensitivity(save_data: Dictionary) -> float:
	return save_data["settings"].get("paddle_sensitivity", 1.0)

# ============================================================================
# KEYBINDINGS
# ============================================================================

func capture_default_keybindings() -> void:
	default_keybindings = capture_keybindings(REBIND_ACTIONS)

func get_rebind_actions() -> Array:
	return REBIND_ACTIONS.duplicate()

func capture_keybindings(actions: Array) -> Dictionary:
	var bindings := {}
	for action in actions:
		if not InputMap.has_action(action):
			continue
		var events = InputMap.action_get_events(action)
		var serialized_events: Array = []
		for event in events:
			var serialized = _serialize_input_event(event)
			if serialized.size() > 0:
				serialized_events.append(serialized)
		bindings[action] = serialized_events
	return bindings

func save_keybindings(save_data: Dictionary, save_to_disk: Callable, keybindings: Dictionary) -> void:
	save_data["settings"]["keybindings"] = keybindings.duplicate(true)
	save_to_disk.call()

func get_keybindings(save_data: Dictionary) -> Dictionary:
	var saved = save_data["settings"].get("keybindings", {})
	if saved.is_empty():
		return capture_keybindings(REBIND_ACTIONS)
	return saved

func apply_keybindings(keybindings: Dictionary) -> void:
	for action in keybindings.keys():
		if not InputMap.has_action(action):
			continue
		InputMap.action_erase_events(action)
		for event_data in keybindings[action]:
			var event = _deserialize_input_event(event_data)
			if event:
				InputMap.action_add_event(action, event)

func apply_saved_keybindings(save_data: Dictionary) -> void:
	var saved = save_data["settings"].get("keybindings", {})
	if saved.is_empty():
		return
	apply_keybindings(saved)

func reset_keybindings_to_default(save_data: Dictionary, save_to_disk: Callable) -> void:
	if not default_keybindings.is_empty():
		apply_keybindings(default_keybindings)
	save_data["settings"]["keybindings"] = default_keybindings.duplicate(true)
	save_to_disk.call()

func reset_settings_to_default(save_data: Dictionary, save_to_disk: Callable) -> void:
	save_data["settings"] = DEFAULT_SETTINGS.duplicate(true)
	if not default_keybindings.is_empty():
		apply_keybindings(default_keybindings)
	save_to_disk.call()

func migrate_settings(save_data: Dictionary, save_to_disk: Callable) -> void:
	"""Migrate old saves that don't have newer settings keys."""
	var updated = false
	if not save_data["settings"].has("screen_shake_intensity"):
		save_data["settings"]["screen_shake_intensity"] = "Medium"
		updated = true
	if not save_data["settings"].has("particle_effects_enabled"):
		save_data["settings"]["particle_effects_enabled"] = true
		updated = true
	if not save_data["settings"].has("ball_trail_enabled"):
		save_data["settings"]["ball_trail_enabled"] = true
		updated = true
	if not save_data["settings"].has("paddle_sensitivity"):
		save_data["settings"]["paddle_sensitivity"] = 1.0
		updated = true
	if not save_data["settings"].has("music_playback_mode"):
		save_data["settings"]["music_playback_mode"] = "loop_all"
		updated = true
	if not save_data["settings"].has("music_track_id"):
		save_data["settings"]["music_track_id"] = ""
		updated = true
	if not save_data["settings"].has("combo_flash_enabled"):
		save_data["settings"]["combo_flash_enabled"] = false
		updated = true
	if not save_data["settings"].has("skip_level_intro"):
		save_data["settings"]["skip_level_intro"] = false
		updated = true
	if not save_data["settings"].has("show_fps"):
		save_data["settings"]["show_fps"] = false
		updated = true
	if not save_data["settings"].has("keybindings"):
		save_data["settings"]["keybindings"] = {}
		updated = true
	if updated:
		save_to_disk.call()

func _serialize_input_event(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		return {
			"type": "key",
			"keycode": event.keycode,
			"physical_keycode": event.physical_keycode,
			"shift": event.shift_pressed,
			"alt": event.alt_pressed,
			"ctrl": event.ctrl_pressed,
			"meta": event.meta_pressed
		}
	if event is InputEventMouseButton:
		return {
			"type": "mouse_button",
			"button_index": event.button_index
		}
	return {}

func _deserialize_input_event(data: Dictionary) -> InputEvent:
	if not data.has("type"):
		return null
	if data["type"] == "key":
		var event := InputEventKey.new()
		event.keycode = int(data.get("keycode", 0)) as Key
		event.physical_keycode = int(data.get("physical_keycode", 0)) as Key
		event.shift_pressed = bool(data.get("shift", false))
		event.alt_pressed = bool(data.get("alt", false))
		event.ctrl_pressed = bool(data.get("ctrl", false))
		event.meta_pressed = bool(data.get("meta", false))
		event.pressed = false
		event.echo = false
		return event
	if data["type"] == "mouse_button":
		var event := InputEventMouseButton.new()
		event.button_index = int(data.get("button_index", 0)) as MouseButton
		event.pressed = false
		return event
	return null
