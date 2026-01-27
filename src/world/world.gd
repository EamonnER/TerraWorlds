@tool
extends Node2D
class_name World

@onready var foreground: TileMapLayer = $Foreground

const CHUNK_SIZE: int = GlobalVariables.CHUNK_SIZE
# Total width / height of playable / explorable area
var map_size: int = CHUNK_SIZE*32  # Must be divisible by CHUNK_SIZE

const DIRT_ID: Vector2i = Vector2i(0, 0)
const STONE_ID: Vector2i = Vector2i(0, 1)

@onready var gravity_threshold_collision: CollisionPolygon2D = $GravityThresholdArea/GravityThresholdCollision

func local_to_map(local_position: Vector2) -> Vector2i:
	return foreground.local_to_map(local_position)

func map_to_local(map_position: Vector2i) -> Vector2:
	return foreground.map_to_local(map_position)

func clear() -> void:
	foreground.clear()

func draw_chunk(chunk: Dictionary[int, Array]) -> void:
	for terrain_id in chunk.keys():
		if terrain_id == 0:
			foreground.set_cells_terrain_connect(chunk[terrain_id], 0, -1)
		if terrain_id == 2:
			foreground.set_cells_terrain_connect(chunk[terrain_id], 0, 0)
		elif terrain_id == 3:
			foreground.set_cells_terrain_connect(chunk[terrain_id], 0, 1)

func draw_chunks(chunks: Array[Dictionary]) -> void:
	for chunk in chunks:
		draw_chunk(chunk)

func draw_gravity_collision() -> void:
	var width = 1.0
	var points = [
		map_to_local(Vector2(-map_size/2, -map_size/2)),  # Top left corner
		map_to_local(Vector2(-map_size/2, (-map_size/2)+width)),  # Below top left corner
		map_to_local(Vector2(-width, 0)),  # Centre left corner 
		map_to_local(Vector2(-map_size/2, (map_size/2)-width)),  # Above bottom left corner
		map_to_local(Vector2(-map_size/2, map_size/2)),  # Bottom left corner
		map_to_local(Vector2((-map_size/2)+width, map_size/2)),  # Right of bottom left corner
		map_to_local(Vector2(0, width)),  # Centre bottom
		map_to_local(Vector2((map_size/2)-width, map_size/2)),  # Left of bottom right corner
		map_to_local(Vector2(map_size/2, map_size/2)),  # Bottom right corner
		map_to_local(Vector2(map_size/2, (map_size/2)-width)),  # Above bottom right corner
		map_to_local(Vector2(width, 0)),  # Centre right
		map_to_local(Vector2(map_size/2, (-map_size/2)+width)),  # Below top right corner
		map_to_local(Vector2(map_size/2, -map_size/2)),  # Top right corner
		map_to_local(Vector2((map_size/2)-width, -map_size/2)),  # Left of top right corner
		map_to_local(Vector2(0, -width)),  # Centre top
		map_to_local(Vector2((-map_size/2)+width, -map_size/2)),  # Right of top left corner
	]

	gravity_threshold_collision.set_polygon(PackedVector2Array(points))

func _erase_tiles(terrain_to_pos: Dictionary, positions: Array) -> void:
	for pos in positions:
		for terrain_id in terrain_to_pos.keys():
			terrain_to_pos[terrain_id].erase(pos)
		
func get_spawn_position() -> Vector2i:
	# Iterates from top of map down until it finds a tile
	var top_of_map = map_size / 2
	const x = 0
	
	for y in range(-top_of_map, top_of_map):
		if get_tile_at_position(Vector2i(x, y)):
			return Vector2i(x, y-1) * GlobalVariables.TILE_SIZE
	return Vector2i(x, top_of_map) * GlobalVariables.TILE_SIZE

func get_tile_at_position(vector: Vector2i) -> TileData:
	return foreground.get_cell_tile_data(vector)

func place_tile(vector: Vector2i, terrain_id: int):
	foreground.set_cells_terrain_connect([vector], 0, terrain_id, false)
	
func remove_tile(vector: Vector2i):
	foreground.set_cells_terrain_connect([vector], 0, -1, false)

func _on_gravity_threshold_area_body_exited(body: Node2D) -> void:
	if body is Entity:
		body.update_rotation()

func spawn_item() -> void:
	var item = PotionItem.new()
	var item_stack = ItemStack.new()
	item_stack.set_item(item, 1)
	var dropped_item = preload("res://src/item/dropped_item.tscn").instantiate()
	dropped_item.set_item_stack(item_stack)
	
	add_child(dropped_item)
	dropped_item.position = get_spawn_position() + Vector2i(40, 0)
