extends GridContainer
class_name Inventory

var rows = 4
var slots: Array[InventorySlot]

func _ready() -> void:
	columns = 9
	
	for i in range(columns * rows):
		var slot = InventorySlot.new()
		add_child(slot)
		slots.append(slot)
		
