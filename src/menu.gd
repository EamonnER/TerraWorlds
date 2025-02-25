extends Control

var SERVER_IP = "127.0.0.1"
var SERVER_PORT = 23398

func _on_singleplayer_pressed() -> void:
	get_tree().change_scene_to_file("res://game.tscn")

func _on_host_pressed() -> void:
	MultiplayerManager._become_host(SERVER_PORT)
	
	
func _on_join_pressed() -> void:
	MultiplayerManager._join_game(SERVER_IP, SERVER_PORT)

func _on_options_pressed() -> void:
	pass # Replace with function body.


func _on_quit_pressed() -> void:
	get_tree().quit()
