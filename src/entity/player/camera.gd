extends Camera2D

@export var follow_speed: float = 10.0

var player: Player = null

func _ready():
	make_current()

func _process(delta):
	if player:
		set_position(get_position().lerp(player.get_position(), follow_speed * delta))
		
		if player.is_rotating:
			set_rotation(player.get_rotation())
		

func set_target(new_player: CharacterBody2D):
	if not new_player.is_multiplayer_authority():
		queue_free()  # Destroy this camera if it's not for the local player
		return

	player = new_player
	make_current()
