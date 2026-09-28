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

# Combat ---------------------------------------------------------------------------------------------------------------
@rpc("any_peer", "call_local", "reliable")
func request_attack(attacker_id: int):
	if !multiplayer.is_server(): return

	var players_node = _game.get_node("World/Players")
	var player_name = "Player#%s" % attacker_id
	if !players_node.has_node(player_name): return

	var player: Player = players_node.get_node(player_name)
	var attack_range: float = 60.0
	var attack_damage: float = 25.0

	for node in _game.get_node("World").get_children():
		if node is Enemy and !node.is_dead:
			if player.global_position.distance_to(node.global_position) <= attack_range:
				node.take_damage(attack_damage)


# Inventory Management -------------------------------------------------------------------------------------------------
func initialise_ui_inventory(player_id: int, rows: int, columns: int) -> void:
	var hud = _game.get_node("CanvasLayer/HUD")
	var inventory_ui = hud.get_node("Inventory")
	inventory_ui.initialise.rpc_id(player_id, rows, columns)

func set_ui_inventory_slot(player_id: int, item_stack: ItemStack, row: int, column: int) -> void:
	var hud = _game.get_node("CanvasLayer/HUD")
	var inventory_ui = hud.get_node("Inventory")
	inventory_ui.set_slot.rpc_id(player_id, row, column, item_stack.get_item_id(), item_stack.quantity)
