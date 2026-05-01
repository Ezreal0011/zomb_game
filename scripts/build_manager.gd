extends Node2D

## Handles M3 build mode, grid snapping, placement preview, and resource spending.

const ConfigLoader := preload("res://scripts/config_loader.gd")
const WALL_SCENE := preload("res://scenes/BuildWall.tscn")
const GATE_SCENE := preload("res://scenes/BuildGate.tscn")
const MAP_RECT := Rect2(Vector2(32, 32), Vector2(1216, 896))
const BLOCKING_MASK := 1 | 2 | 4 | 8 | 16 | 128
const PLACEMENT_CHECK_INSET := 6.0

@export var buildings_container_path: NodePath
@export var game_manager_path: NodePath
@export var ui_path: NodePath
@export var path_manager_path: NodePath
@export var grid_size: int = 32

var selected_building_id := ""
var building_config := {}
var was_left_mouse_pressed := false

@onready var buildings_container: Node2D = get_node(buildings_container_path)
@onready var game_manager: Node = get_node(game_manager_path)
@onready var ui: CanvasLayer = get_node(ui_path)
@onready var path_manager: Node = get_node(path_manager_path)
@onready var preview: Polygon2D = $Preview

func _ready() -> void:
	building_config = ConfigLoader.get_config("res://data/building_config.json")
	preview.visible = false
	queue_redraw()

func _process(_delta: float) -> void:
	_handle_mode_input()
	_update_preview()
	_handle_place_input()

func _handle_mode_input() -> void:
	if Input.is_action_just_pressed("build_wall"):
		selected_building_id = "wall"
		queue_redraw()
	elif Input.is_action_just_pressed("build_gate"):
		selected_building_id = "gate"
		queue_redraw()
	elif Input.is_action_just_pressed("cancel_build"):
		selected_building_id = ""
		ui.set_build_hint("")
		queue_redraw()

func _update_preview() -> void:
	if selected_building_id.is_empty():
		preview.visible = false
		ui.set_build_hint("")
		return

	var snapped_position := _get_snapped_mouse_position()
	var can_place := _can_place_at(snapped_position)
	var config: Dictionary = building_config.get(selected_building_id, {})
	var cost: int = int(config.get("cost", 0))
	var has_resource: bool = game_manager.has_resource(cost)
	preview.global_position = snapped_position
	if can_place and has_resource:
		preview.color = Color(0.1, 1.0, 0.2, 0.45)
	elif can_place and not has_resource:
		preview.color = Color(1.0, 0.85, 0.1, 0.45)
	else:
		preview.color = Color(1.0, 0.1, 0.1, 0.45)
	preview.visible = true
	ui.set_build_hint(_get_build_hint(snapped_position, can_place, has_resource, cost))

func _handle_place_input() -> void:
	var is_left_mouse_pressed := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var just_pressed_left_mouse := is_left_mouse_pressed and not was_left_mouse_pressed
	was_left_mouse_pressed = is_left_mouse_pressed

	if selected_building_id.is_empty():
		return
	if not just_pressed_left_mouse:
		return

	var place_position := _get_snapped_mouse_position()
	if not _can_place_at(place_position):
		return

	var config: Dictionary = building_config.get(selected_building_id, {})
	var cost: int = int(config.get("cost", 0))
	if not game_manager.try_spend_resource(cost):
		return

	var building := _create_building(selected_building_id)
	building.global_position = place_position
	building.setup(config)
	building.setup_path_manager(path_manager)
	buildings_container.add_child(building)
	path_manager.set_world_blocked(place_position, true)

func _create_building(building_id: String) -> StaticBody2D:
	if building_id == "gate":
		return GATE_SCENE.instantiate() as StaticBody2D
	return WALL_SCENE.instantiate() as StaticBody2D

func _get_snapped_mouse_position() -> Vector2:
	var mouse_position := get_global_mouse_position()
	return (mouse_position / float(grid_size)).floor() * grid_size + Vector2.ONE * (grid_size * 0.5)

func _can_place_at(world_position: Vector2) -> bool:
	if not MAP_RECT.has_point(world_position):
		return false

	var shape := RectangleShape2D.new()
	shape.size = Vector2.ONE * max(float(grid_size) - PLACEMENT_CHECK_INSET, 4.0)

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, world_position)
	query.collision_mask = BLOCKING_MASK
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var hits: Array[Dictionary] = get_world_2d().direct_space_state.intersect_shape(query, 1)
	return hits.is_empty()

func _get_build_hint(world_position: Vector2, can_place: bool, has_resource: bool, cost: int) -> String:
	var label := "Gate"
	if selected_building_id == "wall":
		label = "Wall"
	if not MAP_RECT.has_point(world_position):
		return "%s: outside build area" % label
	if not can_place:
		return "%s: occupied" % label
	if not has_resource:
		return "%s: need %d resources" % [label, cost]
	return "%s: cost %d" % [label, cost]

func _draw() -> void:
	if selected_building_id.is_empty():
		return

	var grid_color := Color(0.25, 0.8, 1.0, 0.14)
	var start_x := int(MAP_RECT.position.x)
	var end_x := int(MAP_RECT.end.x)
	var start_y := int(MAP_RECT.position.y)
	var end_y := int(MAP_RECT.end.y)
	for x in range(start_x, end_x + 1, grid_size):
		draw_line(Vector2(x, start_y), Vector2(x, end_y), grid_color, 1.0)
	for y in range(start_y, end_y + 1, grid_size):
		draw_line(Vector2(start_x, y), Vector2(end_x, y), grid_color, 1.0)
