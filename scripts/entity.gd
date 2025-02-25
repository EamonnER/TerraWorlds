extends CharacterBody2D
class_name Entity

const SPEED = 300.0
const ACCELERATION = 1000.0
const DECELERATION = 1500.0
const TERMINAL_VELOCITY = 8000.0
const JUMP_VELOCITY = 400.0
const ROTATION_SPEED = 10 * PI/4

# Gravity attributes
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var gravity_vector = ProjectSettings.get_setting("physics/2d/default_gravity_vector")
var is_rotating = false  # True if up_direction has just been changed in the current frame

var health: float = 100.0

func update_rotation():
	var coords: Vector2 = self.global_position
	var old_up_direction = up_direction
	
	# Checks player position relative to two lines; y=x and y=-x
	# l1 = (y=x), l2 = (y=-x)
	# Remember that y is negative when it goes upward
	var above_l1 = true if -coords.y > coords.x else false
	var above_l2 = true if -coords.y > -coords.x else false
	if above_l1 and above_l2:  # Top quadrant
		up_direction = Vector2.UP
		gravity_vector = Vector2.DOWN
	elif not above_l1 and above_l2:  # Right quadrant
		up_direction = Vector2.RIGHT
		gravity_vector = Vector2.LEFT
	elif not above_l1 and not above_l2:  # Bottom quadrant
		up_direction = Vector2.DOWN
		gravity_vector = Vector2.UP
	elif above_l1 and not above_l2:
		up_direction = Vector2.LEFT
		gravity_vector = Vector2.RIGHT
	
	if old_up_direction != up_direction:
		is_rotating = true
		_on_rotate()


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

func _on_rotate() -> void:
	set_relative_horizontal_speed(SPEED * 2.5 * sign(get_relative_velocity().x))

func _rotate_entity(delta: float) -> void:
	var old_rotation = rotation
	match up_direction:
		Vector2.RIGHT:
			rotation = rotate_toward(rotation, PI/2, ROTATION_SPEED*delta)
		Vector2.DOWN:
			rotation = rotate_toward(rotation, PI, ROTATION_SPEED*delta)
		Vector2.LEFT:
			rotation = rotate_toward(rotation, 3*PI/2, ROTATION_SPEED*delta)
		_:
			rotation = rotate_toward(rotation, 0, ROTATION_SPEED*delta)
	
	if old_rotation == rotation:
		is_rotating = false

func _apply_gravity(delta: float) -> void:
	if motion_mode == MotionMode.MOTION_MODE_GROUNDED and not is_on_floor():
		var old_vertical_velocity = get_relative_velocity().y
		var target_vertical_veloctiy = TERMINAL_VELOCITY
		set_relative_vertical_speed(
			move_toward(old_vertical_velocity, target_vertical_veloctiy, gravity*delta)
		)

func jump() -> void:
	if motion_mode == MotionMode.MOTION_MODE_GROUNDED and is_on_floor(): 
		set_relative_vertical_speed(-JUMP_VELOCITY)

func _physics_process(delta: float) -> void:
	if is_rotating:
		_rotate_entity(delta)
	
	_apply_gravity(delta)
	
	move_and_slide()
