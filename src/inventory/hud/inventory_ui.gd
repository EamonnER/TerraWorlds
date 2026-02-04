extends GridContainer

class_name InventoryUI

@onready var slot_scene: PackedScene = preload("res://src/inventory/hud/inventory_slot.tscn")

var item_slots: Array[Array] = []

@rpc("authority", "call_local", "reliable")
func initialise(num_rows: int, num_columns: int) -> void:
	item_slots = []
	columns = num_columns
	
	for node in get_children():
		remove_child(node)
		node.queue_free()
	
	for row in num_rows:
		item_slots.append([])
		for column in columns:
			var slot: InventorySlot = slot_scene.instantiate()
			var item_stack: ItemStack = ItemStack.new()
			slot.set_item_stack(item_stack)
			item_slots[row].append(slot)
			add_child(slot)

func populate(inventory: Inventory) -> void:
	for node in get_children():
		remove_child(node)
		node.queue_free()
	
	columns = inventory.columns

	for row in inventory.rows:
		item_slots.append([])
		for column in inventory.columns:
			var slot: InventorySlot = slot_scene.instantiate()
			var item_stack: ItemStack = inventory.inventory_array[row][column]
			slot.set_item_stack(item_stack)
			item_slots[row].append(slot)
			add_child(slot)

@rpc("authority", "call_local", "reliable")
func set_slot(row: int, column: int, item_id: int, item_quantity: int) -> void:
	var item = ItemOracle.get_item_by_id(item_id)
	var item_stack = ItemStack.new()
	item_stack.set_item(item, item_quantity)
	item_slots[row][column].set_item_stack(item_stack)
