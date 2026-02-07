extends TextureRect

class_name InventorySlot

var item_stack: ItemStack = ItemStack.new()
@onready var item_stack_sprite: ItemStackSprite = $ItemStackSprite

func set_item_stack(new_item_stack: ItemStack) -> void:
	item_stack = new_item_stack
	# Can be null when scene was just instantiated
	if item_stack_sprite: item_stack_sprite.set_item_stack(item_stack)

func _ready() -> void:
	item_stack_sprite.set_item_stack(item_stack)
