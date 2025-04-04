extends Node2D

@onready var player: Player = $World/Player
@onready var world: World = $World
@onready var camera: Camera2D = $Camera
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var hud: Control = $CanvasLayer/HUD
var world_generator: WorldGenerator
const CHUNK_SIZE: int = GlobalVariables.CHUNK_SIZE

func load_world() -> void:
	world.map_size = world_generator.GetMapSize()
	var all_chunks = world_generator.GetAllChunks()
	world.draw_chunks(all_chunks)
	world.draw_gravity_collision()
	
	player.set_world(world)
	player.set_position(world.get_spawn_position())
	player.update_rotation()
	
	if player.is_multiplayer_authority():  # Only follow the local player
		camera.set_target(player)
		hud.set_target(player)
	
	hud.get_node("Minimap").map_size = world.map_size
	hud.get_node("Minimap").draw(world.foreground)
