extends RefCounted
class_name BallAirBallHelper

## BallAirBallHelper - extracted helpers for air-ball landing data and slot checks.

var air_landing_shape: CircleShape2D = null
var air_landing_query: PhysicsShapeQueryParameters2D = null
var cached_level_key: String = ""
var cached_center_x: float = 0.0
var cached_step_x: float = 0.0

func is_cached_level(level_key: String) -> bool:
	return level_key == cached_level_key

func get_landing_data(
	level_key: String,
	fallback_center_x: float,
	default_step_x: float
) -> Dictionary:
	if level_key == cached_level_key:
		return {
			"center_x": cached_center_x,
			"step_x": cached_step_x
		}

	cached_level_key = level_key
	cached_center_x = fallback_center_x
	cached_step_x = default_step_x
	return {
		"center_x": cached_center_x,
		"step_x": cached_step_x
	}

func cache_landing_data(level_key: String, center_x: float, step_x: float) -> void:
	cached_level_key = level_key
	cached_center_x = center_x
	cached_step_x = step_x

func ensure_landing_query(owner: Node2D, ball_radius: float, collision_mask: int) -> PhysicsShapeQueryParameters2D:
	if air_landing_shape == null:
		air_landing_shape = CircleShape2D.new()
	if air_landing_query == null:
		air_landing_query = PhysicsShapeQueryParameters2D.new()
		air_landing_query.collide_with_areas = false
		air_landing_query.collide_with_bodies = true
	air_landing_shape.radius = ball_radius
	air_landing_query.shape = air_landing_shape
	air_landing_query.exclude = [owner]
	air_landing_query.collision_mask = collision_mask
	return air_landing_query

func is_unbreakable_overlap(
	space: PhysicsDirectSpaceState2D,
	query: PhysicsShapeQueryParameters2D,
	query_max_results: int,
	unbreakable_type: int
) -> bool:
	var results = space.intersect_shape(query, query_max_results)
	for hit in results:
		var collider = hit.get("collider")
		if collider and collider.is_in_group("brick") and "brick_type" in collider:
			if collider.brick_type == unbreakable_type:
				return true
	return false

func get_unbreakable_bricks_near_y(
	hit_y: float,
	ball_radius: float,
	unbreakable_half_size: float,
	row_margin: float,
	bricks: Array[Node],
	unbreakable_type: int
) -> Array[Node]:
	var row_candidates: Array[Node] = []
	var vertical_limit = unbreakable_half_size + ball_radius + row_margin
	for brick in bricks:
		if not is_instance_valid(brick):
			continue
		if not ("brick_type" in brick):
			continue
		if brick.brick_type != unbreakable_type:
			continue
		if abs(brick.global_position.y - hit_y) <= vertical_limit:
			row_candidates.append(brick)
	return row_candidates

func is_unbreakable_slot_blocked(
	candidate_pos: Vector2,
	unbreakable_bricks: Array[Node],
	ball_radius: float,
	unbreakable_half_size: float,
	row_margin: float
) -> bool:
	var horizontal_limit = unbreakable_half_size + ball_radius
	var vertical_limit = unbreakable_half_size + ball_radius + row_margin
	for brick in unbreakable_bricks:
		if not is_instance_valid(brick):
			continue
		var brick_pos = brick.global_position
		if abs(candidate_pos.y - brick_pos.y) > vertical_limit:
			continue
		if abs(candidate_pos.x - brick_pos.x) <= horizontal_limit:
			return true
	return false
