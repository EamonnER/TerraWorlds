extends Node

var time_of_day: float = 0.25

const DAY_DURATION: float = 720.0

func _process(delta: float) -> void:
	time_of_day = fmod(time_of_day + delta / DAY_DURATION, 1.0)
	var raw := sin((time_of_day - 0.25) * TAU)
	var normalized := raw * 0.5 + 0.5
	GlobalVariables.sky_light_level = lerpf(0.02, 1.0, normalized)
