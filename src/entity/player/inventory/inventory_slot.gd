extends TextureRect

@export var quantity: int = 0
@export var item_name: String = ""

@onready var quantity_label: Label = $Quantity
@onready var this_scene = preload("res://src/entity/player/hud/inventory/inventory_slot.tscn")

@onready var parent_inventory = get_parent()

func set_item(new_item: Item, new_quantity: int) -> void:
	if new_item == null or new_quantity == 0:
		return
	
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

func pop_item() -> Array:
	var item = get_item()
	var old_quantity = get_quantity()
	delete_item()
	return [item, old_quantity]

func transfer_item_to(slot: InventorySlot) -> void:
	var item = pop_item()
	slot.set_item(item[0], item[1])

func _update_label() -> void:
	if quantity_label == null:
		return
	if quantity > 0:
		quantity_label.set_text(str(quantity))
		return
	quantity_label.set_text("")

func _ready() -> void:
	self.mouse_filter = Control.MOUSE_FILTER_STOP
	self.gui_input.connect(_on_gui_input)

func get_slot_under_cursor() -> InventorySlot:
		var mouse_position = get_viewport().get_mouse_position()
		for slot: InventorySlot in get_tree().get_nodes_in_group("inventory_slots"):
			if Rect2(slot.get_position(), slot.get_size()).has_point(mouse_position):
				return slot  # Return the first slot found under the cursor
		return null  # No slot found

func is_empty() -> bool:
	return false if get_item() is Item else true

func _on_gui_input(event) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if parent_inventory.held_inventory_slot.is_empty():
			transfer_item_to(parent_inventory.held_inventory_slot)
		else:
			parent_inventory.held_inventory_slot.transfer_item_to(self)
