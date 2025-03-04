extends GridContainer
class_name Inventory

enum SLOT_TYPE {
	INVENTORY_HOTBAR,
	INVENTORY,
	HELD
}

@onready var inventory_slot_scene = preload("res://src/inventory/inventory_slot.tscn")
@onready var held_inventory_slot: InventorySlot = inventory_slot_scene.instantiate()

var rows = 4
var slots: Dictionary
var is_open: bool = false

func _ready() -> void:
	columns = 9
	
	slots[SLOT_TYPE.INVENTORY_HOTBAR] = []
	slots[SLOT_TYPE.INVENTORY] = []
	slots[SLOT_TYPE.HELD] = [held_inventory_slot]
	
	for i in range(columns * rows):
		var slot: InventorySlot = inventory_slot_scene.instantiate()
		add_child(slot)
		slot.add_to_group("inventory_slots")
		
		if i < columns:
			slots[SLOT_TYPE.INVENTORY_HOTBAR].append(slot)
		else:
			slots[SLOT_TYPE.INVENTORY].append(slot)
	
	hide_inventory()
	
	add_child(held_inventory_slot)
	held_inventory_slot.set_texture(null)

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

func add_item(item: Item, quantity: int = 1) -> bool:
	# Returns true if successful; false otherwise
	for slot in get_children():
		if slot == held_inventory_slot:
			continue
		var current_slot_item = slot.get_item()
		if (current_slot_item == null) or (item.is_stackable and current_slot_item.id == item.id):
			slot.set_item(item, quantity)
			return true
	return false

func _process(delta: float) -> void:
	var offset = Vector2(held_inventory_slot.get_size().x, held_inventory_slot.get_size().x/2)
	held_inventory_slot.set_position(get_global_mouse_position() - offset)
	if Input.is_action_just_pressed("game_open_inventory"):
		toggle_inventory()
