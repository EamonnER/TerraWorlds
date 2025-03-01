extends Item
class_name PotionItem

func _init() -> void:
	dropped_item_sprite_path = "res://assets/items/potion/"
	inventory_item_sprite_path = "res://assets/items/potion/"
	id = 2
	item_name = "Potion"

func _ready() -> void:
	super._ready()
