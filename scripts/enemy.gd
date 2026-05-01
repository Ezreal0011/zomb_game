extends CharacterBody2D

## M6 enemy: chases the player, attacks the player, and breaks player buildings.

@export var max_hp: int = 30
@export var move_speed: float = 80.0
@export var attack_damage: int = 10
@export var attack_interval: float = 1.0
@export var attack_range: float = 24.0
@export var resource_drop: int = 1
@export var hit_stun_duration: float = 0.12

var hp: int = max_hp
var attack_cooldown := 0.0
var hit_stun_left := 0.0
var player: Node2D
var blocked_building: Node2D
var game_manager: Node
var is_flashing := false

func setup(config: Dictionary, target_player: Node2D) -> void:
	player = target_player
	max_hp = int(config.get("hp", max_hp))
	hp = max_hp
	_update_health_bar()
	move_speed = float(config.get("move_speed", move_speed))
	attack_damage = int(config.get("attack_damage", attack_damage))
	attack_interval = float(config.get("attack_interval", attack_interval))
	attack_range = float(config.get("attack_range", attack_range))
	resource_drop = int(config.get("resource_drop", resource_drop))
	var managers := get_tree().get_nodes_in_group("game_manager")
	if not managers.is_empty():
		game_manager = managers[0]

func _physics_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	attack_cooldown = max(attack_cooldown - delta, 0.0)
	hit_stun_left = max(hit_stun_left - delta, 0.0)
	if hit_stun_left > 0.0:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var to_player := player.global_position - global_position
	var distance := to_player.length()
	if distance <= attack_range:
		velocity = Vector2.ZERO
		move_and_slide()
		_attack_player()
		return

	velocity = to_player.normalized() * move_speed
	move_and_slide()
	blocked_building = _get_blocked_building()
	if blocked_building != null:
		velocity = Vector2.ZERO
		_attack_building(blocked_building)

func take_damage(amount: int) -> void:
	hp = max(hp - amount, 0)
	_update_health_bar()
	hit_stun_left = hit_stun_duration
	_flash_hit()
	if hp == 0:
		_award_resource_drop()
		queue_free()

func _attack_player() -> void:
	if attack_cooldown > 0.0:
		return
	attack_cooldown = attack_interval
	if player.has_method("take_damage"):
		player.take_damage(attack_damage)

func _attack_building(building: Node2D) -> void:
	if attack_cooldown > 0.0:
		return
	if not is_instance_valid(building):
		return

	attack_cooldown = attack_interval
	building.take_damage(attack_damage)

func _get_blocked_building() -> Node2D:
	for index in get_slide_collision_count():
		var collision := get_slide_collision(index)
		var collider := collision.get_collider()
		if collider is Node2D and collider.has_method("take_damage") and collider.is_in_group("player_buildings"):
			return collider
	return null

func _award_resource_drop() -> void:
	if game_manager == null:
		var managers := get_tree().get_nodes_in_group("game_manager")
		if not managers.is_empty():
			game_manager = managers[0]

	if game_manager != null:
		game_manager.add_resource(resource_drop)

func _update_health_bar() -> void:
	var health_bar := get_node_or_null("HealthBar") as ProgressBar
	if health_bar == null:
		return
	health_bar.max_value = max_hp
	health_bar.value = hp

func _flash_hit() -> void:
	if is_flashing:
		return
	is_flashing = true
	var visual := get_node_or_null("Polygon2D") as Polygon2D
	if visual == null:
		is_flashing = false
		return

	var original_color := visual.color
	visual.color = Color(1, 0.9, 0.9, 1)
	await get_tree().create_timer(0.08).timeout
	if is_instance_valid(visual):
		visual.color = original_color
	is_flashing = false
