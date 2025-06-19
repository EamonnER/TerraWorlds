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

@onready var virtual_cursor := $VirtualCursor
var cursor_speed := 500.0
var deadzone := 0.2

func _process(delta: float) -> void:
	var x_input = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	var y_input = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	var move = Vector2(x_input, y_input)
	if move.length() > deadzone:
		move = move.normalized()
		virtual_cursor.position += move * cursor_speed * delta

	# Keep the cursor on-screen
	var screen_size = get_viewport().get_visible_rect().size
	virtual_cursor.position.x = clamp(virtual_cursor.position.x, 0, screen_size.x)
	virtual_cursor.position.y = clamp(virtual_cursor.position.y, 0, screen_size.y)
	
	# Simulate a mouse move at the cursor position
	var motion := InputEventMouseMotion.new()
	motion.position = virtual_cursor.position
	Input.parse_input_event(motion)

	
	if move_to_game:
		var game = game_scene.instantiate()
		game.world_generator = world_generator
		add_sibling(game)
		game.load_world()
		queue_free()
		
func _input(event):
	if event.is_action_pressed("ui_accept"):
		# Simulate press
		var press = InputEventMouseButton.new()
		press.button_index = MOUSE_BUTTON_LEFT
		press.pressed = true
		press.position = virtual_cursor.position
		Input.parse_input_event(press)
		
		# Simulate release
		var release = InputEventMouseButton.new()
		release.button_index = MOUSE_BUTTON_LEFT
		release.pressed = false
		release.position = virtual_cursor.position
		Input.parse_input_event(release)
