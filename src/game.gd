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
	const MAP_SIZE = 32 * CHUNK_SIZE
	const CAVE_OFFSET = 20
	
	world.map_size = MAP_SIZE
	
	world_generator.GenerateWorld(MAP_SIZE, world_seed, CAVE_OFFSET)
	var all_chunks = world_generator.GetAllChunks()
	world.draw_chunks(all_chunks)
	world.draw_gravity_collision()
	
	var appdata_path = OS.get_user_data_dir()
	var world_path = appdata_path + "/world.json"
	print(world_path)
	world_generator.SaveWorldToFile(world_path)

func _ready() -> void:
	generate_world()
	
	player.set_world(world)
	player.set_position(world.get_spawn_position())
	player.update_rotation()
	
	if player.is_multiplayer_authority():  # Only follow the local player
		camera.set_target(player)
		hud.set_target(player)
	
	hud.get_node("Minimap").map_size = world.map_size
	hud.get_node("Minimap").draw(world.foreground)
	
