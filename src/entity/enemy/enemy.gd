extends Entity
class_name Enemy

const PATROL_SPEED: float = 80.0
const CHASE_SPEED: float = 180.0
const DETECTION_RANGE: float = 300.0
const ATTACK_DAMAGE: float = 10.0
const ATTACK_COOLDOWN: float = 1.0
const JUMP_CHANCE: float = 0.02

var patrol_direction: float = 1.0
var attack_timer: float = 0.0
var target_player: Player = null

func _ready() -> void:
	super._ready()
	health = 50.0
	max_health = 50.0
	patrol_direction = [-1.0, 1.0].pick_random()
	died.connect(_on_died)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if !multiplayer.is_server():
		return

	attack_timer = max(0.0, attack_timer - delta)

	_find_target()

	if target_player and !target_player.is_dead:
		_chase(delta)
	else:
		_patrol(delta)

	_try_jump()

func _find_target() -> void:
	target_player = null
	var closest_dist: float = DETECTION_RANGE
	var players_node = get_parent()
	if !players_node:
		return

	for node in get_tree().get_nodes_in_group("players"):
		if node is Player and !node.is_dead:
			var dist = global_position.distance_to(node.global_position)
			if dist < closest_dist:
				closest_dist = dist
				target_player = node

func _chase(delta: float) -> void:
	var dir_to_player = global_position.direction_to(target_player.global_position)
	var relative_dir = rotate_vector_relative_to_up_direction(dir_to_player)
	var chase_dir = sign(relative_dir.x)
	if chase_dir == 0:
		chase_dir = patrol_direction

	var new_velocity = get_relative_velocity()
	new_velocity.x = move_toward(new_velocity.x, CHASE_SPEED * chase_dir, ACCELERATION * delta)
	set_relative_velocity(new_velocity)

func _patrol(delta: float) -> void:
	if is_on_wall():
		patrol_direction *= -1.0

	var new_velocity = get_relative_velocity()
	new_velocity.x = move_toward(new_velocity.x, PATROL_SPEED * patrol_direction, ACCELERATION * delta)
	set_relative_velocity(new_velocity)

func _try_jump() -> void:
	if is_on_floor() and (is_on_wall() or randf() < JUMP_CHANCE):
		jump()

func deal_contact_damage(body: Node2D) -> void:
	if !multiplayer.is_server():
		return
	if body is Player and !body.is_dead and attack_timer <= 0.0:
		body.take_damage(ATTACK_DAMAGE)
		attack_timer = ATTACK_COOLDOWN

func _on_died() -> void:
	queue_free()
