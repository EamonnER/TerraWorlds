extends Node

const LOCALHOST: String = "127.0.0.1"
const DEFAULT_PORT: int = 8080

var player_scene = preload("res://src/entity/player/player.tscn")

var _game: Node2D

func host_server(game: Node2D, port: int = DEFAULT_PORT):
	_game = game
	
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(port)
	
	multiplayer.multiplayer_peer = peer
	
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	
	await _game.world_ready
	request_player(1)

func connect_to_server(game: Node2D, ip: String = LOCALHOST, port: int = DEFAULT_PORT):
	_game = game
	
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, port)
	
	multiplayer.multiplayer_peer = peer

func _peer_connected(id: int):
	request_player(id)

func _peer_disconnected(id: int):
	remove_player(id)

func request_player(id: int) -> void:
	var player: Player = player_scene.instantiate()
	player.id = id
	player.set_name("Player#%s" % id)
	
	var players_spawn_node = _game.get_node("World/Players")
	
	players_spawn_node.add_child(player, true)
	
	var world =_game.get_node("World")
	player.set_world(world)
	player.set_position(world.get_spawn_position())
	player.update_rotation()

func remove_player(id: int) -> void:
	var players_spawn_node = _game.get_node("World/Players")
	var player_name = "Player#%s" % id
	players_spawn_node.get_node(player_name).queue_free()
