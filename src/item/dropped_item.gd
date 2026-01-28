extends Entity
class_name DroppedItem

var item_stack: ItemStack
var float_speed: float = 2.0
var float_amplitude: float = 10.0

@onready var item_stack_sprite: ItemStackSprite = $ItemStackSprite

func _on_pickup_area_body_entered(body: Node2D) -> void:
	if !multiplayer.is_server() or !(body is Player): return
	
	if body.pick_up_item(item_stack):
		queue_free()

func start_float_animation():
	var tween = create_tween()
	tween.tween_property(item_stack_sprite, "position:y", item_stack_sprite.position.y - float_amplitude, float_speed).set_trans(Tween.TRANS_SINE)
	tween.tween_property(item_stack_sprite, "position:y", 0, float_speed).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(start_float_animation)

func set_item_stack(new_item_stack: ItemStack) -> void:
	item_stack = new_item_stack
	# Can be null when scene was just instantiated
	if item_stack_sprite: item_stack_sprite.set_item_stack(item_stack)

func _ready() -> void:
	super._ready()
	item_stack_sprite.set_item_stack(item_stack)
	start_float_animation()
