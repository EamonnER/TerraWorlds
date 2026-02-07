extends Entity
class_name DroppedItem

@export var quantity: int = 1

var float_speed: float = 2.0
var float_amplitude: float = 10.0

@onready var item_stack_sprite: ItemStackSprite = $ItemStackSprite

func _on_pickup_area_body_entered(body: Node2D) -> void:
	if !multiplayer.is_server(): return
	
	if body is Player and body.pick_up_item(get_item_stack()):
		queue_free()

func start_float_animation():
	var tween = create_tween()
	tween.tween_property(item_stack_sprite, "position:y", item_stack_sprite.position.y - float_amplitude, float_speed).set_trans(Tween.TRANS_SINE)
	tween.tween_property(item_stack_sprite, "position:y", 0, float_speed).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(start_float_animation)

func set_item_stack(item_stack: ItemStack) -> void:
	id = item_stack.get_item().id
	quantity = item_stack.get_quantity()
	# Can be null when scene was just instantiated
	if item_stack_sprite: item_stack_sprite.set_item_stack(get_item_stack())

func get_item_stack() -> ItemStack:
	var item: Item = ItemOracle.get_item_by_id(id)
	var itemStack: ItemStack = ItemStack.new()
	itemStack.set_item(item, quantity)
	return itemStack

func _ready() -> void:
	super._ready()
	item_stack_sprite.set_item_stack(get_item_stack())
	start_float_animation()
