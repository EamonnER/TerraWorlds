extends GridContainer

class_name InventoryUI

@onready var slot_scene: PackedScene = preload("res://src/inventory/hud/inventory_slot.tscn") 

func populate(inventory: Inventory) -> void:
	for node in get_children():
		remove_child(node)
		node.queue_free()
	
	columns = inventory.columns

	for row in inventory.rows:
		for column in inventory.columns:
			var slot: InventorySlot = slot_scene.instantiate()
			var item_stack: ItemStack = inventory.inventoryArray[row][column]
			slot.set_item_stack(item_stack)
			add_child(slot)
