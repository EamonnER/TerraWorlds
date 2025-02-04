@tool
extends Node2D

@onready var foreground: TileMapLayer = $Foreground

const WORLD_SIZE: int = 600  # Total width / height of world (should be even)
const MAP_SIZE: int = WORLD_SIZE * 3  # Total width / height of playable / explorable area

func generate_new_world():
	foreground.clear()
	
	const HALF_WORLD = WORLD_SIZE / 2
	var tile_positions = Dictionary()
	
	# Build completely full world
	for x in range(-HALF_WORLD, HALF_WORLD):
		for y in range(-HALF_WORLD, HALF_WORLD):
			tile_positions[Vector2i(x, y)] = null
	
	# Apply heightmap using radial distance
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	const MAX_DEPTH = HALF_WORLD/4
	for x in range(WORLD_SIZE):
		var noise_value = abs(noise.get_noise_2d(x, 0))
		var depth = int(noise_value * MAX_DEPTH)
		print(depth)
		for y in range(depth):
			tile_positions.erase(Vector2i(x, -HALF_WORLD+y))
	
	# Remove tiles for cave systems
	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	#for position in tile_positions.keys():
		#if noise.get_noise_2d(position.x, position.y) > 0.2:
			#tile_positions.erase(position)
	
	foreground.set_cells_terrain_connect(tile_positions.keys(), 0, 0)

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
	foreground.set_cell(vector, terrain_id)

func remove_tile(vector: Vector2i):
	foreground.set_cell(vector, -1)
