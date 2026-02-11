extends RefCounted
class_name BallStuckDetectionHelper

## BallStuckDetectionHelper - Stuck detection subsystem extracted from ball.gd.

const BRICK_TYPE_UNBREAKABLE = 2

var stuck_check_timer: float = 0.0
var last_position: Vector2 = Vector2.ZERO
var stuck_threshold: float = 2.0  # seconds
var last_collision_normal: Vector2 = Vector2.ZERO
var last_collision_collider = null
var last_collision_age: float = 0.0

func check(ball: CharacterBody2D, delta: float, current_speed: float, ball_radius: float, is_attached: bool) -> void:
	if is_attached:
		stuck_check_timer = 0.0
		last_position = ball.position
		return

	var expected_movement = current_speed * delta * 0.5
	var distance_moved_sq = ball.position.distance_squared_to(last_position)
	var expected_movement_sq = expected_movement * expected_movement

	if distance_moved_sq < expected_movement_sq:
		stuck_check_timer += delta

		if stuck_check_timer >= stuck_threshold:
			push_warning("Ball appears stuck at %s - applying escape boost" % str(ball.position))

			var used_collision_escape = false
			if last_collision_collider != null and is_instance_valid(last_collision_collider):
				if last_collision_collider.is_in_group("brick") and "brick_type" in last_collision_collider:
					if last_collision_collider.brick_type == BRICK_TYPE_UNBREAKABLE and last_collision_age <= 0.75:
						var escape_normal = last_collision_normal if last_collision_normal != Vector2.ZERO else Vector2.LEFT
						ball.position += escape_normal * (ball_radius * 1.2)
						ball.velocity = ball.velocity.bounce(escape_normal).rotated(deg_to_rad(randf_range(-18.0, 18.0)))
						used_collision_escape = true

			if not used_collision_escape:
				var escape_angle = randf_range(135.0, 225.0)
				var angle_rad = deg_to_rad(escape_angle)
				ball.velocity = Vector2(cos(angle_rad), sin(angle_rad)) * current_speed

			stuck_check_timer = 0.0
	else:
		stuck_check_timer = 0.0

	last_position = ball.position

func record_collision(normal: Vector2, collider: Node) -> void:
	last_collision_normal = normal
	last_collision_collider = collider
	last_collision_age = 0.0

func tick_collision_age(delta: float) -> void:
	if last_collision_collider != null:
		last_collision_age += delta
