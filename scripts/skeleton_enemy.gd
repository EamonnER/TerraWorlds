extends "res://scripts/entity.gd"

# SPEED_MODIFIER * SPEED is the final entity speed.
const SPEED_MODIFIER = 1

# Called when the node enters the scene tree for the first time.

func _ready() -> void:
	pass


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
	super._physics_process(delta)  # Runs parent physics first
	
	# Experiemental Logic for enemy following player.
	# temp is a temporary variable to calculate the direction the enemy should move in.
	# this should be changed because it is not ideal and causes issues when an enemy is directly above player.
	var temp
	var new_velocity = get_relative_velocity()
	if targeting_actor:
		temp = targeting_actor.position - position
		#print(temp)
	if is_following:
		new_velocity.x = move_toward(new_velocity.x, SPEED*SPEED_MODIFIER*sign(temp.x), ACCELERATION*delta)
		
	set_relative_velocity(new_velocity)
	move_and_slide()
		
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
