extends Node

@export var id_to_item: Dictionary[int, Item] = {}


func get_item_by_id(item_id: int) -> Item:
	if id_to_item.has(item_id):
		return id_to_item[item_id]
	return null


func _build() -> Dictionary:
	id_to_item.clear()

	var items_path := "res://src/item/items"
	var dir := DirAccess.open(items_path)
	if dir == null:
		push_error("ItemOracle.build: Could not open items directory: %s" % items_path)
		return id_to_item

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name:
		# Skip navigation entries
		if file_name == "." or file_name == "..":
			file_name = dir.get_next()
			continue

		# Skip directories
		if dir.current_is_dir():
			file_name = dir.get_next()
			continue

		var full_path := items_path + "/" + file_name

		# Try .gd scripts and .tscn scenes
		if file_name.ends_with(".uid"):
			file_name = dir.get_next()
			continue
		var loaded = load(full_path)
		if loaded == null:
			push_warning("ItemOracle.build: Failed to load resource at %s" % full_path)
			file_name = dir.get_next()
			continue

		var inst = null
		if loaded is Script:
			# Script files: create a new instance
			inst = loaded.new()
		elif loaded is PackedScene:
			# Scene files: instantiate and try to find an Item node or resource on the root
			var root = loaded.instantiate()
			# If the root itself is an Item (Resource node), accept it; otherwise try to find a child that is an Item
			if root is Item:
				inst = root
			else:
				# search children for an Item-type node/resource (helpful if scenes wrap an Item node)
				for child in root.get_children():
					if child is Item:
						inst = child
						break
		else:
			# Other resource types (e.g., a preconfigured Item Resource file) — try to use directly
			if loaded is Item:
				inst = loaded

		if inst == null:
			# Not an Item, skip
			file_name = dir.get_next()
			continue

		# Ensure inst has an id
		if not inst.has_method("get") and not typeof(inst.id) in [TYPE_INT]:
			# best-effort check; fallback to direct property access
			pass

		var item_id := int(inst.id)
		if id_to_item.has(item_id):
			push_warning("ItemOracle.build: Duplicate item id %d found at %s; previously from %s" % [item_id, full_path, id_to_item[item_id]])
		# Store the instance (Resource) — callers can duplicate if they need fresh copies
		id_to_item[item_id] = inst

		file_name = dir.get_next()

	dir.list_dir_end()
	return id_to_item

func _ready() -> void:
	_build()
