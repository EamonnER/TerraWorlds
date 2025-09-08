extends Camera2D

@export var follow_speed: float = 10.0

var player: Player = null

func _ready():
	make_current()

func _physics_process(delta: float) -> void:
	if player:
		set_position(get_position().lerp(player.global_position, follow_speed * delta))
		
		if player.is_rotating:
			set_rotation(player.get_rotation())
	else:
		player = get_tree().root.get_node("Game/World/Players/Player#%s" % multiplayer.get_unique_id())
