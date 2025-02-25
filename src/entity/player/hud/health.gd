extends Label
class_name Health

var player: Player

func _process(delta: float) -> void:
	if player and is_instance_valid(player):  # Ensure player is not freed
		set_text("Health: " + str(player.health))
