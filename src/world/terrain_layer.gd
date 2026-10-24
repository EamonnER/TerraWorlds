extends TileMapLayer
class_name TerrainLayer

const TILE_NULL: String = "Null"

var _tile_to_terrain: Dictionary[int, int] = {}  # Maps TilesEnum values to terrain indices in the Terrain TileSet
var _null_value: int  # TilesEnum value of Null

# Groups of terrain names that count as each other's neighbours when autotiling
const CONNECTED_TERRAINS: Array = [
	["Dirt", "Grass"],
	["Dirt", "Stone"],
]

# Neighbour bits in mask order (bit 0 = top, then clockwise). Even bits are sides, odd bits are corners
const NEIGHBOUR_BITS: Array = [
	TileSet.CELL_NEIGHBOR_TOP_SIDE,
	TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
	TileSet.CELL_NEIGHBOR_RIGHT_SIDE,
	TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,
	TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
	TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,
	TileSet.CELL_NEIGHBOR_LEFT_SIDE,
	TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER,
]
const NEIGHBOUR_OFFSETS: Array = [
	Vector2i(0, -1), Vector2i(1, -1), Vector2i(1, 0), Vector2i(1, 1),
	Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(-1, -1),
]
const FULL_MASK: int = 0xFF

var _terrain_group: Dictionary[int, int] = {}  # Maps terrain indices to a group id, terrains with the same id connect
var _terrain_tiles: Dictionary[int, Array] = {}  # Maps terrain indices to 256 tiles indexed by neighbour mask, each [source_id, atlas_coords, alternative]

func _build_tile_to_terrain() -> void:
	var name_to_value: Dictionary = Tiles.GetNameToValue()
	_null_value = name_to_value[TILE_NULL]
	for terrain_index in tile_set.get_terrains_count(0):
		var terrain_name: String = tile_set.get_terrain_name(0, terrain_index)
		if name_to_value.has(terrain_name):
			_tile_to_terrain[name_to_value[terrain_name]] = terrain_index
		else:
			push_warning("Terrain '%s' has no matching entry in TileEnum.cs" % terrain_name)
	for tile_name in name_to_value.keys():
		var tile_value: int = name_to_value[tile_name]
		if not _tile_to_terrain.has(tile_value) and tile_name != TILE_NULL:
			push_warning("Tile '%s' has no matching terrain in the Terrain TileSet" % tile_name)

func _build_autotile_lookup() -> void:
	for terrain_index in tile_set.get_terrains_count(0):
		_terrain_group[terrain_index] = terrain_index
	for group in CONNECTED_TERRAINS:
		var group_id: int = -1
		for terrain_index in tile_set.get_terrains_count(0):
			if tile_set.get_terrain_name(0, terrain_index) in group:
				if group_id == -1:
					group_id = terrain_index
				_terrain_group[terrain_index] = group_id

	# Collect every terrain tile by the mask of peering bits that match its own terrain
	var tiles_by_mask: Dictionary = {}  # terrain index -> {mask: [source_id, atlas_coords, alternative]}
	for source_index in tile_set.get_source_count():
		var source_id: int = tile_set.get_source_id(source_index)
		var source := tile_set.get_source(source_id) as TileSetAtlasSource
		if source == null:
			continue
		for tile_index in source.get_tiles_count():
			var atlas_coords: Vector2i = source.get_tile_id(tile_index)
			for alternative_index in source.get_alternative_tiles_count(atlas_coords):
				var alternative: int = source.get_alternative_tile_id(atlas_coords, alternative_index)
				var data: TileData = source.get_tile_data(atlas_coords, alternative)
				if data.terrain_set != 0 or data.terrain < 0:
					continue
				var mask: int = 0
				for bit in NEIGHBOUR_BITS.size():
					if data.is_valid_terrain_peering_bit(NEIGHBOUR_BITS[bit]) \
							and data.get_terrain_peering_bit(NEIGHBOUR_BITS[bit]) == data.terrain:
						mask |= 1 << bit
				mask = _normalise_mask(mask)
				if not tiles_by_mask.has(data.terrain):
					tiles_by_mask[data.terrain] = {}
				if not tiles_by_mask[data.terrain].has(mask):
					tiles_by_mask[data.terrain][mask] = [source_id, atlas_coords, alternative]

	for terrain_index in tiles_by_mask.keys():
		var lookup: Array = []
		lookup.resize(FULL_MASK + 1)
		for mask in FULL_MASK + 1:
			lookup[mask] = _closest_tile(tiles_by_mask[terrain_index], _normalise_mask(mask))
		_terrain_tiles[terrain_index] = lookup

# A corner only counts when both sides next to it are connected, the same as Match Corners and Sides
static func _normalise_mask(mask: int) -> int:
	for corner in [1, 3, 5, 7]:
		var side_a: int = corner - 1
		var side_b: int = (corner + 1) % 8
		if mask & (1 << side_a) == 0 or mask & (1 << side_b) == 0:
			mask &= ~(1 << corner)
	return mask

# Exact match if the terrain has one, otherwise the tile that matches the most bits (sides weigh more than corners)
static func _closest_tile(tiles: Dictionary, mask: int) -> Array:
	if tiles.has(mask):
		return tiles[mask]
	var best_tile: Array = []
	var best_score: int = -1
	for tile_mask in tiles.keys():
		var score: int = 0
		for bit in 8:
			if (tile_mask >> bit) & 1 == (mask >> bit) & 1:
				score += 1 if bit % 2 == 1 else 2
		if score > best_score:
			best_score = score
			best_tile = tiles[tile_mask]
	return best_tile

func _ensure_lookups() -> void:
	if _tile_to_terrain.is_empty():
		_build_tile_to_terrain()
	if _terrain_tiles.is_empty():
		_build_autotile_lookup()

func _get_terrain_at(cell: Vector2i) -> int:
	var data: TileData = get_cell_tile_data(cell)
	if data == null or data.terrain_set != 0:
		return -1
	return data.terrain

func _autotile_cell(cell: Vector2i) -> void:
	var cell_terrain: int = _get_terrain_at(cell)
	if not _terrain_tiles.has(cell_terrain):
		return
	var group: int = _terrain_group[cell_terrain]
	var mask: int = 0
	for bit in 8:
		var neighbour_terrain: int = _get_terrain_at(cell + NEIGHBOUR_OFFSETS[bit])
		if neighbour_terrain != -1 and _terrain_group.get(neighbour_terrain, -1) == group:
			mask |= 1 << bit
	var tile: Array = _terrain_tiles[cell_terrain][mask]
	set_cell(cell, tile[0], tile[1], tile[2])

# Sets each cell to its terrain, then picks the right tile for those cells and their neighbours
func set_cells_autotiled(cells: Dictionary) -> void:
	_ensure_lookups()
	var to_update: Dictionary[Vector2i, bool] = {}
	for cell in cells.keys():
		var terrain_index: int = cells[cell]
		if _terrain_tiles.has(terrain_index):
			var tile: Array = _terrain_tiles[terrain_index][FULL_MASK]
			set_cell(cell, tile[0], tile[1], tile[2])
		else:
			erase_cell(cell)
		to_update[cell] = true
		for offset in NEIGHBOUR_OFFSETS:
			to_update[cell + offset] = true
	for cell in to_update.keys():
		_autotile_cell(cell)

func draw_chunk(chunk: Dictionary[int, Array]) -> void:
	_ensure_lookups()
	var cells: Dictionary[Vector2i, int] = {}
	for tile_id in chunk.keys():
		var terrain_index: int = -1 if tile_id == _null_value else _tile_to_terrain[tile_id]
		for pos in chunk[tile_id]:
			cells[Vector2i(pos)] = terrain_index
	set_cells_autotiled(cells)

func draw_chunks(chunks: Array[Dictionary]) -> void:
	for chunk in chunks:
		draw_chunk(chunk)
