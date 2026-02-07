extends Control

class_name ItemStackSprite

@onready var item_sprite: AnimatedSprite2D = $ItemSprite
@onready var quantity_label: Label = $QuantityLabel
@onready var hover_tooltip: HoverTooltip = $HoverTooltip

var item_stack: ItemStack = ItemStack.new()

func set_item_stack(new_item_stack: ItemStack) -> void:
	item_stack = new_item_stack
	
	# Can be null when scene was just instantiated
	if !item_sprite or !quantity_label or !hover_tooltip: return
	
	item_sprite.sprite_frames = SpriteFrames.new()
	
	if item_stack.is_empty():
		hover_tooltip.set_text("")
		quantity_label.set_text("") 
		return
	
	hover_tooltip.set_text(item_stack.item.name)
	
	if item_stack.item.is_stackable:
		quantity_label.set_text(str(item_stack.quantity))
	
	var sprite_path: String = item_stack.item.sprite_path
	
	var dir = DirAccess.open(sprite_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name:
			if not dir.current_is_dir() and file_name.ends_with(".png"):
				var animation_frame = load(sprite_path + file_name)
				item_sprite.sprite_frames.add_frame("default", animation_frame)
			file_name = dir.get_next()
	
	item_sprite.play("default", 2)
	
#	var texture_size = item_sprite.sprite_frames.get_frame_texture("default", 0).get_size()
#	custom_minimum_size = texture_size

func _ready() -> void:
	set_item_stack(item_stack)
