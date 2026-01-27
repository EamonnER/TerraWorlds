extends AnimatedSprite2D

class_name ItemStackSprite

var item_stack: ItemStack = ItemStack.new()

func set_item_stack(new_item_stack: ItemStack) -> void:
	item_stack = new_item_stack
	queue_redraw()
	
	sprite_frames = SpriteFrames.new()
	
	if item_stack.is_empty(): return
	
	var sprite_path: String = item_stack.item.sprite_path
	
	var dir = DirAccess.open(sprite_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name:
			if not dir.current_is_dir() and file_name.ends_with(".png"):
				var animation_frame = load(sprite_path + file_name)
				sprite_frames.add_frame("default", animation_frame)
			file_name = dir.get_next()
	
	play("default", 2)

func _ready() -> void:
	set_item_stack(item_stack)

func _draw() -> void:
	var quantity_font: Font = ThemeDB.fallback_font;
	var quantity: String
	if item_stack.is_empty():
		quantity = ''
	else:
		quantity = str(item_stack.quantity)
	
	draw_string(quantity_font, Vector2(8, 16), quantity)
