extends Control

@onready var loading_details: Label = $VBoxContainer/LoadingDetailsLabel

func set_loading_details(details: String) -> void:
	loading_details.set_text(details)

func clear_loading_details() -> void:
	loading_details.set_text("")
