extends CharacterBody2D


const SPEED = 300.0
const ACCELERATION = 400.0
const DECELERATION = 800.0
const TERMINAL_VELOCITY = 1000.0
const JUMP_VELOCITY = 400.0
const ROTATION_SPEED = 10 * PI/4

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func update_rotation(delta):
	var coords: Vector2 = self.global_position
	# If in right side of map
	if coords.x > 0:
		# If top right
		if coords.y < 0:
			# If in right segment of map
			if coords.x > abs(coords.y):
				up_direction = Vector2.RIGHT
				rotation = rotate_toward(rotation, PI/2, ROTATION_SPEED*delta)
				return
			# Else, in top segment
			up_direction = Vector2.UP
			rotation = rotate_toward(rotation, 0, ROTATION_SPEED*delta)
			return
		# If in bottom right
		# If in right segment of map
		elif coords.x > coords.y:
			up_direction = Vector2.RIGHT
			rotation = rotate_toward(rotation, PI/2, ROTATION_SPEED*delta)
			return
		# Else, in bottom segment
		up_direction = Vector2.DOWN
		rotation = rotate_toward(rotation, PI, ROTATION_SPEED*delta)
		return
	# If in left side of map
	# If in top left
	elif coords.y < 0:
		# If in left segment
		if coords.x < coords.y:
			up_direction = Vector2.LEFT
			rotation = rotate_toward(rotation, -PI/2, ROTATION_SPEED*delta)
			return
		# Else, in top segment
		up_direction = Vector2.UP
		rotation = rotate_toward(rotation, 0, ROTATION_SPEED*delta)
		return
	# If in bottom left
	# If in left segment
	if abs(coords.x) > coords.y:
		up_direction = Vector2.LEFT
		rotation = rotate_toward(rotation, -PI/2, ROTATION_SPEED*delta)
		return
	# Else, in bottom segment
	up_direction = Vector2.DOWN
	rotation = rotate_toward(rotation, PI, ROTATION_SPEED*delta)
	return

func rotate_vector_relative_to_up_direction(vector: Vector2) -> Vector2:
	# Rotate the input direction to align it with the up_direction
	match up_direction:
		Vector2.RIGHT:
			return vector.rotated(PI/2)
		Vector2.DOWN:
			return vector.rotated(PI)
		Vector2.LEFT:
			return vector.rotated(-PI/2)
		_:
			return vector

func get_relative_velocity() -> Vector2:
	var rotated_velocity = rotate_vector_relative_to_up_direction(get_velocity())
	return rotated_velocity if up_direction in [Vector2.UP, Vector2.DOWN] else -rotated_velocity 
		
func set_relative_velocity(new_velocity: Vector2) -> void:
	set_velocity(rotate_vector_relative_to_up_direction(new_velocity))

func set_relative_horizontal_speed(speed: float):
	var current_velocity = get_relative_velocity()
	set_relative_velocity(Vector2(speed, current_velocity.y))

func set_relative_vertical_speed(speed: float):
	var current_velocity = get_relative_velocity()
	set_relative_velocity(Vector2(current_velocity.x, speed))
