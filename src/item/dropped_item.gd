extends Entity
class_name DroppedItem

var item: Item

func _on_pickup_area_body_entered(body: Node2D) -> void:
	if body is Player and body.pickup_item(item):
		queue_free()
