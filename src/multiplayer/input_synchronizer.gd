extends MultiplayerSynchronizer

var horizontal_input: float = 0.0
var vertical_input: float = 0.0
var jump_pressed: bool = false
var debug_toggle_pressed: bool = false

func _ready() -> void:
	if get_multiplayer_authority() != multiplayer.get_unique_id():
		set_process(false)
		set_physics_process(false)

func _physics_process(_delta: float) -> void:
	horizontal_input = Input.get_axis("game_left", "game_right")
	vertical_input = Input.get_axis("game_up", "game_down")
	jump_pressed = Input.is_action_just_pressed("game_jump")
	debug_toggle_pressed = Input.is_action_just_pressed("game_debug_toggle")
