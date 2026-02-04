extends Control

signal connect_to_server(address: String, port: int)
signal back_button_pressed

var saved_server_list_item_scene: PackedScene = preload("res://src/menu/join_world_menu/saved_server_list_item.tscn")

@onready var new_server_name_input: LineEdit = $Body/SavedServersContainer/VBoxContainer/AddServerContainer/VBoxContainer/ServerNameContainer/ServerNameInput
@onready var new_server_address_input: LineEdit = $Body/SavedServersContainer/VBoxContainer/AddServerContainer/VBoxContainer/ServerAddressContainer/ServerAddressInput
@onready var new_server_port: LineEdit = $Body/SavedServersContainer/VBoxContainer/AddServerContainer/VBoxContainer/ServerPortContainer/ServerPortInput

@onready var saved_servers_container = $Body/SavedServersContainer/VBoxContainer/ServersContainer/PanelContainer/ScrollContainer/VBoxContainer

func _on_add_server_button_pressed() -> void:
	var server_name: String = new_server_name_input.get_text().strip_edges()
	if server_name.is_empty(): return
	
	var server_address: String = new_server_address_input.get_text().strip_edges()
	if server_address.is_empty(): return
	
	var server_port_str: String = new_server_port.get_text().strip_edges()
	if server_port_str.is_empty(): server_port_str = str(GlobalVariables.DEFAULT_PORT)
	elif !server_port_str.is_valid_int(): return
	var server_port: int = server_port_str.to_int()
	
	var saved_server_list_item: SavedServerListItem = saved_server_list_item_scene.instantiate()
	saved_server_list_item.set_details(server_name, server_address, server_port)
	saved_servers_container.add_child(saved_server_list_item)
	
	new_server_name_input.clear()
	new_server_address_input.clear()
	new_server_port.clear()

func _on_join_world_button_pressed() -> void:
	connect_to_server.emit("127.0.0.1", GlobalVariables.DEFAULT_PORT)

func _on_back_button_pressed() -> void:
	back_button_pressed.emit()
