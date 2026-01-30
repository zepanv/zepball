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

# Clear save button
@onready var clear_save_button = $Panel/VBoxContainer/DataSection/ClearSaveButton
@onready var confirm_dialog = $ConfirmDialog

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

	# Clear save button
	clear_save_button.pressed.connect(_on_clear_save_pressed)
	confirm_dialog.confirmed.connect(_on_clear_save_confirmed)

	# Load and apply current settings
	_load_current_settings()

func _load_current_settings():
	"""Load settings from SaveManager and update UI"""
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

func _on_sfx_volume_changed(value: float):
	"""Handle SFX volume slider"""
	SaveManager.save_audio_settings(SaveManager.get_music_volume(), value)
	_update_sfx_label(value)
	# Apply immediately
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), value)

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
