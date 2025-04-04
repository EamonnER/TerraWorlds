extends TextureRect
class_name Minimap

@export var minimap_size: Vector2 = Vector2(300, 300)
#@export var player_texture: ImageTexture
@export var player_texture_size: Vector2 = Vector2(20, 20)

var player: Player

var foreground: TileMapLayer
var map_size: int
var map_image: Image

func draw(new_foreground: TileMapLayer):
	foreground = new_foreground

	var tilemap_size = foreground.get_used_rect().size
	var img = Image.create(tilemap_size.x, tilemap_size.y, false, Image.FORMAT_RGB8)

	for x in range(tilemap_size.x):
		for y in range(tilemap_size.y):
			var tile = foreground.get_cell_tile_data(
				Vector2i(x-(tilemap_size.x/2), y-(tilemap_size.y/2))
			)
			var colour = Color.WHITE if tile else Color.BLACK
			img.set_pixel(x, y, colour)

	img.resize(minimap_size.x, minimap_size.y, Image.INTERPOLATE_NEAREST)
	map_image = img
	texture = ImageTexture.create_from_image(map_image)

func draw_player(pos: Vector2):
	#if not world_map or not player_texture:
	if not map_image:
		return
	
	pos = foreground.local_to_map(pos)
	var img = map_image.duplicate()
	
	# Convert world position to minimap position
	var minimap_pos = Vector2(
		(((pos.x + (map_size/2)) / map_size) * minimap_size.x),
		(((pos.y + (map_size/2)) / map_size) * minimap_size.y)
	)
	
	# Draw the player texture on the image
	for x in range(player_texture_size.x):
		for y in range(player_texture_size.y):
			var px = int(minimap_pos.x - player_texture_size.x / 2 + x)
			var py = int(minimap_pos.y - player_texture_size.y / 2 + y)
			
			if px >= 0 and py >= 0 and px < img.get_width() and py < img.get_height():
				#var colour = player_texture.get_image().get_pixel(x, y)
				var colour = Color.BLUE
				if colour.a > 0:  # Only draw non-transparent pixels
					img.set_pixel(px, py, colour)
	
	texture = ImageTexture.create_from_image(img)

func _process(delta: float) -> void:
	if player:
		draw_player(player.get_global_position())
