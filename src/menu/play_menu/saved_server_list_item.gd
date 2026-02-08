extends PanelContainer
class_name SavedServerListItem

signal just_selected(server: SavedServerListItem)


var server_name: String
var server_address: String
var port: int


func set_details(new_server_name: String, new_address: String, new_port: int = GlobalVariables.DEFAULT_PORT) -> void:
	$VBoxContainer/HBoxContainer/ServerSelectButton.set_text(new_server_name)
	$VBoxContainer/ServerDetailsContainer/VBoxContainer/EditServerNameInput.set_text(new_server_name)
	server_name = new_server_name
	
	$VBoxContainer/ServerDetailsContainer/VBoxContainer/EditServerAddressInput.set_text(new_address)
	server_address = new_server_name
	
	$VBoxContainer/ServerDetailsContainer/VBoxContainer/HBoxContainer/EditServerPortInput.set_text(str(new_port))
	port = new_port

func set_selected(selected: bool) -> void:
	$VBoxContainer/HBoxContainer/ServerSelectButton.button_pressed = selected

func _on_server_select_button_toggled(toggled_on: bool) -> void:
	if toggled_on: just_selected.emit(self)


# Editing Saved Servers ------------------------------------------------------------------------------------------------
func _on_edit_server_button_toggled(toggled_on: bool) -> void:
	$VBoxContainer/ServerDetailsContainer.visible = toggled_on

func _on_edit_server_name_input_editing_toggled(toggled_on: bool) -> void:
	var new_name: String = $VBoxContainer/ServerDetailsContainer/VBoxContainer/EditServerNameInput.get_text().strip_edges()
	if new_name.is_empty(): return
	
	server_name = new_name
	$VBoxContainer/HBoxContainer/ServerSelectButton.set_text(new_name)
	SavedServers.edit_saved_server(server_address, server_name, port)

func _on_edit_server_port_input_editing_toggled(toggled_on: bool) -> void:
	var new_address: String = $VBoxContainer/ServerDetailsContainer/VBoxContainer/HBoxContainer/EditServerPortInput.get_text().strip_edges()
	if new_address.is_empty(): return
	elif !new_address.is_valid_int(): return
	
	var new_port: int = new_address.to_int()
	if new_port < 1 or new_port > 65535: return
	
	port = new_port
	SavedServers.edit_saved_server(server_address, server_name, port)

func _on_edit_server_address_input_editing_toggled(toggled_on: bool) -> void:
	var new_address: String = $VBoxContainer/ServerDetailsContainer/VBoxContainer/EditServerAddressInput.get_text().strip_edges()
	if new_address.is_empty(): return
	
	SavedServers.remove_saved_server(server_address) # Remove old entry with outdated address
	server_address = new_address
	SavedServers.add_saved_server(server_address, server_name, port)

func _on_delete_server_button_pressed() -> void:
	SavedServers.remove_saved_server(server_address)
	queue_free()
