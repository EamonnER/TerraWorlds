extends "res://scripts/entity.gd"

var debug_mode = false

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
	
	update_rotation(delta)
	
	# Draw player on minimap
	$Camera.get_node("Overlay/Minimap").draw_player(get_position())
	
	# Movement
	var new_velocity = get_relative_velocity()
	if motion_mode == MotionMode.MOTION_MODE_GROUNDED:
		if not is_on_floor():  # Add gravity
			new_velocity.y = move_toward(new_velocity.y, TERMINAL_VELOCITY, gravity*delta)
		elif Input.is_action_just_pressed("game_jump"):  # Handle jump
			new_velocity.y = -JUMP_VELOCITY
			
		# Handle movement inputs
		var horizontal_direction = Input.get_axis("game_left", "game_right")
		var vertical_direction = Input.get_axis("game_down", "game_up")
		
		# Apply acceleration or decelleration
		if sign(horizontal_direction) == sign(new_velocity.x):
			new_velocity.x = move_toward(new_velocity.x, SPEED*horizontal_direction, ACCELERATION*delta)
		else:
			new_velocity.x = move_toward(new_velocity.x, SPEED*horizontal_direction, DECELERATION*delta)
	
	else:
		var horizontal_direction =  Input.get_axis("game_left", "game_right")
		var vertical_direction = Input.get_axis("game_up", "game_down")
		new_velocity.x = move_toward(new_velocity.x, SPEED*horizontal_direction*10, ACCELERATION*delta*10)
		new_velocity.y = move_toward(new_velocity.y, SPEED*vertical_direction*10, ACCELERATION*delta*10)
	
	set_relative_velocity(new_velocity)
	move_and_slide()
