extends Label
class_name Health

var player: Player

func _process(delta: float) -> void:
	if player:
		set_text("Health: " + str(player.health))
