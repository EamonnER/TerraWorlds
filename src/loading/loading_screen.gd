extends Control

@onready var loading_details: Label = $VBoxContainer/LoadingDetailsLabel
@onready var progress_bar: ProgressBar = $VBoxContainer/ProgressBar

func update(details: String, percent: int) -> void:
	loading_details.set_text(details)
	progress_bar.value = percent

func clear_loading_details() -> void:
	loading_details.set_text("")
	progress_bar.value = 0
