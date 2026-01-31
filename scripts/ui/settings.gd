extends Control

## Settings Menu - Customize game options

@onready var back_button = $BackButton

# Screen shake controls
@onready var shake_off_button = $Panel/VBoxContainer/ScreenShakeSection/ShakeButtons/OffButton
@onready var shake_low_button = $Panel/VBoxContainer/ScreenShakeSection/ShakeButtons/LowButton
@onready var shake_medium_button = $Panel/VBoxContainer/ScreenShakeSection/ShakeButtons/MediumButton
@onready var shake_high_button = $Panel/VBoxContainer/ScreenShakeSection/ShakeButtons/HighButton

# Toggle controls
@onready var particles_check = $Panel/VBoxContainer/EffectsSection/ParticlesCheck
@onready var trail_check = $Panel/VBoxContainer/EffectsSection/TrailCheck

# Sensitivity slider
@onready var sensitivity_slider = $Panel/VBoxContainer/ControlsSection/SensitivitySlider
@onready var sensitivity_label = $Panel/VBoxContainer/ControlsSection/SensitivityLabel

# Audio sliders
@onready var music_slider = $Panel/VBoxContainer/AudioSection/MusicSlider
@onready var sfx_slider = $Panel/VBoxContainer/AudioSection/SFXSlider
@onready var music_label = $Panel/VBoxContainer/AudioSection/MusicLabel
@onready var sfx_label = $Panel/VBoxContainer/AudioSection/SFXLabel
@onready var music_mode_label = $Panel/VBoxContainer/AudioSection/MusicModeLabel
@onready var music_mode_option = $Panel/VBoxContainer/AudioSection/MusicModeOption
@onready var music_track_label = $Panel/VBoxContainer/AudioSection/MusicTrackLabel
@onready var music_track_option = $Panel/VBoxContainer/AudioSection/MusicTrackOption

# Clear save button
@onready var clear_save_button = $Panel/VBoxContainer/DataSection/ClearSaveButton
@onready var confirm_dialog = $ConfirmDialog

var is_loading_settings: bool = false

func _ready():
	"""Initialize settings menu with current values"""
	# Connect buttons and sliders
	back_button.pressed.connect(_on_back_pressed)

	# Screen shake buttons
	shake_off_button.pressed.connect(func(): _set_screen_shake("Off"))
	shake_low_button.pressed.connect(func(): _set_screen_shake("Low"))
	shake_medium_button.pressed.connect(func(): _set_screen_shake("Medium"))
	shake_high_button.pressed.connect(func(): _set_screen_shake("High"))

	# Effect toggles
	particles_check.toggled.connect(_on_particles_toggled)
	trail_check.toggled.connect(_on_trail_toggled)

	# Sensitivity slider
	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)

	# Audio sliders
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	music_mode_option.item_selected.connect(_on_music_mode_selected)
	music_track_option.item_selected.connect(_on_music_track_selected)
	if AudioManager.music_volume_changed.is_connected(_on_music_volume_external_changed) == false:
		AudioManager.music_volume_changed.connect(_on_music_volume_external_changed)

	# Clear save button
	clear_save_button.pressed.connect(_on_clear_save_pressed)
	confirm_dialog.confirmed.connect(_on_clear_save_confirmed)

	# Load and apply current settings
	_load_current_settings()

func _load_current_settings():
	"""Load settings from SaveManager and update UI"""
	is_loading_settings = true
	# Screen shake intensity
	var shake_intensity = SaveManager.get_screen_shake_intensity()
	_update_shake_buttons(shake_intensity)

	# Particle effects
	particles_check.button_pressed = SaveManager.get_particle_effects()

	# Ball trail
	trail_check.button_pressed = SaveManager.get_ball_trail()

	# Paddle sensitivity
	var sensitivity = SaveManager.get_paddle_sensitivity()
	sensitivity_slider.value = sensitivity
	_update_sensitivity_label(sensitivity)

	# Audio volumes
	var music_volume = SaveManager.get_music_volume()
	var sfx_volume = SaveManager.get_sfx_volume()
	music_slider.value = music_volume
	sfx_slider.value = sfx_volume
	_update_music_label(music_volume)
	_update_sfx_label(sfx_volume)

	# Music mode + track
	_populate_music_mode_options()
	_populate_music_track_options()
	_set_music_mode_selection(SaveManager.get_music_playback_mode())
	_set_music_track_selection(SaveManager.get_music_track_id())
	_update_music_track_visibility()
	is_loading_settings = false

func _set_screen_shake(intensity: String):
	"""Set screen shake intensity"""
	SaveManager.save_screen_shake_intensity(intensity)
	_update_shake_buttons(intensity)
	print("Screen shake set to: ", intensity)

func _update_shake_buttons(intensity: String):
	"""Update button highlights based on selected intensity"""
	shake_off_button.modulate = Color.WHITE if intensity == "Off" else Color(0.6, 0.6, 0.6)
	shake_low_button.modulate = Color.WHITE if intensity == "Low" else Color(0.6, 0.6, 0.6)
	shake_medium_button.modulate = Color.WHITE if intensity == "Medium" else Color(0.6, 0.6, 0.6)
	shake_high_button.modulate = Color.WHITE if intensity == "High" else Color(0.6, 0.6, 0.6)

func _on_particles_toggled(enabled: bool):
	"""Handle particle effects toggle"""
	SaveManager.save_particle_effects(enabled)
	print("Particle effects: ", "On" if enabled else "Off")

func _on_trail_toggled(enabled: bool):
	"""Handle ball trail toggle"""
	SaveManager.save_ball_trail(enabled)
	print("Ball trail: ", "On" if enabled else "Off")

func _on_sensitivity_changed(value: float):
	"""Handle paddle sensitivity slider"""
	SaveManager.save_paddle_sensitivity(value)
	_update_sensitivity_label(value)

func _update_sensitivity_label(value: float):
	"""Update sensitivity display label"""
	sensitivity_label.text = "Paddle Sensitivity: " + str(snapped(value, 0.1)) + "x"

func _on_music_volume_changed(value: float):
	"""Handle music volume slider"""
	SaveManager.save_audio_settings(value, SaveManager.get_sfx_volume())
	_update_music_label(value)
	# Apply immediately
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), value)
	AudioManager.music_volume_changed.emit(value)

func _on_sfx_volume_changed(value: float):
	"""Handle SFX volume slider"""
	SaveManager.save_audio_settings(SaveManager.get_music_volume(), value)
	_update_sfx_label(value)
	# Apply immediately
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), value)

func _on_music_volume_external_changed(value: float) -> void:
	if is_loading_settings:
		return
	music_slider.set_value_no_signal(value)
	_update_music_label(value)

func _populate_music_mode_options():
	music_mode_option.clear()
	for mode in AudioManager.get_music_mode_options():
		music_mode_option.add_item(AudioManager.get_music_mode_label(mode))
		var index = music_mode_option.get_item_count() - 1
		music_mode_option.set_item_metadata(index, mode)

func _populate_music_track_options():
	music_track_option.clear()
	for track_id in AudioManager.get_music_track_ids():
		music_track_option.add_item(track_id)
		var index = music_track_option.get_item_count() - 1
		music_track_option.set_item_metadata(index, track_id)

func _set_music_mode_selection(mode: String) -> void:
	for i in range(music_mode_option.get_item_count()):
		if music_mode_option.get_item_metadata(i) == mode:
			music_mode_option.select(i)
			return
	if music_mode_option.get_item_count() > 0:
		music_mode_option.select(0)

func _set_music_track_selection(track_id: String) -> void:
	if track_id == "":
		track_id = AudioManager.get_music_track_ids()[0] if AudioManager.get_music_track_ids().size() > 0 else ""
	for i in range(music_track_option.get_item_count()):
		if music_track_option.get_item_metadata(i) == track_id:
			music_track_option.select(i)
			return
	if music_track_option.get_item_count() > 0:
		music_track_option.select(0)

func _update_music_track_visibility() -> void:
	var selected_mode = _get_selected_music_mode()
	var show_track = selected_mode == AudioManager.MUSIC_MODE_LOOP_ONE and music_track_option.get_item_count() > 0
	music_track_label.visible = show_track
	music_track_option.visible = show_track

func _on_music_mode_selected(index: int) -> void:
	if is_loading_settings:
		return
	var mode = music_mode_option.get_item_metadata(index)
	SaveManager.save_music_playback_mode(mode)
	AudioManager.set_music_mode(mode)
	_update_music_track_visibility()

func _on_music_track_selected(index: int) -> void:
	if is_loading_settings:
		return
	var track_id = music_track_option.get_item_metadata(index)
	SaveManager.save_music_track_id(track_id)
	AudioManager.set_music_track(track_id)

func _get_selected_music_mode() -> String:
	var index = music_mode_option.get_selected()
	if index == -1:
		return SaveManager.get_music_playback_mode()
	var metadata = music_mode_option.get_item_metadata(index)
	return metadata if metadata != null else SaveManager.get_music_playback_mode()

func _update_music_label(value: float):
	"""Update music volume display label"""
	var percentage = int((value + 40) / 40 * 100)  # Assuming -40 to 0 dB range
	music_label.text = "Music Volume: " + str(percentage) + "%"

func _update_sfx_label(value: float):
	"""Update SFX volume display label"""
	var percentage = int((value + 40) / 40 * 100)  # Assuming -40 to 0 dB range
	sfx_label.text = "SFX Volume: " + str(percentage) + "%"

func _on_clear_save_pressed():
	"""Show confirmation dialog before clearing save"""
	confirm_dialog.popup_centered()

func _on_clear_save_confirmed():
	"""Clear all save data and return to main menu"""
	print("Clearing save data...")
	SaveManager.reset_save_data()

	# Return to main menu to refresh everything
	MenuController.show_main_menu()

func _on_back_pressed():
	"""Return to main menu"""
	MenuController.show_main_menu()
