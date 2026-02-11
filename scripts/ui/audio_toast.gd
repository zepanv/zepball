extends CanvasLayer
class_name AudioToast

## AudioToast - lightweight toast UI for audio hotkey/status feedback.

const TOAST_SHOW_SECONDS = 0.9
const TOAST_FADE_SECONDS = 0.4
const TOAST_LAYER_INDEX = 100

var toast_container: PanelContainer = null
var toast_label: Label = null
var toast_tween: Tween = null

func _ready() -> void:
	layer = TOAST_LAYER_INDEX
	_init_ui()

func show_toast(text: String) -> void:
	if toast_container == null or toast_label == null:
		return
	toast_label.text = text
	toast_container.modulate = Color(1.0, 1.0, 1.0, 1.0)
	if toast_tween != null and toast_tween.is_running():
		toast_tween.kill()
	toast_tween = create_tween()
	toast_tween.tween_interval(TOAST_SHOW_SECONDS)
	toast_tween.tween_property(toast_container, "modulate:a", 0.0, TOAST_FADE_SECONDS)

func _init_ui() -> void:
	toast_container = PanelContainer.new()
	toast_container.modulate = Color(1.0, 1.0, 1.0, 0.0)
	toast_container.anchor_left = 0.5
	toast_container.anchor_right = 0.5
	toast_container.anchor_top = 0.0
	toast_container.anchor_bottom = 0.0
	toast_container.offset_left = -220.0
	toast_container.offset_right = 220.0
	toast_container.offset_top = 18.0
	toast_container.offset_bottom = 58.0
	add_child(toast_container)

	toast_label = Label.new()
	toast_label.anchor_left = 0.0
	toast_label.anchor_top = 0.0
	toast_label.anchor_right = 1.0
	toast_label.anchor_bottom = 1.0
	toast_label.offset_left = 8.0
	toast_label.offset_right = -8.0
	toast_label.offset_top = 4.0
	toast_label.offset_bottom = -4.0
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	toast_container.add_child(toast_label)
