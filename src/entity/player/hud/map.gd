extends ColorRect

var player: Player

func tilemap_to_texture(tilemap: TileMapLayer) -> ImageTexture:
	var tilemap_size = tilemap.get_used_rect().size
	var img = Image.create(tilemap_size.x, tilemap_size.y, false, Image.FORMAT_RGBA8)

	for x in range(tilemap_size.x):
		for y in range(tilemap_size.y):
			var tile = tilemap.get_cell_tile_data(
				Vector2i(x-(tilemap_size.x/2), y-(tilemap_size.y/2))
			)
			var colour: Color
			if tile:
				match tile.terrain:
					0:  # Grass
						colour = Color.DARK_GREEN
					1:  # Stone
						colour = Color.DARK_GRAY
					_:  # Default
						colour = Color.WHITE
			else:
				colour = Color.TRANSPARENT
			img.set_pixel(x, y, colour)

	img.resize(tilemap_size.x, tilemap_size.y, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(img)

func set_texture_from_tilemap(tilemap: TileMapLayer) -> void:
	$MapTexture.set_texture(tilemap_to_texture(tilemap))

func toggle() -> void:
	visible = not visible
	
	if !visible: return
	
	var world = get_tree().root.get_node("Game/World")
	if not world: return

	var tilemap = world.foreground
	set_texture_from_tilemap(tilemap)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("game_map"):
		toggle()
