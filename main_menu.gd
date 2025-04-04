extends Control

var game_scene: PackedScene = preload("res://src/game.tscn")
var world_generator: WorldGenerator = load("res://src/world/WorldGenerator.cs").new()
const CHUNK_SIZE: int = GlobalVariables.CHUNK_SIZE
var move_to_game = false

var loading_screen: Control = preload("res://src/loading/loading_screen.tscn").instantiate()

var world_thread: Thread = Thread.new()

func _on_generate_world_button_pressed() -> void:
	var world_seed = randi()
	const MAP_SIZE = 32 * CHUNK_SIZE
	const CAVE_OFFSET = 20
	
	world_generator.Seed = world_seed
	world_generator.MapSize = MAP_SIZE
	world_generator.CaveOffset = CAVE_OFFSET
	
	hide()
	loading_screen.show()
	
	if world_thread.is_started(): world_thread.wait_to_finish()
	world_thread.start(_generate_world)

func _on_load_world_button_pressed() -> void:
	hide()
	loading_screen.show()
	
	if world_thread.is_started(): world_thread.wait_to_finish()
	world_thread.start(_load_world)

func _generate_world() -> void:
	world_generator.GenerateWorld()
	world_generator.SaveWorldToFile("world.tworld")

func _load_world() -> void:
	world_generator.LoadWorldFromFile("world.tworld")

func _on_world_gen_progress_update(details: String, percent: int) -> void:
	loading_screen.call_deferred("update", details, percent)

func _on_world_gen_completed() -> void:
	world_generator.SaveWorldToFile("world.tworld")
	call_deferred("show")
	loading_screen.call_deferred("hide")

func _on_world_load_completed() -> void:
	move_to_game = true

func _ready() -> void:
	get_tree().root.add_child.call_deferred(loading_screen)
	loading_screen.hide()
	
	world_generator.connect("ProgressUpdate", _on_world_gen_progress_update)
	world_generator.connect("GenCompleted", _on_world_gen_completed)
	world_generator.connect("LoadCompleted", _on_world_load_completed)

func _process(delta: float) -> void:
	if move_to_game:
		var game = game_scene.instantiate()
		game.world_generator = world_generator
		add_sibling(game)
		game.load_world()
		queue_free()
