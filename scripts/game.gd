extends Node2D


func _ready() -> void:
	$World.generate_new_world()

	$Player.position = $World.get_spawn_position()
	$skeleton.position = $World.get_spawn_position()
	
	$Player.get_node("CanvasLayer/HUD/Minimap").world_size = $World.WORLD_SIZE
	$Player.get_node("CanvasLayer/HUD/Minimap").draw($World.foreground)
