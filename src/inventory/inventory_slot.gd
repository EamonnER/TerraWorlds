extends TextureRect
class_name InventorySlot

var item: InventoryItem  # This is essentually a fancy Sprite2D
var quantity: int

func set_item(new_item: InventoryItem, new_quantity: int) -> void:
	item = new_item
	quantity = new_quantity if new_quantity > 0 else null

func increment_quantity(amount: int) -> void:
	quantity += amount

func decrement_quantity(amount: int) -> void:
	quantity -= amount
	if quantity < 0:
		item = null
		quantity = 0

func get_item() -> InventoryItem:
	return item
	
func get_quantity() -> int:
	return quantity

func set_quantity(new_quantity: int) -> void:
	quantity = new_quantity
	if quantity < 0:
		quantity = 0
