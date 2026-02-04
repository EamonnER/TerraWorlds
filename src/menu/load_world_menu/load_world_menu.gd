extends Control

signal generate_new_world_button_pressed
signal load_world(world_name: String)
signal back_button_pressed

@onready var world_list: ItemList = $Body/VBoxContainer/WorldsContainer/VBoxContainer/WorldsContainer/WorldList

func _on_generate_new_world_button_pressed() -> void:
	generate_new_world_button_pressed.emit()

func _on_load_world_button_pressed() -> void:
	var selected_item_indexes: PackedInt32Array = world_list.get_selected_items()
	if selected_item_indexes.is_empty(): return
	var selected_world: String = world_list.get_item_text(selected_item_indexes[0])
	load_world.emit(selected_world)

func _on_back_button_pressed() -> void:
	back_button_pressed.emit()

func reload_worlds() -> void:
	var worlds_path: String = ProjectSettings.globalize_path("user://worlds/")
	var dir = DirAccess.open(worlds_path)
	if dir == null: return  # Directory doesn't exist or cannot be opened
	
	world_list.clear()
	
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.to_lower().ends_with(".tworld"):
			# Strip the extension and store the base name
			var base_name = file_name.substr(0, file_name.length() - ".tworld".length())
			world_list.add_item(base_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	
	if world_list.item_count == 0:
		world_list.add_item("No saved worlds...", null, false)
		world_list.set_item_disabled(0, true)
	
