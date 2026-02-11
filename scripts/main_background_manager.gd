extends RefCounted
class_name MainBackgroundManager

## MainBackgroundManager - Background setup/viewport-fit helper for main gameplay scene.

const BACKGROUND_LAYER_NAME = "BackgroundLayer"
const BACKGROUND_LAYER_INDEX = -100
const BACKGROUND_DIM_ALPHA = 0.85

const BACKGROUNDS = [
	"res://assets/graphics/backgrounds/bg_minimal_3_1769629212643.jpg",
	"res://assets/graphics/backgrounds/bg_minimal_4_1769629224923.jpg",
	"res://assets/graphics/backgrounds/bg_minimal_5_1769629238427.jpg",
	"res://assets/graphics/backgrounds/bg_refined_1_1769629758259.jpg",
	"res://assets/graphics/backgrounds/bg_refined_2_1769629770443.jpg",
	"res://assets/graphics/backgrounds/bg_nebula_dark_1769629799342.jpg",
	"res://assets/graphics/backgrounds/bg_stars_subtle_1769629782553.jpg"
]

func setup_background(root: Node, background_node: Node) -> Control:
	if root == null or background_node == null:
		return background_node if background_node is Control else null

	var texture = _load_random_background_texture()
	if texture == null:
		return background_node if background_node is Control else null

	var background_control = _ensure_background_control(background_node, texture)
	if background_control == null:
		return null

	var background_layer = _ensure_background_layer(root)
	var old_parent = background_control.get_parent()
	if old_parent != null:
		old_parent.remove_child(background_control)
	background_layer.add_child(background_control)

	configure_background_rect(background_control, root.get_viewport())
	return background_control

func configure_background_rect(background_node: Node, viewport: Viewport) -> void:
	if viewport == null or not (background_node is Control):
		return
	var background_control = background_node as Control
	background_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	background_control.position = Vector2.ZERO
	# Use deferred size updates to avoid anchor/layout warnings.
	background_control.set_deferred("size", viewport.get_visible_rect().size)

func _load_random_background_texture() -> Texture2D:
	if BACKGROUNDS.is_empty():
		return null
	var selected_bg = BACKGROUNDS[randi() % BACKGROUNDS.size()]
	var texture = load(selected_bg)
	if texture == null:
		push_warning("Could not load background: %s" % selected_bg)
		return null
	return texture

func _ensure_background_layer(root: Node) -> CanvasLayer:
	var existing_layer = root.get_node_or_null(BACKGROUND_LAYER_NAME)
	if existing_layer is CanvasLayer:
		return existing_layer

	var background_layer = CanvasLayer.new()
	background_layer.name = BACKGROUND_LAYER_NAME
	background_layer.layer = BACKGROUND_LAYER_INDEX
	root.add_child(background_layer)
	return background_layer

func _ensure_background_control(background_node: Node, texture: Texture2D) -> Control:
	if background_node is TextureRect:
		var texture_rect = background_node as TextureRect
		_apply_background_texture(texture_rect, texture)
		return texture_rect

	if background_node is ColorRect:
		var old_parent = background_node.get_parent()
		if old_parent != null:
			old_parent.remove_child(background_node)
		background_node.queue_free()

		var new_texture_rect = TextureRect.new()
		new_texture_rect.name = "Background"
		_apply_background_texture(new_texture_rect, texture)
		return new_texture_rect

	push_warning("Unsupported background node type: %s" % background_node.get_class())
	return null

func _apply_background_texture(texture_rect: TextureRect, texture: Texture2D) -> void:
	texture_rect.texture = texture
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.modulate.a = BACKGROUND_DIM_ALPHA
