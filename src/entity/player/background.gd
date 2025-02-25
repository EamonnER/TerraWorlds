extends Parallax2D
class_name Background

var player: Player

func set_target(new_player: Player):
	if not new_player.is_multiplayer_authority():
		queue_free()
		return

	player = new_player

func _process(delta: float) -> void:
	if player and player.is_rotating:
		# set_rotation(-player.get_rotation())
		pass
	
