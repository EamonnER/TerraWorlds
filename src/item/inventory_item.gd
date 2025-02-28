extends Sprite2D
class_name InventoryItem

var item_id: int = 0
var item_name: String = "Item"

var stackable: bool = true

func get_id() -> int:
	return item_id
