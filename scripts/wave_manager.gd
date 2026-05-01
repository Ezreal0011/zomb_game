extends Node

## M5 wave spawner. Creates day/night enemy groups at random map edges.

const ConfigLoader := preload("res://scripts/config_loader.gd")
const ENEMY_SCENE := preload("res://scenes/Enemy.tscn")
const MAP_RECT := Rect2(Vector2(32, 32), Vector2(1216, 896))
const NO_MAP_SPAWN := Vector2(100000000.0, 100000000.0)

@export var enemies_container_path: NodePath
@export var player_path: NodePath
@export var game_manager_path: NodePath
@export var path_manager_path: NodePath

var enemy_config := {}
var wave_config := {}
var pending_night_spawns := 0
var map_controller: Node

@onready var enemies_container: Node2D = get_node(enemies_container_path)
@onready var player: Node2D = get_node(player_path)
@onready var game_manager: Node = get_node(game_manager_path)
@onready var path_manager: Node = get_node(path_manager_path)

func _ready() -> void:
	enemy_config = ConfigLoader.get_config("res://data/enemy_config.json")
	wave_config = ConfigLoader.get_config("res://data/wave_config.json")
	map_controller = get_tree().current_scene.get_node_or_null("World/CurrentMap")
	if map_controller != null and not map_controller.is_node_ready():
		await map_controller.ready

func spawn_for_phase(phase_name: String) -> void:
	if phase_name == "Day":
		pending_night_spawns = 0
		spawn_wave(_get_day_count())
	else:
		_start_night_batches(_get_night_count())

func spawn_wave(count: int) -> void:
	for index in range(count):
		var enemy: Node2D = ENEMY_SCENE.instantiate() as Node2D
		var config := _get_enemy_config_for_day()
		enemy.global_position = _get_offscreen_edge_spawn_position()
		enemies_container.add_child(enemy)
		enemy.setup(config, player, path_manager)

func _start_night_batches(total_count: int) -> void:
	pending_night_spawns = total_count
	_spawn_next_night_batch()

func _spawn_next_night_batch() -> void:
	if pending_night_spawns <= 0:
		return

	var batch_size: int = int(wave_config.get("night_spawn_batch_size", 4))
	var spawn_count: int = min(batch_size, pending_night_spawns)
	pending_night_spawns -= spawn_count
	spawn_wave(spawn_count)

	if pending_night_spawns > 0:
		var interval: float = float(wave_config.get("night_spawn_batch_interval", 3.0))
		await get_tree().create_timer(interval).timeout
		if pending_night_spawns > 0:
			_spawn_next_night_batch()

func _get_day_count() -> int:
	return int(wave_config.get("base_day_enemy_count", 3))

func _get_night_count() -> int:
	var base_count: int = int(wave_config.get("base_night_enemy_count", 15))
	var increase: int = int(wave_config.get("night_enemy_increase_per_day", 8))
	return base_count + max(game_manager.current_day - 1, 0) * increase

func _get_enemy_config_for_day() -> Dictionary:
	var enemy_id := _choose_enemy_id_for_day()
	var base_config: Dictionary = enemy_config.get(enemy_id, enemy_config.get("basic_enemy", {}))
	var scaled: Dictionary = base_config.duplicate(true)
	var interval: int = int(wave_config.get("enemy_power_scale_interval", 3))
	var scale_steps: int = int(max(game_manager.current_day - 1, 0) / max(interval, 1))
	if scale_steps > 0:
		var hp_scale: float = pow(float(wave_config.get("enemy_hp_scale", 1.2)), scale_steps)
		var damage_scale: float = pow(float(wave_config.get("enemy_damage_scale", 1.15)), scale_steps)
		scaled["hp"] = int(round(float(scaled.get("hp", 30)) * hp_scale))
		scaled["attack_damage"] = int(round(float(scaled.get("attack_damage", 10)) * damage_scale))
	return scaled

func _choose_enemy_id_for_day() -> String:
	var available: Array[String] = ["basic_enemy"]
	if game_manager.current_day >= int(wave_config.get("unlock_fast_enemy_day", 2)):
		available.append("fast_enemy")
	if game_manager.current_day >= int(wave_config.get("unlock_breaker_enemy_day", 4)):
		available.append("breaker_enemy")
	return available[randi_range(0, available.size() - 1)]

func _get_offscreen_edge_spawn_position() -> Vector2:
	var map_spawn := _get_map_spawn_position_outside_view()
	if map_spawn != NO_MAP_SPAWN:
		return map_spawn

	var candidates: Array[Vector2] = []
	for index in range(16):
		var candidate := _get_edge_spawn_position()
		if not _is_in_camera_view(candidate):
			candidates.append(candidate)
	if not candidates.is_empty():
		return candidates[randi_range(0, candidates.size() - 1)]
	return _get_edge_spawn_position()

func _get_map_spawn_position_outside_view() -> Vector2:
	if map_controller == null or not map_controller.has_method("get_enemy_spawn_positions"):
		return NO_MAP_SPAWN

	var positions: Array[Vector2] = []
	for raw_position in map_controller.get_enemy_spawn_positions():
		var position: Vector2 = raw_position
		positions.append(position)
	if positions.is_empty():
		return NO_MAP_SPAWN

	var outside_positions: Array[Vector2] = []
	for position in positions:
		if not _is_in_camera_view(position):
			outside_positions.append(position)
	if not outside_positions.is_empty():
		return outside_positions[randi_range(0, outside_positions.size() - 1)]
	return positions[randi_range(0, positions.size() - 1)]

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

func _is_in_camera_view(world_position: Vector2) -> bool:
	var viewport: Viewport = get_viewport()
	var camera: Camera2D = viewport.get_camera_2d()
	if camera == null:
		return false

	var view_size: Vector2 = viewport.get_visible_rect().size / camera.zoom
	var view_rect: Rect2 = Rect2(camera.global_position - view_size * 0.5, view_size).grow(96.0)
	return view_rect.has_point(world_position)
