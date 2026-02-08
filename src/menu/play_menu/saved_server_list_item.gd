extends PanelContainer
class_name SavedServerListItem

signal just_selected(server: SavedServerListItem)


var server_name: String
var server_address: String
var port: int


func _on_edit_server_button_toggled(toggled_on: bool) -> void:
	$VBoxContainer/ServerDetailsContainer.visible = toggled_on

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
