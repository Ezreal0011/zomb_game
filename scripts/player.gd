extends CharacterBody2D

## Handles movement, mouse aiming, shooting, upgrades, and health.

const PROJECTILE_SCENE := preload("res://scenes/Projectile.tscn")

@export var move_speed: float = 180.0
@export var max_hp: int = 100
@export var muzzle_distance: float = 22.0

var hp: int = max_hp
var game_manager: Node
var weapon_manager: Node
var attack_cooldown := 0.0

@onready var body_visual: Polygon2D = $Polygon2D
@onready var muzzle_flash: Polygon2D = $MuzzleFlash

func _physics_process(delta: float) -> void:
	if hp <= 0:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	attack_cooldown = max(attack_cooldown - delta, 0.0)
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_vector * move_speed
	move_and_slide()
	_aim_at_mouse()
	_handle_attack_input()
	_handle_upgrade_input()

func setup_health(config: Dictionary, manager: Node) -> void:
	game_manager = manager
	max_hp = int(config.get("player_max_hp", max_hp))
	move_speed = float(config.get("player_move_speed", move_speed))
	hp = max_hp
	if game_manager != null:
		game_manager.set_player_hp(hp, max_hp)

func setup_weapon_manager(manager: Node) -> void:
	weapon_manager = manager

func take_damage(amount: int) -> void:
	if hp <= 0:
		return

	hp = max(hp - amount, 0)
	if game_manager != null:
		game_manager.set_player_hp(hp, max_hp)
		if hp == 0:
			game_manager.game_over()

func _handle_attack_input() -> void:
	if weapon_manager == null:
		return
	if attack_cooldown > 0.0:
		return
	if not Input.is_action_pressed("attack"):
		return

	attack_cooldown = weapon_manager.get_attack_interval()
	_fire_projectile()

func _handle_upgrade_input() -> void:
	if weapon_manager == null:
		return
	if Input.is_action_just_pressed("upgrade_weapon"):
		weapon_manager.try_upgrade()

func _aim_at_mouse() -> void:
	var aim_direction := get_global_mouse_position() - global_position
	if aim_direction.length_squared() <= 0.01:
		return
	rotation = aim_direction.angle() + PI * 0.5

func _fire_projectile() -> void:
	var shoot_direction := (get_global_mouse_position() - global_position).normalized()
	if shoot_direction.length_squared() <= 0.01:
		shoot_direction = Vector2.UP.rotated(rotation)

	var projectile := PROJECTILE_SCENE.instantiate()
	get_parent().add_child(projectile)
	projectile.setup(global_position + shoot_direction * muzzle_distance, shoot_direction, weapon_manager.get_damage())
	_show_muzzle_flash()

func _show_muzzle_flash() -> void:
	muzzle_flash.position = Vector2(0, -muzzle_distance)
	muzzle_flash.visible = true
	await get_tree().create_timer(0.06).timeout
	if is_instance_valid(muzzle_flash):
		muzzle_flash.visible = false
