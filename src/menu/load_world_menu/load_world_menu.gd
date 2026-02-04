extends Control

signal generate_new_world_button_pressed
signal load_world(world_name: String)
signal back_button_pressed


func _on_generate_new_world_button_pressed() -> void:
	generate_new_world_button_pressed.emit()

func _on_load_world_button_pressed() -> void:
	load_world.emit("World")

func _on_back_button_pressed() -> void:
	back_button_pressed.emit()
