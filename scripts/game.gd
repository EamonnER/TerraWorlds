extends Node2D

@onready var player: Player = $World/Player
@onready var world: World = $World
@onready var camera = $Camera

func _ready() -> void:
	world.generate_new_world()

	player.position = $World.get_spawn_position()
	player.update_rotation()
	
	if player.is_multiplayer_authority():  # Only follow the local player
		camera.set_target(player)
	
	player.get_node("CanvasLayer/HUD/Minimap").world_size = world.WORLD_SIZE
	player.get_node("CanvasLayer/HUD/Minimap").draw(world.foreground)
