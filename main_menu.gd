extends Control

var game_scene: PackedScene = preload("res://src/game.tscn")

func _on_generate_world_button_pressed() -> void:
	var game = game_scene.instantiate()
	get_tree().root.add_child(game)
	get_tree().set_current_scene(game)
	game.generate_world()
	self.queue_free()


func _on_load_world_button_pressed() -> void:
	var game = game_scene.instantiate()
	get_tree().root.add_child(game)
	get_tree().set_current_scene(game)
	game.load_world()
	self.queue_free()
