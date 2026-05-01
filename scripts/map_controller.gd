extends Node2D

## Owns editable TileMapLayer map data and generates runtime collision from wall tiles.

const GRID_SIZE := 32
const DEFAULT_WALL_LAYER := 4
const WALL_ATLAS_COORDS := Vector2i(1, 0)

@onready var wall_layer: TileMapLayer = $TileLayers/WallLayer
@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var enemy_spawn_points: Node2D = $EnemySpawnPoints
@onready var wall_collision_root: Node2D = $WallCollisions

func _ready() -> void:
	generate_wall_collisions()

func generate_wall_collisions() -> void:
	for child in wall_collision_root.get_children():
		child.queue_free()

	for cell in wall_layer.get_used_cells():
		if not _is_wall_cell(cell):
			continue

		var body: StaticBody2D = StaticBody2D.new()
		body.name = "Wall_%d_%d" % [cell.x, cell.y]
		body.collision_layer = DEFAULT_WALL_LAYER
		body.collision_mask = 0

		var shape: CollisionShape2D = CollisionShape2D.new()
		var rect: RectangleShape2D = RectangleShape2D.new()
		rect.size = Vector2(GRID_SIZE, GRID_SIZE)
		shape.shape = rect
		body.add_child(shape)
		wall_collision_root.add_child(body)
		body.global_position = wall_layer.to_global(wall_layer.map_to_local(cell))

func get_wall_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell in wall_layer.get_used_cells():
		if _is_wall_cell(cell):
			cells.append(cell)
	return cells

func get_player_spawn_position() -> Vector2:
	return player_spawn.global_position

func get_enemy_spawn_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for child in enemy_spawn_points.get_children():
		if child is Node2D:
			var spawn_point: Node2D = child as Node2D
			positions.append(spawn_point.global_position)
	return positions

func _is_wall_cell(cell: Vector2i) -> bool:
	return wall_layer.get_cell_atlas_coords(cell) == WALL_ATLAS_COORDS
