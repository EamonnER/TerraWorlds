extends Control

@onready var health = $Health
@onready var minimap = $Minimap
@onready var inventory = $Inventory

func set_target(new_player: Player):
	health.player = new_player
	minimap.player = new_player
	new_player.inventory = inventory
