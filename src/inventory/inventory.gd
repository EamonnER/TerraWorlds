extends GridContainer
class_name Inventory

enum SLOT_TYPE {
	INVENTORY_HOTBAR,
	INVENTORY
}

@onready var inventory_slot_scene = preload("res://src/inventory/inventory_slot.tscn")

var rows = 4
var slots: Dictionary

func _ready() -> void:
	columns = 9
	
	slots[SLOT_TYPE.INVENTORY_HOTBAR] = []
	slots[SLOT_TYPE.INVENTORY] = []
	
	for i in range(columns * rows):
		var slot: InventorySlot = inventory_slot_scene.instantiate()
		add_child(slot)
		
		if i < columns:
			slots[SLOT_TYPE.INVENTORY_HOTBAR].append(slot)
		else:
			slots[SLOT_TYPE.INVENTORY].append(slot)

func hide_inventory() -> void:
	for slot in slots[SLOT_TYPE.INVENTORY]:
		slot.hide()

func show_inventory() -> void:
	for slot in slots[SLOT_TYPE.INVENTORY]:
		slot.show()
