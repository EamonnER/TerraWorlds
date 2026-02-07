extends Control

signal generate_world(world_name: String, world_seed: int, map_size: int, cave_offset: int)
signal back_button_pressed

func _on_generate_world_button_pressed() -> void:
	var world_name = $Options/OptionsContainer/VBoxContainer/WorldNameContainer/VBoxContainer/WorldNameInput.get_text()
	if world_name.is_empty(): return
	
	var world_seed_input: String = $Options/OptionsContainer/VBoxContainer/SeedContainer/VBoxContainer/SeedInput.get_text()
	# TODO allow text input
	if !world_seed_input.is_empty() and !world_seed_input.is_valid_int(): return
	
	var world_seed: int
	if world_seed_input.is_empty():
		world_seed = randi()
	else:
		world_seed = world_seed_input.to_int()
	
	var world_size_input: int = $Options/OptionsContainer/VBoxContainer/AdvancedOptionsContainer/AdvancedOptionsContainer/WorldSizeContainer/VBoxContainer/HBoxContainer/WorldSizeSlider.get_value()
	
	var map_size = world_size_input * GlobalVariables.CHUNK_SIZE
	
	const CAVE_OFFSET = 20
	
	generate_world.emit(world_name, world_seed, map_size, CAVE_OFFSET)


func _on_back_button_pressed() -> void:
	back_button_pressed.emit()


func _on_world_size_slider_value_changed(value: float) -> void:
	$Options/OptionsContainer/VBoxContainer/AdvancedOptionsContainer/AdvancedOptionsContainer/WorldSizeContainer/VBoxContainer/HBoxContainer/WorldSizeValueLabel.set_text(str(int(value)))
