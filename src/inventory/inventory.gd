extends GridContainer
class_name Inventory

enum SLOT_TYPE {
	INVENTORY_HOTBAR,
	INVENTORY
}

@onready var inventory_slot_scene = preload("res://src/inventory/inventory_slot.tscn")

var rows = 4
var slots: Dictionary
var is_open: bool = false

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
	
	hide_inventory()

func hide_inventory() -> void:
	for slot in slots[SLOT_TYPE.INVENTORY]:
		slot.hide()
	is_open = false

func show_inventory() -> void:
	for slot in slots[SLOT_TYPE.INVENTORY]:
		slot.show()
	is_open = true

func toggle_inventory() -> void:
	hide_inventory() if is_open else show_inventory()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("game_open_inventory"):
		toggle_inventory()
