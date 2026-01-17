extends Entity
class_name Player

var debug_mode = false
var inventory: Inventory

@export var id = 0

func pickup_item(item: Item) -> bool:
	return false  # TODO revert
	return inventory.add_item(item)

func handle_primary_action_input():
	# Only function is to remove tiles at mouse pos ATM
	
	# TODO I dislike implimenting this by directly referencing the world. 
	# Player should not have direct access to the world object. 
	var mouse_pos = get_global_mouse_position()
	var tile_coords = world.local_to_map(mouse_pos)
	world.remove_tile(Vector2i(tile_coords))

func handle_secondary_action_input():
	# Only function is to place tiles at mouse pos ATM
	
	# TODO I dislike implimenting this by directly referencing the world. 
	# Player should not have direct access to the world object. 
	var mouse_pos = get_global_mouse_position()  
	var tile_coords = world.local_to_map(mouse_pos)
	world.place_tile(Vector2i(tile_coords), 0)

func _ready() -> void:
	health = 100.0

func _handle_inputs(delta: float) -> void:
	if $InputSynchronizer.debug_toggle_pressed:
		debug_mode = not debug_mode
		print("Debug mode: ", debug_mode)
		if debug_mode == true:
			motion_mode = MotionMode.MOTION_MODE_FLOATING
			set_collision_mask_value(2, false)
		else:
			world.spawn_item()
			motion_mode = MotionMode.MOTION_MODE_GROUNDED
			set_collision_mask_value(2, true)
	
	# Left / right / up / down inputs
	var new_velocity = get_relative_velocity()
	var horizontal_direction = $InputSynchronizer.horizontal_input
	var vertical_direction = $InputSynchronizer.vertical_input
	if motion_mode == MotionMode.MOTION_MODE_GROUNDED:
		# Apply acceleration or decelleration
		if sign(horizontal_direction) == sign(new_velocity.x):
			if Input.is_action_pressed("sprint"):
				new_velocity.x = move_toward(new_velocity.x, SPEED*horizontal_direction*SPRINT_MOD, ACCELERATION*delta)
			else:
				new_velocity.x = move_toward(new_velocity.x, SPEED*horizontal_direction, ACCELERATION*delta)
		else:
			new_velocity.x = move_toward(new_velocity.x, SPEED*horizontal_direction, DECELERATION*delta)
			
	else:  # Debug Movement
		new_velocity.x = move_toward(new_velocity.x, SPEED*horizontal_direction*10, ACCELERATION*delta*10)
		new_velocity.y = move_toward(new_velocity.y, SPEED*vertical_direction*10, ACCELERATION*delta*10)
	set_relative_velocity(new_velocity)
	
	# Jump
	if $InputSynchronizer.jump_pressed: 
		jump()
	
	# Mouse actions
	#var mouse_pos = get_global_mouse_position()
	# Primary action input (LMB)
	#if Input.is_action_pressed("game_primary_action"):
	#	handle_primary_action_input()
	# Secondary action input (RMB)
	#if Input.is_action_pressed("game_secondary_action"):
	#	handle_secondary_action_input()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if multiplayer.is_server():
		_handle_inputs(delta)
