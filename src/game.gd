extends Node2D

signal world_ready

@onready var world: World = $World
@onready var players: MultiplayerSpawner = $World/Players
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
	
	emit_signal("world_ready")
