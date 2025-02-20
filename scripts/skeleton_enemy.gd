extends "res://scripts/entity.gd"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	pass # Replace with function body.


func _on_detection_area_body_entered(body: Node2D) -> void:
	print("Entered Detection Area")
	targeting_actor = body
	is_following = true
	
	pass # Replace with function body.


func _on_detection_area_body_exited(body: Node2D) -> void:
	print("Exited Detection Area")

	targeting_actor = null
	is_following = false
	
	pass # Replace with function body.

func _physics_process(delta: float) -> void:
	#super._physics_process(delta)  # Runs parent physics first

	if is_following:
		position += (targeting_actor.position - position)/SPEED
		
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
