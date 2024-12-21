extends CharacterBody2D


const SPEED = 300.0
const ACCELERATION = 100
const DECELERATION = 20
const JUMP_VELOCITY = -400.0

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
	velocity -= up_direction * JUMP_VELOCITY

func move(direction: float):
	# Compute the right direction (perpendicular to up_direction)
	var right = up_direction.orthogonal()
	
	# Project the velocity onto the right direction to get the left-right component
	var right_velocity = velocity.project(right)
	
	if direction == 0:
		# Transition sideways velocity towards 0
		right_velocity = right_velocity.move_toward(Vector2.ZERO, DECELERATION)
	else:
		# Transition sideways velocity towards max speed
		right_velocity = right_velocity.move_toward(right * SPEED * direction * -1, ACCELERATION)
		
	# Update velocity & keep verticle velocity
	velocity = velocity.project(up_direction) + right_velocity

func _physics_process(delta):
	update_up_direction()
		
	# Add the gravity.
	if not is_on_floor():
		velocity -= up_direction * gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		jump()
		
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("ui_left", "ui_right")
	move(direction)

	move_and_slide()
