extends Node2D

@onready var world: Node2D = $World
@onready var player: CharacterBody2D = $Player

func _ready() -> void:
	world.generate_new_world()
	
	player.world = world
	player.send_to_spawn()
