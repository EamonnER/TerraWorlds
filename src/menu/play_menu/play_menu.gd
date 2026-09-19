extends Control

signal back_button_pressed

func _ready() -> void:
	SteamManager.friends_updated.connect(populate_steam_friend_list)

# Singleplayer Tab ---------------------------------------------------------------------------------
signal load_world(world_name: String, multiplayer_connection_details: Dictionary)
signal generate_new_world_button_pressed

@onready var world_list: ItemList = $Body/TabContainer/Singleplayer/WorldsContainer/WorldList
@onready var connection_method_option_button: OptionButton = $Body/TabContainer/Singleplayer/FoldableContainer/ServerHostingOptionsContainer/HostServerHBoxContainer/ConnectionMethodOptionButton
@onready var server_port_input: LineEdit = $Body/TabContainer/Singleplayer/FoldableContainer/ServerHostingOptionsContainer/ServerPortHBoxContainer/ServerPortInput

func _on_generate_new_world_button_pressed() -> void:
	generate_new_world_button_pressed.emit()

func reload_worlds() -> void:
	var worlds_path: String = ProjectSettings.globalize_path("user://worlds/")
	var dir: DirAccess = DirAccess.open(worlds_path)
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
	if connection_method_option_button.selected != GlobalVariables.MULTIPLAYER_CONNECTION_TYPE.NONE:
		var port_str: String = server_port_input.get_text().strip_edges()
		if port_str.is_empty(): port_str = str(GlobalVariables.DEFAULT_PORT)
		elif !port_str.is_valid_int(): return
		port = port_str.to_int()
		if port < 1 or port > 65535: return

	var selected_item_indexes: PackedInt32Array = world_list.get_selected_items()
	if selected_item_indexes.is_empty(): return
	var selected_world: String = world_list.get_item_text(selected_item_indexes[0])
	var multiplayer_connection_details: Dictionary = {
		"connection_type": connection_method_option_button.selected,
		"port": port
	}
	load_world.emit(selected_world, multiplayer_connection_details)


# Multiplayer Tab ----------------------------------------------------------------------------------
var selected_item: MarginContainer

func _on_item_selected(item: MarginContainer) -> void:
	if selected_item: selected_item.set_selected(false)
	selected_item = item

func _on_multiplayer_play_pressed() -> void:
	if not selected_item: return
	
	elif selected_item is SteamFriendListItem:
		var lobby_id: int = selected_item.lobby_id
		var host_steam_id: int = selected_item.steam_id
		connect_to_server.emit({"connection_type": GlobalVariables.MULTIPLAYER_CONNECTION_TYPE.STEAM, "lobby_id": lobby_id, "host_steam_id": host_steam_id})
	
	elif selected_item is SavedServerListItem:
		var server_address: String = selected_item.server_address
		var server_port: int = selected_item.port
		connect_to_server.emit({"connection_type": GlobalVariables.MULTIPLAYER_CONNECTION_TYPE.ENET, "ip": server_address, "port": server_port})

# Steam Connections
@onready var steam_friends_container: VBoxContainer = $Body/TabContainer/Multiplayer/JoinFriendsContainer/PanelContainer/ScrollContainer/VBoxContainer

var steam_friend_list_item_scene: PackedScene = preload("res://src/menu/play_menu/steam_friend_list_item.tscn")

func populate_steam_friend_list(friends: Array[Dictionary]) -> void:
	for child in steam_friends_container.get_children():
		child.queue_free()
	
	for friend in friends:
		var steam_id: int = friend.get("steam_id", 0)
		var avatar: Texture2D = friend.get("avatar", null)
		var steam_name: String = friend.get("name", "Unknown")
		var status: String = friend.get("status", "Unknown")
		var lobby_id: int = friend.get("lobby_id", 0)
		
		if lobby_id == 0:
			continue  # Skip friends not in a lobby
		
		var steam_friend_list_item: SteamFriendListItem = steam_friend_list_item_scene.instantiate()
		steam_friend_list_item.set_details(steam_id, avatar, steam_name, status, lobby_id)
		steam_friends_container.add_child(steam_friend_list_item)
		steam_friend_list_item.just_selected.connect(_on_item_selected)

# ENET / Server Connections
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
		saved_server_list_item.just_selected.connect(_on_item_selected)

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
