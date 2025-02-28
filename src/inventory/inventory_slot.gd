extends TextureRect
class_name InventorySlot

@export var quantity: int = 0

func set_item(new_item: Item, new_quantity: int) -> void:
	var current_item = get_item()
	if current_item and new_item.id == current_item.id:
		increment_quantity(new_quantity)
		return
	var inventory_item = new_item.to_inventory_item()
	add_child(inventory_item)
	inventory_item.set_position(get_size()/2)
	inventory_item.set_scale(Vector2(0.7, 0.7))
	quantity = max(new_quantity, 0)

func increment_quantity(amount: int) -> void:
	quantity += amount

func decrement_quantity(amount: int) -> void:
	quantity -= amount
	if quantity < 0:
		delete_item()

func get_item() -> Item:
	for child in get_children():
		return child.item
	return null
	
func get_quantity() -> int:
	return quantity

func set_quantity(new_quantity: int) -> void:
	quantity = new_quantity
	if quantity < 0:
		quantity = 0

func delete_item() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
		quantity = 0

func pop_item() -> Item:
	var item = get_item()
	delete_item()
	return item
