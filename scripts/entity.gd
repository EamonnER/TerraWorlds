extends CharacterBody2D


const SPEED = 100.0
const ACCELERATION = 1000.0
const DECELERATION = 1500.0
const TERMINAL_VELOCITY = 8000.0
const JUMP_VELOCITY = 400.0
const ROTATION_SPEED = 10 * PI/4

var targeting_actor = null
var is_following = null

# Gravity accelleration
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var rotation_updated = false  # True if up_direction has just been changed in the current frame

func update_rotation(delta):
	var coords: Vector2 = self.global_position
	
	# Checks player position relative to two lines; y=x and y=-x
	# l1 = (y=x), l2 = (y=-x)
	# Remember that y is negative when it goes upward
	var above_l1 = true if -coords.y > coords.x else false
	var above_l2 = true if -coords.y > -coords.x else false
	if above_l1 and above_l2:  # Top quadrant
		up_direction = Vector2.UP
		rotation = rotate_toward(rotation, 0, ROTATION_SPEED*delta)
		return
	elif not above_l1 and above_l2:  # Right quadrant
		up_direction = Vector2.RIGHT
		rotation = rotate_toward(rotation, PI/2, ROTATION_SPEED*delta)
		return
	elif not above_l1 and not above_l2:  # Bottom quadrant
		up_direction = Vector2.DOWN
		rotation = rotate_toward(rotation, PI, ROTATION_SPEED*delta)
		return
	elif above_l1 and not above_l2:
		up_direction = Vector2.LEFT
		rotation = rotate_toward(rotation, PI*3/2, ROTATION_SPEED*delta)
		return
	
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

func _physics_process(delta: float) -> void:
	var previous_up_direction = up_direction
	update_rotation(delta)
	if previous_up_direction != up_direction:
		rotation_updated = true
	else:
		rotation_updated = false
	
	var new_velocity = get_relative_velocity()
	if motion_mode == MotionMode.MOTION_MODE_GROUNDED:
		if not is_on_floor():  # Add gravity
			
			new_velocity.y = move_toward(new_velocity.y, TERMINAL_VELOCITY, gravity*delta)
		
		if rotation_updated:
			new_velocity.x = SPEED * 7.5 * sign(new_velocity.x)
		
	else:
		pass

	set_relative_velocity(new_velocity)
