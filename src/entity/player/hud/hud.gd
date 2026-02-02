extends Control

func _process(_delta: float) -> void:
	if !$Health.player || !$Minimap.player:
		return
	
	var player = get_tree().root.get_node("Game/World/Players/Player#%s" % multiplayer.get_unique_id())
	if !player:
		return
		
	$Health.player = player
	$Minimap.player = player
	$Map.player = player
