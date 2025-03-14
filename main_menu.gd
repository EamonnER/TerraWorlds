extends Control

var game_scene: PackedScene = preload("res://src/game.tscn")
var loading_screen: Control = preload("res://src/loading/loading_screen.tscn").instantiate()

func show_loading_screen() -> void:
	self.hide()
	get_tree().root.add_child(loading_screen)

func _on_generate_world_button_pressed() -> void:
	show_loading_screen()
	
	var game = game_scene.instantiate()
	get_tree().root.add_child(game)
	get_tree().set_current_scene(game)
	game.generate_world()
	self.queue_free()
	loading_screen.queue_free()

func _on_load_world_button_pressed() -> void:
	show_loading_screen()
	
	var game = game_scene.instantiate()
	get_tree().root.add_child(game)
	get_tree().set_current_scene(game)
	game.load_world()
	self.queue_free()
	loading_screen.queue_free()
