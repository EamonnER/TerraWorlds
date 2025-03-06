extends Node2D

@onready var player: Player = $World/Player
@onready var world: World = $World
@onready var camera: Camera2D = $Camera
@onready var hud: Control = $CanvasLayer/HUD

func _ready() -> void:
	world.generate_new_world()
	
	player.set_world(world)
	player.position = world.get_spawn_position()
	player.update_rotation()
	
	if player.is_multiplayer_authority():  # Only follow the local player
		camera.set_target(player)
		hud.set_target(player)
	
	hud.get_node("Minimap").world_size = world.MAP_SIZE
	hud.get_node("Minimap").draw(world.foreground)
	
