extends Control

signal load_world_button_pressed
signal join_world_button_pressed
signal back_button_pressed


func _on_load_world_button_pressed() -> void:
	load_world_button_pressed.emit()

func _on_join_world_button_pressed() -> void:
	join_world_button_pressed.emit()

func _on_back_button_pressed() -> void:
	back_button_pressed.emit()
