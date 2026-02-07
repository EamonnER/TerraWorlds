extends Control

@onready var loading_screen: Control = $CanvasLayer/LoadingScreen

var game: Node2D = preload("res://src/game.tscn").instantiate()
var move_to_game: bool = false

func move_to_menu(menu: Node2D):
	create_tween().tween_property(
		$Camera, "global_position",
		menu.global_position,
		0.4
	).set_trans(Tween.TRANS_SINE) \
	.set_ease(Tween.EASE_IN_OUT)

func _ready() -> void:
	world_generator.connect("ProgressUpdate", _on_world_gen_progress_update)
	world_generator.connect("GenCompleted", _on_world_gen_completed)
	world_generator.connect("LoadCompleted", _on_world_load_completed)

func _process(_delta: float) -> void:
	if move_to_game:
		game.show()
		if world_thread.is_started(): world_thread.wait_to_finish()
		game.world_generator = world_generator
		game.load_world()

		queue_free()


# Main Menu ----------------------------------------------------------------------------------------
func _on_main_menu_play_button_pressed() -> void:
	$Menus/PlayMenu/PlayMenuUI.reload_worlds()
	move_to_menu($Menus/PlayMenu)


# Play Menu ----------------------------------------------------------------------------------------
func _on_play_menu_back_button_pressed() -> void:
	move_to_menu($Menus/MainMenu)

## Singleplayer
func _on_load_world_menu_back_button_pressed() -> void:
	move_to_menu($Menus/PlayMenu)

func _on_load_world_menu_generate_new_world_button_pressed() -> void:
	move_to_menu($Menus/GenerateWorldMenu)

func load_world(world_name: String) -> void:
	add_sibling(game)
	game.hide()
	MultiplayerManager.host_server(game)
	
	$Menus.hide()
	loading_screen.show()
	
	if world_thread.is_started(): world_thread.wait_to_finish()
	var callable = Callable(self, "_load_world").bind(world_name)
	world_thread.start(callable)
	
func _load_world(world_name: String) -> void:
	world_generator.LoadWorld(world_name)

## Multiplayer
func _on_join_world_menu_back_button_pressed() -> void:
	move_to_menu($Menus/PlayMenu)

func connect_to_server(address: String, port: int) -> void:
	add_sibling(game)
	game.hide()
	MultiplayerManager.connect_to_server(game, address, port)
	
	$Menus.hide()
	loading_screen.show()
	
	if world_thread.is_started(): world_thread.wait_to_finish()
	var callable = Callable(self, "_load_world").bind("World")
	world_thread.start(callable)


# Generate World Menu ------------------------------------------------------------------------------
var world_generator: WorldGenerator = load("res://src/world/WorldGenerator.cs").new()
var world_thread: Thread = Thread.new()

func _on_generate_world_menu_back_button_pressed() -> void:
	$Menus/PlayMenu/PlayMenuUI.reload_worlds()
	move_to_menu($Menus/PlayMenu)

func _on_generate_world_menu_generate_world_button_pressed(world_name: String, world_seed: int, map_size: int, cave_offset: int) -> void:
	world_generator.WorldName = world_name
	world_generator.Seed = world_seed
	world_generator.MapSize = map_size
	world_generator.CaveOffset = cave_offset
	
	$Menus.hide()
	loading_screen.show()
	
	if world_thread.is_started(): world_thread.wait_to_finish()
	world_thread.start(_generate_world)

func _generate_world() -> void:
	world_generator.GenerateWorld()
	
func _on_world_gen_progress_update(details: String, percent: int) -> void:
	loading_screen.call_deferred("update", details, percent)

func _on_world_gen_completed() -> void:
	await get_tree().create_timer(1.5).timeout
	$Menus.call_deferred("show")
	loading_screen.call_deferred("hide")

func _on_world_load_completed() -> void:
	move_to_game = true
