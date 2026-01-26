extends Resource
class_name Item

var dropped_item_scene = preload("res://src/item/dropped_item.tscn")
var dropped_item_sprite_path = "res://assets/items/null/"

var inventory_item_scene = preload("res://src/entity/player/hud/inventory/inventory_item.tscn")
var inventory_item_sprite_path = "res://assets/items/null/"

var id: int = 0
var item_name: String = "Item"
var is_stackable: bool = true

func _populate_animated_sprite(animated_sprite: AnimatedSprite2D, path: String):
	var dir = DirAccess.open(path)
	if dir:
		animated_sprite.sprite_frames = SpriteFrames.new()
		animated_sprite.sprite_frames.add_animation("default")
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name:
			if not dir.current_is_dir() and file_name.ends_with(".png"):
				var frame = load(path + file_name)
				animated_sprite.sprite_frames.add_frame("default", frame)
			file_name = dir.get_next()
	
		animated_sprite.play("default", 2)

func to_inventory_item() -> InventoryItem:
	var inventory_item = inventory_item_scene.instantiate()
	inventory_item.item = self
	_populate_animated_sprite(inventory_item, inventory_item_sprite_path)
	return inventory_item

func to_dropped_item() -> DroppedItem:
	var dropped_item = dropped_item_scene.instantiate()
	dropped_item.item = self
	_populate_animated_sprite(dropped_item.get_node("Sprite"), inventory_item_sprite_path)
	return dropped_item

func _ready() -> void:
	pass
