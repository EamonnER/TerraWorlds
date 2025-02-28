extends Control

@onready var health = $Health
@onready var minimap = $Minimap
@onready var inventory = $Inventory

func set_target(new_player: Player):
	if not new_player.is_multiplayer_authority():
		minimap.queue_free()
		health.queue_free()
		inventory.queue_free()
		return

	health.player = new_player
	minimap.player = new_player
	inventory.player = new_player
	new_player.inventory = inventory
