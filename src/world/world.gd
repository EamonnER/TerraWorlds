@tool
extends Node2D
class_name World

@onready var terrain: TileMapLayer = $Terrain

const CHUNK_SIZE: int = GlobalVariables.CHUNK_SIZE
# Total width / height of playable / explorable area
var map_size: int = CHUNK_SIZE*32  # Must be divisible by CHUNK_SIZE

const DIRT_ID: Vector2i = Vector2i(0, 0)
const STONE_ID: Vector2i = Vector2i(0, 1)

const TILE_NULL: String = "Null"
const TILE_INVISIBLE: String = "Invisible"

var _tile_to_terrain: Dictionary[int, int] = {}  # Maps TilesEnum values to terrain indices in the Terrain TileSet
var _null_value: int  # TilesEnum value of Null

@onready var gravity_threshold_collision: CollisionPolygon2D = $GravityThresholdArea/GravityThresholdCollision

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var engine: Node = load("res://src/world/LightingEngine.cs").new()
	engine.name = "LightingEngine"
	add_child(engine)
	engine.Initialize(terrain)
	var overlay := Node2D.new()
	overlay.name = "LightOverlay"
	overlay.set_script(load("res://src/world/light_overlay.gd"))
	add_child(overlay)

func local_to_map(local_position: Vector2) -> Vector2i:
	return terrain.local_to_map(local_position)

func map_to_local(map_position: Vector2i) -> Vector2:
	return terrain.map_to_local(map_position)

func clear() -> void:
	terrain.clear()

func _build_tile_to_terrain() -> void:
	var name_to_value: Dictionary = Tiles.new().GetNameToValue()
	_null_value = name_to_value[TILE_NULL]
	var tile_set: TileSet = terrain.tile_set
	for terrain_index in tile_set.get_terrains_count(0):
		var terrain_name: String = tile_set.get_terrain_name(0, terrain_index)
		if name_to_value.has(terrain_name):
			_tile_to_terrain[name_to_value[terrain_name]] = terrain_index
		else:
			push_warning("Terrain '%s' has no matching entry in TileEnum.cs" % terrain_name)
	for tile_name in name_to_value.keys():
		var tile_value: int = name_to_value[tile_name]
		# Invisible has no terrain by design
		if not _tile_to_terrain.has(tile_value) and tile_name != TILE_NULL and tile_name != TILE_INVISIBLE:
			push_warning("Tile '%s' has no matching terrain in the Terrain TileSet" % tile_name)

func draw_chunk(chunk: Dictionary[int, Array]) -> void:
	if _tile_to_terrain.is_empty():
		_build_tile_to_terrain()
	for tile_id in chunk.keys():
		if tile_id == _null_value:
			terrain.set_cells_terrain_connect(chunk[tile_id], 0, -1)
		else:
			terrain.set_cells_terrain_connect(chunk[tile_id], 0, _tile_to_terrain[tile_id])

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
			return Vector2i(x, y-2) * GlobalVariables.TILE_SIZE
	return Vector2i(x, top_of_map) * GlobalVariables.TILE_SIZE

func get_tile_at_position(vector: Vector2i) -> TileData:
	return terrain.get_cell_tile_data(vector)

func place_tile(vector: Vector2i, terrain_id: int):
	terrain.set_cells_terrain_connect([vector], 0, terrain_id, false)
	var overlay: Node2D = get_node_or_null("LightOverlay")
	if overlay:
		overlay.mark_dirty()

func remove_tile(vector: Vector2i):
	terrain.set_cells_terrain_connect([vector], 0, -1, false)
	var overlay: Node2D = get_node_or_null("LightOverlay")
	if overlay:
		overlay.mark_dirty()

func _on_gravity_threshold_area_body_exited(body: Node2D) -> void:
	if body is Entity:
		body.update_rotation()
