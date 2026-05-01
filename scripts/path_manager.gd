extends Node

## Provides simple 32x32 AStarGrid2D paths around map wall tiles and player buildings.

const MAP_RECT := Rect2(Vector2(32, 32), Vector2(1216, 896))
const GRID_SIZE := 32

var astar := AStarGrid2D.new()
var map_controller: Node

func _ready() -> void:
	astar.region = Rect2i(1, 1, 38, 28)
	astar.cell_size = Vector2(GRID_SIZE, GRID_SIZE)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	map_controller = get_tree().current_scene.get_node_or_null("World/CurrentMap")
	if map_controller != null and not map_controller.is_node_ready():
		await map_controller.ready
	rebuild_static_obstacles()

func get_navigation_path(from_world: Vector2, to_world: Vector2) -> PackedVector2Array:
	var from_cell := _world_to_cell(from_world)
	var to_cell := _world_to_cell(to_world)
	if not astar.is_in_boundsv(from_cell) or not astar.is_in_boundsv(to_cell):
		return PackedVector2Array()

	if astar.is_point_solid(from_cell):
		from_cell = _find_nearest_open_cell(from_cell)
	if astar.is_point_solid(to_cell):
		to_cell = _find_nearest_open_cell(to_cell)

	if not astar.is_in_boundsv(from_cell) or not astar.is_in_boundsv(to_cell):
		return PackedVector2Array()

	var id_path: Array[Vector2i] = []
	for path_cell in astar.get_id_path(from_cell, to_cell):
		id_path.append(path_cell)
	var world_path := PackedVector2Array()
	for cell in id_path:
		world_path.append(_cell_to_world(cell))
	return world_path

func rebuild_static_obstacles() -> void:
	for x in range(astar.region.position.x, astar.region.end.x):
		for y in range(astar.region.position.y, astar.region.end.y):
			astar.set_point_solid(Vector2i(x, y), false)

	if map_controller != null and map_controller.has_method("get_wall_cells"):
		for raw_cell in map_controller.get_wall_cells():
			var cell: Vector2i = raw_cell
			if astar.is_in_boundsv(cell):
				astar.set_point_solid(cell, true)
		return

func set_world_blocked(world_position: Vector2, blocked: bool) -> void:
	var cell := _world_to_cell(world_position)
	if astar.is_in_boundsv(cell):
		astar.set_point_solid(cell, blocked)

func get_world_cell(world_position: Vector2) -> Vector2i:
	return _world_to_cell(world_position)

func _world_to_cell(world_position: Vector2) -> Vector2i:
	return Vector2i(floori(world_position.x / GRID_SIZE), floori(world_position.y / GRID_SIZE))

func _cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell) * GRID_SIZE + Vector2.ONE * (GRID_SIZE * 0.5)

func _find_nearest_open_cell(origin: Vector2i) -> Vector2i:
	for radius in range(1, 6):
		for x in range(origin.x - radius, origin.x + radius + 1):
			for y in range(origin.y - radius, origin.y + radius + 1):
				var cell := Vector2i(x, y)
				if astar.is_in_boundsv(cell) and not astar.is_point_solid(cell):
					return cell
	return origin
