@tool
extends Node2D
class_name World

@onready var foreground: TileMapLayer = $Foreground
@onready var item_scene = preload("res://src/item/Item.tscn")

const WORLD_SIZE: int = 600  # Total width / height of world (should be even)
const MAP_SIZE: int = WORLD_SIZE * 4  # Total width / height of playable / explorable area

const DIRT_ID: Vector2i = Vector2i(0, 0)
const STONE_ID: Vector2i = Vector2i(0, 1)

@onready var gravity_threshold_collision: CollisionPolygon2D = $GravityThresholdArea/GravityThresholdCollision


func local_to_map(local_position: Vector2) -> Vector2i:
	return foreground.local_to_map(local_position)

func map_to_local(map_position: Vector2i) -> Vector2:
	return foreground.map_to_local(map_position)

func generate_new_world():
	foreground.clear()
	
	const HALF_WORLD = WORLD_SIZE / 2
	const CAVE_OFFSET = 20
	var terrain_to_pos = Dictionary()
	terrain_to_pos[DIRT_ID] = Dictionary()
	terrain_to_pos[STONE_ID] = Dictionary()
	
	_build_base_world(terrain_to_pos, CAVE_OFFSET)
	
	
	
	_add_surface_heightmap(terrain_to_pos)
	
	_add_caves(terrain_to_pos, CAVE_OFFSET)
	
	for terrain_id in terrain_to_pos.keys():
		foreground.set_cells_terrain_connect(terrain_to_pos[terrain_id].keys(), terrain_id.x, terrain_id.y)
	
	#foreground.set_cells_terrain_connect(tile_positions.keys(), 0, 0)
	
	_draw_gravity_collision()

func _add_surface_heightmap(terrain_to_pos: Dictionary) -> void:
	# Apply heightmap using radial distance
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	const HALF_WORLD = WORLD_SIZE/2
	const MAX_DEPTH = HALF_WORLD/4
	
	var positions_to_erase = []
	for x in range(WORLD_SIZE*4):
		var noise_value = abs(noise.get_noise_2d(x, 0))
		var depth = int(noise_value * MAX_DEPTH)
		
		# Top side
		if x <= WORLD_SIZE:
			for y in range(depth):
				positions_to_erase.append(Vector2i(HALF_WORLD-x, -HALF_WORLD+y))
		
		# Left side
		elif x <= WORLD_SIZE * 2:
			x -= WORLD_SIZE
			for y in range(depth):
				positions_to_erase.append(Vector2i(-HALF_WORLD+y, x-HALF_WORLD))
		
		# Bottom side
		elif x <= WORLD_SIZE * 3:
			x -= WORLD_SIZE*2
			for y in range(depth):
				positions_to_erase.append(Vector2i(x-HALF_WORLD, HALF_WORLD-y))
		
		# Right side
		else:
			x -= WORLD_SIZE*3
			for y in range(depth):
				positions_to_erase.append(Vector2i(HALF_WORLD-y, HALF_WORLD-x))
	
	_erase_tiles(terrain_to_pos, positions_to_erase)

func _add_caves(terrain_to_pos: Dictionary, cave_offset: int) -> void:
	# Remove tiles for cave systems
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	var is_cave_tile = func (vector: Vector2i) -> bool:
		return true if (abs(vector.x) < WORLD_SIZE/2 - cave_offset and 
						abs(vector.y) < WORLD_SIZE/2 - cave_offset and 
						noise.get_noise_2d(vector.x, vector.y) > 0.2) \
					else false
	
	var cave_tile_positions = []
	for terrain_id in terrain_to_pos.keys():
		cave_tile_positions += terrain_to_pos[terrain_id].keys().filter(is_cave_tile)
	_erase_tiles(terrain_to_pos, cave_tile_positions)

func _build_base_world(terrain_to_pos: Dictionary, cave_offset: int) -> void:
	const HALF_WORLD = WORLD_SIZE/2
	var cave_threshold = (HALF_WORLD) - cave_offset
	
	for x in range(-HALF_WORLD, HALF_WORLD):
		for y in range(-HALF_WORLD, HALF_WORLD):
			# Below line y = -HALF_WORLD+cave_offset;
			# Left of line x = HALF_WORLD-cave_offset;
			# Above line y = HALF_WORLD-cave_offset;
			# Right of line x = -HALF_WORLD+cave_offset
			if (y > -HALF_WORLD+cave_offset) and \
				(x < HALF_WORLD-cave_offset) and \
				(y < HALF_WORLD-cave_offset) and \
				(x > -HALF_WORLD+cave_offset):
				terrain_to_pos[STONE_ID][Vector2i(x, y)] = null
			else:
				terrain_to_pos[DIRT_ID][Vector2i(x, y)] = null
				

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
	var item = item_scene.instantiate()
	var dropped_item = item.to_dropped_item()
	add_child(dropped_item)
	dropped_item.position = get_spawn_position() + Vector2i(40, 0)
