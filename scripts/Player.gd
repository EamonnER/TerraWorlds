extends "res://scripts/entity.gd"

var debug_mode = false


func handle_primary_action_input(mouse_pos: Vector2):
	# Only function is to remove tiles at mouse pos ATM
	
	# TODO I dislike implimenting this by directly referencing the world. 
	# Player should not have direct access to the world object. 
	var world = get_node("/root/Game/World")  
	var tile_coords = world.local_to_map(mouse_pos)
	world.remove_tile(Vector2i(tile_coords))

func handle_secondary_action_input(mouse_pos: Vector2):
	# Only function is to place tiles at mouse pos ATM
	
	# TODO I dislike implimenting this by directly referencing the world. 
	# Player should not have direct access to the world object. 
	var world = get_node("/root/Game/World")  
	var tile_coords = world.local_to_map(mouse_pos)
	world.place_tile(Vector2i(tile_coords), 0)

func _physics_process(delta):
	super._physics_process(delta)  # Runs parent physics first
	
	if Input.is_action_just_pressed("game_debug_toggle"):
		debug_mode = not debug_mode
		print("Debug mode: ", debug_mode)
		if debug_mode == true:
			motion_mode = MotionMode.MOTION_MODE_FLOATING
			$Collision.set_deferred("disabled", true)
		else:
			motion_mode = MotionMode.MOTION_MODE_GROUNDED
			$Collision.set_deferred("disabled", false)
	
	var mouse_pos = get_global_mouse_position()
	
	# Draw player on minimap
	$CanvasLayer/HUD/Minimap.draw_player(get_position())
	
	# Movement
	var new_velocity = get_relative_velocity()
	if motion_mode == MotionMode.MOTION_MODE_GROUNDED:
		
		# Jump
		if is_on_floor() and Input.is_action_just_pressed("game_jump"): 
			new_velocity.y = -JUMP_VELOCITY
			
		# Handle movement inputs
		var horizontal_direction = Input.get_axis("game_left", "game_right")
		var vertical_direction = Input.get_axis("game_down", "game_up")
		
		# Apply acceleration or decelleration
		if sign(horizontal_direction) == sign(new_velocity.x):
			new_velocity.x = move_toward(new_velocity.x, SPEED*horizontal_direction, ACCELERATION*delta)
		else:
			new_velocity.x = move_toward(new_velocity.x, SPEED*horizontal_direction, DECELERATION*delta)
		
	# Debug Movement
	else:
		var horizontal_direction =  Input.get_axis("game_left", "game_right")
		var vertical_direction = Input.get_axis("game_up", "game_down")
		new_velocity.x = move_toward(new_velocity.x, SPEED*horizontal_direction*10, ACCELERATION*delta*10)
		new_velocity.y = move_toward(new_velocity.y, SPEED*vertical_direction*10, ACCELERATION*delta*10)
	
	# Primary action input (LMB)
	if Input.is_action_just_pressed("game_primary_action"):
		handle_primary_action_input(mouse_pos)
	# Secondary action input (RMB)
	if Input.is_action_just_pressed("game_secondary_action"):
		handle_secondary_action_input(mouse_pos)
	
	set_relative_velocity(new_velocity)
	move_and_slide()
