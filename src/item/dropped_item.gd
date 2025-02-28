extends Entity
class_name DroppedItem

var item: Item
var float_speed: float = 2.0
var float_amplitude: float = 10.0

@onready var sprite = $Sprite

func _on_pickup_area_body_entered(body: Node2D) -> void:
	if body is Player and body.pickup_item(item):
		queue_free()

func start_float_animation():
	var tween = create_tween()
	tween.tween_property(sprite, "position:y", sprite.position.y - float_amplitude, float_speed).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "position:y", 0, float_speed).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(start_float_animation)

func _ready() -> void:
	start_float_animation()
