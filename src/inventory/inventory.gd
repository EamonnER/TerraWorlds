extends Resource
class_name Inventory

var rows: int = 4
var columns: int = 9
@export var inventoryArray: Array[Array]  # 2D array if 'ItemStack'. Row index 0 is hotbar

func _init() -> void:
	inventoryArray = []
	for row in rows:
		inventoryArray.append([])
		for column in columns:
			inventoryArray[row].append(ItemStack.new())

func set_inventory(new_inventory: Array[Array]) -> void:
	inventoryArray = new_inventory

# Adds an item to the first available slot. Returns true if successful; false otherwise
func pick_up_item(item_stack: ItemStack) -> bool:
	for row in rows:
		for column in columns:
			if add_item_to_slot(item_stack, row, column): return true
	
	return false

# Attempts to add an item to a specific slot. Returns true if successful; false otherwise
func add_item_to_slot(item_stack: ItemStack, row: int, column: int) -> bool:
	var item_stack_in_slot: ItemStack = inventoryArray[row][column]
	
	if item_stack_in_slot.combine_stacks(item_stack):
		inventoryArray[row][column] = item_stack_in_slot
		return true
		
	return false
