extends Control

@onready var loading_details: Label = $VBoxContainer/LoadingDetailsLabel
@onready var progress_bar: ProgressBar = $VBoxContainer/ProgressBar
var world_generator: WorldGenerator = load("res://src/world/WorldGenerator.cs").new()

func update(details: String, percent: int) -> void:
	loading_details.set_text(details)
	progress_bar.value = percent
	
	if percent >= 100:
		self.hide()

func clear_loading_details() -> void:
	loading_details.set_text("")
	progress_bar.value = 0
