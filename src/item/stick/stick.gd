extends Item
class_name StickItem

func _init() -> void:
	dropped_item_sprite = load("res://assets/items/stick.png")
	inventory_item_sprite = load("res://assets/items/stick.png")
	id = 1
	item_name = "Stick"

func _ready() -> void:
	super._ready()
