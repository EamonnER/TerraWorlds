extends Control

signal play_button_pressed
signal settings_button_pressed
signal quit_button_pressed

func _on_play_button_pressed() -> void:
	play_button_pressed.emit()

func _on_settings_button_pressed() -> void:
	settings_button_pressed.emit()

func _on_quit_button_pressed() -> void:
	quit_button_pressed.emit()
