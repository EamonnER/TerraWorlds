extends Node

var multiplayer_actor = preload("res://scripts/mp/multiplayer_player.tscn")
var _players_spawn_node
var current_scene

func _become_host(port: int) -> void:
	print("Starting Host Session...")
	_create_world()
	await get_tree().create_timer(0.1).timeout
		
	_players_spawn_node = get_tree().get_current_scene().get_node("Players")

	var server_peer = ENetMultiplayerPeer.new()
	server_peer.create_server(port)
	
	multiplayer.multiplayer_peer = server_peer
	multiplayer.peer_connected.connect(_add_player_to_world)
	multiplayer.peer_disconnected.connect(_disconnect)
	
	
	rpc("change_scene_for_clients", "res://game.tscn")
	_add_player_to_world(1)


# Host calls _create_world() on first join?
func _create_world() -> void:
	print("World Generation Begun.")
	get_tree().change_scene_to_file("res://game.tscn")
	current_scene = "res://game.tscn"

# Connecting to a session.
func _join_game(ip, port) -> void:
	print("Connecting to Host...")
	
	var client_peer = ENetMultiplayerPeer.new()
	client_peer.create_client(ip, port)
	
	multiplayer.multiplayer_peer = client_peer	
	

# Adds player instance to the world.
func _add_player_to_world(id: int) -> void:
	print("Player %s joined the game!" % id)
	rpc_id(id, "change_scene_for_clients", current_scene)  # Tell new client to change scene
	
	await get_tree().create_timer(0.5).timeout  # Ensure scene switch completes
	_remove_singleplayer_player()
	
	# Ensure _players_spawn_node exists before proceeding
	if not _players_spawn_node or not is_instance_valid(_players_spawn_node):
		print("Players node not found, trying to get it...")
		await get_tree().process_frame  # Wait a frame for the scene to load
		_players_spawn_node = get_tree().get_current_scene().get_node_or_null("Players")
	
	if not _players_spawn_node:
		print("Error: Players node STILL not found! Cannot add player.")
		return
	
	var player_to_add = multiplayer_actor.instantiate()
	player_to_add.entity_id = id
	player_to_add.name = str(id)
	
	_players_spawn_node.add_child(player_to_add, true)

	
# Deletes player instance from the world.
func _disconnect(id: int) -> void:
	print("Player %s has left the game." % id)
	
func _remove_singleplayer_player():
	print("Removing Singleplayer Actor.")
	var player_to_remove = get_tree().get_current_scene().get_node("Player")
	if player_to_remove:
		player_to_remove.queue_free()

@rpc("authority", "reliable")
func change_scene_for_clients(scene_path: String) -> void:
	if get_tree().current_scene.scene_file_path != scene_path:
		print("Switching to scene:", scene_path)
		get_tree().change_scene_to_file(scene_path)
