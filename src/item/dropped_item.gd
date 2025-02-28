extends Node2D
class_name DroppedItem

var item: Item

func _on_pickup_area_body_entered(body: Node2D) -> void:
	if body is Player:
		queue_free()
