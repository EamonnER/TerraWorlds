extends Node
class_name Item

@onready var dropped_item_scene = preload("res://src/item/dropped_item.tscn")
@onready var inventory_item_scene = preload("res://src/item/inventory_item.tscn")

var id: int = 0
var item_name: String = "Item"

func to_inventory_item() -> InventoryItem:
	var inventory_item = inventory_item_scene.instantiate()
	inventory_item.item = self
	return inventory_item

func to_dropped_item() -> DroppedItem:
	var dropped_item = dropped_item_scene.instantiate()
	dropped_item.item = self
	return dropped_item
