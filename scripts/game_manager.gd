extends Node

## Owns global M2 resource state and spawns resource nodes on empty map cells.

signal resource_changed(amount: int)
signal day_changed(day: int)
signal player_hp_changed(current_hp: int, max_hp: int)
signal game_over_changed(is_game_over: bool)

const ConfigLoader := preload("res://scripts/config_loader.gd")
const RESOURCE_SCENE := preload("res://scenes/ResourceNode.tscn")
const MAP_RECT := Rect2(Vector2(32, 32), Vector2(1216, 896))
const BLOCKING_MASK := 1 | 2 | 4 | 8 | 16 | 128

@export var resources_container_path: NodePath
@export var player_path: NodePath
@export var ui_path: NodePath
@export var weapon_manager_path: NodePath

var resource_count: int = 0
var current_day: int = 1
var is_game_over := false
var is_game_started := false
var grid_size: int = 32
var initial_resource_count: int = 40

@onready var resources_container: Node2D = get_node(resources_container_path)
@onready var player: Node2D = get_node(player_path)
@onready var ui: CanvasLayer = get_node(ui_path)
@onready var weapon_manager: Node = get_node(weapon_manager_path)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("game_manager")
	_load_config()
	if not ui.is_node_ready():
		await ui.ready
	resource_changed.connect(ui.set_resource_count)
	day_changed.connect(ui.set_day)
	player_hp_changed.connect(ui.set_player_hp)
	game_over_changed.connect(ui.set_game_over)
	ui.set_resource_count(resource_count)
	ui.set_day(current_day)
	ui.set_game_over(false)
	ui.set_start_screen(true)
	player.setup_health(ConfigLoader.get_config("res://data/game_config.json"), self)
	player.setup_weapon_manager(weapon_manager)
	await get_tree().physics_frame
	spawn_resources(initial_resource_count)
	get_tree().paused = true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if not is_game_started and event.keycode == KEY_ENTER:
			start_game()
		elif is_game_over and event.keycode == KEY_R:
			restart_game()

func start_game() -> void:
	is_game_started = true
	ui.set_start_screen(false)
	get_tree().paused = false

func add_resource(amount: int) -> void:
	resource_count += amount
	resource_changed.emit(resource_count)

func try_spend_resource(amount: int) -> bool:
	if resource_count < amount:
		return false

	resource_count -= amount
	resource_changed.emit(resource_count)
	return true

func advance_day() -> void:
	current_day += 1
	day_changed.emit(current_day)

func set_player_hp(current_hp: int, max_hp: int) -> void:
	player_hp_changed.emit(current_hp, max_hp)

func game_over() -> void:
	if is_game_over:
		return
	is_game_over = true
	game_over_changed.emit(true)
	get_tree().paused = true

func restart_game() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func spawn_resources(amount: int) -> void:
	var spawned := 0
	var attempts := 0
	var max_attempts := amount * 80
	while spawned < amount and attempts < max_attempts:
		attempts += 1
		var spawn_position := _get_random_grid_position()
		if _is_spawn_position_clear(spawn_position):
			var resource_node := RESOURCE_SCENE.instantiate()
			resource_node.global_position = spawn_position
			resources_container.add_child(resource_node)
			spawned += 1

func _load_config() -> void:
	var config := ConfigLoader.get_config("res://data/game_config.json")
	grid_size = int(config.get("grid_size", grid_size))
	initial_resource_count = int(config.get("initial_resource_count", initial_resource_count))

func _get_random_grid_position() -> Vector2:
	var min_x := int(MAP_RECT.position.x / grid_size)
	var max_x := int((MAP_RECT.position.x + MAP_RECT.size.x) / grid_size) - 1
	var min_y := int(MAP_RECT.position.y / grid_size)
	var max_y := int((MAP_RECT.position.y + MAP_RECT.size.y) / grid_size) - 1
	return Vector2(randi_range(min_x, max_x), randi_range(min_y, max_y)) * grid_size + Vector2.ONE * (grid_size * 0.5)

func _is_spawn_position_clear(world_position: Vector2) -> bool:
	if player.global_position.distance_to(world_position) < grid_size * 2.0:
		return false

	var shape := RectangleShape2D.new()
	shape.size = Vector2(grid_size * 0.8, grid_size * 0.8)

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, world_position)
	query.collision_mask = BLOCKING_MASK
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var space_state := resources_container.get_world_2d().direct_space_state
	return space_state.intersect_shape(query, 1).is_empty()
