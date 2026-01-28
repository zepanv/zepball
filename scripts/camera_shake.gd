extends Camera2D

## Camera Shake Utility
## Provides screen shake effects for game events
## Usage: CameraShake.shake(intensity, duration)

var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var shake_timer: float = 0.0
var original_offset: Vector2 = Vector2.ZERO

func _ready():
	# Store original offset
	original_offset = offset

func _process(delta):
	if shake_timer > 0:
		shake_timer -= delta

		# Calculate shake offset
		var shake_x = randf_range(-shake_intensity, shake_intensity)
		var shake_y = randf_range(-shake_intensity, shake_intensity)
		offset = original_offset + Vector2(shake_x, shake_y)

		# Gradually reduce intensity
		shake_intensity = lerp(shake_intensity, 0.0, delta * 5.0)
	else:
		# Reset to original offset when shake complete
		offset = original_offset
		shake_intensity = 0.0

func shake(intensity: float, duration: float):
	"""Trigger a screen shake effect
	intensity: How far the camera shakes (pixels)
	duration: How long the shake lasts (seconds)
	"""
	shake_intensity = intensity
	shake_duration = duration
	shake_timer = duration
