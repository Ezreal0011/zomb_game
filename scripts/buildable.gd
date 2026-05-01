extends StaticBody2D

## Base class for player-built structures with health and destruction.

@export var building_id: String = ""
@export var max_hp: int = 100
@export var can_player_pass: bool = false
@export var can_enemy_pass: bool = false
@export var destructible: bool = true

var hp: int = max_hp
var is_flashing := false
var path_manager: Node

func setup(config: Dictionary) -> void:
	building_id = str(config.get("id", building_id))
	max_hp = int(config.get("hp", max_hp))
	can_player_pass = bool(config.get("can_player_pass", can_player_pass))
	can_enemy_pass = bool(config.get("can_enemy_pass", can_enemy_pass))
	destructible = bool(config.get("destructible", destructible))
	hp = max_hp
	_update_health_bar()

func setup_path_manager(manager: Node) -> void:
	path_manager = manager

func take_damage(amount: int) -> void:
	if not destructible:
		return

	hp = max(hp - amount, 0)
	_update_health_bar()
	_flash_hit()
	if hp == 0:
		destroy()

func destroy() -> void:
	if path_manager != null:
		path_manager.set_world_blocked(global_position, false)
	queue_free()

func _update_health_bar() -> void:
	var health_bar := get_node_or_null("HealthBar") as ProgressBar
	if health_bar == null:
		return
	health_bar.max_value = max_hp
	health_bar.value = hp
	health_bar.visible = hp < max_hp

func _flash_hit() -> void:
	if is_flashing:
		return
	is_flashing = true
	var visual := get_node_or_null("Visual") as CanvasItem
	if visual == null:
		is_flashing = false
		return

	var original_color := visual.modulate
	visual.modulate = Color(1, 0.2, 0.2, 1)
	await get_tree().create_timer(0.08).timeout
	if is_instance_valid(visual):
		visual.modulate = original_color
	is_flashing = false
