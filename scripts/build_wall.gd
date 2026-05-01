extends "res://scripts/buildable.gd"

## Player-built wall. Blocks player and enemy movement in the M3 demo.

func _ready() -> void:
	add_to_group("player_buildings")
