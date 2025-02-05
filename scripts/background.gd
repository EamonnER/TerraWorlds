extends TextureRect

func resize():
	var window_size = get_viewport().size
	size = window_size
	set_position(Vector2(-size.x/2, -size.y/2))

func _ready() -> void:
	resize()
