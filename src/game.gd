extends Node2D

@onready var player: Player = $World/Player
@onready var world: World = $World
@onready var camera: Camera2D = $Camera
@onready var hud: Control = $CanvasLayer/HUD

var world_generator: WorldGenerator = load("res://src/world/WorldGenerator.cs").new()
const CHUNK_SIZE: int = GlobalVariables.CHUNK_SIZE

func generate_world() -> void:
	world.clear()
	var world_seed = randi()
	var cave_offset = 20
	var map_size = world.MAP_SIZE
	
	world_generator.GenerateWorld(map_size, world_seed, cave_offset)
	var all_chunks = world_generator.GetAllChunks()
	world.draw_chunks(all_chunks)

func _ready() -> void:
	generate_world()
	
	player.set_world(world)
	player.position = world.get_spawn_position()
	player.update_rotation()
	
	if player.is_multiplayer_authority():  # Only follow the local player
		camera.set_target(player)
		hud.set_target(player)
	
	hud.get_node("Minimap").map_size = world.MAP_SIZE
	hud.get_node("Minimap").draw(world.foreground)
	
