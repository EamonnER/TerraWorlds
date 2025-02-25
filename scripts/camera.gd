extends Camera2D

@export var follow_speed: float = 5.0

var player: CharacterBody2D = null

func _ready():
	make_current()

func _process(delta):
	if player:
		global_position = global_position.lerp(player.global_position, follow_speed * delta)

func set_target(new_player: CharacterBody2D):
	if not new_player.is_multiplayer_authority():
		queue_free()  # Destroy this camera if it's not for the local player
		return

	player = new_player
	make_current()
