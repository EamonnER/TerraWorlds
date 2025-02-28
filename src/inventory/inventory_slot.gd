extends TextureRect
class_name InventorySlot

@export var quantity: int = 0
@export var item_name: String

@onready var quantity_label: Label = $Quantity

func set_item(new_item: Item, new_quantity: int) -> void:
	var current_item = get_item()
	if current_item and new_item.id == current_item.id:
		increment_quantity(new_quantity)
		return
	var inventory_item = new_item.to_inventory_item()
	add_child(inventory_item)
	inventory_item.set_position(get_size()/2)
	quantity = max(new_quantity, 0)
	item_name = inventory_item.item.item_name
	_update_label()

func increment_quantity(amount: int) -> void:
	quantity += amount
	_update_label()

func decrement_quantity(amount: int) -> void:
	quantity -= amount
	if quantity < 0:
		delete_item()
	_update_label()

func get_item() -> Item:
	for child in get_children():
		if child is InventoryItem:
			return child.item
	return null
	
func get_quantity() -> int:
	return quantity

func set_quantity(new_quantity: int) -> void:
	quantity = new_quantity
	if quantity < 0:
		quantity = 0
	_update_label()

func delete_item() -> void:
	for child in get_children():
		if child is InventoryItem:
			remove_child(child)
			child.queue_free()
			quantity = 0
	item_name = ""
	_update_label()

func pop_item() -> Item:
	var item = get_item()
	delete_item()
	return item

func _update_label() -> void:
	if quantity > 0:
		quantity_label.set_text(str(quantity))
		return
	quantity_label.set_text("")
