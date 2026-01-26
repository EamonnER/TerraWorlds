extends Entity
class_name Player

var debug_mode: bool = false

@export var id: int = 0

var rpc_interface: Node
@export var inventory: Inventory

func get_tile_pos_at_mouse_pos() -> Vector2i:
	return world.local_to_map(get_global_mouse_position())

func _ready() -> void:
	super._ready()
	rpc_interface = world.get_node("RpcInterface")
	health = 100.0

func _handle_server_authoratitive_inputs(delta: float) -> void:
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
	var new_velocity: Vector2 = get_relative_velocity()
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
	
func _handle_local_inputs() -> void:
	# Primary action input (LMB)
	if $InputSynchronizer.primary_action_pressed:
		rpc_interface.request_remove_tile.rpc_id(1, get_tile_pos_at_mouse_pos())
	# Secondary action input (RMB)
	if $InputSynchronizer.secondary_action_pressed:
		rpc_interface.request_place_tile.rpc_id(1, get_tile_pos_at_mouse_pos(), 0)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if multiplayer.is_server(): _handle_server_authoratitive_inputs(delta)
	if id == multiplayer.get_unique_id(): _handle_local_inputs()
