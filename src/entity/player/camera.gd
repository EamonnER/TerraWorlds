extends Camera2D

@export var follow_speed: float = 10.0

var player: Player = null

func _ready():
	if not player or not is_instance_valid(player):
		#queue_free()  # Remove camera if player is missing
		pass
	return
		
	if not player.is_multiplayer_authority():
		#queue_free()  # Destroy camera if it's not for the local player
		pass
		return
		
	make_current()  # Only the local player’s camera should be active

func _process(delta):
	if player and is_instance_valid(player):  # Ensure player is not freed
		set_position(get_position().lerp(player.get_position(), follow_speed * delta))
		
		if player.is_rotating:
			set_rotation(player.get_rotation())
		

func set_target(new_player: Player):
	#if not new_player:
		#print("Error: No valid player provided to camera!")
		#queue_free()
		#return
#
	## Ensure the camera is only assigned to the local player
	#if not new_player.is_multiplayer_authority():
		#print("Deleting camera: This is not the local player's camera.")
		##queue_free()
		#return

	print("Camera assigned to player:", new_player.name)
	player = new_player
	make_current()
