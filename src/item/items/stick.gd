extends Item
class_name StickItem

func _init() -> void:
	dropped_item_sprite_path = "res://assets/items/stick/"
	inventory_item_sprite_path = "res://assets/items/stick/"
	id = 1
	item_name = "Stick"

func _ready() -> void:
	super._ready()
