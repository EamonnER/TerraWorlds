extends TextureRect
class_name InventorySlot

var inventory_item: InventoryItem  # This is essentually a fancy Sprite2D
var quantity: int

func set_item(new_item: Item, new_quantity: int) -> void:
	if new_item.id == inventory_item.item.id:
		increment_quantity(new_quantity)
		return
	inventory_item = new_item.to_inventory_item()
	quantity = max(new_quantity, 0)

func increment_quantity(amount: int) -> void:
	quantity += amount

func decrement_quantity(amount: int) -> void:
	quantity -= amount
	if quantity < 0:
		inventory_item = null
		quantity = 0

func get_item() -> Item:
	return inventory_item.item
	
func get_quantity() -> int:
	return quantity

func set_quantity(new_quantity: int) -> void:
	quantity = new_quantity
	if quantity < 0:
		quantity = 0
