extends Node2D

const TILE_SIZE: int = GlobalVariables.TILE_SIZE
const MARGIN: int = 30
const AIR_DECAY: float = 0.04
const SOLID_DECAY: float = 0.18

var _foreground: TileMapLayer
var _image: Image
var _texture: ImageTexture
var _region_origin: Vector2i
var _region_width: int
var _region_height: int

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	z_index = 100
	_foreground = get_parent().get_node("Foreground") as TileMapLayer

func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or _foreground == null:
		return

	var camera := get_viewport().get_camera_2d()
	if not camera:
		return

	var vp_size := get_viewport_rect().size
	var ct := get_viewport().get_canvas_transform()
	var inv := ct.affine_inverse()
	var corners: Array[Vector2] = [
		inv * Vector2.ZERO,
		inv * Vector2(vp_size.x, 0),
		inv * vp_size,
		inv * Vector2(0, vp_size.y)
	]

	var min_x := corners[0].x
	var max_x := corners[0].x
	var min_y := corners[0].y
	var max_y := corners[0].y
	for c in corners:
		min_x = minf(min_x, c.x)
		max_x = maxf(max_x, c.x)
		min_y = minf(min_y, c.y)
		max_y = maxf(max_y, c.y)

	var tile_min := _foreground.local_to_map(Vector2(min_x, min_y)) - Vector2i(MARGIN, MARGIN)
	var tile_max := _foreground.local_to_map(Vector2(max_x, max_y)) + Vector2i(MARGIN, MARGIN)

	_region_origin = tile_min
	_region_width = tile_max.x - tile_min.x + 1
	_region_height = tile_max.y - tile_min.y + 1

	var light := _compute_light()
	_build_texture(light)
	queue_redraw()

func _compute_light() -> PackedFloat32Array:
	var size := _region_width * _region_height
	var light := PackedFloat32Array()
	light.resize(size)

	var is_solid := PackedByteArray()
	is_solid.resize(size)
	for ly in range(_region_height):
		var ty := _region_origin.y + ly
		for lx in range(_region_width):
			var tx := _region_origin.x + lx
			var idx := ly * _region_width + lx
			is_solid[idx] = 1 if _foreground.get_cell_tile_data(Vector2i(tx, ty)) != null else 0

	var sky_light: float = GlobalVariables.sky_light_level

	# Column-scan seeding from all 4 edges
	for lx in range(_region_width):
		for ly in range(_region_height):
			var idx := ly * _region_width + lx
			if is_solid[idx] == 1:
				break
			light[idx] = sky_light

	for lx in range(_region_width):
		for ly in range(_region_height - 1, -1, -1):
			var idx := ly * _region_width + lx
			if is_solid[idx] == 1:
				break
			light[idx] = sky_light

	for ly in range(_region_height):
		for lx in range(_region_width):
			var idx := ly * _region_width + lx
			if is_solid[idx] == 1:
				break
			light[idx] = sky_light

	for ly in range(_region_height):
		for lx in range(_region_width - 1, -1, -1):
			var idx := ly * _region_width + lx
			if is_solid[idx] == 1:
				break
			light[idx] = sky_light

	# BFS light propagation
	var queue: Array[int] = []
	for idx in range(size):
		if light[idx] > 0.0:
			queue.append(idx)

	var dir_x := [1, -1, 0, 0]
	var dir_y := [0, 0, 1, -1]

	var head := 0
	while head < queue.size():
		var idx := queue[head]
		head += 1
		var current_light := light[idx]
		if current_light <= 0.01:
			continue

		var cx := idx % _region_width
		var cy := idx / _region_width

		for d in range(4):
			var nx := cx + dir_x[d]
			var ny := cy + dir_y[d]
			if nx < 0 or nx >= _region_width or ny < 0 or ny >= _region_height:
				continue
			var nidx := ny * _region_width + nx
			var decay := SOLID_DECAY if is_solid[nidx] == 1 else AIR_DECAY
			var new_light := current_light - decay
			if new_light > light[nidx]:
				light[nidx] = new_light
				queue.append(nidx)

	return light

func _build_texture(light: PackedFloat32Array) -> void:
	var sky_light: float = GlobalVariables.sky_light_level
	var night_factor := clampf(1.0 - sky_light, 0.0, 1.0)
	var r_tint := int(15.0 * night_factor)
	var g_tint := int(15.0 * night_factor)
	var b_tint := int(40.0 * night_factor)

	var data := PackedByteArray()
	data.resize(_region_width * _region_height * 4)
	for i in range(_region_width * _region_height):
		var darkness := clampf(1.0 - light[i], 0.0, 1.0)
		var alpha := int(darkness * 255.0)
		var idx := i * 4
		data[idx] = int(float(r_tint) * darkness)
		data[idx + 1] = int(float(g_tint) * darkness)
		data[idx + 2] = int(float(b_tint) * darkness)
		data[idx + 3] = alpha

	var new_image := Image.create_from_data(_region_width, _region_height, false, Image.FORMAT_RGBA8, data)
	if _texture == null or _image == null or _image.get_width() != _region_width or _image.get_height() != _region_height:
		_texture = ImageTexture.create_from_image(new_image)
	else:
		_texture.update(new_image)
	_image = new_image

func _draw() -> void:
	if _texture == null:
		return
	var world_pos := Vector2(_foreground.map_to_local(_region_origin))
	var corner := world_pos - Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
	var rect_size := Vector2(_region_width * TILE_SIZE, _region_height * TILE_SIZE)
	draw_texture_rect(_texture, Rect2(corner, rect_size), false)
