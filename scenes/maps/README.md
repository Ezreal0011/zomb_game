# Map Editing Notes

Open `res://scenes/maps/TestMap.tscn` to edit the current map directly.

You can also edit it from `res://scenes/Main.tscn`: expand `World/CurrentMap`, select `TileLayers/WallLayer`, then use the TileMap editor at the bottom of Godot.

## TileMapLayer Editing

The map has editable tile layers:

- `TileLayers/GroundLayer`
- `TileLayers/WallLayer`

Both use `res://scenes/maps/demo_tileset.tres`.

Tile atlas:

- Tile `0,0`: ground
- Tile `1,0`: default wall

Use Godot's TileMap painting tools to draw on these layers. Keep grid size at `32x32`.
Only tile `1,0` on `TileLayers/WallLayer` is treated as a wall for collision and pathfinding.

If the TileMap paint panel does not appear, make sure the selected node is exactly `TileLayers/WallLayer`, not `CurrentMap` or `TileLayers`.

## Runtime Collision

`TileLayers/WallLayer` is the source of truth for default walls.

`MapController` generates `StaticBody2D` collision under `WallCollisions` at runtime, and `PathManager` reads the same wall cells for enemy pathfinding. The old `DefaultWalls` node has been removed.

Move `PlayerSpawn` to change the player start position.

Add or move children under `EnemySpawnPoints` to control enemy spawn positions.
