extends Node

signal connection_success
signal connection_failed

const LOCALHOST: String = "127.0.0.1"

var player_scene: PackedScene = preload("res://src/entity/player/player.tscn")
var dropped_item_scene: PackedScene = preload("res://src/item/dropped_item.tscn")

var _game: Node2D

func _ready() -> void:
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)

func _on_connected():
	connection_success.emit()

func _on_connection_failed():
	connection_failed.emit()

func _process(_delta: float) -> void:
	var peer := multiplayer.multiplayer_peer

	if peer is ExpressoSteamMultiplayerPeer:
		peer.poll()


# Hosting server -------------------------------------------------------------------------------------------------------
func host_server(game: Node2D, multiplayer_connection_details: Dictionary) -> void:
	assign_game(game)
	
	match multiplayer_connection_details["connection_type"]:
		GlobalVariables.MULTIPLAYER_CONNECTION_TYPE.STEAM:
			var peer := ExpressoSteamMultiplayerPeer.new()
			var result := peer.create_host(0)

			if result != OK:
				print("[MultiplayerManager] Steam host creation failed: ", result)
				return

			multiplayer.multiplayer_peer = peer
			SteamManager.host_game()
			
		GlobalVariables.MULTIPLAYER_CONNECTION_TYPE.ENET:
			var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
			peer.create_server(multiplayer_connection_details["port"])
			multiplayer.multiplayer_peer = peer
		
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	
	await _game.world_ready
	request_player(1)

func open_steam_invite_overlay() -> void:
	if SteamManager and SteamManager.has_method("open_invite_overlay"):
		SteamManager.open_invite_overlay()

func assign_game(game: Node2D) -> void:
	_game = game
	RpcInterface._game = game


# Joining server -------------------------------------------------------------------------------------------------------
func connect_to_server(game: Node2D, multiplayer_connection_details: Dictionary) -> void:
	assign_game(game)
	
	var peer
	match multiplayer_connection_details["connection_type"]:
		GlobalVariables.MULTIPLAYER_CONNECTION_TYPE.STEAM:
			print("[MultiplayerManager] Steam lobby joined")
			print("[MultiplayerManager] Connecting to host SteamID: ", multiplayer_connection_details["host_steam_id"])
		
			peer = ExpressoSteamMultiplayerPeer.new()
		
			var result = peer.create_client(multiplayer_connection_details["host_steam_id"], 0)
		
			if result != OK:
				print("[MultiplayerManager] Steam peer creation failed: ", result)
				return
			
		GlobalVariables.MULTIPLAYER_CONNECTION_TYPE.ENET:
			peer = ENetMultiplayerPeer.new()
			peer.create_client(multiplayer_connection_details["ip"], multiplayer_connection_details["port"])
	
	multiplayer.multiplayer_peer = peer


# On peer connection ---------------------------------------------------------------------------------------------------
func _peer_connected(id: int):
	request_player(id)

func request_player(id: int) -> void:
	var player: Player = player_scene.instantiate()
	player.id = id
	player.set_name("Player#%s" % id)
	
	var players_spawn_node: MultiplayerSpawner = _game.get_node("World/Players")
	players_spawn_node.add_child(player, true)
	
	var world: World = _game.get_node("World")
	player.set_position(world.get_spawn_position())
	player.update_rotation()


# On peer disconnection ------------------------------------------------------------------------------------------------
func _peer_disconnected(id: int):
	remove_player(id)

func remove_player(id: int) -> void:
	var players_spawn_node: MultiplayerSpawner = _game.get_node("World/Players")
	var player_name: String = "Player#%s" % id
	players_spawn_node.get_node(player_name).queue_free()


# Item spawning --------------------------------------------------------------------------------------------------------
func spawn_item_stack(item_stack: ItemStack) -> void:
	var dropped_item: DroppedItem = dropped_item_scene.instantiate()
	dropped_item.set_item_stack(item_stack)
	
	var world: World = _game.get_node("World")
	var item_spawn_node: MultiplayerSpawner = world.get_node("Items")
	item_spawn_node.add_child(dropped_item)
	dropped_item.set_position(world.get_spawn_position())
