extends Node

var _game: Node2D

# World Editing --------------------------------------------------------------------------------------------------------
@rpc("any_peer", "call_local", "reliable")  # Clients call to server, server validates
func request_place_tile(tile: Vector2i, terrain_id: int):
	if !multiplayer.is_server(): return
	# TODO validation
	_place_tile(tile, terrain_id)  # Server creates change locally
	_place_tile.rpc(tile, terrain_id)  # Server creates change on all clients

@rpc("authority", "call_remote", "reliable")  # Server calls all clients
func _place_tile(tile: Vector2i, terrain_id: int):
	var world = _game.get_node("World")
	world.place_tile(tile, terrain_id)


@rpc("any_peer", "call_local", "reliable")  # Clients call to server, server validates
func request_remove_tile(tile: Vector2i):
	if !multiplayer.is_server(): return
	# TODO validation
	_remove_tile(tile)  # Server creates change locally
	_remove_tile.rpc(tile)  # Server creates change on all clients

@rpc("authority", "call_remote", "reliable")  # Server calls all clients
func _remove_tile(tile: Vector2i):
	var world = _game.get_node("World")
	world.remove_tile(tile)


# Item Interaction ---------------------------------------------------------------------------------------------

		
