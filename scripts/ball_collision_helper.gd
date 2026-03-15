class_name BallCollisionHelper
extends RefCounted

func handle_collision(parent: Node, collision: KinematicCollision2D) -> void:
	"""Handle ball collision with walls, paddle, or bricks"""
	var collider = collision.get_collider()
	var normal = collision.get_normal()

	# Ignore ball-to-ball collisions entirely (prevents physics pausing)
	if collider.is_in_group("ball"):
		return

	# Check what we hit
	if collider.is_in_group("paddle"):
		if parent.paddle_reference == null and collider is Node2D:
			parent.paddle_reference = collider as Node2D
		var hit_y = parent.position.y
		parent.time_since_paddle_hit = 0.0
		# Pass through paddle during launch immunity window — prevents freshly-launched balls
		# (especially stacked triple-ball grabs) from immediately bouncing off the paddle face
		# and reversing direction toward the right boundary.
		if parent.grab_immunity_timer > 0.0:
			return
		# Allow ball to pass through paddle when it's behind the paddle (to the right)
		# and moving rightward. Prevents "ghost hits" where a fast paddle catches a ball
		# that already passed it, applying spin and pulling it back through.
		if parent.paddle_reference and parent.position.x > parent.paddle_reference.position.x and parent.velocity.x > 0.0:
			return
		# Special case: Allow ball to escape through paddle if pinched near walls.
		# Forces leftward velocity so the ball returns to play instead of exiting.
		if parent.position.y < parent.TOP_ESCAPE_ZONE_Y:
			parent.velocity.x = -abs(parent.velocity.x)
			return
		elif parent.position.y > parent.BOTTOM_ESCAPE_ZONE_Y:
			parent.velocity.x = -abs(parent.velocity.x)
			return

		# Check if grab is enabled and ball is not immune to grab
		if parent.frame_grab_active and parent.grab_immunity_timer <= 0.0:
			# Attach ball to paddle (grab mode) at the exact contact point
			parent.is_attached_to_paddle = true
			parent.velocity = Vector2.ZERO
			# Store the current offset from paddle so ball sticks where it was grabbed
			if parent.paddle_reference:
				parent.paddle_offset = parent.position - parent.paddle_reference.position
				# Ensure ball is on the front (left) side of paddle, not the back (right)
				# Paddle is vertical on the right side, so negative X offset = front/left = good
				# Positive X offset = back/right = bad (ball would be lost immediately)
				if parent.paddle_offset.x > 0:
					# Ball grabbed on back side - move it to front side at same Y position
					parent.paddle_offset.x = -abs(parent.paddle_offset.x)
		else:
			# Paddle collision: reflect + add spin
			parent.velocity = parent.velocity.bounce(normal)

			# A fast swipe can catch the ball on the back face and produce a rightward
			# bounce normal — that would send the ball straight through the right boundary.
			# The paddle is always on the right side, so the ball must always leave leftward.
			if parent.velocity.x > 0.0:
				parent.velocity.x = -parent.velocity.x

			# Add paddle spin influence
			if parent.paddle_reference and parent.paddle_reference.has_method("get_velocity_for_spin"):
				var paddle_velocity = parent.paddle_reference.get_velocity_for_spin()
				parent.spin_amount = clampf(paddle_velocity * parent.SPIN_IMPART_FACTOR, -parent.SPIN_MAX, parent.SPIN_MAX)

			# Prevent pure vertical motion
			if abs(parent.velocity.x) < parent.current_speed * (1.0 - parent.MAX_VERTICAL_ANGLE):
				parent.velocity.x = -abs(parent.velocity.x)  # always leftward

			# Prevent paddle-bottom wall wedge by nudging ball upward at the boundary
			var min_y = parent.TOP_WALL_Y + parent.ball_radius
			var max_y = parent.BOTTOM_WALL_Y - parent.ball_radius
			if parent.position.y < min_y:
				parent.position.y = min_y
				parent.velocity.y = abs(parent.velocity.y)
			elif parent.position.y > max_y:
				parent.position.y = max_y
				parent.velocity.y = -abs(parent.velocity.y)

			if parent.frame_air_ball_active:
				parent._jump_to_level_center_x(hit_y)
				return
		AudioManager.play_sfx("hit_paddle")

	elif collider.is_in_group("brick"):
		# Brick collision: reflect + notify brick
		var old_velocity = parent.velocity  # Store for particle direction
		var hit_brick_position = collider.global_position  # Store for bomb effect
		var had_high_spin: bool = absf(parent.spin_amount) >= parent.HIGH_SPIN_THRESHOLD
		var is_unbreakable = false
		var is_powerup_brick = false
		if "brick_type" in collider:
			is_unbreakable = collider.brick_type == parent.BRICK_TYPE_UNBREAKABLE
			is_powerup_brick = collider.brick_type == parent.BRICK_TYPE_POWERUP_BRICK

		var is_block_brick = collider.is_in_group("block_brick")
		# normal.x > 0 means ball hit the brick from the right (behind the barrier)
		# normal.x <= 0 means ball hit from the field side — don't pass through even if velocity.x < 0
		# (prevents escaping the barrier after bouncing off one brick and clipping the next)
		var from_behind = normal.x > 0.0
		if is_block_brick and (from_behind and parent.velocity.x < 0.0):
			# Allow balls approaching from behind the barrier (field side) to pass through
			parent.position += parent.velocity * parent.last_physics_delta
			return

		# Check if brick through is enabled (block + unbreakable bricks always behave normally)
		var has_penetrating_spin = absf(parent.spin_amount) >= parent.PENETRATING_SPIN_THRESHOLD
		var can_pass_through = not is_block_brick and not is_unbreakable and (parent.frame_brick_through_active or has_penetrating_spin)
		_tag_high_spin_hit(collider, had_high_spin)

		if is_powerup_brick and not can_pass_through:
			# Powerup bricks bounce like normal bricks and grant their effect on contact
			parent._emit_brick_hit(collider)
			if collider.has_method("collect_powerup"):
				collider.collect_powerup()
			parent.velocity = parent.velocity.bounce(normal)
			parent.spin_amount *= parent.SPIN_ON_HIT_DECAY
			AudioManager.play_sfx("power_up")
			return

		if can_pass_through:
			# Don't bounce, just pass through and notify brick
			parent._emit_brick_hit(collider)
			if is_powerup_brick and collider.has_method("collect_powerup"):
				collider.collect_powerup()
				AudioManager.play_sfx("power_up")
			elif collider.has_method("hit"):
				collider.hit(old_velocity.normalized())
			else:
				collider.break_brick(Vector2(-1, 0))
			if not is_powerup_brick:
				parent.spin_amount *= parent.SPIN_ON_HIT_DECAY
			parent.position += parent.velocity * parent.last_physics_delta
		else:
			var bounce_normal = normal
			var brick_shape = "square"
			if collider.has_method("_get_brick_shape"):
				brick_shape = collider._get_brick_shape()

			if is_block_brick:
				# Block barrier bricks are a lateral wall — always bounce on the X axis.
				# Using the hit-position offset can resolve to a Y-axis bounce when the ball
				# clips a top/bottom edge, which leaves velocity.x unchanged and lets the
				# ball knife through the remaining barrier bricks.
				var x_sign = sign(parent.position.x - collider.global_position.x)
				if x_sign == 0:
					x_sign = -sign(parent.velocity.x)
				bounce_normal = Vector2(x_sign, 0)
			elif brick_shape == "square":
				var hit_pos = collision.get_position()
				var offset = hit_pos - collider.global_position
				if abs(offset.x) > abs(offset.y):
					var x_sign = sign(offset.x)
					if x_sign != 0:
						bounce_normal = Vector2(x_sign, 0)
				elif abs(offset.y) > abs(offset.x):
					var y_sign = sign(offset.y)
					if y_sign != 0:
						bounce_normal = Vector2(0, y_sign)

			# Normal bounce behavior
			parent.velocity = parent.velocity.bounce(bounce_normal)
			normal = bounce_normal

			# Push ball away from brick to prevent rapid re-collision
			# This is especially important for polygon/diamond shapes with angled faces
			if is_block_brick:
				# Separate ball from barrier face so next frame doesn't start embedded
				parent.position += bounce_normal * (parent.ball_radius * 0.5)
			elif is_unbreakable:
				# Add a small random deflection to avoid edge hugging
				parent.velocity = parent.velocity.rotated(deg_to_rad(randf_range(-12.0, 12.0)))
				parent.position += bounce_normal * (parent.ball_radius * 0.6)
			elif brick_shape in ["polygon", "diamond"]:
				# For polygon/diamond bricks, add slight separation to prevent stuck loops
				parent.position += bounce_normal * (parent.ball_radius * 0.3)

			parent._emit_brick_hit(collider)
			if collider.has_method("hit"):
				collider.hit(old_velocity.normalized())
			parent.spin_amount *= parent.SPIN_ON_HIT_DECAY
		AudioManager.play_sfx("hit_brick")

		# Check if bomb ball is active - destroy surrounding bricks (skip block bricks)
		if not is_block_brick and parent.frame_bomb_ball_active:
			destroy_surrounding_bricks(parent, hit_brick_position)

	else:
		# Wall collision: simple reflection
		AudioManager.play_sfx("hit_wall")
		parent.velocity = parent.velocity.bounce(normal)

	if collider != null:
		parent.stuck_helper.record_collision(normal, collider)

func _tag_high_spin_hit(collider: Variant, had_high_spin: bool) -> void:
	if collider == null:
		return
	if collider is Node and (collider as Node).has_method("set_meta"):
		(collider as Node).set_meta("wave_objective_high_spin_hit", had_high_spin)

func destroy_surrounding_bricks(parent: Node, impact_position: Vector2) -> void:
	"""Destroy bricks in a radius around the impact point (bomb ball effect)"""
	var bomb_radius_sq = parent.BOMB_BALL_RADIUS * parent.BOMB_BALL_RADIUS

	var all_bricks = parent._get_cached_level_bricks()

	for brick in all_bricks:
		if not is_instance_valid(brick):
			continue
		if brick.is_in_group("block_brick"):
			continue
		if "brick_type" in brick and brick.brick_type == parent.BRICK_TYPE_UNBREAKABLE:
			continue

		# Check distance from impact point using squared values (avoid sqrt in hot path)
		var dist_sq = brick.global_position.distance_squared_to(impact_position)
		if dist_sq <= bomb_radius_sq:
			# For power-up bricks, grant the effect immediately (not a falling power-up)
			if "brick_type" in brick and brick.brick_type == parent.BRICK_TYPE_POWERUP_BRICK:
				if brick.has_method("collect_powerup"):
					brick.collect_powerup()
				else:
					brick.break_brick(Vector2(-1, 0))
			# For regular bricks, break normally
			elif brick.has_method("break_brick"):
				brick.break_brick(Vector2(-1, 0))  # Use left direction for consistency
			elif brick.has_method("hit"):
				brick.hit(Vector2(-1, 0))  # Fallback for safety

	parent.visual_helper._update_trail_appearance(parent)
