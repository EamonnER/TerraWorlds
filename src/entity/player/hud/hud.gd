extends Control

@onready var health = $Health
@onready var minimap = $Minimap
@onready var inventory = $Inventory

func _process(_delta: float) -> void:
	if !health.player || !minimap.player:
		return
	
	var player = get_tree().root.get_node("Game/World/Players/Player#%s" % multiplayer.get_unique_id())
	if !player:
		return
		
	health.player = player
	minimap.player = player
	player.inventory = inventory
