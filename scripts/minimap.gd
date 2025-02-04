extends TextureRect

@export var minimap_size: Vector2 = Vector2(300, 300)

func update(foreground: TileMapLayer):

	var tilemap_size = foreground.get_used_rect().size
	var img = Image.create(tilemap_size.x, tilemap_size.y, false, Image.FORMAT_RGB8)

	for x in range(tilemap_size.x):
		for y in range(tilemap_size.y):
			var tile = foreground.get_cell_tile_data(
				Vector2i(x-(tilemap_size.x/2), y-(tilemap_size.y/2))
			)
			var color = Color.WHITE if tile else Color.BLACK
			img.set_pixel(x, y, color)

	img.resize(minimap_size.x, minimap_size.y, Image.INTERPOLATE_NEAREST)
	var tex = ImageTexture.create_from_image(img)
	texture = tex
