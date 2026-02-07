extends PanelContainer

class_name SavedServerListItem

@onready var edit_button = $VBoxContainer/HBoxContainer/EditServerButton

func _on_edit_server_button_toggled(toggled_on: bool) -> void:
	$VBoxContainer/ServerDetailsContainer.visible = toggled_on

func set_details(server_name: String, address: String, port: int = GlobalVariables.DEFAULT_PORT) -> void:
	$VBoxContainer/HBoxContainer/ServerNameLabel.set_text(server_name)
	$VBoxContainer/ServerDetailsContainer/VBoxContainer/EditServerNameInput.set_text(server_name)
	
	$VBoxContainer/ServerDetailsContainer/VBoxContainer/EditServerAddressInput.set_text(address)
	
	$VBoxContainer/ServerDetailsContainer/VBoxContainer/HBoxContainer/EditServerPortInput.set_text(str(port))
