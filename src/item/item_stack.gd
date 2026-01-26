extends Resource
class_name ItemStack

@export var item: Item
@export var quantity: int


func set_item(new_item: Item, new_quantity = 1) -> void:
	if new_quantity <= 0 or !new_item:
		push_error("Tried setting item stack with parameters: Item: '%s', Quantity: '%d'" % [item, quantity])
	
	item = new_item
	quantity = new_quantity

func add_amount(amount: int) -> void:
	quantity += amount

func remove_amount(amount: int):
	quantity -= amount

func clear_item() -> void:
	item = null
	quantity = 0

func is_empty() -> bool:
	return !item or !quantity

# Returns true if successful
func combine_stacks(stack_to_combine: ItemStack) -> bool:
	if is_empty():
		item = stack_to_combine.item
		quantity = stack_to_combine.quantity
		return true
	elif stack_to_combine.is_empty():
		return true
	elif item.id == stack_to_combine.item.id and item.is_stackable:
		add_amount(stack_to_combine.quantity)
		return true
	return false 
