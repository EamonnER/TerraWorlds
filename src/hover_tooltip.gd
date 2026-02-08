extends Control

class_name HoverTooltip

@export var offset: Vector2 = Vector2(8, 4)

@onready var tooltip: Label = $Tooltip

func set_text(text: String) -> void:
	tooltip.set_text(text)

func get_text() -> String:
	return tooltip.get_text()

func is_empty() -> bool:
	return get_text().is_empty()

func _on_mouse_entered() -> void:
	if tooltip and !is_empty(): tooltip.show()

func _on_mouse_exited() -> void:
	if tooltip: tooltip.hide()

func _process(_delta: float) -> void:
	if tooltip and tooltip.is_visible_in_tree():
		tooltip.set_global_position(get_global_mouse_position() + offset)

func _ready() -> void:
	set_text("")
	tooltip.hide()
