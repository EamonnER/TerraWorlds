extends Control

signal back_button_pressed

# Singleplayer Tab ---------------------------------------------------------------------------------
signal load_world(world_name: String, port: int)
signal generate_new_world_button_pressed

@onready var world_list: ItemList = $Body/TabContainer/Singleplayer/WorldsContainer/WorldList
@onready var host_server_checkbox: CheckBox = $Body/TabContainer/Singleplayer/FoldableContainer/ServerHostingOptionsContainer/HostServerCheckbox
@onready var server_port_input: LineEdit = $Body/TabContainer/Singleplayer/FoldableContainer/ServerHostingOptionsContainer/HBoxContainer/ServerPortInput

func _on_generate_new_world_button_pressed() -> void:
	generate_new_world_button_pressed.emit()

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

func _on_singleplayer_play_pressed() -> void:
	var port: int
	if host_server_checkbox.is_pressed():
		var port_str: String = server_port_input.get_text().strip_edges()
		if port_str.is_empty(): port_str = str(GlobalVariables.DEFAULT_PORT)
		elif !port_str.is_valid_int(): return
		port = port_str.to_int()

	var selected_item_indexes: PackedInt32Array = world_list.get_selected_items()
	if selected_item_indexes.is_empty(): return
	var selected_world: String = world_list.get_item_text(selected_item_indexes[0])
	load_world.emit(selected_world, port)


# Multiplayer Tab ----------------------------------------------------------------------------------
signal connect_to_server(address: String, port: int)

@onready var new_server_name_input: LineEdit = $Body/TabContainer/Multiplayer/AddServerContainer/VBoxContainer/ServerNameContainer/ServerNameInput
@onready var new_server_address_input: LineEdit = $Body/TabContainer/Multiplayer/AddServerContainer/VBoxContainer/ServerAddressContainer/ServerAddressInput
@onready var new_server_port: LineEdit = $Body/TabContainer/Multiplayer/AddServerContainer/VBoxContainer/ServerPortContainer/ServerPortInput
@onready var saved_servers_container: VBoxContainer = $Body/TabContainer/Multiplayer/ServersContainer/PanelContainer/ScrollContainer/VBoxContainer

var saved_server_list_item_scene: PackedScene = preload("res://src/menu/play_menu/saved_server_list_item.tscn")

func load_saved_servers() -> void:
	for child in saved_servers_container.get_children():
		child.queue_free()
	
	var saved_servers: Dictionary = SavedServers.load_saved_servers()
	for server_address in saved_servers.keys():
		var server_info: Dictionary = saved_servers[server_address]
		var server_name: String = server_info.get("name", "Unnamed Server")
		var server_port: int = server_info.get("port", GlobalVariables.DEFAULT_PORT)
		
		var saved_server_list_item: SavedServerListItem = saved_server_list_item_scene.instantiate()
		saved_server_list_item.set_details(server_name, server_address, server_port)
		saved_servers_container.add_child(saved_server_list_item)

func _on_add_server_button_pressed() -> void:
	var server_name: String = new_server_name_input.get_text().strip_edges()
	if server_name.is_empty(): return
	
	var server_address: String = new_server_address_input.get_text().strip_edges()
	if server_address.is_empty(): return
	
	var server_port_str: String = new_server_port.get_text().strip_edges()
	if server_port_str.is_empty(): server_port_str = str(GlobalVariables.DEFAULT_PORT)
	elif !server_port_str.is_valid_int(): return
	var server_port: int = server_port_str.to_int()
	
	SavedServers.add_saved_server(server_address, server_name, server_port)
	new_server_name_input.clear()
	new_server_address_input.clear()
	new_server_port.clear()
	load_saved_servers()

func _on_multiplayer_play_pressed() -> void:
	connect_to_server.emit("127.0.0.1", GlobalVariables.DEFAULT_PORT)


# Footer Buttons------------------------------------------------------------------------------------
func _on_play_button_pressed() -> void:
	# Singleplayer Tab
	if $Body/TabContainer.get_current_tab() == 0: 
		_on_singleplayer_play_pressed()
		return
	
	# Multiplayer Tab Active
	elif $Body/TabContainer.get_current_tab() == 1:
		_on_multiplayer_play_pressed()
		return

func _on_back_button_pressed() -> void:
	back_button_pressed.emit()
