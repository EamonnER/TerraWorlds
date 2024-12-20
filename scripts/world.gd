@tool
extends Node2D

@onready var foreground: TileMapLayer = $Foreground

const WORLD_SIZE: int = 100  # Total width / height of world (should be even)
const MAP_SIZE: int = WORLD_SIZE * 3  # Total width / height of playable / explorable area

func generate_new_world():
	foreground.clear()
	
	# Generates a list of vectors from (-50, -50) to (50, 50)
	const HALF_WORLD = WORLD_SIZE / 2
	var tile_positions = []
	for x in range(-HALF_WORLD, HALF_WORLD):
		for y in range(-HALF_WORLD, HALF_WORLD):
			tile_positions.append(Vector2i(x, y))
	
	foreground.set_cells_terrain_connect(tile_positions, 0, 0)

func get_spawn_position() -> Vector2i:
	# Iterates from top of map down until it finds a tile
	const TOP_OF_MAP = MAP_SIZE / 2
	const x = 0
	
	for y in range(-TOP_OF_MAP, TOP_OF_MAP):
		if get_tile_at_position(Vector2i(x, y)):
			return Vector2i(x, y-1)
	return Vector2i(x, TOP_OF_MAP)

func get_tile_at_position(vector: Vector2i) -> TileData:
	return foreground.get_cell_tile_data(vector)


func place_tile(vector: Vector2i, terrain_id: int):
	foreground.set_cell(vector, terrain_id)

func remove_tile(vector: Vector2i):
	foreground.set_cell(vector, -1)
