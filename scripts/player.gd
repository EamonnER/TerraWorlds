extends "res://scripts/entity.gd"
class_name Player

const SPEED_MODIFIER = 3

var debug_mode = false
@export var step_height: int = GlobalVariables.TILE_SIZE * 10  # Adjust based on tile size
@export var step_check_distance: float = 10  # How far in front to check

# Called when the node enters the scene tree for the first time.

func _ready() -> void:
	pass
	
func step_up():
	#if $RayCast2D.is_colliding():
		#var world = get_node("/root/Game/World")  
		#var translation_vector = Vector2(0, -step_height)
		##translation_vector = world.map_to_local(translation_vector)
		#
		#set_relative_vertical_speed(-JUMP_VELOCITY/1.4)
		##translate(translation_vector)#
	
	# Check if the player is grounded
	if not is_on_floor():
		return
	
	var space_state = get_world_2d().direct_space_state
	
	# Cast a ray in front at ground level
	var new_velocity = get_relative_velocity()
	var foot_pos = global_position + Vector2(step_check_distance * sign(new_velocity.x), 0)
	var query = PhysicsRayQueryParameters2D.create(global_position, foot_pos, collision_mask)
	var result = space_state.intersect_ray(query)

	if result:
		# Found an obstacle, check if we can step up
		var step_pos = global_position + Vector2(step_check_distance * sign(new_velocity.x), -step_height)
		query = PhysicsRayQueryParameters2D.create(foot_pos, step_pos, collision_mask)
		var step_result = space_state.intersect_ray(query)
		
		if not step_result:
			# No obstacle above, step up
			global_position.y -= step_height
		
func handle_primary_action_input():
	# Only function is to remove tiles at mouse pos ATM
	
	# TODO I dislike implimenting this by directly referencing the world. 
	# Player should not have direct access to the world object. 
	var mouse_pos = get_global_mouse_position()
	var world = get_node("/root/Game/World")  
	var tile_coords = world.local_to_map(mouse_pos)
	world.remove_tile(Vector2i(tile_coords))

func handle_secondary_action_input():
	# Only function is to place tiles at mouse pos ATM
	
	# TODO I dislike implimenting this by directly referencing the world. 
	# Player should not have direct access to the world object. 
	var mouse_pos = get_global_mouse_position()
	var world = get_node("/root/Game/World")  
	var tile_coords = world.local_to_map(mouse_pos)
	world.place_tile(Vector2i(tile_coords), 0)

# Handling inputs
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("game_debug_toggle"):
		debug_mode = not debug_mode
		print("Debug mode: ", debug_mode)
		$RayCast2D.enabled = not $RayCast2D.enabled
		if debug_mode == true:
			motion_mode = MotionMode.MOTION_MODE_FLOATING
			set_collision_mask_value(2, false)
		else:
			motion_mode = MotionMode.MOTION_MODE_GROUNDED
			set_collision_mask_value(2, true)
	
	# Draw player on minimap
	$CanvasLayer/HUD/Minimap.draw_player(get_position())
	
	# Left / right / up / down inputs
	var new_velocity = get_relative_velocity()
	var horizontal_direction = Input.get_axis("game_left", "game_right")
	var vertical_direction = Input.get_axis("game_up", "game_down")
	
	
	if motion_mode == MotionMode.MOTION_MODE_GROUNDED:
		# Apply acceleration or decelleration
		if sign(horizontal_direction) == sign(new_velocity.x):
			new_velocity.x = move_toward(new_velocity.x, (SPEED*SPEED_MODIFIER)*horizontal_direction, ACCELERATION*delta)
		else:
			new_velocity.x = move_toward(new_velocity.x, SPEED*horizontal_direction, DECELERATION*delta)
	else:  # Debug Movement
		new_velocity.x = move_toward(new_velocity.x, SPEED*horizontal_direction*10, ACCELERATION*delta*10)
		new_velocity.y = move_toward(new_velocity.y, SPEED*vertical_direction*10, ACCELERATION*delta*10)
	set_relative_velocity(new_velocity)
	
	# Jump
	if Input.is_action_just_pressed("game_jump"): 
		jump()
	
	# Mouse actions
	var mouse_pos = get_global_mouse_position()
	# Primary action input (LMB)
	if Input.is_action_just_pressed("game_primary_action"):
		handle_primary_action_input()
	# Secondary action input (RMB)
	if Input.is_action_just_pressed("game_secondary_action"):
		handle_secondary_action_input()
	
	if new_velocity.x != 0:
		step_up()
