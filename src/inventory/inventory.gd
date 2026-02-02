extends Resource
class_name Inventory

@export var id: int

var rows: int = 4
var columns: int = 9
@export var inventory_array: Array[Array]  # 2D array if 'ItemStack'. Row index 0 is hotbar

func _init() -> void:
	inventory_array = []
	for row in rows:
		inventory_array.append([])
		for column in columns:
			inventory_array[row].append(ItemStack.new())

func set_inventory(new_inventory: Array[Array]) -> void:
	inventory_array = new_inventory

# Adds an item to the first available slot. Returns true if successful; false otherwise
func pick_up_item(item_stack: ItemStack) -> bool:
	for row in rows:
		for column in columns:
			if add_item_to_slot(item_stack, row, column):
				
				return true
	
	return false

# Attempts to add an item to a specific slot. Returns true if successful; false otherwise
func add_item_to_slot(item_stack: ItemStack, row: int, column: int) -> bool:
	var item_stack_in_slot: ItemStack = inventory_array[row][column]
	
	if item_stack_in_slot.combine_stacks(item_stack):
		inventory_array[row][column] = item_stack_in_slot
		return true
		
	return false
