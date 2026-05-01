extends Node

## M5 wave spawner. Creates day/night enemy groups at random map edges.

const ConfigLoader := preload("res://scripts/config_loader.gd")
const ENEMY_SCENE := preload("res://scenes/Enemy.tscn")
const MAP_RECT := Rect2(Vector2(32, 32), Vector2(1216, 896))

@export var enemies_container_path: NodePath
@export var player_path: NodePath
@export var game_manager_path: NodePath

var enemy_config := {}
var wave_config := {}

@onready var enemies_container: Node2D = get_node(enemies_container_path)
@onready var player: Node2D = get_node(player_path)
@onready var game_manager: Node = get_node(game_manager_path)

func _ready() -> void:
	enemy_config = ConfigLoader.get_config("res://data/enemy_config.json")
	wave_config = ConfigLoader.get_config("res://data/wave_config.json")

func spawn_for_phase(phase_name: String) -> void:
	if phase_name == "Day":
		spawn_wave(_get_day_count())
	else:
		spawn_wave(_get_night_count())

func spawn_wave(count: int) -> void:
	for index in count:
		var enemy := ENEMY_SCENE.instantiate()
		var config := _get_enemy_config_for_day()
		enemy.global_position = _get_edge_spawn_position()
		enemies_container.add_child(enemy)
		enemy.setup(config, player)

func _get_day_count() -> int:
	return int(wave_config.get("base_day_enemy_count", 3))

func _get_night_count() -> int:
	var base_count := int(wave_config.get("base_night_enemy_count", 15))
	var increase := int(wave_config.get("night_enemy_increase_per_day", 8))
	return base_count + max(game_manager.current_day - 1, 0) * increase

func _get_enemy_config_for_day() -> Dictionary:
	var enemy_id := _choose_enemy_id_for_day()
	var base_config: Dictionary = enemy_config.get(enemy_id, enemy_config.get("basic_enemy", {}))
	var scaled := base_config.duplicate(true)
	var interval := int(wave_config.get("enemy_power_scale_interval", 3))
	var scale_steps := int(max(game_manager.current_day - 1, 0) / max(interval, 1))
	if scale_steps > 0:
		var hp_scale := pow(float(wave_config.get("enemy_hp_scale", 1.2)), scale_steps)
		var damage_scale := pow(float(wave_config.get("enemy_damage_scale", 1.15)), scale_steps)
		scaled["hp"] = int(round(float(scaled.get("hp", 30)) * hp_scale))
		scaled["attack_damage"] = int(round(float(scaled.get("attack_damage", 10)) * damage_scale))
	return scaled

func _choose_enemy_id_for_day() -> String:
	var available := ["basic_enemy"]
	if game_manager.current_day >= int(wave_config.get("unlock_fast_enemy_day", 2)):
		available.append("fast_enemy")
	if game_manager.current_day >= int(wave_config.get("unlock_breaker_enemy_day", 4)):
		available.append("breaker_enemy")
	return available.pick_random()

func _get_edge_spawn_position() -> Vector2:
	var side := randi_range(0, 3)
	var left := MAP_RECT.position.x + 16.0
	var right := MAP_RECT.end.x - 16.0
	var top := MAP_RECT.position.y + 16.0
	var bottom := MAP_RECT.end.y - 16.0
	match side:
		0:
			return Vector2(randf_range(left, right), top)
		1:
			return Vector2(randf_range(left, right), bottom)
		2:
			return Vector2(left, randf_range(top, bottom))
		_:
			return Vector2(right, randf_range(top, bottom))
