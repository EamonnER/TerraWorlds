extends CharacterBody2D


const SPEED = 300.0
const ACCELERATION = 400.0
const DECELERATION = 80.0
const TERMINAL_VELOCITY = 500.0
const JUMP_VELOCITY = 400.0
var debug_mode = false

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

func rotate_vector_relative_to_up_direction(vector: Vector2) -> Vector2:
	# Rotate the input direction to align it with the up_direction
	if up_direction == Vector2.UP:  # Up
		return vector
	elif up_direction == Vector2.DOWN:  # Down
		return vector.rotated(PI)
	elif up_direction == Vector2.RIGHT:  # Right (90 degrees clockwise)
		return vector.rotated(PI/2)
	else:  # Left (90 degrees anti-clockwise)
		return vector.rotated(-PI/2)

func rotate_player(delta):
	var new_rotation = 0
	
	match up_direction:
		Vector2.RIGHT:
			new_rotation = PI/2
		Vector2.DOWN:
			new_rotation = PI
		Vector2.LEFT:
			new_rotation = 3*PI/2
		_:
			pass
	
	rotation = new_rotation

func get_relative_velocity() -> Vector2:
	return rotate_vector_relative_to_up_direction(get_velocity())

func set_relative_velocity(new_velocity: Vector2) -> void:
	match up_direction:
		Vector2.RIGHT:
			new_velocity = new_velocity.rotated(PI/2)
		Vector2.DOWN:
			new_velocity = new_velocity.rotated(PI)
		Vector2.LEFT:
			new_velocity = new_velocity.rotated(3*PI/2)
		_:
			pass
	
	set_velocity(new_velocity)

func set_relative_horizontal_speed(speed: float):
	var current_velocity = get_relative_velocity()
	set_relative_velocity(Vector2(speed, current_velocity.y))

func set_relative_vertical_speed(speed: float):
	var current_velocity = get_relative_velocity()
	set_relative_velocity(Vector2(current_velocity.x, speed))

func _physics_process(delta):
	if Input.is_action_just_pressed("game_debug_toggle"):
		debug_mode = not debug_mode
		print("Debug mode: ", debug_mode)
		if debug_mode == true:
			motion_mode = MotionMode.MOTION_MODE_FLOATING
			$Collision.set_deferred("disabled", true)
		else:
			motion_mode = MotionMode.MOTION_MODE_GROUNDED
			$Collision.set_deferred("disabled", false)
	
	var previous_up_direction = up_direction
	update_up_direction()
	if previous_up_direction != up_direction:
		rotate_player(delta)
	
	var new_velocity = get_relative_velocity()
	print(new_velocity)
	if motion_mode == MotionMode.MOTION_MODE_GROUNDED:
		# Add gravity to the velocity if the body is not on the floor
		if not is_on_floor():
			new_velocity.y = move_toward(new_velocity.y, TERMINAL_VELOCITY, gravity*delta)
		elif Input.is_action_just_pressed("game_jump"):  # Handle jump
			new_velocity.y = -JUMP_VELOCITY
			
		# Handle movement inputs
		var horizontal_direction = Input.get_axis("game_left", "game_right")
		var vertical_direction = Input.get_axis("game_down", "game_up")
		new_velocity.x = move_toward(new_velocity.x, SPEED*horizontal_direction, ACCELERATION*delta)
	
	else:
		var horizontal_direction =  Input.get_axis("game_left", "game_right")
		var vertical_direction = Input.get_axis("game_up", "game_down")
		new_velocity.x = move_toward(new_velocity.x, SPEED*horizontal_direction, ACCELERATION*delta)
		new_velocity.y = move_toward(new_velocity.y, SPEED*vertical_direction, ACCELERATION*delta)
	
	set_relative_velocity(new_velocity)
	move_and_slide()
