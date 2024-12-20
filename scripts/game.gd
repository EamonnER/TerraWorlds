extends Node2D

@onready var world: Node2D = $World
@onready var player: CharacterBody2D = $Player

const TILE_SIZE: int = 16

func _ready() -> void:
	world.generate_new_world()
	
	var spawn_point = world.get_spawn_position() * TILE_SIZE
	print(spawn_point)
	player.global_position = spawn_point
