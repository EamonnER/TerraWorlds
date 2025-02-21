extends Node2D


func _ready() -> void:
	$World.generate_new_world()

	#$Player.position = $World.get_spawn_position()
	$skeleton_enemy.position = $World.get_spawn_position() + Vector2i(-4000, -200)
	
	var player = load("res://player.tscn").instantiate()
	var Game = get_node(".")
	Game.add_child(player)
	
	player.position = $World.get_spawn_position()
	
	player.get_node("CanvasLayer/HUD/Minimap").world_size = $World.WORLD_SIZE
	player.get_node("CanvasLayer/HUD/Minimap").draw($World.foreground)
