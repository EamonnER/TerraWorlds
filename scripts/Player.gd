extends CharacterBody2D


const SPEED = 300.0
const ACCELERATION = 5000.0
const DECELERATION = 800.0
const TERMINAL_VELOCITY = 5000.0
const JUMP_VELOCITY = 300.0

var world: Node2D

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func update_up_direction():
	var coords: Vector2 = self.global_position
	# If in right side of map
	if coords.x > 0:
		# If top right
		if coords.y < 0:
			# If in right segment of map
			if coords.x > abs(coords.y):
				up_direction = Vector2.RIGHT
				return
			# Else, in top segment
			up_direction = Vector2.UP
			return
		# If in bottom right
		# If in right segment of map
		elif coords.x > coords.y:
			up_direction = Vector2.RIGHT
			return
		# Else, in bottom segment
		up_direction = Vector2.DOWN
		return
	# If in left side of map
	# If in top left
	elif coords.y < 0:
		# If in left segment
		if coords.x < coords.y:
			up_direction = Vector2.LEFT
			return
		# Else, in top segment
		up_direction = Vector2.UP
		return
	# If in bottom left
	# If in left segment
	if abs(coords.x) > coords.y:
		up_direction = Vector2.LEFT
		return
	# Else, in bottom segment
	up_direction = Vector2.DOWN
	return

func send_to_spawn():
	if is_instance_valid(world):  # Null check
		var spawn_point = world.get_spawn_position()
		self.global_position = spawn_point

func jump():
	velocity = up_direction * JUMP_VELOCITY

func move_horizontal(direction: float, delta: float):
	# Compute the right direction (perpendicular to up_direction)
	var right = up_direction.orthogonal()
	
	# Project the velocity onto the right direction to get the left-right component
	var right_velocity = velocity.project(right)
	
	if not direction:
		# Transition sideways velocity towards 0
		right_velocity = right_velocity.move_toward(Vector2.ZERO, DECELERATION*delta)
	else:
		# Transition sideways velocity towards max speed
		right_velocity = right_velocity.move_toward(right * SPEED * direction * -1, ACCELERATION*delta)
		
	# Update velocity & keep verticle velocity
	velocity = velocity.project(up_direction) + right_velocity

func rotate_vector_relative(vector: Vector2) -> Vector2:
	# Rotate the input direction to align it with the up_direction
	vector = vector.normalized()
	if up_direction == Vector2.UP:  # Up
		return vector
	elif up_direction == Vector2.DOWN:  # Down
		return vector.rotated(PI)
	elif up_direction == Vector2.RIGHT:  # Right (90 degrees clockwise)
		return vector.rotated(PI/2)
	else:  # Left (90 degrees anti-clockwise)
		return vector.rotated(-PI/2)

func get_relative_velocity(direction: Vector2) -> float:
	var relative_direction = rotate_vector_relative(direction.normalized())
	var projected_velocity = velocity * relative_direction
	
	return velocity.x if velocity.x else velocity.y

func add_velocity(direction: Vector2, magnitude: float):
	var relative_direction = rotate_vector_relative(direction.normalized())
	var magnitude_as_vector = relative_direction * magnitude
	velocity += magnitude_as_vector

func rotate_player(delta):
	if up_direction == Vector2.UP:
		# rotation = rotate_toward(rotation, 0, ROTATION_SPEED*delta)
		rotation = 0
	elif up_direction == Vector2.LEFT:
		rotation = 3*PI/2
		#rotation = rotate_toward(rotation, 3*PI/2, ROTATION_SPEED*delta)
	elif up_direction == Vector2.DOWN:
		rotation = PI
		#rotation = rotate_toward(rotation, PI, ROTATION_SPEED*delta)
	else:  # Right
		rotation = PI/2
		#rotation = rotate_toward(rotation, PI/2, ROTATION_SPEED*delta)
	
func _physics_process(delta):
	var previous_up_direction = up_direction
	update_up_direction()
	if previous_up_direction != up_direction:
		rotate_player(delta)

	# Add gravity to the velocity if the body is not on the floor.
	if not is_on_floor():
		var down_velocity = gravity*delta
		add_velocity(Vector2.DOWN, down_velocity)

	# Handle jump.
	if Input.is_action_just_pressed("game_jump") and is_on_floor():
		jump()
		
	# Get the input direction and handle the movement/deceleration.
	var direction = Input.get_axis("game_left", "game_right")
	move_horizontal(direction, delta)

	move_and_slide()
