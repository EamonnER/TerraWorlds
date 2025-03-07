@tool
extends Node2D
class_name World

@onready var foreground: TileMapLayer = $Foreground

const CHUNK_SIZE: int = GlobalVariables.CHUNK_SIZE
# Total width / height of playable / explorable area
const MAP_SIZE: int = CHUNK_SIZE*32  # Must be divisible by CHUNK_SIZE

const DIRT_ID: Vector2i = Vector2i(0, 0)
const STONE_ID: Vector2i = Vector2i(0, 1)

@onready var gravity_threshold_collision: CollisionPolygon2D = $GravityThresholdArea/GravityThresholdCollision

var world_generator: WorldGenerator = load("res://src/world/WorldGenerator.cs").new()

func local_to_map(local_position: Vector2) -> Vector2i:
	return foreground.local_to_map(local_position)

func map_to_local(map_position: Vector2i) -> Vector2:
	return foreground.map_to_local(map_position)

func generate_new_world():
	foreground.clear()
	var world_seed = randi()
	var cave_offset = 20
	
	world_generator.GenerateWorld(MAP_SIZE, world_seed, cave_offset)
	for x in range(MAP_SIZE/CHUNK_SIZE):
		for y in range(MAP_SIZE/CHUNK_SIZE):
			var chunk = world_generator.GetChunk(x, y)
			for terrain_id in chunk.keys():
				if terrain_id == 2:
					foreground.set_cells_terrain_connect(chunk[terrain_id], 0, 0)
				elif terrain_id == 3:
					foreground.set_cells_terrain_connect(chunk[terrain_id], 0, 1)
				
	_draw_gravity_collision()

func _draw_gravity_collision() -> void:
	var width = 1.0
	var points = [
		map_to_local(Vector2(-MAP_SIZE/2, -MAP_SIZE/2)),  # Top left corner
		map_to_local(Vector2(-MAP_SIZE/2, (-MAP_SIZE/2)+width)),  # Below top left corner
		map_to_local(Vector2(-width, 0)),  # Centre left corner 
		map_to_local(Vector2(-MAP_SIZE/2, (MAP_SIZE/2)-width)),  # Above bottom left corner
		map_to_local(Vector2(-MAP_SIZE/2, MAP_SIZE/2)),  # Bottom left corner
		map_to_local(Vector2((-MAP_SIZE/2)+width, MAP_SIZE/2)),  # Right of bottom left corner
		map_to_local(Vector2(0, width)),  # Centre bottom
		map_to_local(Vector2((MAP_SIZE/2)-width, MAP_SIZE/2)),  # Left of bottom right corner
		map_to_local(Vector2(MAP_SIZE/2, MAP_SIZE/2)),  # Bottom right corner
		map_to_local(Vector2(MAP_SIZE/2, (MAP_SIZE/2)-width)),  # Above bottom right corner
		map_to_local(Vector2(width, 0)),  # Centre right
		map_to_local(Vector2(MAP_SIZE/2, (-MAP_SIZE/2)+width)),  # Below top right corner
		map_to_local(Vector2(MAP_SIZE/2, -MAP_SIZE/2)),  # Top right corner
		map_to_local(Vector2((MAP_SIZE/2)-width, -MAP_SIZE/2)),  # Left of top right corner
		map_to_local(Vector2(0, -width)),  # Centre top
		map_to_local(Vector2((-MAP_SIZE/2)+width, -MAP_SIZE/2)),  # Right of top left corner
	]

	gravity_threshold_collision.set_polygon(PackedVector2Array(points))

func _erase_tiles(terrain_to_pos: Dictionary, positions: Array) -> void:
	for pos in positions:
		for terrain_id in terrain_to_pos.keys():
			terrain_to_pos[terrain_id].erase(pos)
		
func get_spawn_position() -> Vector2i:
	# Iterates from top of map down until it finds a tile
	const TOP_OF_MAP = MAP_SIZE / 2
	const x = 0
	
	for y in range(-TOP_OF_MAP, TOP_OF_MAP):
		if get_tile_at_position(Vector2i(x, y)):
			return Vector2i(x, y-1) * GlobalVariables.TILE_SIZE
	return Vector2i(x, TOP_OF_MAP) * GlobalVariables.TILE_SIZE

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
	var dropped_item = item.to_dropped_item()
	add_child(dropped_item)
	dropped_item.position = get_spawn_position() + Vector2i(40, 0)
