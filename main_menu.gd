extends Control

var game_path: String = "res://src/game.tscn"

func _on_generate_world_button_pressed() -> void:
	get_tree().change_scene_to_file(game_path)
