extends Node
class_name Item

var dropped_item_scene = preload("res://src/item/dropped_item.tscn")
var dropped_item_sprite = preload("res://icon.svg")

var inventory_item_scene = preload("res://src/item/inventory_item.tscn")
var inventory_item_sprite = preload("res://icon.svg")

var id: int = 0
var item_name: String = "Item"
var is_stackable: bool = true

func to_inventory_item() -> InventoryItem:
	var inventory_item = inventory_item_scene.instantiate()
	inventory_item.item = self
	inventory_item.texture = inventory_item_sprite
	return inventory_item

func to_dropped_item() -> DroppedItem:
	var dropped_item = dropped_item_scene.instantiate()
	dropped_item.item = self
	dropped_item.get_node("Sprite").texture = dropped_item_sprite
	return dropped_item

func _ready() -> void:
	pass
