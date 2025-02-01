extends Node2D


func _ready() -> void:
	$World.generate_new_world()

	$Player.position = $World.get_spawn_position()
