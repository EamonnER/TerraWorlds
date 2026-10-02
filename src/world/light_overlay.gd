extends Node2D

const TILE_SIZE: int = GlobalVariables.TILE_SIZE
const MARGIN: int = 30

var _foreground: TileMapLayer
var _engine: Node
var _image: Image
var _texture: ImageTexture
var _region_origin: Vector2i
var _region_width: int
var _region_height: int

var _dirty: bool = true
var _last_origin: Vector2i
var _last_sky_light: float = -1.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	z_index = 100
	_foreground = get_parent().get_node("Foreground") as TileMapLayer
	_engine = get_parent().get_node_or_null("LightingEngine")

func mark_dirty() -> void:
	_dirty = true

func _process(_delta: float) -> void:
	if _engine == null or _foreground == null:
		return

	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return

	var vp_size: Vector2 = get_viewport_rect().size
	var ct: Transform2D = get_viewport().get_canvas_transform()
	var inv: Transform2D = ct.affine_inverse()

	var c0: Vector2 = inv * Vector2.ZERO
	var c1: Vector2 = inv * Vector2(vp_size.x, 0)
	var c2: Vector2 = inv * vp_size
	var c3: Vector2 = inv * Vector2(0, vp_size.y)

	var min_x: float = minf(minf(c0.x, c1.x), minf(c2.x, c3.x))
	var max_x: float = maxf(maxf(c0.x, c1.x), maxf(c2.x, c3.x))
	var min_y: float = minf(minf(c0.y, c1.y), minf(c2.y, c3.y))
	var max_y: float = maxf(maxf(c0.y, c1.y), maxf(c2.y, c3.y))

	var tile_min: Vector2i = _foreground.local_to_map(Vector2(min_x, min_y)) - Vector2i(MARGIN, MARGIN)
	var tile_max: Vector2i = _foreground.local_to_map(Vector2(max_x, max_y)) + Vector2i(MARGIN, MARGIN)

	_region_origin = tile_min
	_region_width = tile_max.x - tile_min.x + 1
	_region_height = tile_max.y - tile_min.y + 1

	var sky_light: float = GlobalVariables.sky_light_level
	var origin_shifted: bool = (absi(_region_origin.x - _last_origin.x) >= 2
								or absi(_region_origin.y - _last_origin.y) >= 2)
	var light_changed: bool = absf(sky_light - _last_sky_light) > 0.01

	if not origin_shifted and not light_changed and not _dirty:
		return

	_last_origin = _region_origin
	_last_sky_light = sky_light
	_dirty = false

	var data: PackedByteArray = _engine.ComputeLightMap(
		_region_origin, _region_width, _region_height, sky_light)

	var new_image: Image = Image.create_from_data(
		_region_width, _region_height, false, Image.FORMAT_RGBA8, data)
	if _texture == null or _image == null or _image.get_width() != _region_width or _image.get_height() != _region_height:
		_texture = ImageTexture.create_from_image(new_image)
	else:
		_texture.update(new_image)
	_image = new_image
	queue_redraw()

func _draw() -> void:
	if _texture == null or _foreground == null:
		return
	var world_pos: Vector2 = Vector2(_foreground.map_to_local(_region_origin))
	var corner: Vector2 = world_pos - Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
	var rect_size: Vector2 = Vector2(_region_width * TILE_SIZE, _region_height * TILE_SIZE)
	draw_texture_rect(_texture, Rect2(corner, rect_size), false)
