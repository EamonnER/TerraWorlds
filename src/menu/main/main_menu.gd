extends Control

signal generate_world_button_pressed
signal host_game_button_pressed
signal join_game_button_pressed


func _on_generate_world_button_pressed() -> void:
	generate_world_button_pressed.emit()

func _on_host_game_button_pressed() -> void:
	host_game_button_pressed.emit()

func _on_join_game_button_pressed() -> void:
	join_game_button_pressed.emit()
